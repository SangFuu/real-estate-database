"""Checks sql/ with SQLite (Python standard library only).

    python -m unittest discover -s tests -v
"""

import re
import sqlite3
import unittest
from pathlib import Path

SQL = Path(__file__).resolve().parent.parent / "sql"


def load_queries() -> dict[str, str]:
    text = (SQL / "queries.sql").read_text(encoding="utf-8")
    blocks = re.split(r"\n(?=-- Q\d+\.)", text)[1:]
    return {re.match(r"-- (Q\d+)\.", b).group(1): b for b in blocks}


QUERIES = load_queries()


class DatabaseTestCase(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(":memory:")
        self.db.execute("PRAGMA foreign_keys = ON")
        self.db.executescript((SQL / "schema.sql").read_text(encoding="utf-8"))
        self.db.executescript((SQL / "data.sql").read_text(encoding="utf-8"))

    def tearDown(self):
        self.db.close()

    def query(self, name):
        return self.db.execute(QUERIES[name]).fetchall()

    def assertRejected(self, sql):
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute(sql)


class DataTests(DatabaseTestCase):
    def test_row_counts(self):
        expected = {"agence": 3, "proprietaire": 7, "entrepreneur": 7, "locataire": 5, "personnel": 5,
                    "bien": 5, "contrat_bail": 5, "facture": 5, "paiement": 5}
        for table, count in expected.items():
            self.assertEqual(self.db.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0], count, table)

    def test_foreign_keys_are_consistent(self):
        self.assertEqual(self.db.execute("PRAGMA foreign_key_check").fetchall(), [])


class ConstraintTests(DatabaseTestCase):
    def test_rent_must_be_positive(self):
        self.assertRejected("INSERT INTO bien VALUES (50, 'x', '86000', 'Poitiers', 30, 0, 0, 'SIMPLE', 0, 0, NULL)")

    def test_unknown_mandate_type(self):
        self.assertRejected("INSERT INTO bien VALUES (50, 'x', '86000', 'Poitiers', 30, 400, 0, 'VENTE', 0, 0, NULL)")

    def test_postcode_has_five_characters(self):
        self.assertRejected("INSERT INTO bien VALUES (50, 'x', '860', 'Poitiers', 30, 400, 0, 'SIMPLE', 0, 0, NULL)")

    def test_lease_must_end_after_it_starts(self):
        self.assertRejected("INSERT INTO contrat_bail VALUES (500, '2025-06-01', '2025-01-01', 0, 0, 0)")

    def test_open_lease_is_allowed(self):
        self.db.execute("INSERT INTO contrat_bail VALUES (500, '2025-06-01', NULL, 11, 4, 1)")

    def test_unknown_payment_method(self):
        self.assertRejected("INSERT INTO paiement VALUES (500, '2025-03-01', 100, 'Bitcoin', 9)")

    def test_foreign_key(self):
        self.assertRejected("INSERT INTO facture VALUES (500, '2025-03-01', 100, 'Test', 999, 0)")


class QueryTests(DatabaseTestCase):
    def test_every_query_runs(self):
        for name in QUERIES:
            with self.subTest(query=name):
                self.query(name)

    def test_q2_agency(self):
        self.assertEqual(self.query("Q2"), [("Horizon Immobilier", "Paris")])

    def test_q3_rented_on_date(self):
        self.assertEqual({r[0] for r in self.query("Q3")}, {"12 Rue de la Regratterie", "5 Impasse des Roses"})

    def test_q7_rent_total(self):
        self.assertEqual(self.query("Q7"), [("42 Av de la Gare", 380), ("5 Impasse des Roses", 900)])

    def test_q9_work_during_lease(self):
        self.assertEqual(self.query("Q9"), [(1200,)])

    def test_q10_not_in_chatellerault(self):
        self.assertEqual({r[0] for r in self.query("Q10")}, {"Chauffage Confort", "SOS Plomberie"})

    def test_q11_tenants_in_debt(self):
        self.assertEqual(self.query("Q11"), [("RICHARD", "Emma", -450)])

    def test_q13_balance(self):
        rows = {r[0]: r[3] for r in self.query("Q13")}
        self.assertEqual(rows["12 Rue de la Regratterie"], 400)
        self.assertEqual(rows["5 Impasse des Roses"], -300)


if __name__ == "__main__":
    unittest.main()
