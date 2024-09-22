DROP PROCEDURE IF EXISTS consigli_di_intervento;

DELIMITER %%

CREATE PROCEDURE consigli_di_intervento(IN CodiceEdificio INT)
BEGIN
DECLARE RischioSismico FLOAT DEFAULT NULL;
DECLARE RischioFrana FLOAT DEFAULT NULL;
DECLARE RischioAlluvione FLOAT DEFAULT NULL;
DECLARE RischioEruzione FLOAT DEFAULT NULL;
DECLARE RischioTsunami FLOAT DEFAULT NULL;
DECLARE RischioLahar FLOAT DEFAULT NULL;


DROP TABLE IF EXISTS AlertDanni;
DROP TABLE IF EXISTS AlertDanniInfluenzati;
DROP TABLE IF EXISTS ElementiStrutturaliCoinvolti;
DROP TABLE IF EXISTS Consigli;
CREATE TEMPORARY TABLE AlertDanni(
						X FLOAT,
                        Y FLOAT,
                        Z FLOAT,
                        CodiceVano INT,
                        Tipo VARCHAR(45),
                        Scostamento FLOAT,
                        EntitaDanno INT,
                        PRIMARY KEY(X,Y,Z,CodiceVano)
                        );
                        
CREATE TEMPORARY TABLE AlertDanniInfluenzati(
						X FLOAT,
                        Y FLOAT,
                        Z FLOAT,
                        CodiceVano INT,
                        Tipo VARCHAR(45),
                        FattoreUrgenza FLOAT,
                        PRIMARY KEY(X,Y,Z,CodiceVano)
                        );

CREATE TEMPORARY TABLE ElementiStrutturaliCoinvolti(
						X FLOAT,
                        Y FLOAT,
                        Z FLOAT,
                        CodiceVano INT,
                        Nome VARCHAR(45),
                        FattoreUrgenza FLOAT,
                        PRIMARY KEY(X,Y,Z,CodiceVano)
						);

CREATE TEMPORARY TABLE Consigli(
						Consiglio VARCHAR(400),
                        Urgenza FLOAT,
                        CodiceVano INT,
                        PRIMARY KEY(Consiglio)
						);

-- Inserisco i punti dei sensori1D

INSERT INTO AlertDanni (X, Y, Z, CodiceVano, Tipo, Scostamento)
SELECT X, Y, Z, CodiceVano, Tipo, AVG(Scostamento)
		FROM Alert1D A1D NATURAL JOIN Sensore1D S1D 
        WHERE Timestamp > (NOW() - INTERVAL 1 WEEK)
        AND CodiceVano IN (SELECT CodiceVano FROM Vano V WHERE V.CodiceEdificio = CodiceEdificio)
GROUP BY CodiceSensore;
-- Inserisco i punti dei sensori2D

INSERT INTO AlertDanni (X, Y, Z, CodiceVano, Tipo, Scostamento)
SELECT X, Y, Z, CodiceVano, Tipo, AVG(ScostamentoX/2 + ScostamentoY/2) AS Scostamento
		FROM Alert2D A2D NATURAL JOIN Sensore2D S2D
        WHERE Timestamp > (NOW() - INTERVAL 1 WEEK)
		AND CodiceVano IN (SELECT CodiceVano FROM Vano V WHERE V.CodiceEdificio = CodiceEdificio)
GROUP BY CodiceSensore
ON DUPLICATE KEY UPDATE    
Scostamento = (Scostamento + AlertDanni.Scostamento)/2;

-- Inserisco i punti dei sensori3D

INSERT INTO AlertDanni (X, Y, Z, CodiceVano, Tipo, Scostamento)
SELECT X, Y, Z, CodiceVano, Tipo, AVG(ScostamentoX/3 + ScostamentoY/3 + ScostamentoZ/3) AS Scostamento
		FROM Alert3D A3D NATURAL JOIN Sensore3D S3D 
        WHERE Timestamp > (NOW() - INTERVAL 1 WEEK)
        AND CodiceVano IN (SELECT CodiceVano FROM Vano V WHERE V.CodiceEdificio = CodiceEdificio)
GROUP BY CodiceSensore
ON DUPLICATE KEY UPDATE    
Scostamento = (Scostamento + AlertDanni.Scostamento)/2;


