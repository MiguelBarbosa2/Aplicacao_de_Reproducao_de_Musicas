DROP TABLE contem CASCADE CONSTRAINTS;
DROP TABLE agrega CASCADE CONSTRAINTS;
DROP TABLE tem CASCADE CONSTRAINTS;
DROP TABLE guarda CASCADE CONSTRAINTS;
DROP TABLE segue CASCADE CONSTRAINTS;
DROP TABLE Albuns CASCADE CONSTRAINTS;
DROP TABLE Musicas CASCADE CONSTRAINTS;
DROP TABLE PlayLists CASCADE CONSTRAINTS;
DROP TABLE Pagamentos CASCADE CONSTRAINTS;
DROP TABLE SubscricoesFamily CASCADE CONSTRAINTS;
DROP TABLE SubscricoesPremium CASCADE CONSTRAINTS;
DROP TABLE SubscricoesPagas CASCADE CONSTRAINTS;
DROP TABLE Pacotes CASCADE CONSTRAINTS;
DROP TABLE Artistas CASCADE CONSTRAINTS;
DROP TABLE SubscricoesFree CASCADE CONSTRAINTS;
DROP TABLE Contas CASCADE CONSTRAINTS;
DROP SEQUENCE seq_num_idContas;
DROP SEQUENCE seq_num_idMusicas;
DROP SEQUENCE seq_num_idAlbuns;
DROP SEQUENCE seq_num_idPlayLists;

-- Create all tables
CREATE TABLE Contas (
    id NUMBER(10) PRIMARY KEY,
    nome VARCHAR(50),
    email VARCHAR(100),
    userPassword VARCHAR(255)
);

CREATE TABLE SubscricoesFree (
    id NUMBER(10) PRIMARY KEY
);

CREATE TABLE Artistas (
    id NUMBER(10) PRIMARY KEY
);

CREATE TABLE Pacotes (
    meses INT,
    tipo VARCHAR(7),
    preco DECIMAL(5, 2),
    CHECK (meses IN (1, 3, 6, 12)),
    CHECK (tipo IN ('Premium', 'Family')),
    PRIMARY KEY (meses, tipo)
);

CREATE TABLE SubscricoesPagas (
    id NUMBER(10) PRIMARY KEY,
    meses INT,
    tipo VARCHAR(7),
    dataInicio DATE
);

CREATE TABLE SubscricoesPremium (
    id NUMBER(10) PRIMARY KEY
);

CREATE TABLE SubscricoesFamily (
    id NUMBER(10) PRIMARY KEY
);

CREATE TABLE Pagamentos (
    id NUMBER(10),
    numP INT,
    montante NUMERIC(5, 2),
    data DATE,
    PRIMARY KEY (id, numP)
);

CREATE TABLE PlayLists (
    idPlayList NUMBER(20) PRIMARY KEY,
    id NUMBER(10),
    nomeP VARCHAR(100)
);

CREATE TABLE Musicas (
    idMusica NUMBER(20) PRIMARY KEY,
    id NUMBER(10),
    nomeM VARCHAR2(30),
    tempo VARCHAR2(5),
    genero VARCHAR2(10),
    CONSTRAINT chk_tempo_format CHECK (
        REGEXP_LIKE(tempo, '^\d{2}:\d{2}$')
    )
);

CREATE TABLE Albuns (
    idAlbum NUMBER(20) PRIMARY KEY,
    id NUMBER(10),
    titulo VARCHAR(30),
    dataLancamento DATE
);

CREATE TABLE segue (
    id_SubscricoesFree NUMBER(10),
    id_Artistas NUMBER(10),
    PRIMARY KEY (id_SubscricoesFree, id_Artistas)
);

CREATE TABLE guarda (
    id NUMBER(10),
    idPlayList NUMBER(20),
    PRIMARY KEY (id, idPlayList)
);

CREATE TABLE tem (
    idPlayList NUMBER(20),
    idMusica NUMBER(20),
    PRIMARY KEY (idPlayList, idMusica)
);

CREATE TABLE agrega (
    id_SubscricoesFree NUMBER(10),
    id_SubscricoesFamily NUMBER(10), 
    PRIMARY KEY (id_SubscricoesFree)
);

