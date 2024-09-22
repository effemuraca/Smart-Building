-- 5.2.2

DROP PROCEDURE IF EXISTS report_progettuale;
DELIMITER $$
CREATE PROCEDURE report_progettuale (IN codice_progetto INT)
BEGIN
	DECLARE giorni INT;
    DECLARE area_geo VARCHAR(40);
    DECLARE vera_fine DATE;
    DECLARE costo_mat INT;
    DECLARE costo_lav INT;
    DECLARE costo_res INT;
    DECLARE costo_tot INT;
    
    SELECT A.NomeArea INTO area_geo
    FROM AreaGeo A
    INNER JOIN Edificio E ON E.NomeArea = A.NomeArea
    INNER JOIN Progetto P ON P.CodiceEdificio = E.CodiceEdificio
    WHERE P.CodiceProgetto = codice_progetto;
    
    SELECT IF(DataFine IS NULL, StimaDataFine, DataFine) INTO vera_fine
    FROM Progetto
    WHERE CodiceProgetto = codice_progetto;
    
    SELECT DATEDIFF(vera_fine, DataInizio) INTO giorni
    FROM Progetto
    WHERE CodiceProgetto = codice_progetto;
    
    SELECT SUM(L.CostoMateriali), SUM(L.CostoLavoratori) INTO costo_mat, costo_lav 
	FROM Progetto P
	INNER JOIN StadioAva S ON S.CodiceProgetto = P.CodiceProgetto
	INNER JOIN Lavoro L ON L.CodiceProgetto = P.CodiceProgetto
    WHERE P.CodiceProgetto = codice_progetto;
    
    SELECT SUM(StipendioGiornaliero) * giorni INTO costo_res
	FROM Progetto P
	INNER JOIN Gestione G ON G.CodiceProgetto = P.CodiceProgetto
	INNER JOIN Responsabile R ON R.CodFiscale = G.CodFiscale
    WHERE P.CodiceProgetto = codice_progetto;
    
    SET costo_tot = costo_mat + costo_lav + costo_res;
    
    DROP TEMPORARY TABLE IF EXISTS Report;
	CREATE TEMPORARY TABLE Report (
		CodiceProgetto INT,
        CostoProgetto INT DEFAULT 0,
        Tempo INT,
        AreaGeografica VARCHAR(40),
        PRIMARY KEY (CodiceProgetto, CostoProgetto, Tempo, AreaGeografica)
	);
    INSERT INTO Report (CodiceProgetto, Tempo, AreaGeografica, CostoProgetto)
    VALUE (codice_progetto, giorni, area_geo, costo_res);

  
  SELECT *
  FROM Report;
END $$
DELIMITER ;