-- Inserisco i punti dei danni(in questo caso senza la media fatta sugli alert per avere valori più attendibili)

INSERT INTO AlertDanni (X, Y, Z, CodiceVano, Tipo, EntitaDanno) 
SELECT X, Y, Z, CodiceVano, Tipo, Entita  FROM Danno D 
INNER JOIN Riferimento R ON R.CodiceDanno = D.CodiceDanno
WHERE D.CodiceVano IN (SELECT CodiceVano FROM Vano V WHERE V.CodiceEdificio = CodiceEdificio)
AND D.Entita <> -1
ON DUPLICATE KEY UPDATE    
EntitaDanno = D.Entita,
Tipo = D.Tipo;


-- Accedo ai rischi dell'area dell'edificio per incrociarli con i valori di sensori e danni

SELECT Coefficiente
FROM Rischio R
INNER JOIN AreaGeo A ON R.NomeArea = A.NomeArea
INNER JOIN Edificio E ON E.NomeArea = A.NomeArea
WHERE E.CodiceEdificio = CodiceEdificio
AND R.Tipo = 'Terremoto'
INTO RischioSismico;

SELECT Coefficiente
FROM Rischio R
INNER JOIN AreaGeo A ON R.NomeArea = A.NomeArea
INNER JOIN Edificio E ON E.NomeArea = A.NomeArea
WHERE E.CodiceEdificio = CodiceEdificio
AND R.Tipo = 'Frana'
INTO RischioFrana;

SELECT Coefficiente
FROM Rischio R
INNER JOIN AreaGeo A ON R.NomeArea = A.NomeArea
INNER JOIN Edificio E ON E.NomeArea = A.NomeArea
WHERE E.CodiceEdificio = CodiceEdificio
AND R.Tipo = 'Alluvione'
INTO RischioAlluvione;

SELECT Coefficiente
FROM Rischio R
INNER JOIN AreaGeo A ON R.NomeArea = A.NomeArea
INNER JOIN Edificio E ON E.NomeArea = A.NomeArea
WHERE E.CodiceEdificio = CodiceEdificio
AND R.Tipo = 'Eruzione'
INTO RischioEruzione;

SELECT Coefficiente
FROM Rischio R
INNER JOIN AreaGeo A ON R.NomeArea = A.NomeArea
INNER JOIN Edificio E ON E.NomeArea = A.NomeArea
WHERE E.CodiceEdificio = CodiceEdificio
AND R.Tipo = 'Tsunami'
INTO RischioTsunami;

SELECT Coefficiente
FROM Rischio R
INNER JOIN AreaGeo A ON R.NomeArea = A.NomeArea
INNER JOIN Edificio E ON E.NomeArea = A.NomeArea
WHERE E.CodiceEdificio = CodiceEdificio
AND R.Tipo = 'Lahar'
INTO RischioLahar;

-- Inserimento dei punti coperti solo dai sensori

INSERT INTO AlertDanniInfluenzati(X, Y, Z, CodiceVano, Tipo, FattoreUrgenza)
SELECT X, Y, Z, CodiceVano, Tipo, (Scostamento)
FROM AlertDanni
WHERE EntitaDanno IS NULL;

-- Inserimento dei soli punti che coinvolgono danni

INSERT INTO AlertDanniInfluenzati(X, Y, Z, CodiceVano, Tipo, FattoreUrgenza)
SELECT X, Y, Z, CodiceVano, Tipo, (EntitaDanno/9)
FROM AlertDanni
WHERE Scostamento IS NULL;

-- Inserimento dei punti che coinvolgono sensori e danni

INSERT INTO AlertDanniInfluenzati(X, Y, Z, CodiceVano, Tipo, FattoreUrgenza)
SELECT X, Y, Z, CodiceVano, Tipo, (Scostamento + EntitaDanno/9)/2
FROM AlertDanni
WHERE EntitaDanno IS NOT NULL AND Scostamento IS NOT NULL;


-- Aggiornamento del fattore urgenza attraverso i rischi

IF(RischioSismico IS NOT NULL) THEN
UPDATE AlertDanniInfluenzati
SET FattoreUrgenza = 1 -  EXP(LOG(1 - FattoreUrgenza) - RischioSismico)
WHERE Tipo IN ("Giroscopio", "Accelerometro", "Posizione", "Crepa");
END IF;