CREATE TABLE contem (
    idMusica NUMBER(20),
    idAlbum NUMBER(20),
    PRIMARY KEY (idMusica)
);

ALTER TABLE SubscricoesFree ADD CONSTRAINT fk_subfree_conta 
FOREIGN KEY (id) REFERENCES Contas(id) ON DELETE CASCADE;

ALTER TABLE Artistas ADD CONSTRAINT fk_artista_conta 
FOREIGN KEY (id) REFERENCES Contas(id) ON DELETE CASCADE;

ALTER TABLE SubscricoesPagas ADD CONSTRAINT fk_subpag_subfree 
FOREIGN KEY (id) REFERENCES SubscricoesFree(id) ON DELETE CASCADE;

ALTER TABLE SubscricoesPagas ADD CONSTRAINT fk_subpagas_pacote
FOREIGN KEY (meses, tipo) REFERENCES Pacotes(meses, tipo);

ALTER TABLE SubscricoesFamily ADD CONSTRAINT fk_subfam_subpagas 
FOREIGN KEY (id) REFERENCES SubscricoesPagas(id) ON DELETE CASCADE;

ALTER TABLE SubscricoesPremium ADD CONSTRAINT fk_subprem_subpagas 
FOREIGN KEY (id) REFERENCES SubscricoesPagas(id) ON DELETE CASCADE;

ALTER TABLE Pagamentos ADD CONSTRAINT fk_pag_subpagas 
FOREIGN KEY (id) REFERENCES SubscricoesPagas(id) ON DELETE CASCADE;

ALTER TABLE PlayLists ADD CONSTRAINT fk_play_subfree 
FOREIGN KEY (id) REFERENCES SubscricoesFree(id) ON DELETE CASCADE;

ALTER TABLE Musicas ADD CONSTRAINT fk_mus_artista 
FOREIGN KEY (id) REFERENCES Artistas(id) ON DELETE CASCADE;

ALTER TABLE Albuns ADD CONSTRAINT fk_alb_artista 
FOREIGN KEY (id) REFERENCES Artistas(id) ON DELETE CASCADE;

ALTER TABLE segue ADD CONSTRAINT fk_segue_subfree 
FOREIGN KEY (id_SubscricoesFree) REFERENCES SubscricoesFree(id) ON DELETE CASCADE;

ALTER TABLE segue ADD CONSTRAINT fk_segue_artista 
FOREIGN KEY (id_Artistas) REFERENCES Artistas(id) ON DELETE CASCADE;

ALTER TABLE guarda ADD CONSTRAINT fk_guarda_subfree 
FOREIGN KEY (id) REFERENCES SubscricoesFree(id) ON DELETE CASCADE;

ALTER TABLE guarda ADD CONSTRAINT fk_guarda_playlist 
FOREIGN KEY (idPlayList) REFERENCES PlayLists(idPlayList) ON DELETE CASCADE;

ALTER TABLE tem ADD CONSTRAINT fk_tem_playlist 
FOREIGN KEY (idPlayList) REFERENCES PlayLists(idPlayList) ON DELETE CASCADE;

ALTER TABLE tem ADD CONSTRAINT fk_tem_musica 
FOREIGN KEY (idMusica) REFERENCES Musicas(idMusica) ON DELETE CASCADE;

ALTER TABLE agrega ADD CONSTRAINT fk_agrega_subfree 
FOREIGN KEY (id_SubscricoesFree) REFERENCES SubscricoesFree(id) ON DELETE CASCADE;

ALTER TABLE agrega ADD CONSTRAINT fk_agrega_subfamily 
FOREIGN KEY (id_SubscricoesFamily) REFERENCES SubscricoesFamily(id) ON DELETE CASCADE;

ALTER TABLE contem ADD CONSTRAINT fk_contem_musica 
FOREIGN KEY (idMusica) REFERENCES Musicas(idMusica) ON DELETE CASCADE;

ALTER TABLE contem ADD CONSTRAINT fk_contem_album 
FOREIGN KEY (idAlbum) REFERENCES Albuns(idAlbum) ON DELETE CASCADE;

