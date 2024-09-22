DROP EVENT IF EXISTS StatoEdificio;

DELIMITER %%
CREATE EVENT StatoEdificio ON SCHEDULE
EVERY 1 DAY STARTS '2022-07-29 00:00:00'
DO
BEGIN
DECLARE CodiceEdi INT;
DECLARE VulnSismica FLOAT DEFAULT 0;
DECLARE VulnIdrogeologica FLOAT DEFAULT 0;
DECLARE VulnTermica FLOAT DEFAULT 0;
DECLARE VulnStrutturale FLOAT DEFAULT 0;
DECLARE NumSensTotali1D INT DEFAULT 0;
DECLARE NumSensTotali2D INT DEFAULT 0;
DECLARE NumSensTotali3D INT DEFAULT 0;
DECLARE fine INT DEFAULT 0;
DECLARE Edifici CURSOR FOR (SELECT CodiceEdificio FROM Edificio);
DECLARE CONTINUE HANDLER FOR NOT FOUND SET fine = 1;


OPEN Edifici;
ciclo:LOOP
FETCH Edifici INTO CodiceEdi;
	IF fine = 1 THEN LEAVE ciclo;
	END IF;
    SET VulnSismica = 0,
		VulnIdrogeologica = 0,
		VulnTermica = 0,
        VulnStrutturale = 0;
	-- Setto a 0 le vulnerabilità

SELECT COUNT(DISTINCT CodiceSensore) FROM (SELECT CodiceSensore, Tipo, CodiceVano 
				   FROM Sensore1D S1D 
				   NATURAL JOIN Vano V
				   INNER JOIN Edificio E ON V.CodiceEdificio = E.CodiceEdificio
                   WHERE E.CodiceEdificio = CodiceEdi) AS S1D INTO NumSensTotali1D;
SELECT COUNT(DISTINCT CodiceSensore) FROM (SELECT CodiceSensore, Tipo, CodiceVano 
				   FROM Sensore2D S2D 
				   NATURAL JOIN Vano V
				   INNER JOIN Edificio E ON V.CodiceEdificio = E.CodiceEdificio
                   WHERE E.CodiceEdificio = CodiceEdi) AS S2D INTO NumSensTotali2D;
SELECT COUNT(DISTINCT CodiceSensore) FROM (SELECT CodiceSensore, Tipo, CodiceVano 
				   FROM Sensore3D S3D 
				   NATURAL JOIN Vano V
				   INNER JOIN Edificio E ON V.CodiceEdificio = E.CodiceEdificio
                   WHERE E.CodiceEdificio = CodiceEdi) AS S3D INTO NumSensTotali3D;

IF((NumSensTotali1D + NumSensTotali2D + NumSensTotali3D)!=0) THEN
WITH Sensori1D AS (SELECT CodiceSensore, Tipo, CodiceVano 
				   FROM Sensore1D S1D 
				   NATURAL JOIN Vano V
				   INNER JOIN Edificio E ON V.CodiceEdificio = E.CodiceEdificio
                   WHERE E.CodiceEdificio = CodiceEdi),
Sensori2D AS (SELECT CodiceSensore, Tipo, CodiceVano 
				   FROM Sensore2D S2D 
				   NATURAL JOIN Vano V
				   INNER JOIN Edificio E ON V.CodiceEdificio = E.CodiceEdificio
                   WHERE E.CodiceEdificio = CodiceEdi),
Sensori3D AS (SELECT CodiceSensore, Tipo, CodiceVano 
				   FROM Sensore3D S3D 
				   NATURAL JOIN Vano V
				   INNER JOIN Edificio E ON V.CodiceEdificio = E.CodiceEdificio
                   WHERE E.CodiceEdificio = CodiceEdi),
LastAlert1D AS (SELECT Scostamento, Timestamp, CodiceSensore, Tipo FROM Alert1D A1D 
                NATURAL JOIN Sensori1D S1D
                WHERE A1D.Timestamp >= (NOW() - INTERVAL 1 DAY)),
LastAlert2D AS (SELECT ScostamentoX, ScostamentoY, Timestamp, CodiceSensore, Tipo FROM Alert2D A2D 
                NATURAL JOIN Sensori2D S2D
                WHERE A2D.Timestamp >= (NOW() - INTERVAL 1 DAY)),
LastAlert3D AS (SELECT ScostamentoX, ScostamentoY, ScostamentoZ,  Timestamp, CodiceSensore, Tipo FROM Alert3D A3D 
                NATURAL JOIN Sensori3D S3D
                WHERE A3D.Timestamp >= (NOW() - INTERVAL 1 DAY)),
