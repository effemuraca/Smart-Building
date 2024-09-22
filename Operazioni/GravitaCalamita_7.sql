DROP FUNCTION IF EXISTS Distanza;
DELIMITER %%

CREATE FUNCTION Distanza(lat1 FLOAT, lat2 FLOAT, lon1 FLOAT, lon2 FLOAT)
RETURNS FLOAT DETERMINISTIC
BEGIN

        RETURN 111.111 *
    DEGREES(ACOS(LEAST(1.0, COS(RADIANS(lat1))
         * COS(RADIANS(lat2))
         * COS(RADIANS(lon1 - lon2))
         + SIN(RADIANS(lat1))
         * SIN(RADIANS(lat2)))));
END %%

DELIMITER ;

DROP PROCEDURE IF EXISTS gravita_calamita;

DELIMITER %%

CREATE PROCEDURE gravita_calamita(IN CodiceCalamita INT)
BEGIN
DECLARE Gravita INT;
DECLARE EntitaVicina FLOAT;
DECLARE EntitaMedia FLOAT;
DECLARE EntitaLontana FLOAT;


WITH Calamita AS (SELECT * FROM Calamita C1 
				  WHERE C1.CodiceCalamita = CodiceCalamita),
   DanniTotali AS (SELECT D.CodiceDanno, E.Latitudine, E.Longitudine, D.Entita
FROM Calamita C
INNER JOIN Danno D ON D.CodiceCalamita = C.CodiceCalamita
INNER JOIN Vano V ON D.CodiceVano = V.CodiceVano
INNER JOIN Edificio E ON E.CodiceEdificio = V.CodiceEdificio
WHERE C.CodiceCalamita = CodiceCalamita
AND D.Entita <> -1)

SELECT (SELECT DISTINCT AVG(Entita)
		FROM (SELECT * FROM DanniTotali) AS T 
        WHERE ((Distanza(T.Latitudine, (SELECT Latitudine FROM Calamita), T.Longitudine, (SELECT Longitudine FROM Calamita))/
        (SELECT Raggio FROM Calamita)) < 0.25)), 
         (SELECT DISTINCT AVG(Entita)
		FROM (SELECT * FROM DanniTotali) AS T 
        WHERE ((Distanza(T.Latitudine, (SELECT Latitudine FROM Calamita), T.Longitudine, (SELECT Longitudine FROM Calamita))/
        (SELECT Raggio FROM Calamita)) BETWEEN 0.25 AND 0.50)),
        (SELECT DISTINCT AVG(Entita)
		FROM (SELECT * FROM DanniTotali) AS T 
        WHERE ((Distanza(T.Latitudine, (SELECT Latitudine FROM Calamita), T.Longitudine, (SELECT Longitudine FROM Calamita))/
        (SELECT Raggio FROM Calamita)) > 0.50))
INTO EntitaVicina, EntitaMedia, EntitaLontana;

IF EntitaVicina IS NULL THEN
SET EntitaVicina = 0;
END IF;

IF EntitaMedia IS NULL THEN
SET EntitaMedia = 0;
END IF;

IF EntitaLontana IS NULL THEN
SET EntitaLontana = 0;
END IF;

SET Gravita = CAST(((3 + EntitaVicina + EntitaMedia + EntitaLontana)/3) AS SIGNED INT);

UPDATE Calamita
SET LivelloGravita = Gravita
WHERE CodiceCalamita = CodiceCalamita;

END %%

DELIMITER ; 