CREATE SEQUENCE seq_num_idContas
START WITH 1
INCREMENT BY 1;

CREATE SEQUENCE seq_num_idMusicas
START WITH 1
INCREMENT BY 1;

CREATE SEQUENCE seq_num_idAlbuns
START WITH 1
INCREMENT BY 1;

CREATE SEQUENCE seq_num_idPlayLists
START WITH 1
INCREMENT BY 1;

CREATE OR REPLACE FUNCTION account_num_pag (p_id IN NUMBER)
    RETURN INTEGER IS pag_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO pag_count
    FROM Pagamentos
    WHERE Pagamentos.id = p_id;
    RETURN pag_count + 1;
END account_num_pag;
/

CREATE OR REPLACE TRIGGER trg_validate_payment_amount
BEFORE INSERT ON Pagamentos
FOR EACH ROW
DECLARE
    v_expected_amount DECIMAL(5,2);
    num_pag number;
BEGIN
    SELECT preco INTO v_expected_amount
    FROM SubscricoesPagas NATURAL JOIN Pacotes
    WHERE SubscricoesPagas.id = :NEW.id;

    IF :NEW.montante != v_expected_amount THEN
        RAISE_APPLICATION_ERROR(-20100, 'Montante inválido. Esperado: ' || v_expected_amount);
    END IF;

    :new.numP := account_num_pag(:NEW.id);
    :new.data := SYSDATE;

    UPDATE SubscricoesPagas
    SET dataInicio = SYSDATE
    WHERE id = :NEW.id;
END;
/

CREATE OR REPLACE TRIGGER trg_insert_subscription_type_before
BEFORE INSERT ON SubscricoesPagas
FOR EACH ROW
DECLARE
    v_count1 NUMBER;
    v_count2 NUMBER;
    v_count3 NUMBER;
    v_amount_needed DECIMAL(5,2);
BEGIN
    SELECT COUNT(*) INTO v_count1 FROM agrega WHERE id_SubscricoesFree = :NEW.id;

    IF v_count1 > 0 THEN
        RAISE_APPLICATION_ERROR(-20100, 'Account already in family');
    END IF;

    SELECT COUNT(*) INTO v_count2 FROM SubscricoesFree WHERE id = :NEW.id;

    IF v_count2 = 0 THEN 
        INSERT INTO SubscricoesFree VALUES (:NEW.id);
    END IF;

    SELECT preco INTO v_amount_needed
    FROM Pacotes
    WHERE meses = :NEW.meses AND tipo = :NEW.tipo;

    :NEW.dataInicio := NULL;
END;
/


CREATE OR REPLACE TRIGGER trg_insert_subscription_type_after
AFTER INSERT ON SubscricoesPagas
FOR EACH ROW
BEGIN
    IF :NEW.tipo = 'Premium' THEN
        INSERT INTO SubscricoesPremium 
        VALUES (:NEW.id);
    ELSE
        INSERT INTO SubscricoesFamily 
        VALUES (:NEW.id);
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_update_subscription_type
BEFORE UPDATE ON SubscricoesPagas
FOR EACH ROW
BEGIN
    IF :OLD.id != :NEW.id THEN
        RAISE_APPLICATION_ERROR(-20100, 'Id cannot be updated.');
    END IF;

    IF :OLD.tipo != :NEW.tipo THEN
        IF :OLD.tipo = 'Premium' THEN
            DELETE FROM SubscricoesPremium WHERE id = :OLD.id;
        ELSIF :OLD.tipo = 'Family' THEN
            DELETE FROM SubscricoesFamily WHERE id = :OLD.id;
        END IF;

        IF :NEW.tipo = 'Premium' THEN
            INSERT INTO SubscricoesPremium 
            VALUES (:NEW.id);
        ELSIF :NEW.tipo = 'Family' THEN
            INSERT INTO SubscricoesFamily
            VALUES (:NEW.id);
        END IF;
        :NEW.dataInicio := NULL;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_remove_subscription
BEFORE DELETE ON SubscricoesPagas
FOR EACH ROW
DECLARE
    v_end_date DATE;
