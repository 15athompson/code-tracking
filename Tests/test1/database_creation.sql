-- create the hotel_DB database, dropping any existing version of the database
DROP DATABASE IF EXISTS hotel_DB;
CREATE DATABASE hotel_DB;
USE hotel_DB;

-- Create tables in the correct order so that any table referenced by a foreign key has already been created
-- Tables are first created based on model submitted in Assignment 1
CREATE TABLE staff (
    staff_id SMALLINT NOT NULL AUTO_INCREMENT,
    manager_id SMALLINT,
    title VARCHAR(10) NOT NULL,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    role VARCHAR(15) NOT NULL,
    PRIMARY KEY (staff_id),
    FOREIGN KEY (manager_id) REFERENCES staff (staff_id)
);

CREATE TABLE room_type (
    room_type_code CHAR(3) NOT NULL ,
    room_type_name VARCHAR(25) NOT NULL,
    modern_style TINYINT NOT NULL COMMENT '0 or 1 to represent boolean',
    deluxe TINYINT NOT NULL COMMENT '0 or 1 to represent boolean',
    maximum_guests TINYINT NOT NULL,
    PRIMARY KEY (room_type_code)
);

CREATE TABLE bathroom_type (
    bathroom_type_code CHAR(2) NOT NULL,
    bathroom_type_name VARCHAR(50) NOT NULL,
    seperate_shower TINYINT NOT NULL,
    bath TINYINT NOT NULL,
    PRIMARY KEY (bathroom_type_code)
);

CREATE TABLE room_price (
    room_type_code CHAR(3) NOT NULL,
    bathroom_type_code CHAR(2) NOT NULL,
    price DECIMAL(6, 2) NOT NULL,
    PRIMARY KEY (room_type_code, bathroom_type_code),
    FOREIGN KEY (room_type_code) REFERENCES room_type (room_type_code),
    FOREIGN KEY (bathroom_type_code) REFERENCES bathroom_type (bathroom_type_code)
);

CREATE TABLE room (
    room_number SMALLINT NOT NULL,
    room_type_code CHAR(3) NOT NULL,
    bathroom_type_code CHAR(2) NOT NULL,
    status CHAR(3) NOT NULL DEFAULT 'ACT' COMMENT 'ACT = room active, CLN = room requires deep cleaning, REP = room requires repair',
    key_serial_number VARCHAR(15) NOT NULL,
    PRIMARY KEY (room_number),
    CONSTRAINT FK_room_type FOREIGN KEY (room_type_code, bathroom_type_code) REFERENCES room_price (room_type_code, bathroom_type_code),
    CHECK (status IN ('ACT', 'CLN', 'REP'))
);

CREATE TABLE address (
    postcode VARCHAR(7) NOT NULL,
    address_line1 VARCHAR(80) NOT NULL,
    address_line2 VARCHAR(80),
    city VARCHAR(80) NOT NULL,
    county VARCHAR(80) NOT NULL,
    PRIMARY KEY (postcode)    
);