NumSensAlert1D AS (SELECT COUNT(DISTINCT CodiceSensore) FROM (SELECT * FROM LastAlert1D) AS LA1D),
NumSensAlert2D AS (SELECT COUNT(DISTINCT CodiceSensore) FROM (SELECT * FROM LastAlert2D) AS LA2D),
NumSensAlert3D AS (SELECT COUNT(DISTINCT CodiceSensore) FROM (SELECT * FROM LastAlert3D) AS LA3D),
SCLastAlertPos AS (SELECT AVG(Scostamento) FROM (SELECT * FROM LastAlert1D) AS LA1D WHERE LA1D.Tipo = 'Posizione'),
SCLastAlertUmiEst AS (SELECT AVG(Scostamento) FROM (SELECT * FROM LastAlert1D) AS LA1D WHERE LA1D.Tipo = 'UmiditaEsterna'),
SCLastAlertUmiInt AS (SELECT AVG(Scostamento) FROM (SELECT * FROM LastAlert1D) AS LA1D WHERE LA1D.Tipo = 'UmiditaInterna'),
SCLastAlertTempEst AS (SELECT AVG(Scostamento) FROM (SELECT * FROM LastAlert1D) AS LA1D WHERE LA1D.Tipo = 'TemperaturaEsterna'),
SCLastAlertTempInt AS (SELECT AVG(Scostamento) FROM (SELECT * FROM LastAlert1D) AS LA1D WHERE LA1D.Tipo = 'TemperaturaInterna'),
SCLastAlertPrec AS (SELECT AVG(Scostamento) FROM (SELECT * FROM LastAlert1D) AS LA1D WHERE LA1D.Tipo = 'Precipitazione'),
SCLastAlertGir2DX AS (SELECT AVG(ScostamentoX) FROM (SELECT * FROM LastAlert2D WHERE ScostamentoX <> 0) AS LA2D WHERE LA2D.Tipo = 'Giroscopio'),
SCLastAlertGir2DY AS (SELECT AVG(ScostamentoY) FROM (SELECT * FROM LastAlert2D WHERE ScostamentoY <> 0) AS LA2D WHERE LA2D.Tipo = 'Giroscopio'),
SCLastAlertAcc2DX AS (SELECT AVG(ScostamentoX) FROM (SELECT * FROM LastAlert2D WHERE ScostamentoX <> 0) AS LA2D WHERE LA2D.Tipo = 'Accelerometro'),
SCLastAlertAcc2DY AS (SELECT AVG(ScostamentoY) FROM (SELECT * FROM LastAlert2D WHERE ScostamentoY <> 0) AS LA2D WHERE LA2D.Tipo = 'Accelerometro'),
SCLastAlertGir3DX AS (SELECT AVG(ScostamentoX) FROM (SELECT * FROM LastAlert3D WHERE ScostamentoX <> 0) AS LA3D WHERE LA3D.Tipo = 'Giroscopio'),
SCLastAlertGir3DY AS (SELECT AVG(ScostamentoY) FROM (SELECT * FROM LastAlert3D WHERE ScostamentoY <> 0) AS LA3D WHERE LA3D.Tipo = 'Giroscopio'),
SCLastAlertGir3DZ AS (SELECT AVG(ScostamentoZ) FROM (SELECT * FROM LastAlert3D WHERE ScostamentoZ <> 0) AS LA3D WHERE LA3D.Tipo = 'Giroscopio'),
SCLastAlertAcc3DX AS (SELECT AVG(ScostamentoX) FROM (SELECT * FROM LastAlert3D WHERE ScostamentoX <> 0) AS LA3D WHERE LA3D.Tipo = 'Accelerometro'),
SCLastAlertAcc3DY AS (SELECT AVG(ScostamentoY) FROM (SELECT * FROM LastAlert3D WHERE ScostamentoY <> 0) AS LA3D WHERE LA3D.Tipo = 'Accelerometro'),
SCLastAlertAcc3DZ AS (SELECT AVG(ScostamentoZ) FROM (SELECT * FROM LastAlert3D WHERE ScostamentoZ <> 0) AS LA3D WHERE LA3D.Tipo = 'Accelerometro')

SELECT 
-- vulnerabilità sismica
((IfNull((SELECT DISTINCT * FROM SCLastAlertPos),0) + 
		(IfNull((SELECT DISTINCT * FROM SCLastAlertGir2DX), 0) + IfNull((SELECT DISTINCT * FROM SCLastAlertGir2DY), 0))/2 + 
		(IfNull((SELECT DISTINCT * FROM SCLastAlertAcc2DX), 0) + IfNull((SELECT DISTINCT * FROM SCLastAlertAcc2DY), 0))/2 + 
		(IfNull((SELECT DISTINCT * FROM SCLastAlertGir3DX), 0) + 
         IfNull((SELECT DISTINCT * FROM SCLastAlertGir3DY), 0) + 
         IfNull((SELECT DISTINCT * FROM SCLastAlertGir3DZ), 0))/3 +
	    (IfNull((SELECT DISTINCT * FROM SCLastAlertAcc3DX), 0) + 
	     IfNull((SELECT DISTINCT * FROM SCLastAlertAcc3DY), 0) +
         IfNull((SELECT DISTINCT * FROM SCLastAlertAcc3DZ),0))/3) *
		 (
         (IfNull((SELECT DISTINCT * FROM NumSensAlert1D),0) + IfNull((SELECT DISTINCT * FROM NumSensAlert2D), 0) + IfNull((SELECT DISTINCT * FROM NumSensAlert3D),0))/
		 (NumSensTotali1D + NumSensTotali2D + NumSensTotali3D)
         )
		 ),
         
