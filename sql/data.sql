-- Fictional data exported from agence-immobiliere.odb.

INSERT INTO agence (id_agence, nom, adresse, ville) VALUES
    (0, 'Maison & Vous', '7 rue des Jardins', 'Tours'),
    (1, 'Les Clefs de la Ville', '22 rue des Carmes', 'Bordeaux'),
    (2, 'Horizon Immobilier', '12 avenue de la République', 'Paris');

INSERT INTO proprietaire (id_proprio, nom, prenom, tel, adresse) VALUES
    (0, 'Luc', 'Bastien', '07 89 14 62 35', '63 chemin des Vignes'),
    (1, 'Martin', 'Julien', '06 45 82 19 37', '18 rue des Tilleuls'),
    (2, 'Dupont', 'Claire', '07 12 34 56 78', '42 avenue Victor Hugo'),
    (3, 'Bernard', 'Lucas', '06 98 45 21 64', '5 rue de la Liberté'),
    (4, 'Lefevre', 'Sophie', '06 23 67 89 10', '27 boulevard Gambetta'),
    (5, 'Moreau', 'Antoine', '07 55 44 33 22', '9 impasse des Jardins'),
    (6, 'Petit', 'Elodie', '06 11 22 33 44', '14 rue Pasteur');

INSERT INTO entrepreneur (id_entrepreneur, nom_societe, metier, tel) VALUES
    (0, 'SOS Plomberie', 'Plombier', '06 12 34 56 78'),
    (1, 'Elec Express', 'Électricien', '06 98 76 54 32'),
    (2, 'Peinture & Déco 86', 'Peintre', '07 45 12 36 98'),
    (3, 'Jardinage du Poitou', 'Paysagiste', '05 49 00 11 22'),
    (4, 'Serrurerie Durand', 'Serrurier', '06 11 22 33 44'),
    (5, 'Nettoyage Pro', 'Nettoyage', '05 55 66 77 88'),
    (6, 'Chauffage Confort', 'Chauffagiste', '07 88 99 00 11');

INSERT INTO locataire (id_locataire, nom, prenom, tel, solde_compte) VALUES
    (0, 'LACROIX', 'Anne-Claire', '06 12 34 56 78', 0.00),
    (1, 'LAFFERIERE', 'Françis', '06 98 76 54 32', 0.00),
    (2, 'DUMONT', 'Pierre', '07 45 12 65 98', 0.00),
    (3, 'RICHARD', 'Emma', '06 11 22 33 44', -450.00),
    (4, 'MOREL', 'Thomas', '07 55 66 77 88', 150.00);

INSERT INTO personnel (id_personnel, nom, prenom, id_agence) VALUES
    (0, 'CHARRAUD', 'Jérôme', 2),
    (2, 'DUPONT', 'Alice', 2),
    (3, 'MARTIN', 'Paul', 1),
    (4, 'LEROY', 'Sarah', 0),
    (5, 'PETIT', 'Thomas', 1);

INSERT INTO bien (id_bien, adresse, code_postal, ville, surface, loyer_hc, charges, type_mandat, id_proprio, id_agence, id_personnel_gestionnaire) VALUES
    (0, '12 Rue de la Regratterie', '86000', 'Poitiers', 85.00, 750.00, 50.00, 'SIMPLE', 1, 2, 0),
    (4, '5 Impasse des Roses', '86000', 'Poitiers', 100.00, 900.00, 0.00, 'GESTION', 2, 2, 0),
    (6, '42 Av de la Gare', '86100', 'Chatellerault', 25.00, 350.00, 30.00, 'GESTION', 3, 0, 4),
    (7, '25 rue Honoré Mirabeau', '86300', 'Chauvigny', 45.00, 500.00, 40.00, 'SIMPLE', 4, 1, 5),
    (11, '1 Place de la Liberté', '86000', 'Poitiers', 150.00, 1500.00, 300.00, 'GESTION', 0, 1, 3);

INSERT INTO contrat_bail (id_bail, date_debut, date_fin, id_bien, id_locataire, id_agence) VALUES
    (4, '2023-01-01', '2026-01-01', 0, 0, 2),
    (9, '2024-03-15', NULL, 4, 1, 2),
    (11, '2024-09-01', '2025-06-30', 6, 2, 0),
    (12, '2022-01-01', '2023-12-31', 7, 3, 1),
    (99, '2018-01-01', '2020-01-01', 0, 0, 2);

INSERT INTO facture (id_facture, date_facture, montant, objet, id_bien, id_entrepreneur) VALUES
    (1, '2024-12-30', 1200.00, 'Remplacement Chaudière', 4, 6),
    (2, '2024-02-10', 85.00, 'Réparation fuite évier', 11, 0),
    (6, '2024-09-05', 450.00, 'Peinture Salon', 6, 2),
    (7, '2023-12-20', 150.00, 'Nettoyage Complet', 7, 5),
    (99, '2018-02-15', 1200.00, 'Remplacement Chaudière', 0, 6);

INSERT INTO paiement (id_paiement, date_paiement, montant, moyen_paiement, id_bail) VALUES
    (8, '2025-01-05', 800.00, 'Virement', 4),
    (9, '2025-02-05', 800.00, 'Virement', 4),
    (10, '2025-02-01', 900.00, 'Chèque', 9),
    (11, '2025-01-10', 380.00, 'Prélèvement', 11),
    (12, '2023-12-01', 540.00, 'Virement', 12);
