-- utilizzo la temporary table utilizzata nell'operazione 5.2.x. per avere i punti gia danneggiati
DROP PROCEDURE IF EXISTS classifica_punti_criticiS;
DELIMITER %%

CREATE PROCEDURE classifica_punti_criticiS(IN codice_edificio INT)
BEGIN
DROP TEMPORARY TABLE IF EXISTS RankPunti;
CREATE TEMPORARY TABLE RankPunti(
						X FLOAT DEFAULT 0,
                        Y FLOAT DEFAULT 0,
                        Z FLOAT DEFAULT 0,
                        CodiceVano INT DEFAULT 0,
                        Scostamento FLOAT DEFAULT 0,
                        EntitaDanno INT DEFAULT 0,
                        PRIMARY KEY(X,Y,Z,CodiceVano));

-- Inserisco i punti dei sensori1D

INSERT INTO RankPunti (X, Y, Z, CodiceVano, Scostamento)
SELECT X, Y, Z, CodiceVano, Scostamento
		FROM Alert1D A1D INNER JOIN Sensore1D S1D ON S1D.CodiceSensore = A1D.CodiceSensore
        WHERE Timestamp = (SELECT MAX(Timestamp) 
							FROM Alert1D A1D2
							WHERE A1D2.CodiceSensore = A1D.CodiceSensore
                            AND A1D2.Timestamp > (NOW() - INTERVAL 1 MONTH))
		AND CodiceVano IN (SELECT CodiceVano FROM Vano V WHERE V.CodiceEdificio = codice_edificio);

-- Inserisco i punti dei sensori2D

INSERT INTO RankPunti (X, Y, Z, CodiceVano, Scostamento)
SELECT X, Y, Z, CodiceVano, (ScostamentoX/2 + ScostamentoY/2) AS Scostamento
		FROM Alert2D A2D INNER JOIN Sensore2D S2D ON S2D.CodiceSensore = A2D.CodiceSensore
        WHERE Timestamp = (SELECT MAX(Timestamp) 
							FROM Alert2D A2D2
							WHERE A2D2.CodiceSensore = A2D.CodiceSensore
                            AND A2D2.Timestamp > (NOW() - INTERVAL 1 MONTH))
		AND CodiceVano IN (SELECT CodiceVano FROM Vano V WHERE V.CodiceEdificio = codice_edificio)
ON DUPLICATE KEY UPDATE    
Scostamento = (Scostamento + RankPunti.Scostamento)/2;

-- Inserisco i punti dei sensori3D

INSERT INTO RankPunti (X, Y, Z, CodiceVano, Scostamento)
SELECT X, Y, Z, CodiceVano, (ScostamentoX/3 + ScostamentoY/3 + ScostamentoZ/3) AS Scostamento
		FROM Alert3D A3D INNER JOIN Sensore3D S3D ON S3D.CodiceSensore = A3D.CodiceSensore
        WHERE Timestamp = (SELECT MAX(Timestamp) 
							FROM Alert3D A3D2
							WHERE A3D2.CodiceSensore = A3D.CodiceSensore
                            AND A3D2.Timestamp > (NOW() - INTERVAL 1 MONTH))
		AND CodiceVano IN (SELECT CodiceVano FROM Vano V WHERE V.CodiceEdificio = codice_edificio)
ON DUPLICATE KEY UPDATE    
Scostamento = (Scostamento + RankPunti.Scostamento)/2;


-- Inserisco i punti dei danni

INSERT INTO RankPunti (X, Y, Z, CodiceVano, EntitaDanno) 
SELECT X, Y, Z, CodiceVano, Entita  FROM Danno D 
INNER JOIN Riferimento R ON R.CodiceDanno = D.CodiceDanno
WHERE D.CodiceVano IN (SELECT CodiceVano FROM Vano V WHERE V.CodiceEdificio = codice_edificio)
AND D.Entita <> -1
ON DUPLICATE KEY UPDATE    
EntitaDanno = D.Entita;

END %%
DELIMITER ;

