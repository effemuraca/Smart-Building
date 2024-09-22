DROP PROCEDURE IF EXISTS classifica_aziende;

DELIMITER %% 

CREATE PROCEDURE classifica_aziende()
BEGIN

WITH Lista AS (SELECT El.Tipo, L.NomeFornitore
FROM EleStrutt El
INNER JOIN Utilizzo U ON U.X = El.X AND U.Y = El.Y AND U.Z = El.Z AND U.CodiceVano = El.CodiceVano
INNER JOIN Lotto L ON L.CodiceLotto = U.CodiceLotto)

SELECT D.Tipo, D.NomeFornitore
FROM (SELECT * FROM Lista) AS D
GROUP BY D.Tipo, D.NomeFornitore
HAVING COUNT(*) = (SELECT MAX(Conto) FROM 
				   (SELECT COUNT(*) AS Conto 
                   FROM Lista Li
                   WHERE Li.Tipo = D.Tipo
                   GROUP BY Li.NomeFornitore) AS T);
                   

END %%

DELIMITER ;

call classifica_aziende()