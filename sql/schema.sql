-- Real-estate agency database, standard SQL.
-- Tested with SQLite 3 and PostgreSQL 16.
-- Rewritten by hand from the LibreOffice Base (HSQLDB) version in hsqldb/.

CREATE TABLE agence (
    id_agence   INTEGER      PRIMARY KEY,
    nom         VARCHAR(100) NOT NULL,
    adresse     VARCHAR(250),
    ville       VARCHAR(100) NOT NULL
);

CREATE TABLE proprietaire (
    id_proprio  INTEGER      PRIMARY KEY,
    nom         VARCHAR(50)  NOT NULL,
    prenom      VARCHAR(50)  NOT NULL,
    tel         VARCHAR(20),
    adresse     VARCHAR(250)
);

CREATE TABLE entrepreneur (
    id_entrepreneur INTEGER      PRIMARY KEY,
    nom_societe     VARCHAR(100) NOT NULL,
    metier          VARCHAR(50),
    tel             VARCHAR(20)
);

CREATE TABLE locataire (
    id_locataire INTEGER      PRIMARY KEY,
    nom          VARCHAR(50)  NOT NULL,
    prenom       VARCHAR(50)  NOT NULL,
    tel          VARCHAR(20),
    solde_compte NUMERIC(9,2) NOT NULL DEFAULT 0  -- negative = the tenant owes money
);

CREATE TABLE personnel (
    id_personnel INTEGER     PRIMARY KEY,
    nom          VARCHAR(50) NOT NULL,
    prenom       VARCHAR(50) NOT NULL,
    id_agence    INTEGER     NOT NULL,
    CONSTRAINT fk_personnel_agence FOREIGN KEY (id_agence) REFERENCES agence (id_agence)
);

CREATE TABLE bien (
    id_bien                   INTEGER      PRIMARY KEY,
    adresse                   VARCHAR(250) NOT NULL,
    code_postal               CHAR(5)      NOT NULL,
    ville                     VARCHAR(100) NOT NULL,
    surface                   NUMERIC(6,2) NOT NULL,
    loyer_hc                  NUMERIC(7,2) NOT NULL,
    charges                   NUMERIC(7,2) NOT NULL DEFAULT 0,
    type_mandat               VARCHAR(10)  NOT NULL,
    id_proprio                INTEGER      NOT NULL,
    id_agence                 INTEGER      NOT NULL,
    id_personnel_gestionnaire INTEGER,
    CONSTRAINT ck_bien_code_postal CHECK (LENGTH(code_postal) = 5),
    CONSTRAINT ck_bien_surface     CHECK (surface > 0),
    CONSTRAINT ck_bien_loyer       CHECK (loyer_hc > 0),
    CONSTRAINT ck_bien_charges     CHECK (charges >= 0),
    CONSTRAINT ck_bien_mandat      CHECK (type_mandat IN ('SIMPLE', 'GESTION')),
    CONSTRAINT fk_bien_proprio     FOREIGN KEY (id_proprio) REFERENCES proprietaire (id_proprio),
    CONSTRAINT fk_bien_agence      FOREIGN KEY (id_agence) REFERENCES agence (id_agence),
    CONSTRAINT fk_bien_gestionnaire FOREIGN KEY (id_personnel_gestionnaire) REFERENCES personnel (id_personnel)
);

CREATE TABLE contrat_bail (
    id_bail      INTEGER PRIMARY KEY,
    date_debut   DATE    NOT NULL,
    date_fin     DATE,                       -- NULL = lease still running
    id_bien      INTEGER NOT NULL,
    id_locataire INTEGER NOT NULL,
    id_agence    INTEGER NOT NULL,
    CONSTRAINT ck_bail_dates     CHECK (date_fin IS NULL OR date_fin > date_debut),
    CONSTRAINT fk_bail_bien      FOREIGN KEY (id_bien) REFERENCES bien (id_bien),
    CONSTRAINT fk_bail_locataire FOREIGN KEY (id_locataire) REFERENCES locataire (id_locataire),
    CONSTRAINT fk_bail_agence    FOREIGN KEY (id_agence) REFERENCES agence (id_agence)
);

CREATE TABLE facture (
    id_facture      INTEGER      PRIMARY KEY,
    date_facture    DATE         NOT NULL,
    montant         NUMERIC(9,2) NOT NULL,
    objet           VARCHAR(255) NOT NULL,
    id_bien         INTEGER      NOT NULL,
    id_entrepreneur INTEGER      NOT NULL,
    CONSTRAINT ck_facture_montant      CHECK (montant > 0),
    CONSTRAINT fk_facture_bien         FOREIGN KEY (id_bien) REFERENCES bien (id_bien),
    CONSTRAINT fk_facture_entrepreneur FOREIGN KEY (id_entrepreneur) REFERENCES entrepreneur (id_entrepreneur)
);

CREATE TABLE paiement (
    id_paiement    INTEGER      PRIMARY KEY,
    date_paiement  DATE         NOT NULL,
    montant        NUMERIC(9,2) NOT NULL,
    moyen_paiement VARCHAR(20)  NOT NULL,
    id_bail        INTEGER      NOT NULL,
    CONSTRAINT ck_paiement_montant CHECK (montant > 0),
    CONSTRAINT ck_paiement_moyen   CHECK (moyen_paiement IN ('Virement', 'Chèque', 'Prélèvement', 'Espèces', 'Carte')),
    CONSTRAINT fk_paiement_bail    FOREIGN KEY (id_bail) REFERENCES contrat_bail (id_bail)
);

-- Indexes on foreign keys and on the columns used in the queries.
CREATE INDEX idx_personnel_agence  ON personnel (id_agence);
CREATE INDEX idx_bien_proprio      ON bien (id_proprio);
CREATE INDEX idx_bien_agence       ON bien (id_agence);
CREATE INDEX idx_bien_ville        ON bien (ville);
CREATE INDEX idx_bail_bien         ON contrat_bail (id_bien);
CREATE INDEX idx_bail_locataire    ON contrat_bail (id_locataire);
CREATE INDEX idx_facture_bien      ON facture (id_bien);
CREATE INDEX idx_facture_entrepr   ON facture (id_entrepreneur);
CREATE INDEX idx_paiement_bail     ON paiement (id_bail);
