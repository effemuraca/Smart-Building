DROP TRIGGER IF EXISTS coeff_rischio_e;

DELIMITER %%

CREATE TRIGGER coeff_rischio_e AFTER INSERT ON Edificio
FOR EACH ROW
BEGIN

INSERT INTO Rischio (Tipo, Data, Coefficiente, NomeArea)
SELECT Tipo, CURRENT_DATE, 1 -  EXP(LOG(1 - Coefficiente) - 0.05), A1.NomeArea 
FROM Rischio R1
INNER JOIN AreaGeo A1 ON A1.NomeArea = R1.NomeArea
INNER JOIN Edificio E1 ON E1.NomeArea = A1.NomeArea
WHERE E1.CodiceEdificio = NEW.CodiceEdificio;

END %%

DELIMITER ;

DROP TRIGGER IF EXISTS coeff_rischio_c;

DELIMITER %%

CREATE TRIGGER coeff_rischio_c AFTER INSERT ON Avvenimento
FOR EACH ROW
BEGIN

INSERT INTO Rischio (Tipo, Data, Coefficiente, NomeArea)
SELECT C.Tipo, CURRENT_DATE, 1 -  EXP(LOG(1 - Coefficiente) - 0.05), R1.NomeArea 
FROM Rischio R1
INNER JOIN AreaGeo A1 ON A1.NomeArea = R1.NomeArea
INNER JOIN Avvenimento AV ON A1.NomeArea = AV.NomeArea
INNER JOIN Calamita C ON C.CodiceCalamita = AV.CodiceCalamita
WHERE R1.Tipo = C.Tipo
AND AV.CodiceCalamita = NEW.CodiceCalamita;

END %%


DELIMITER ;