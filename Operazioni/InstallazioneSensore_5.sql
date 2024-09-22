DROP PROCEDURE IF EXISTS installazione_sensore;
DELIMITER %%

CREATE PROCEDURE installazione_sensore(IN Tipo VARCHAR(45), IN Dimensioni INT, IN CodiceSensore INT, IN CodiceVano INT)
BEGIN
DECLARE fine INT DEFAULT 0;
DECLARE Vertice1C FLOAT;
DECLARE Vertice1X FLOAT;
DECLARE Vertice1Y FLOAT;
DECLARE Vertice2C FLOAT;
DECLARE Vertice2X FLOAT;
DECLARE Vertice2Y FLOAT;
DECLARE X FLOAT DEFAULT -1;
DECLARE Y FLOAT DEFAULT -1;
DECLARE Z FLOAT DEFAULT -1;
DECLARE Vertici CURSOR FOR (SELECT VV.Cardinalita, VV.X, VV.Y FROM VertVano VV
    WHERE VV.CodiceVano = CodiceVano);
DECLARE CONTINUE HANDLER FOR NOT FOUND SET fine = 1;

SET Z = (SELECT AltezzaMax FROM Vano V WHERE V.CodiceVano = CodiceVano)/2;

CASE
-- Sensori a 1 dimensione

    WHEN Dimensioni=1 THEN 
    OPEN Vertici;
    ciclo:LOOP
    FETCH Vertici INTO Vertice2C, Vertice2X, Vertice2Y;
    IF fine = 1 THEN LEAVE ciclo;
	END IF;
    
    IF(Vertice2C > 0) THEN
    SET X = ABS(Vertice2X - Vertice1X)/2;
    SET Y = ABS(Vertice2Y - Vertice2Y)/2;
    
		IF((SELECT COUNT(*) FROM Sensore1D S1D 
		   WHERE S1D.Tipo = Tipo
		   AND S1D.X = X
		   AND S1D.Y = Y
		   AND S1D.Z = Z
           AND S1D.CodiceVano = CodiceVano) = 0) THEN
		   LEAVE ciclo;
		ELSE
			SET X = -1;
            SET Y = -1;
		END IF;
        
    END IF;
    
    SET Vertice1C = Vertice2C;
    SET Vertice1X = Vertice2X;
    SET Vertice1Y = Vertice2Y;
    END LOOP;
	CLOSE Vertici;
    
    IF((X=-1) OR (Y=-1) OR (Z=-1)) THEN
	SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Assenza di spazio per il sensore';
	END IF;
    
    INSERT INTO Sensore1D(CodiceSensore, X, Y, Z, Tipo, DataInstallazione, CodiceVano)
		VALUES(CodiceSensore, X, Y, Z, Tipo, CURRENT_TIMESTAMP, CodiceVano);
        
    IF(Tipo = 'Temperatura') THEN
		INSERT INTO SogliaInferiore(CodiceSensore)
			VALUES(CodiceSensor);
    END IF;    
    
-- Sensori a 2 dimensioni
    
    WHEN Dimensioni=2 THEN 
    OPEN Vertici;
    ciclo:LOOP
    FETCH Vertici INTO Vertice2C, Vertice2X, Vertice2Y;
    IF fine = 1 THEN LEAVE ciclo;
	END IF;
    
    IF(Vertice2C > 0) THEN
    SET X = ABS(Vertice2X - Vertice1X)/2;
    SET Y = ABS(Vertice2Y - Vertice2Y)/2;
    
		IF((SELECT COUNT(*) FROM Sensore2D S2D 
		   WHERE S2D.Tipo = Tipo
		   AND S2D.X = X
		   AND S2D.Y = Y
		   AND S2D.Z = Z
           AND S2D.CodiceVano = CodiceVano) = 0) THEN
		   LEAVE ciclo;
		ELSE
			SET X = -1;
            SET Y = -1;
		END IF;
        
    END IF;
    
    SET Vertice1C = Vertice2C;
    SET Vertice1X = Vertice2X;
    SET Vertice1Y = Vertice2Y;
    END LOOP;
	CLOSE Vertici;
    
    IF((X=-1) OR (Y=-1) OR (Z=-1)) THEN
	SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Assenza di spazio per il sensore';
	END IF;
    
    INSERT INTO Sensore2D(CodiceSensore, X, Y, Z, Tipo, DataInstallazione, CodiceVano)
		VALUES(CodiceSensore, X, Y, Z, Tipo, CURRENT_TIMESTAMP, CodiceVano);

