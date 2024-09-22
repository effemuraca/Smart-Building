DROP PROCEDURE IF EXISTS classifica_punti_critici;
DELIMITER %%

CREATE PROCEDURE classifica_punti_critici(IN CodiceEdificio INT)
BEGIN

DROP TABLE IF EXISTS RankPunti;
CREATE TEMPORARY TABLE RankPunti(
						X FLOAT,
                        Y FLOAT,
                        Z FLOAT,
                        CodiceVano INT,
                        Scostamento FLOAT,
                        EntitaDanno INT,
                        PRIMARY KEY(X,Y,Z,CodiceVano));

-- Inserisco i punti dei sensori1D

INSERT INTO RankPunti (X, Y, Z, CodiceVano, Scostamento)
SELECT X, Y, Z, CodiceVano, Scostamento
		FROM Alert1D A1D INNER JOIN Sensore1D S1D ON S1D.CodiceSensore = A1D.CodiceSensore
        WHERE Timestamp = (SELECT MAX(Timestamp) 
							FROM Alert1D A1D2
							WHERE A1D2.CodiceSensore = A1D.CodiceSensore
                            AND A1D2.Timestamp > (NOW() - INTERVAL 1 MONTH))
		AND CodiceVano IN (SELECT CodiceVano FROM Vano V WHERE V.CodiceEdificio = CodiceEdificio);

-- Inserisco i punti dei sensori2D

INSERT INTO RankPunti (X, Y, Z, CodiceVano, Scostamento)
SELECT X, Y, Z, CodiceVano, (ScostamentoX/2 + ScostamentoY/2) AS Scostamento
		FROM Alert2D A2D INNER JOIN Sensore2D S2D ON S2D.CodiceSensore = A2D.CodiceSensore
        WHERE Timestamp = (SELECT MAX(Timestamp) 
							FROM Alert2D A2D2
							WHERE A2D2.CodiceSensore = A2D.CodiceSensore
                            AND A2D2.Timestamp > (NOW() - INTERVAL 1 MONTH))
		AND CodiceVano IN (SELECT CodiceVano FROM Vano V WHERE V.CodiceEdificio = CodiceEdificio)
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
		AND CodiceVano IN (SELECT CodiceVano FROM Vano V WHERE V.CodiceEdificio = CodiceEdificio)
ON DUPLICATE KEY UPDATE    
Scostamento = (Scostamento + RankPunti.Scostamento)/2;


-- Inserisco i punti dei danni

INSERT INTO RankPunti (X, Y, Z, CodiceVano, EntitaDanno) 
SELECT X, Y, Z, CodiceVano, Entita  FROM Danno D 
INNER JOIN Riferimento R ON R.CodiceDanno = D.CodiceDanno
WHERE D.CodiceVano IN (SELECT CodiceVano FROM Vano V WHERE V.CodiceEdificio = CodiceEdificio)
AND D.Entita <> -1
ON DUPLICATE KEY UPDATE    
EntitaDanno = D.Entita;

SELECT * FROM RankPunti ORDER BY Scostamento, EntitaDanno;

END %%

DELIMITER ;