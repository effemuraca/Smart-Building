

DROP FUNCTION IF EXISTS penale_ritardi;
DELIMITER $$
CREATE FUNCTION penale_ritardi(codice_progetto INT, data_inizio DATE)
RETURNS FLOAT
DETERMINISTIC
BEGIN
	-- costo_derivato_ava è il costo dato solamente dai costi dei lavori, costo_stadio_ava è lo stesso costo, a cui sono aggiunti gli stipendi dei responsabili
	DECLARE costo_derivato_ava FLOAT;
    DECLARE costo_mat FLOAT;
    DECLARE costo_lav FLOAT;
    DECLARE stima_data_fine DATE DEFAULT NULL;
    DECLARE data_fine DATE DEFAULT NULL; 
    DECLARE costo_stadio_ava FLOAT;
    DECLARE multiplier FLOAT DEFAULT 0;
    DECLARE responsabili_daily FLOAT;
    
    SELECT SA.DataFine, SA.StimaDataFine
    FROM StadioAva SA
    WHERE SA.CodiceProgetto = codice_progetto
		  AND SA.DataInizio = data_inizio
	INTO data_fine, stima_data_fine;
          
	-- nel caso in cui lo stadio d'avanzamento non è ancora terminato, allora il suo costo non è ancora calcolabile
	IF data_fine IS NULL THEN
		SET costo_stadio_ava = NULL;
		RETURN costo_stadio_ava;
	END IF;
    
    SELECT SUM(IfNull(L.CostoMateriali, 0)), SUM(IfNull(L.CostoLavoratori, 0)) INTO costo_mat, costo_lav
	FROM Lavoro L
		 NATURAL JOIN
         StadioAva SA
	WHERE SA.CodiceProgetto = codice_progetto
		  AND SA.DataInizio = data_inizio;
          
	SELECT SUM(DISTINCT R.StipendioGiornaliero) INTO responsabili_daily
    FROM Responsabile R
		 NATURAL JOIN
         Gestione G
    WHERE G.CodiceProgetto = codice_progetto
		  AND G.DataInizio = data_inizio;
          
	SET costo_stadio_ava = costo_mat + costo_lav + responsabili_daily * DATEDIFF(data_fine, data_inizio);
	IF data_fine <= stima_data_fine THEN
    -- se la data va bene si ritorna costo derivato
		RETURN costo_stadio_ava;
	END IF;
    SET costo_lav = costo_lav * (DATEDIFF(data_fine, data_inizio)/7);
    SET multiplier = (DATEDIFF(data_fine, stima_data_fine) / DATEDIFF(data_fine, data_inizio)) * 0.7;
    RETURN multiplier * costo_stadio_ava + costo_stadio_ava;
END $$
DELIMITER ;
          
	