-- Sensori a 3 dimensioni
    
    WHEN Dimensioni=3 THEN 
    OPEN Vertici;
    ciclo:LOOP
    FETCH Vertici INTO Vertice2C, Vertice2X, Vertice2Y;
    IF fine = 1 THEN LEAVE ciclo;
	END IF;
    
    IF(Vertice2C > 0) THEN
    SET X = ABS(Vertice2X - Vertice1X)/2;
    SET Y = ABS(Vertice2Y - Vertice2Y)/2;
    
		IF((SELECT COUNT(*) FROM Sensore3D S3D 
		   WHERE S3D.Tipo = Tipo
		   AND S3D.X = X
		   AND S3D.Y = Y
		   AND S3D.Z = Z
           AND S3D.CodiceVano = CodiceVano) = 0) THEN
		   LEAVE ciclo;
		ELSE
			SET X = -1;
            SET Y = -1;
		END IF;
        
    END IF;
    
    SET Vertice1C = Vertice2C;
    SET Vertice1X = Vertice2X;
    SET Vertice1Y = Vertice2Y;
    END LOOP;
	CLOSE Vertici;
    
    IF((X=-1) OR (Y=-1) OR (Z=-1)) THEN
	SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Assenza di spazio per il sensore';
	END IF;
    
    INSERT INTO Sensore3D(CodiceSensore, X, Y, Z, Tipo, DataInstallazione, CodiceVano)
		VALUES(CodiceSensore, X, Y, Z, Tipo, CURRENT_TIMESTAMP, CodiceVano);

END CASE;


END %%

DELIMITER ; 

DROP PROCEDURE IF EXISTS installazione_sensore_con_danni;

DELIMITER %%

CREATE PROCEDURE installazione_sensore_con_danni(IN Tipo VARCHAR(45), IN Dimensioni INT, IN CodiceSensore INT, IN CodiceVano INT, IN CodiceDanno INT)
BEGIN
DECLARE X FLOAT DEFAULT -1;
DECLARE Y FLOAT DEFAULT -1;
DECLARE Z FLOAT DEFAULT -1;

SELECT R.X, R.Y, R.Z 
INTO X, Y, Z
FROM Riferimento R 
WHERE R.CodiceDanno = CodiceDanno;

CASE
-- Sensore a 1 dimensione
	WHEN Dimensioni = 1 THEN
	 INSERT INTO Sensore1D(CodiceSensore, X, Y, Z, Tipo, DataInstallazione, CodiceVano)
		VALUES(CodiceSensore, X, Y, Z, Tipo, CURRENT_TIMESTAMP, CodiceVano);
        
     IF(Tipo = 'TemperaturaInterna' OR Tipo = 'TemperaturaEsterna') THEN
		INSERT INTO SogliaInferiore(CodiceSensore)
			VALUES(CodiceSensore);
    END IF;      
    
-- Sensore a 2 dimensioni
    WHEN Dimensioni = 2 THEN
    INSERT INTO Sensore2D(CodiceSensore, X, Y, Z, Tipo, DataInstallazione, CodiceVano)
		VALUES(CodiceSensore, X, Y, Z, Tipo, CURRENT_TIMESTAMP, CodiceVano);
        
-- Sensore a 3 dimensioni
    WHEN Dimensioni = 3 THEN
    
    INSERT INTO Sensore3D(CodiceSensore, X, Y, Z, Tipo, DataInstallazione, CodiceVano)
		VALUES(CodiceSensore, X, Y, Z, Tipo, CURRENT_TIMESTAMP, CodiceVano);
    
END CASE;

END %%

DELIMITER ; 