-- vulnerabilità idrogeologica
         ((IfNull((SELECT DISTINCT * FROM SCLastAlertPos),0) + 
         IfNull((SELECT DISTINCT * FROM SCLastAlertUmiEst), 0) + 
	     IfNull((SELECT DISTINCT * FROM SCLastAlertUmiInt), 0) + 
         IfNull((SELECT DISTINCT * FROM SCLastAlertPrec), 0) + 
		(IfNull((SELECT DISTINCT * FROM SCLastAlertAcc2DX), 0) + IfNull((SELECT DISTINCT * FROM SCLastAlertAcc2DY),0))/2 + 
	    (IfNull((SELECT DISTINCT * FROM SCLastAlertAcc3DX), 0) + 
	     IfNull((SELECT DISTINCT * FROM SCLastAlertAcc3DY), 0) +
         IfNull((SELECT DISTINCT * FROM SCLastAlertAcc3DZ),0))/3) *
		 (
         (IfNull((SELECT DISTINCT * FROM NumSensAlert1D), 0) 
         + IfNull((SELECT DISTINCT * FROM NumSensAlert2D),0) 
         + IfNull((SELECT DISTINCT * FROM NumSensAlert3D),0))/
		 (NumSensTotali1D + NumSensTotali2D + NumSensTotali3D)
         )
		 ),
         
-- vulnerabilità termica
         ((IfNull((SELECT DISTINCT * FROM SCLastAlertUmiEst), 0) + 
         IfNull((SELECT DISTINCT * FROM SCLastAlertUmiInt), 0) + 
         IfNull((SELECT DISTINCT * FROM SCLastAlertTempEst),0) + 
         IfNull((SELECT DISTINCT * FROM SCLastAlertTempInt),0)) *
		 (
         (IfNull((SELECT DISTINCT * FROM NumSensAlert1D), 0) + 
         IfNull((SELECT DISTINCT * FROM NumSensAlert2D), 0) + 
         IfNull((SELECT DISTINCT * FROM NumSensAlert3D), 0))/
		 (NumSensTotali1D + NumSensTotali2D + NumSensTotali3D)
         )
		 ),
         
-- vulnerabilità strutturale
         ((IfNull((SELECT DISTINCT * FROM SCLastAlertPos), 0) + 
         IfNull((SELECT DISTINCT * FROM SCLastAlertUmiEst), 0) + 
         IfNull((SELECT DISTINCT * FROM SCLastAlertUmiInt), 0) + 
         IfNull((SELECT DISTINCT * FROM SCLastAlertPrec), 0) + 
		(IfNull((SELECT DISTINCT * FROM SCLastAlertGir2DX), 0) + IfNull((SELECT DISTINCT * FROM SCLastAlertGir2DY), 0))/2 + 
	    (IfNull((SELECT DISTINCT * FROM SCLastAlertGir3DX), 0) + 
	     IfNull((SELECT DISTINCT * FROM SCLastAlertGir3DY), 0) +
         IfNull((SELECT DISTINCT * FROM SCLastAlertGir3DZ), 0))/3 +
         IfNull((SELECT DISTINCT * FROM SCLastAlertTempEst), 0) + 
         IfNull((SELECT DISTINCT * FROM SCLastAlertTempInt), 0)) *
		 (
         (IfNull((SELECT DISTINCT * FROM NumSensAlert1D), 0) + IfNull((SELECT DISTINCT * FROM NumSensAlert2D), 0) + IfNull((SELECT DISTINCT * FROM NumSensAlert3D), 0))/
		 (NumSensTotali1D + NumSensTotali2D + NumSensTotali3D)
         )
		 )
		INTO VulnSismica,
		VulnIdrogeologica,
		VulnTermica,
		VulnStrutturale;
        
        
IF VulnSismica IS NULL THEN
SET VulnSismica = 0;
END IF;

IF VulnIdrogeologica IS NULL THEN
SET VulnIdrogeologica = 0;
END IF;

IF VulnTermica IS NULL THEN
SET VulnTermica = 0;
END IF;

IF VulnStrutturale IS NULL THEN
SET VulnStrutturale = 0;
END IF;

UPDATE Stato S 
SET S.VulnSismica = VulnSismica,
    S.VulnIdrogeologica = VulnIdrogeologica,
    S.VulnTermica = VulnTermica,
    S.VulnStrutturale = VulnStrutturale
WHERE S.CodiceEdificio = CodiceEdi;


END IF;

END LOOP;
CLOSE Edifici;

END %%

DELIMITER ;