BEGIN

        v_end_date := ADD_MONTHS(:OLD.dataInicio, :OLD.meses);

        IF SYSDATE < v_end_date THEN
            RAISE_APPLICATION_ERROR(-20100, 'Cannot delete active subscription. Ends on ' || TO_CHAR(v_end_date, 'DD-MON-YYYY'));
        END IF;

END;
/


CREATE OR REPLACE TRIGGER trg_disj_Premium
BEFORE INSERT ON SubscricoesPremium 
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM SubscricoesFamily
    WHERE id = :NEW.id;
    
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20100, 'Account cannot be both Premium and Family');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_disj_Family
BEFORE INSERT ON SubscricoesFamily
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM SubscricoesPremium
    WHERE id = :NEW.id;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20100, 'Account cannot be both Premium and Family');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_validate_family_account
BEFORE INSERT OR UPDATE ON agrega
FOR EACH ROW
DECLARE
    v_count1 NUMBER;
    v_count2 NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count1
    FROM agrega
    WHERE id_SubscricoesFamily = :NEW.id_SubscricoesFamily;

    SELECT COUNT(*) INTO v_count2
    FROM SubscricoesPagas
    WHERE id = :NEW.id_SubscricoesFree;
    
    IF v_count1 >= 5 THEN
    RAISE_APPLICATION_ERROR(-20100, 'Family account cannot have more than 5 associated free accounts');
    END IF;

    IF v_count2 > 0 THEN
    RAISE_APPLICATION_ERROR(-20100, 'This account is already associated with a paid subscription');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_album_artist_consistency
BEFORE INSERT OR UPDATE ON contem
FOR EACH ROW
DECLARE
    v_song_artist NUMBER;
    v_album_artist NUMBER;
BEGIN
    SELECT id INTO v_song_artist
    FROM Musicas
    WHERE idMusica = :NEW.idMusica;
    
    SELECT id INTO v_album_artist
    FROM Albuns
    WHERE idAlbum = :NEW.idAlbum;
    
    IF v_song_artist != v_album_artist THEN
        RAISE_APPLICATION_ERROR(-20100, 'Song and album must be by the same artist');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER id_contas
BEFORE INSERT ON Contas
FOR EACH ROW
DECLARE
    id_conta number;
BEGIN
    SELECT seq_num_idContas.nextval
    INTO id_conta
    FROM dual;
    :new.id := id_conta;
END;
/

CREATE OR REPLACE TRIGGER id_playLists
BEFORE INSERT ON PlayLists
FOR EACH ROW
DECLARE
    id_playList number;
BEGIN
    SELECT seq_num_idPlayLists.nextval
    INTO id_playList
    FROM dual;
    :new.idPlayList := id_playList;
END;
/

CREATE OR REPLACE TRIGGER id_musicas
BEFORE INSERT ON Musicas
FOR EACH ROW
DECLARE
    id_musica number;
BEGIN
    SELECT seq_num_idMusicas.nextval
    INTO id_musica
    FROM dual;
    :new.idMusica := id_musica;
END;
/

CREATE OR REPLACE TRIGGER id_albuns
BEFORE INSERT ON Albuns
FOR EACH ROW
DECLARE
    id_album number;
BEGIN
    SELECT seq_num_idAlbuns.nextval
    INTO id_album
    FROM dual;
    :new.idAlbum := id_album;
END;
/

DELETE FROM Pacotes;

INSERT INTO Pacotes VALUES (1, 'Premium', 5.99);
INSERT INTO Pacotes VALUES (3, 'Premium', 17.07);
INSERT INTO Pacotes VALUES (6, 'Premium', 31.63);
INSERT INTO Pacotes VALUES (12, 'Premium', 57.50);

INSERT INTO Pacotes VALUES (1, 'Family', 14.99);
INSERT INTO Pacotes VALUES (3, 'Family', 42.72);
INSERT INTO Pacotes VALUES (6, 'Family', 79.15);
INSERT INTO Pacotes VALUES (12, 'Family', 143.90);

COMMIT;

DELETE FROM Contas;