IF(RischioFrana IS NOT NULL) THEN
UPDATE AlertDanniInfluenzati
SET FattoreUrgenza = 1 -  EXP(LOG(1 - FattoreUrgenza) - RischioFrana)
WHERE Tipo IN ("Accelerometro", "UmiditaInterna", "UmiditaEsterna", "Posizione", "Crepa", "Precipitazione");
END IF;

IF(RischioAlluvione IS NOT NULL) THEN
UPDATE AlertDanniInfluenzati
SET FattoreUrgenza = 1 - EXP(-FattoreUrgenza - RischioAlluvione)
WHERE Tipo IN ("Accelerometro", "UmiditaInterna", "UmiditaEsterna", "Posizione", "Crepa", "Precipitazione", "TemperaturaInterna", "TemperaturaEsterna");
END IF;

IF(RischioEruzione IS NOT NULL) THEN
UPDATE AlertDanniInfluenzati
SET FattoreUrgenza = 1 -  EXP(LOG(1 - FattoreUrgenza) - RischioEruzione); -- colpisce tutto i danni e/o vulnerabilità
END IF;

IF(RischioTsunami IS NOT NULL) THEN
UPDATE AlertDanniInfluenzati
SET FattoreUrgenza = 1 -  EXP(LOG(1 - FattoreUrgenza) - RischioTsunami); -- colpisce tutto i danni e/o vulnerabilità
END IF;

IF(RischioLahar IS NOT NULL) THEN
UPDATE AlertDanniInfluenzati
SET FattoreUrgenza = 1 -  EXP(LOG(1 - FattoreUrgenza) - RischioLahar); -- colpisce tutto i danni e/o vulnerabilità
END IF;

-- Seleziono gli elementi strutturali che si trovano coinvolti nei punti evidenziati(secondo il modello di coordinate descritto)

INSERT INTO ElementiStrutturaliCoinvolti(X, Y, Z, CodiceVano, Nome, FattoreUrgenza)
SELECT E.X, E.Y, E.Z, E.CodiceVano, E.Tipo AS Nome, AVG(FattoreUrgenza) AS FattoreUrgenza 
FROM EleStrutt E
INNER JOIN AlertDanniInfluenzati ADI ON ADI.Codicevano = E.CodiceVano
AND ((ADI.X BETWEEN ((COS(E.Orientazione * 0.0174533) * E.Lunghezza) + E.X) AND (SIN(E.Orientazione * 0.0174533)* E.Larghezza + E.X) ) OR ADI.X BETWEEN (SIN(E.Orientazione * 0.0174533)* E.Larghezza + E.X) AND ((COS(E.Orientazione * 0.0174533) * E.Lunghezza) + E.X))
AND ((ADI.Y BETWEEN ((SIN(E.Orientazione * 0.0174533) * E.Lunghezza) + E.Y) AND (COS((E.Orientazione * 0.0174533))* E.Larghezza + E.Y)) OR ADI.Y BETWEEN (COS((E.Orientazione * 0.0174533))* E.Larghezza + E.Y) AND ((SIN(E.Orientazione * 0.0174533) * E.Lunghezza) + E.Y) )
AND
(ADI.Z BETWEEN E.Z AND (E.Altezza + E.Z))
INNER JOIN Vano V ON V.CodiceVano = E.CodiceVano 
WHERE V.CodiceEdificio = CodiceEdificio
GROUP BY E.X, E.Y, E.Z, E.Tipo, E.CodiceVano;

-- Inserisco i consigli all'interno della tabella finale

INSERT INTO Consigli(Consiglio, Urgenza, CodiceVano)
SELECT CONCAT("Ristruttura l'elemento di tipo ", ESC.Nome, " nel vano numero ", ESC.CodiceVano, " alle coordinate ", ESC.X, ", ", ESC.Y, ", ", ESC.Z),
 ESC.FattoreUrgenza,
 ESC.CodiceVano
 FROM ElementiStrutturaliCoinvolti ESC;
 
 -- Seleziono i consigli ottenuti
 
 SELECT Consiglio, Urgenza, CodiceVano, AVG(Urgenza) OVER(PARTITION BY CodiceVano)  AS UrgenzaMediaVano
 FROM Consigli 
 ORDER BY Urgenza DESC;


END %%


DELIMITER ; 