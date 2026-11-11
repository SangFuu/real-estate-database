-- Queries from the project, rewritten for sql/schema.sql.
-- They run unchanged on SQLite and PostgreSQL.

-- Q1. Biens à Poitiers de plus de 80 m², loyer < 800 €, dont un bail est terminé
SELECT b.id_bien, b.adresse, b.surface, b.loyer_hc
FROM bien b
WHERE b.ville = 'Poitiers'
  AND b.surface > 80
  AND b.loyer_hc < 800
  AND b.id_bien IN (SELECT id_bien FROM contrat_bail WHERE date_fin <= CURRENT_DATE);

-- Q2. Agence qui gère le bail d'Anne-Claire Lacroix
SELECT DISTINCT a.nom, a.ville
FROM agence a
JOIN contrat_bail c ON c.id_agence = a.id_agence
JOIN locataire l    ON l.id_locataire = c.id_locataire
WHERE l.nom = 'LACROIX' AND l.prenom = 'Anne-Claire';

-- Q3. Biens de plus de 80 m² loués au 10 décembre 2024
SELECT b.adresse, b.ville, b.surface
FROM bien b
JOIN contrat_bail c ON c.id_bien = b.id_bien
WHERE b.surface > 80
  AND c.date_debut <= '2024-12-10'
  AND (c.date_fin IS NULL OR c.date_fin >= '2024-12-10');

-- Q4. Biens en gestion de l'agence où travaille Jérôme Charraud
SELECT b.id_bien, b.adresse, b.ville
FROM bien b
WHERE b.type_mandat = 'GESTION'
  AND b.id_agence = (SELECT id_agence FROM personnel WHERE nom = 'CHARRAUD' AND prenom = 'Jérôme');

-- Q5. Locataires du même propriétaire que Françis Lafferiere
SELECT DISTINCT l.nom, l.prenom
FROM locataire l
JOIN contrat_bail c ON c.id_locataire = l.id_locataire
JOIN bien b         ON b.id_bien = c.id_bien
WHERE b.id_proprio IN (
    SELECT b2.id_proprio
    FROM bien b2
    JOIN contrat_bail c2 ON c2.id_bien = b2.id_bien
    JOIN locataire l2    ON l2.id_locataire = c2.id_locataire
    WHERE l2.nom = 'LAFFERIERE' AND l2.prenom = 'Françis'
);

-- Q6. Factures de remplacement de chaudière sur des biens dont un bail a commencé en 2018
SELECT DISTINCT f.id_facture, f.montant, f.date_facture
FROM facture f
JOIN contrat_bail c ON c.id_bien = f.id_bien
WHERE f.objet LIKE '%Remplacement Chaudière%'
  AND c.date_debut >= '2018-01-01' AND c.date_debut < '2019-01-01';

-- Q7. Total des loyers encaissés depuis 2025 pour les biens en gestion
SELECT b.adresse, SUM(p.montant) AS total_loyers
FROM paiement p
JOIN contrat_bail c ON c.id_bail = p.id_bail
JOIN bien b         ON b.id_bien = c.id_bien
WHERE b.type_mandat = 'GESTION' AND p.date_paiement >= '2025-01-01'
GROUP BY b.adresse
ORDER BY b.adresse;

-- Q8. Propriétaire qui a le plus de biens loués en ce moment
SELECT p.nom, p.prenom, COUNT(DISTINCT b.id_bien) AS nb_biens_loues
FROM proprietaire p
JOIN bien b         ON b.id_proprio = p.id_proprio
JOIN contrat_bail c ON c.id_bien = b.id_bien
WHERE c.date_fin IS NULL OR c.date_fin > CURRENT_DATE
GROUP BY p.id_proprio, p.nom, p.prenom
ORDER BY nb_biens_loues DESC
LIMIT 1;

-- Q9. Montant des travaux facturés pendant le bail n° 99
SELECT SUM(f.montant) AS total_travaux
FROM facture f
JOIN contrat_bail c ON c.id_bien = f.id_bien
WHERE c.id_bail = 99
  AND f.date_facture BETWEEN c.date_debut AND COALESCE(c.date_fin, CURRENT_DATE);

-- Q10. Entrepreneurs qui ont travaillé à Poitiers mais jamais à Châtellerault
SELECT DISTINCT e.nom_societe
FROM entrepreneur e
JOIN facture f ON f.id_entrepreneur = e.id_entrepreneur
JOIN bien b    ON b.id_bien = f.id_bien
WHERE b.ville = 'Poitiers'
  AND NOT EXISTS (
    SELECT 1
    FROM facture f2
    JOIN bien b2 ON b2.id_bien = f2.id_bien
    WHERE f2.id_entrepreneur = e.id_entrepreneur AND b2.ville = 'Chatellerault'
  );

-- Q11. Locataires débiteurs (solde négatif)
SELECT nom, prenom, solde_compte
FROM locataire
WHERE solde_compte < 0
ORDER BY solde_compte;

-- Q12. Biens sans bail en cours
SELECT b.id_bien, b.adresse, b.ville, b.loyer_hc
FROM bien b
WHERE NOT EXISTS (
    SELECT 1 FROM contrat_bail c
    WHERE c.id_bien = b.id_bien
      AND c.date_debut <= CURRENT_DATE
      AND (c.date_fin IS NULL OR c.date_fin > CURRENT_DATE)
)
ORDER BY b.id_bien;

-- Q13. Bilan par bien : loyers encaissés moins travaux facturés
WITH loyers AS (
    SELECT c.id_bien, SUM(p.montant) AS total
    FROM paiement p JOIN contrat_bail c ON c.id_bail = p.id_bail
    GROUP BY c.id_bien
), travaux AS (
    SELECT id_bien, SUM(montant) AS total
    FROM facture
    GROUP BY id_bien
)
SELECT b.adresse,
       COALESCE(l.total, 0) AS loyers,
       COALESCE(t.total, 0) AS travaux,
       COALESCE(l.total, 0) - COALESCE(t.total, 0) AS bilan
FROM bien b
LEFT JOIN loyers l  ON l.id_bien = b.id_bien
LEFT JOIN travaux t ON t.id_bien = b.id_bien
ORDER BY bilan DESC;
