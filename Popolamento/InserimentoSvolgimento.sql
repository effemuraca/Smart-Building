SELECT * FROM (
SELECT FLOOR(RAND()*(7)+2) AS Ore, CodiceLavoro, GiornoInizio, GiornoFine, OraInizio, OraFine, L.CodFiscale, ROW_NUMBER() OVER(PARTITION BY L.CodFiscale) AS Ordine
FROM Lavoratore L 
INNER JOIN Capocantiere C ON L.Capocantiere = C.CodFiscale
INNER JOIN AsseCapo AC ON AC.CodFiscale = C.CodFiscale
JOIN Lavoro LA 

WHERE C.CodFiscale = 'NDRFRD70D21Z404M') AS D
WHERE D.Ordine < 41;