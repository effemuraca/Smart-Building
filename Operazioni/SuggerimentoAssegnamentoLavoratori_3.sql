DROP TRIGGER IF EXISTS assegnamento_turno;

DELIMITER $$
CREATE TRIGGER assegnamento_turno
AFTER INSERT ON Svolgimento
FOR EACH ROW
BEGIN
	DECLARE min_lavoratori INT;
    DECLARE cod_capo VARCHAR(20);
    DECLARE max_lavoratori INT;
    
    SELECT COUNT(DISTINCT L.CodFiscale) / C.MaxLavoratori, L.CodFiscaleCapocantiere, C.MaxLavoratori INTO min_lavoratori, cod_capo, max_lavoratori
    FROM Lavoratore L
    INNER JOIN Capocantiere C ON C.CodFiscale = L.CodFiscaleCapocantiere
    INNER JOIN AsseCapo A ON A.CodFiscale = C.CodFiscale
    INNER JOIN Svolgimento SV ON SV.GiornoInizio = A.GiornoInizio AND SV.GiornoFine = A.GiornoFine AND SV.OraInizio = A.OraInizio AND SV.OraFine = A.OraFine
    WHERE SV.GiornoInizio = NEW.GiornoInizio AND SV.GiornoFine = NEW.GiornoFine AND SV.OraInizio = NEW.OraInizio AND SV.OraFine = NEW.OraFine
    GROUP BY L.CodFiscaleCapocantiere, SV.GiornoInizio, SV.GiornoFine, SV.OraInizio, SV.OraFine
    HAVING COUNT(DISTINCT L.CodFiscale) / C.MaxLavoratori <= ALL (
		SELECT COUNT(DISTINCT L.CodFiscale) / C.MaxLavoratori
		FROM Lavoratore L
		GROUP BY CodFiscaleCapocantiere
	);
    IF min_lavoratori + 1 <= max_lavoratori THEN
		UPDATE Lavoratore
        SET CodFiscaleCapocantiere = cod_capo
        WHERE CodFiscale = NEW.CodFiscale;
    END IF;
    
END $$
DELIMITER ;