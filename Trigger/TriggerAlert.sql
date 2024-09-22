/* Nel momento in cui una registrazione supera una delle sue soglie, un trigger provvede a salvarla come alert; questo per ogni tipo di sensore (in base alle dimensioni). */

DROP TRIGGER IF EXISTS set_alert1D;
DELIMITER $$
CREATE TRIGGER set_alert1D
AFTER INSERT ON Registrazione1D
FOR EACH ROW
BEGIN
	DECLARE valore_soglia FLOAT DEFAULT 1;
    DECLARE valore_soglia_inf FLOAT DEFAULT NULL;
    SELECT Soglia INTO valore_soglia
    FROM Sensore1D
    WHERE CodiceSensore = NEW.CodiceSensore;
    SELECT ValoreInf INTO valore_soglia_inf
    FROM Sensore1D
		 NATURAL JOIN SogliaInferiore
    WHERE CodiceSensore = NEW.CodiceSensore;
	IF NEW.Valore >= valore_soglia THEN
		INSERT INTO Alert1D(CodiceSensore, Timestamp, Scostamento)
        SELECT R1D.CodiceSensore, R1D.Timestamp, ((R1D.Valore / valore_soglia) - 1)
        FROM Registrazione1D R1D
        WHERE R1D.CodiceSensore = NEW.CodiceSensore AND R1D.Timestamp = NEW.Timestamp;
	END IF;
    IF (valore_soglia_inf IS NOT NULL) THEN
		IF NEW.Valore < valore_soglia_inf THEN
			INSERT INTO Alert1D
			SELECT R1D1.CodiceSensore, R1D1.Timestamp, ABS((R1D1.Valore / valore_soglia) - 1)
			FROM Registrazione1D R1D1
			WHERE R1D1.CodiceSensore = NEW.CodiceSensore AND R1D1.Timestamp = NEW.Timestamp;
		END IF;
    END IF;
END $$

DELIMITER ;
DROP TRIGGER IF EXISTS set_alert2D;
DELIMITER $$
CREATE TRIGGER set_alert2D
AFTER INSERT ON Registrazione2D
FOR EACH ROW
BEGIN
	DECLARE valore_soglia_x FLOAT DEFAULT 0;
    DECLARE valore_soglia_y FLOAT DEFAULT 0;
	DECLARE valore_ins_x FLOAT DEFAULT NULL;
    DECLARE valore_ins_y FLOAT DEFAULT NULL;
    SELECT SogliaX, SogliaY INTO valore_soglia_x, valore_soglia_y
    FROM Sensore2D
    WHERE CodiceSensore = NEW.CodiceSensore;
    IF(NEW.ValoreX >= valore_soglia_x) THEN
			SET valore_ins_x = (NEW.ValoreX / valore_soglia_x) - 1;
	END IF;
    IF(NEW.ValoreY >= valore_soglia_y) THEN
			SET valore_ins_y = (NEW.ValoreY / valore_soglia_y) - 1;
	END IF;
	IF NEW.ValoreX >= valore_soglia_x OR NEW.ValoreY >= valore_soglia_y  THEN
		INSERT INTO Alert2D
        SELECT R2D.CodiceSensore, R2D.Timestamp, valore_ins_x, valore_ins_y
		FROM Registrazione2D R2D
		WHERE R2D.CodiceSensore = NEW.CodiceSensore AND R2D.Timestamp = NEW.Timestamp;
	END IF;
END $$

DELIMITER ;
DROP TRIGGER IF EXISTS set_alert3D;
DELIMITER $$
CREATE TRIGGER set_alert3D
AFTER INSERT ON Registrazione3D
FOR EACH ROW
BEGIN
	DECLARE valore_soglia_x FLOAT DEFAULT 0;
    DECLARE valore_soglia_y FLOAT DEFAULT 0;
    DECLARE valore_soglia_z FLOAT DEFAULT 0;
    DECLARE valore_ins_x FLOAT DEFAULT NULL;
    DECLARE valore_ins_y FLOAT DEFAULT NULL;
    DECLARE valore_ins_z FLOAT DEFAULT NULL;
    SELECT SogliaX, SogliaY, SogliaZ INTO valore_soglia_x, valore_soglia_y, valore_soglia_z
    FROM Sensore3D
    WHERE CodiceSensore = NEW.CodiceSensore;
    IF(NEW.ValoreX >= valore_soglia_x) THEN
			SET valore_ins_x = (NEW.ValoreX / valore_soglia_x) - 1;
	END IF;
    IF(NEW.ValoreY >= valore_soglia_y) THEN
			SET valore_ins_y = (NEW.ValoreY / valore_soglia_y) - 1;
	END IF;
    IF(NEW.ValoreZ >= valore_soglia_z) THEN
			SET valore_ins_z = (NEW.ValoreZ / valore_soglia_z) - 1;
	END IF;
	IF NEW.ValoreX >= valore_soglia_x OR NEW.ValoreY >= valore_soglia_y OR NEW.ValoreZ >= valore_soglia_z  THEN
		INSERT INTO Alert3D
        SELECT R3D.CodiceSensore, R3D.Timestamp, valore_ins_x, valore_ins_y, valore_ins_z
		FROM Registrazione3D R3D
		WHERE R3D.CodiceSensore = NEW.CodiceSensore AND R3D.Timestamp = NEW.Timestamp;
	END IF;
END $$

DELIMITER ;