INSERT INTO Contas VALUES (1, 'João Silva', 'joao@gmail.com', 'pwd123');
INSERT INTO Contas VALUES (2, 'Maria Costa', 'maria@gmail.com', 'pwd123');
INSERT INTO Contas VALUES (3, 'Pedro Rocha', 'pedro@gmail.com', 'pwd123');
INSERT INTO Contas VALUES (4, 'Ana Lima', 'ana@gmail.com', 'pwd123');
INSERT INTO Contas VALUES (5, 'Rita Martins', 'rita@gmail.com', 'pwd123');
INSERT INTO Contas VALUES (6, 'Carlos Pinto', 'carlos@gmail.com', 'pwd123');
INSERT INTO Contas VALUES (7, 'Banda Alfa', 'alfa@gmail.com', 'pwd123');
INSERT INTO Contas VALUES (8, 'DJ Electro', 'dj@gmail.com', 'pwd123');
INSERT INTO Contas VALUES (9, 'Luís Nunes', 'luis@gmail.com', 'pwd123');
INSERT INTO Contas VALUES (10, 'Sofia Ribeiro', 'sofia@gmail.com', 'pwd123');
INSERT INTO Contas VALUES (11, 'Rock Band', 'rock@gmail.com', 'pwd123');
INSERT INTO Contas VALUES (12, 'DJ Bassline', 'bassline@gmail.com', 'pwd123');

INSERT INTO Contas VALUES (13, 'Miguel Duarte', 'miguel.duarte@gmail.com', 'pwd456');
INSERT INTO Contas VALUES (14, 'Carla Mendes', 'carla.mendes@gmail.com', 'senha789');
INSERT INTO Contas VALUES (15, 'DJ Storm', 'djstorm@gmail.com', 'beatdrop1');
INSERT INTO Contas VALUES (16, 'The Acoustic Souls', 'acousticsouls@gmail.com', 'soulpass');
INSERT INTO Contas VALUES (17, 'Lara Monteiro', 'lara.monteiro@gmail.com', 'lara2025');


COMMIT;

DELETE FROM Artistas;

-- Banda Alfa
INSERT INTO Artistas VALUES (7);
-- DJ Electro
INSERT INTO Artistas VALUES (8);
-- Rock Band
INSERT INTO Artistas VALUES (11);
-- DJ Bassline
INSERT INTO Artistas VALUES (12);
-- DJ Storm
INSERT INTO Artistas VALUES (15);
-- The Acoustic Souls
INSERT INTO Artistas VALUES (16);

COMMIT;

DELETE FROM SubscricoesFree;

-- João
INSERT INTO SubscricoesFree VALUES (1); 
-- Maria 
INSERT INTO SubscricoesFree VALUES (2);
-- Pedro  
INSERT INTO SubscricoesFree VALUES (3);
-- Ana  
INSERT INTO SubscricoesFree VALUES (4); 
-- Rita 
INSERT INTO SubscricoesFree VALUES (5); 
-- Carlos
INSERT INTO SubscricoesFree VALUES (6);
-- Luís
INSERT INTO SubscricoesFree VALUES (9);
-- Sofia
INSERT INTO SubscricoesFree VALUES (10);
-- Miguel
INSERT INTO SubscricoesFree VALUES (13);
-- Carla
INSERT INTO SubscricoesFree VALUES (14);
-- Lara
INSERT INTO SubscricoesFree VALUES (17);

COMMIT;

DELETE FROM SubscricoesPagas;

-- Premium (Maria)
INSERT INTO SubscricoesPagas VALUES (2, 6, 'Premium', NULL);
-- Family (Pedro)
INSERT INTO SubscricoesPagas VALUES (3, 12, 'Family', NULL);
-- Sofia gets a Premium subscription
INSERT INTO SubscricoesPagas VALUES (10, 3, 'Premium', NULL);
-- Luís gets a Family subscription
INSERT INTO SubscricoesPagas VALUES (9, 6, 'Family', NULL);

COMMIT;

DELETE FROM agrega;

