DROP EVENT IF EXISTS set_costo_lavoratori;

DELIMITER %%

CREATE EVENT set_costo_lavoratori  ON SCHEDULE
EVERY 1 DAY STARTS '2022-07-29 00:00:00'
DO
BEGIN

WITH sum_lavoratori AS (SELECT SUM(Parziale) AS Somma, D.CodiceLavoro
						FROM (SELECT L.StipendioOrario * SL.Ore AS Parziale, SL.CodiceLavoro
								FROM Lavoratore L
                                INNER JOIN Svolgimento SL ON L.CodFiscale = SL.CodFiscale) AS D
						GROUP BY D.CodiceLavoro),
sum_capocantieri AS (SELECT SUM(ParzialeCapo) AS SommaCapi, D.CodiceLavoro
					 FROM(SELECT DISTINCT C.StipendioGiornaliero * IfNull(7/
                     (SELECT COUNT(*) FROM Lavoro L1 
                             WHERE L1.DataInizio = SA.DataInizio
                             AND L1.CodiceProgetto = SA.CodiceProgetto), 0) AS ParzialeCapo, L3.CodiceLavoro 
						  FROM Capocantiere C
                          INNER JOIN Lavoratore L2 ON L2.CodFiscaleCapocantiere = C.CodFiscale
                          INNER JOIN Svolgimento SV1 ON SV1.CodFiscale = L2.CodFiscale
                          INNER JOIN Lavoro L3 ON L3.CodiceLavoro = SV1.CodiceLavoro
                          INNER JOIN StadioAva SA ON SA.CodiceProgetto = L3.CodiceProgetto 
                          AND SA.DataInizio = L3.DataInizio) AS D
					 GROUP BY D.CodiceLavoro)
                     
UPDATE Lavoro L
SET L.CostoLavoratori = (SELECT Somma 
						 FROM sum_lavoratori SV 
                         WHERE L.CodiceLavoro = SV.CodiceLavoro)  
                         +
                         (SELECT SommaCapi 
						  FROM sum_capocantieri SC
						  WHERE L.CodiceLavoro = SC.CodiceLavoro);
                          
END %%

DELIMITER ;

DROP TRIGGER IF EXISTS set_costo_materiali;

DELIMITER %%

CREATE TRIGGER set_costo_materiali
AFTER INSERT ON Fornitura
FOR EACH ROW
BEGIN
DECLARE Costo FLOAT;
SELECT Lo.Costo
FROM Lotto Lo
WHERE Lo.CodiceLotto = NEW.CodiceLotto
INTO Costo;

UPDATE Lavoro L
SET L.CostoMateriali = IfNull(L.CostoMateriali, 0) + Costo * NEW.Quantita
WHERE L.CodiceLavoro = NEW.CodiceLavoro;

END %%

DELIMITER ;