-- inserisco in una temporary table tutti gli edifici colpiti dal terremoto
DROP PROCEDURE IF EXISTS edifici_colpiti;
DELIMITER $$
CREATE PROCEDURE edifici_colpiti(IN lat_epicentro FLOAT, IN lon_epicentro FLOAT, IN raggio FLOAT)
BEGIN
	DECLARE lat_edificio FLOAT DEFAULT 0;
    DECLARE lon_edificio FLOAT DEFAULT 0;
    DECLARE cod_edificio INTEGER DEFAULT 0;
    DECLARE finito1 BOOLEAN DEFAULT FALSE;
    DECLARE cur CURSOR FOR 
		SELECT Latitudine, Longitudine, CodiceEdificio
        FROM Edificio;
	DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET finito1 = TRUE;
    DROP TEMPORARY TABLE IF EXISTS EdificiColpiti;
    CREATE TEMPORARY TABLE EdificiColpiti(
					CodiceEdificio INT DEFAULT 0,
					DistanzaEpicentro FLOAT,
					PRIMARY KEY(CodiceEdificio));
	OPEN cur;
	WHILE finito1 <> TRUE DO
		FETCH cur INTO lat_edificio, lon_edificio, cod_edificio;
        -- se la distanza è minore del raggio il terremoto ha effetto sull'edificio
        IF Distanza(lat_edificio, lat_epicentro, lon_edificio, lon_epicentro) < raggio THEN
			INSERT INTO EdificiColpiti
			VALUES (cod_edificio, Distanza(lat_edificio, lat_epicentro, lon_edificio, lon_epicentro));
		END IF;
	END WHILE;
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS stima_danni;
DELIMITER $$
CREATE PROCEDURE stima_danni(IN lat_epicentro FLOAT, IN lon_epicentro FLOAT, IN raggio FLOAT, IN magnitudo_100km FLOAT)
BEGIN
	DECLARE finito2 BOOLEAN DEFAULT FALSE;
    DECLARE codice INTEGER DEFAULT 0;
    DECLARE distanza FLOAT DEFAULT 0;
    -- questa variabile indica i danni del solo terremoto (in punti non danneggiati dell'edificio)
    DECLARE danni_terremoto FLOAT DEFAULT 0;
    -- ampiezza_onda rappresenta una costante: l'ampiezza dell'onda nell'epicentro
    DECLARE ampiezza_onda FLOAT DEFAULT 0;
	
	DECLARE curs CURSOR FOR 
		SELECT *
        FROM EdificiColpiti;
	DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET finito2 = TRUE;
	OPEN curs;
    
    IF (SELECT COUNT(*) FROM EdificiColpiti) = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Non ci sono edifici colpiti';
	END IF;
    -- creare una table che contiene rankpunti + CodiceEdificio e i nuovi dati
    DROP TEMPORARY TABLE IF EXISTS StatoDopoTerremoto;
    CREATE TEMPORARY TABLE StatoDopoTerremoto (
		X FLOAT DEFAULT 0,
		Y FLOAT DEFAULT 0,
		Z FLOAT DEFAULT 0,
		CodiceVano INT DEFAULT 0,
		DannoRichter FLOAT DEFAULT 0,
        Stato VARCHAR(40) DEFAULT NULL,
		PRIMARY KEY(X,Y,Z, CodiceVano));
    
    
	WHILE finito2 <> TRUE DO
		FETCH curs INTO codice, distanza;
        -- utilizzo la formula inversa per calcolare l'ampiezza dell'onda
        SET ampiezza_onda = 2.71^(magnitudo_100km - 1.6 * log10(1 + distanza) - 0.15);
        CALL classifica_punti_criticiS(codice);
        -- inserisco in RankPunti un record che indica i punti non danneggiati di quell'edificio
        INSERT INTO RankPunti(X,Y,Z, CodiceVano)
        SELECT DISTINCT -1, -1, -1, V.CodiceVano
        FROM Vano V
        WHERE V.CodiceEdificio = codice
        AND NOT EXISTS(SELECT * FROM Danno D WHERE D.CodiceVano = V.CodiceVano);
        
        -- aggiungo alla tabella magnitudo e danni secondo la scala richter
        ALTER TABLE RankPunti
        ADD Magnitudo FLOAT DEFAULT 0, ADD DannoRichter FLOAT DEFAULT 0, ADD Stato VARCHAR(30) DEFAULT NULL;
		-- calcolo la magnitudo nel punto in cui si trovano gli edifici
        UPDATE RankPunti
        SET Magnitudo = log10(1 + ampiezza_onda) + 1.6 * log10(1 + distanza) + 0.15,
        DannoRichter = Magnitudo;
        -- rendo EntitaDanno compatibile con DannoRichter
        UPDATE RankPunti
        SET EntitaDanno = 0
        WHERE EntitaDanno = -1;
        UPDATE RankPunti
        SET EntitaDanno = EntitaDanno - 1 
        WHERE EntitaDanno BETWEEN 0 AND 9;
        
        -- creo la legge che modifica dannirichter in base ai danni gia presenti
        UPDATE RankPunti
        SET DannoRichter = 0.17 * EntitaDanno + DannoRichter
        WHERE X <> -1;
        
        -- imposto l'effetto del terremoto su ogni vano in base al DannoRichter
        UPDATE RankPunti
		SET Stato = 'Nessun effetto'
		WHERE DannoRichter BETWEEN 0 AND 3.999999;
        UPDATE RankPunti
        SET Stato = 'Danni lievi'
		WHERE DannoRichter BETWEEN 4 AND 4.999999;
        UPDATE RankPunti
        SET Stato = 'Danni medio-gravi'
        WHERE DannoRichter BETWEEN 5 AND 5.499999;
        UPDATE RankPunti
        SET Stato = 'Danni gravi'
		WHERE DannoRichter BETWEEN 5.5 AND 5.999999;
        UPDATE RankPunti
		SET Stato = 'Danni molto gravi'
		WHERE DannoRichter BETWEEN 6 AND 6.49999999;
        UPDATE RankPunti
		SET Stato = 'Danni catastrofici'
		WHERE DannoRichter > 6.5;
        
        -- inserimento nella nuova tabella
        INSERT INTO StatoDopoTerremoto (X, Y, Z, CodiceVano, DannoRichter, Stato)
        SELECT X, Y, Z, CodiceVano, DannoRichter, Stato
        FROM RankPunti;
	END WHILE;
    
    SELECT *
    FROM StatoDopoTerremoto;
END $$
DELIMITER ;
CALL edifici_colpiti(43.38, 10.30, 60);

CALL stima_danni(43.38, 10.74, 30, 60);


		