-- Pedro (3) é titular, e Ana (4), Rita (5) e Carlos (6) são agregados
INSERT INTO agrega VALUES (4, 3);
INSERT INTO agrega VALUES (5, 3);
INSERT INTO agrega VALUES (6, 3);
INSERT INTO agrega VALUES (1, 9);

COMMIT;

DELETE FROM Pagamentos;
-- Maria
INSERT INTO Pagamentos VALUES (2, 1, 31.63, NULL);  
-- Pedro
INSERT INTO Pagamentos VALUES (3, 1, 143.90, NULL);
-- Sofia
INSERT INTO Pagamentos VALUES (10, 1, 17.07, NULL);
-- Luís
INSERT INTO Pagamentos VALUES (9, 1, 79.15, NULL);

COMMIT;

DELETE FROM Albuns;

-- Albuns
INSERT INTO Albuns VALUES (1, 7, 'Alfa Hits', DATE '2023-05-20');
INSERT INTO Albuns VALUES (2, 8, 'Electro Beats', DATE '2024-06-15');
INSERT INTO Albuns VALUES (3, 11, 'Rock Legends', DATE '2022-09-12');
INSERT INTO Albuns VALUES (4, 12, 'Bass Drops', DATE '2023-11-03');

COMMIT;

DELETE FROM Musicas;

-- Músicas
INSERT INTO Musicas VALUES (1, 7, 'Canção 1', '03:00', 'Pop');
INSERT INTO Musicas VALUES (2, 7, 'Canção 2', '04:00', 'Pop');
INSERT INTO Musicas VALUES (3, 8, 'Electro 1', '05:00', 'EDM');
INSERT INTO Musicas VALUES (4, 11, 'Rock On', '04:20', 'Rock');
INSERT INTO Musicas VALUES (5, 11, 'Ballad Night', '03:45', 'Rock');
INSERT INTO Musicas VALUES (6, 12, 'Bass Attack', '05:10', 'EDM');
INSERT INTO Musicas VALUES (6, 12, 'LoFi Beat #1', '06:40', 'LoFi');
INSERT INTO Musicas VALUES (6, 12, 'LoFi Beat #2', '06:40', 'LoFi');

COMMIT;

DELETE FROM contem;

-- Vincular músicas aos álbuns (contem)
INSERT INTO contem VALUES (1, 1);
INSERT INTO contem VALUES (2, 1);
INSERT INTO contem VALUES (3, 2);
INSERT INTO contem VALUES (4, 3);
INSERT INTO contem VALUES (5, 3);
INSERT INTO contem VALUES (6, 4);

COMMIT;

DELETE FROM PlayLists;

-- João (Free) cria playlists
INSERT INTO PlayLists VALUES (1, 1, 'Favoritas do João');
INSERT INTO PlayLists VALUES (2, 1, 'Músicas para estudar');
INSERT INTO PlayLists VALUES (3, 9, 'Luís Favorites');
INSERT INTO PlayLists VALUES (4, 10, 'Sofia Mood');

COMMIT;

DELETE FROM tem;

-- Adicionar músicas às playlists
INSERT INTO tem VALUES (1, 1);
INSERT INTO tem VALUES (1, 3);
INSERT INTO tem VALUES (2, 2);
INSERT INTO tem VALUES (3, 4);
INSERT INTO tem VALUES (3, 5);
INSERT INTO tem VALUES (4, 6);

COMMIT;

DELETE FROM guarda;

-- Maria (2) guarda playlist de João (1)
INSERT INTO guarda VALUES (2, 1);
-- Pedro (3) guarda outra playlist
INSERT INTO guarda VALUES (3, 2);
-- Sofia saves Luís' playlist
INSERT INTO guarda VALUES (10, 3);
-- Luís saves Sofia's playlist
INSERT INTO guarda VALUES (9, 4);

COMMIT;

DELETE FROM segue;

-- João segue Banda Alfa
INSERT INTO segue VALUES (1, 7);
-- Ana segue DJ Electro
INSERT INTO segue VALUES (4, 8);
-- Luís follows Rock Band
INSERT INTO segue VALUES (9, 11);
-- Sofia follows DJ Bassline
INSERT INTO segue VALUES (10, 12);

COMMIT;