CREATE TABLE company_account (
    company_id INT NOT NULL AUTO_INCREMENT,
    company_name VARCHAR(255) NOT NULL,
    building VARCHAR(50) NOT NULL,
    postcode VARCHAR(7) NOT NULL,
    admin_title VARCHAR(10) NOT NULL,
    admin_first_name VARCHAR(80) NOT NULL,
    admin_last_name VARCHAR(80) NOT NULL,
    admin_phone_number VARCHAR(11) NOT NULL,
    admin_email VARCHAR(320) NOT NULL,
    PRIMARY KEY (company_id),
    FOREIGN KEY (postcode) REFERENCES address (postcode) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT CHK_admin_email CHECK (admin_email REGEXP '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
);
CREATE INDEX IDX_company_name ON company_account (company_name);

CREATE TABLE guest (
    guest_id INT NOT NULL AUTO_INCREMENT,
    company_id INT,
    title VARCHAR(10) NOT NULL,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    phone_number VARCHAR(11) NOT NULL,
    email VARCHAR(320) NOT NULL,
    house_name_number VARCHAR(50) NOT NULL,
    postcode VARCHAR(7) NOT NULL,
    PRIMARY KEY (guest_id),
    FOREIGN KEY (company_id) REFERENCES company_account (company_id) ON UPDATE SET NULL ON DELETE SET NULL,
    FOREIGN KEY (postcode) REFERENCES address (postcode) ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT CHK_phone_number CHECK (phone_number REGEXP '^[0-9]{10,11}$'),
    CONSTRAINT CHK_email CHECK (email REGEXP '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
);
CREATE INDEX IDX_guest_company_id ON guest (company_id);
CREATE INDEX IDX_guest_last_name ON guest (last_name);
CREATE INDEX IDX_guest_postcode ON guest (postcode);

CREATE TABLE marketing (
    guest_id INT NOT NULL,
    marketing_code CHAR(3) NOT NULL,
    contact_by_phone TINYINT NOT NULL COMMENT '0 or 1 to represent no/yes',
    contact_by_email TINYINT NOT NULL COMMENT '0 or 1 to represent no/yes',
    contact_by_post TINYINT NOT NULL COMMENT '0 or 1 to represent no/yes',
    PRIMARY KEY (guest_id),
    FOREIGN KEY (guest_id) REFERENCES guest (guest_id) ON DELETE CASCADE
);
CREATE INDEX IDX_marketing_code ON marketing (marketing_code);

CREATE TABLE invoice (
    invoice_number MEDIUMINT NOT NULL AUTO_INCREMENT,
    invoice_date DATE NOT NULL,
    amount_due DECIMAL(7, 2) NOT NULL,
    amount_paid DECIMAL(7, 2) NOT NULL,
    payment_method VARCHAR(20),
    payment_date DATE,
    PRIMARY KEY (invoice_number)
);

CREATE TABLE promotion (
    promotion_code CHAR(10) NOT NULL,
    promotion_name VARCHAR(50) NOT NULL,
    discount_percentage DECIMAL(5, 2) NOT NULL,
    PRIMARY KEY (promotion_code)
);

CREATE TABLE reservation (
    reservation_id INT NOT NULL AUTO_INCREMENT,
    guest_id INT NOT NULL,
    room_number SMALLINT NOT NULL,
    invoice_number MEDIUMINT,
    promotion_code CHAR(10),
    reservation_staff_id SMALLINT NOT NULL,
    reservation_date_time DATETIME NOT NULL,
    number_of_guests TINYINT NOT NULL,
    start_of_stay DATE NOT NULL,
    length_of_stay SMALLINT NOT NULL,
    status_code CHAR(2) NOT NULL DEFAULT 'RE' COMMENT 'RE - reserved, IN - checked in, OT - checked out',
    PRIMARY KEY (reservation_id),
    FOREIGN KEY (invoice_number) REFERENCES invoice (invoice_number) ON UPDATE RESTRICT ON DELETE RESTRICT,
    FOREIGN KEY (promotion_code) REFERENCES promotion (promotion_code) ON UPDATE RESTRICT ON DELETE RESTRICT,
    FOREIGN KEY (guest_id) REFERENCES guest (guest_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CHECK (status_code IN ('RE', 'IN', 'OT'))
);
CREATE INDEX IDX_reservation_guest ON reservation (guest_id);
CREATE INDEX IDX_reservation_room_number ON reservation (room_number);
CREATE INDEX IDX_reservation_promotion ON reservation (promotion_code);
CREATE INDEX IDX_reservation_staff ON reservation (reservation_staff_id);
CREATE INDEX IDX_reservation_status_code ON reservation (status_code);

CREATE TABLE check_in (
    reservation_id INT NOT NULL,
    staff_id SMALLINT NOT NULL,
    date_time DATETIME NOT NULL,
    notes VARCHAR(255),
    PRIMARY KEY (reservation_id),
	FOREIGN KEY (staff_id) REFERENCES staff (staff_id),
	FOREIGN KEY (reservation_id) REFERENCES reservation (reservation_id)
);

CREATE TABLE check_out (
    reservation_id INT NOT NULL,
    staff_id SMALLINT NOT NULL,
    date_time DATETIME NOT NULL,
    settled_invoice TINYINT NOT NULL COMMENT '0 or 1 to indicate no/yes regarding if invoice was fully paid at the time of check-out.',
    notes VARCHAR(255),
    PRIMARY KEY (reservation_id),
    FOREIGN KEY (staff_id) REFERENCES staff (staff_id),
	FOREIGN KEY (reservation_id) REFERENCES reservation (reservation_id)
);

CREATE TABLE complaint_category (
    category_code CHAR(4) NOT NULL,
    category_name VARCHAR(80) NOT NULL,
    severity INT NOT NULL,
    PRIMARY KEY (category_code)
);

CREATE TABLE complaint (
    reservation_id INT NOT NULL,
    opened_date DATETIME NOT NULL,
    category_code CHAR(4) NOT NULL,
    opened_by SMALLINT NOT NULL,
    description VARCHAR(255) NOT NULL,
    PRIMARY KEY (reservation_id, opened_date),
    FOREIGN KEY (reservation_id) REFERENCES reservation (reservation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    FOREIGN KEY (category_code) REFERENCES complaint_category (category_code) ON UPDATE RESTRICT ON DELETE RESTRICT,
    FOREIGN KEY (opened_by) REFERENCES staff (staff_id) ON UPDATE RESTRICT ON DELETE RESTRICT
);
CREATE INDEX IDX_complaint_category ON complaint (category_code);

CREATE TABLE complaint_resolution (
    reservation_id INT NOT NULL,
    opened_date DATETIME NOT NULL,
    resolved_by SMALLINT NOT NULL,
    resolution VARCHAR(255) NOT NULL,
    resolution_date DATETIME NOT NULL,
    PRIMARY KEY (reservation_id, opened_date),
    FOREIGN KEY (reservation_id, opened_date) REFERENCES complaint (reservation_id, opened_date) ON UPDATE RESTRICT ON DELETE RESTRICT,
    FOREIGN KEY (resolved_by) REFERENCES staff (staff_id) ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE cleaning_session (
    date_of_clean DATE NOT NULL,
    staff_id SMALLINT NOT NULL,
    allocated_master_key CHAR(1) NOT NULL,
    PRIMARY KEY (date_of_clean, staff_id),
    FOREIGN KEY (staff_id) REFERENCES staff (staff_id)
);

CREATE TABLE room_clean (
    room_number SMALLINT NOT NULL,
    date_of_clean DATE NOT NULL,
    staff_id SMALLINT NOT NULL,
    time_of_clean TIME NOT NULL,
    type_of_clean CHAR(1) NOT NULL DEFAULT 'L' COMMENT 'L = Light, F = Full',
    PRIMARY KEY (room_number, date_of_clean),
    FOREIGN KEY (room_number) REFERENCES room (room_number),
    FOREIGN KEY (date_of_clean, staff_id) REFERENCES cleaning_session (date_of_clean, staff_id),
    CHECK (type_of_clean IN ('L', 'F'))
);
CREATE INDEX IDX_staff_id ON room_clean (staff_id);

--
-- Alterations to Assignment 1 initial design
--

-- Make postcode 8 chars long and apply a CHECK to address to validate format
ALTER TABLE address 
	MODIFY postcode VARCHAR(8) NOT NULL,
    ADD CONSTRAINT CHK_postcode CHECK (postcode REGEXP '^[A-Z]{1,2}[0-9][0-9A-Z]? [0-9][A-Z]{2}$');
ALTER TABLE guest MODIFY postcode VARCHAR(8) NOT NULL;    
ALTER TABLE company_account	MODIFY postcode VARCHAR(8) NOT NULL;

-- Create a table to hold the possible payment methods and alter the invoice table to use it
-- Also add a payment_reference column to the invoice table
CREATE TABLE payment_method (
	payment_code CHAR(4),
    payment_method VARCHAR(30),
    PRIMARY KEY (payment_code)
);
ALTER TABLE invoice 
	CHANGE payment_method payment_code CHAR(4),
    ADD COLUMN payment_reference VARCHAR(50),
    ADD CONSTRAINT FK_payment_code FOREIGN KEY (payment_code) REFERENCES payment_method (payment_code) ON UPDATE SET NULL ON DELETE SET NULL;   

-- DESCRIBE each table to check alterations
DESCRIBE address;
DESCRIBE guest;
DESCRIBE company_account;
DESCRIBE invoice;

--
-- Views
--

-- View that enhances the data from the reservation table with derived 
-- date values for the end_of_stay and the last_night in the room
CREATE VIEW reservation_with_end_date_view AS
SELECT 
    reservation_id,
    guest_id,
    room_number,
    invoice_number,
    promotion_code,
    reservation_staff_id,
    reservation_date_time,
    number_of_guests,
    start_of_stay,
    length_of_stay,
    DATE_ADD(start_of_stay, INTERVAL length_of_stay DAY) AS end_of_stay,
    DATE_ADD(start_of_stay, INTERVAL length_of_stay-1 DAY) AS last_night,
    status_code
FROM reservation;

-- View that provides full details about a room (number, type, bathroom features, price etc)
-- by joining four tables together
CREATE VIEW room_details_view AS
SELECT
    r.room_number,
    r.room_type_code,
    rt.room_type_name,
    rt.modern_style,
    rt.deluxe,
    rt.maximum_guests,
    r.bathroom_type_code,
    bt.bathroom_type_name,
    bt.seperate_shower,
    bt.bath,
    r.status,
    r.key_serial_number,
    rp.price
FROM 
    room r
INNER JOIN room_price rp 
    ON r.room_type_code = rp.room_type_code 
    AND r.bathroom_type_code = rp.bathroom_type_code
INNER JOIN room_type rt 
    ON rp.room_type_code = rt.room_type_code
INNER JOIN bathroom_type bt 
    ON rp.bathroom_type_code = bt.bathroom_type_code;

-- View that provides full details about room cleaning
-- (which room, by who, when and with which key)
-- by joining four tables together
-- Cleaning staff will be limited to only see the data in this view
CREATE VIEW room_cleaning_view AS
SELECT
    r.room_number,
    r.date_of_clean,
    r.time_of_clean,
    s.staff_id,
    s.title,
    s.first_name,
    s.last_name,
    r.type_of_clean,
    c.allocated_master_key
FROM 
    room_clean r
INNER JOIN staff s 
    ON r.staff_id = s.staff_id
INNER JOIN cleaning_session c 
    ON r.date_of_clean = c.date_of_clean
    AND r.staff_id = c.staff_id;


--
-- Stored Procedures
-- 

-- ; is required to seperate statements in the stored procedure, so change the MySQL delimiter to //
DELIMITER //

-- Create a stored procedure to find reserved/occupied rooms for a given date range
DROP PROCEDURE IF EXISTS findReservedRooms//
CREATE PROCEDURE findReservedRooms (
    IN start_date DATE,
    IN end_date DATE
)
BEGIN
    SELECT DISTINCT 
		room_number
	FROM 
		reservation_with_end_date_view
	WHERE 
		status_code IN ('RE', 'IN')  /* room is reserved or checked_in */
		AND start_date <= DATE_SUB(end_of_stay, INTERVAL 1 DAY) /* the last night the room is reserved overlaps the search dates */
		AND start_of_stay < end_date /* the first night the room is reserved overlaps the search dates */
	ORDER BY
		room_number;
END //

-- Create a stored procedure to find available rooms for a given date range
DROP PROCEDURE IF EXISTS findAvailableRooms//
CREATE PROCEDURE findAvailableRooms (
    IN start_date DATE,
    IN end_date DATE
)
BEGIN
    SELECT *
	FROM 
		room_details_view
	WHERE
		status = 'ACT'
		AND room_number NOT IN ( 
			SELECT DISTINCT 
				room_number
			FROM 
				reservation_with_end_date_view
			WHERE 
				status_code IN ('RE', 'IN')  /* room is reserved or checked_in */
				AND start_date <= DATE_SUB(end_of_stay, INTERVAL 1 DAY) /* the last night the room is reserved overlaps the search dates */
				AND start_of_stay < end_date 
		);
END //


-- Instead of using a constraint, this trigger shows another way of validating a phone number
-- It allows a custom error message to be displayed when an invalid phone number is entered.
-- When the company_account table has data inserted or updated, the triggers are executed and the 
-- validate_phone_number stored procedure is called.
DROP PROCEDURE IF EXISTS validate_phone_number//
CREATE PROCEDURE validate_phone_number(phone_number VARCHAR(30))
BEGIN
    IF NOT phone_number REGEXP '^[0-9]{10,11}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: The phone number must be 10 or 11 digits in length.';
    END IF;
END //

--
-- Triggers
-- 

CREATE TRIGGER validate_phone_before_insert
BEFORE INSERT ON company_account
FOR EACH ROW
BEGIN
    CALL validate_phone_number(NEW.admin_phone_number);
END //

CREATE TRIGGER validate_phone_before_update
BEFORE UPDATE ON company_account
FOR EACH ROW
BEGIN
    CALL validate_phone_number(NEW.admin_phone_number);
END //

DELIMITER ;

--
-- Roles, Users and Permissions
--

-- create roles
CREATE ROLE IF NOT EXISTS manager, receptionist, cleaner;
-- give a manager full access
GRANT ALL PRIVILEGES ON hotel_DB.* TO manager;
-- limit a cleaner to only reading the room_cleaning_view
GRANT SELECT ON hotel_DB.room_cleaning_view TO cleaner;
-- receptionists can SELECT from all tables, but can only use INSERT, UPDATE, DELETE on some
GRANT SELECT ON hotel_DB.* TO receptionist;
GRANT INSERT, UPDATE, DELETE ON hotel_DB.address TO receptionist;
GRANT INSERT, UPDATE, DELETE ON hotel_DB.check_in TO receptionist;
GRANT INSERT, UPDATE, DELETE ON hotel_DB.check_out TO receptionist;
GRANT INSERT, UPDATE, DELETE ON hotel_DB.company_account TO receptionist;
GRANT INSERT, UPDATE, DELETE ON hotel_DB.complaint TO receptionist;
GRANT INSERT, UPDATE, DELETE ON hotel_DB.complaint_resolution TO receptionist;
GRANT INSERT, UPDATE, DELETE ON hotel_DB.guest TO receptionist;
GRANT INSERT, UPDATE, DELETE ON hotel_DB.invoice TO receptionist;
GRANT INSERT, UPDATE, DELETE ON hotel_DB.marketing TO receptionist;
GRANT INSERT, UPDATE, DELETE ON hotel_DB.reservation TO receptionist;
GRANT EXECUTE ON PROCEDURE hotel_DB.findAvailableRooms TO receptionist;
GRANT EXECUTE ON PROCEDURE hotel_DB.findReservedRooms TO receptionist;
GRANT EXECUTE ON PROCEDURE hotel_DB.validate_phone_number TO receptionist;

-- create some user accounts if they don't exist, passwords will need to be made secure for real usage
CREATE USER IF NOT EXISTS 'manager1'@'localhost' IDENTIFIED BY 'pass1234';
CREATE USER IF NOT EXISTS 'recep1'@'localhost' IDENTIFIED BY 'pass1234';
CREATE USER IF NOT EXISTS 'recep2'@'localhost' IDENTIFIED BY 'pass1234';
CREATE USER IF NOT EXISTS 'clean1'@'localhost' IDENTIFIED BY 'pass1234';
CREATE USER IF NOT EXISTS 'clean2'@'localhost' IDENTIFIED BY 'pass1234';

-- assign roles to users
GRANT 'manager' TO 'manager1'@'localhost';
SET DEFAULT ROLE 'manager' TO 'manager1'@'localhost';
GRANT 'receptionist' TO 'recep1'@'localhost';
SET DEFAULT ROLE 'receptionist' TO 'recep1'@'localhost';
GRANT 'receptionist' TO 'recep2'@'localhost';
SET DEFAULT ROLE 'receptionist' TO 'recep2'@'localhost';
GRANT 'cleaner' TO 'clean1'@'localhost';
SET DEFAULT ROLE 'cleaner' TO 'clean1'@'localhost';
GRANT 'cleaner' TO 'clean2'@'localhost';
SET DEFAULT ROLE 'cleaner' TO 'clean2'@'localhost';
