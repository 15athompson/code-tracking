-- create the hotel_DB database, dropping any existing version of the database
DROP DATABASE IF EXISTS hotel_DB;
CREATE DATABASE hotel_DB;
USE hotel_DB;

GRANT ALL PRIVILEGES ON Hotel_DB.* TO 'root'@'localhost';
FLUSH PRIVILEGES;

CREATE USER 'new_user'@'localhost' IDENTIFIED BY 'new_password';
GRANT ALL PRIVILEGES ON Hotel_DB.* TO 'new_user'@'localhost';
FLUSH PRIVILEGES;


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


-------------------

-- 1) Example of using ON UPDATE CASCADE to change a postcode
SELECT * FROM address WHERE postcode = 'CO10 0CD';
SELECT * FROM guest WHERE postcode = 'CO10 0CD';
-- shows that guest 4 has that postcode, they provided it incorrectly so wish to 
-- change it to CO10 1CD, so update the address table and prove the change cascades
-- down to update the guest table too.
UPDATE address SET postcode = 'CO10 1CD' WHERE postcode = 'CO10 0CD';
SELECT * FROM guest WHERE guest_id = 4;

-- 2) Example of using ON DELETE CASCADE
-- First insert a new guest with marketing info
INSERT INTO guest (guest_id, company_id, title, first_name, last_name, phone_number, email, house_name_number, postcode) VALUES
(50, NULL, 'Mr', 'Will', 'BeDeleted', '07701100999', 'willb@gmail.com', '125', 'TS3 0AC');
INSERT INTO marketing (guest_id, marketing_code, contact_by_phone, contact_by_email, contact_by_post) VALUES
(50, 'ALL', 1, 1, 1);
-- First show the rows for guest 50
SELECT * FROM guest WHERE guest_id = 50;
SELECT * FROM marketing WHERE guest_id = 50;
-- Now delete the guest and prove the change cascades
-- down to remove the row from marketing too
DELETE FROM guest WHERE guest_id = 50;
SELECT * FROM guest WHERE guest_id = 50;
SELECT * FROM marketing WHERE guest_id = 50;

-- 3) Implement a soft delete flag on guest to help maintain data integrity of reservation information
-- Add a deleted flag to the guest table
ALTER TABLE guest ADD deleted TINYINT DEFAULT 0;
-- list the first ten guests that are not flagged as deleted
SELECT * FROM guest where guest_id <= 10 AND deleted = 0;
-- soft delete guest 7
UPDATE guest SET deleted = 1 WHERE guest_id = 7;
-- prove guest 7 is now missing from the select results
SELECT * FROM guest where guest_id <= 10 AND deleted = 0;
-- And that their reservation history still remains intact for reporting purposes
SELECT * FROM reservation where guest_id = 7;

-- 4) demonstrate table creation, renaming, data replacement and dropping
CREATE TABLE childrenClub (
	id INT NOT NULL AUTO_INCREMENT ,
    child_name VARCHAR(30) NOT NULL COMMENT 'This column will soon be renamed',
    age INT NOT NULL,
    PRIMARY KEY (id)    
);
-- rename the table to kidsClub
RENAME TABLE childrenClub TO kidsClub;
-- describe it to prove existence
DESC kidsClub;
-- rename a column and describe again
ALTER TABLE kidsClub RENAME COLUMN child_name TO child_first_name; 
DESC kidsClub;
-- INSERT some data
INSERT INTO kidsClub (child_first_name, age) VALUES
('John', '7'),
('Peter', '9');
SELECT * from kidsClub;
-- replace John's age
REPLACE INTO kidsClub VALUES
(1, 'John', '8');
-- Select again to prove change
SELECT * from kidsClub;
-- Drop the age column
ALTER TABLE kidsClub DROP COLUMN age;
DESC kidsClub;
-- Truncate the data from the table
TRUNCATE TABLE kidsClub;
-- Show the table is empty
SELECT * from kidsClub;
-- Add more data to show the auto increment has been reset
INSERT INTO kidsClub (child_first_name) VALUES
('Paul');
SELECT * from kidsClub;
-- Drop the table
DROP TABLE kidsClub;

-- 5 Use EXPLAIN to optimise a query
EXPLAIN SELECT 
    rt.room_type_name,
    SUM(i.amount_paid) AS total_earnings
FROM 
    invoice i
JOIN 
    reservation r ON i.invoice_number = r.invoice_number
JOIN 
    room rm ON r.room_number = rm.room_number
JOIN 
    room_type rt ON rm.room_type_code = rt.room_type_code
GROUP BY 
    rt.room_type_name
ORDER BY 
    total_earnings DESC;       
-- The explain shows 'ALL' meaning a full table scan was required
-- add an index to the room_type_name column to resolve this (run above explain query again to prove)
CREATE INDEX IDX_room_type_name ON room_type (room_type_name);   

-- 6 use a Transaction to be able to ROLLBACK an address change if there's a problem with guest creation
START TRANSACTION;
-- Insert address
INSERT INTO address (postcode, address_line1, address_line2, city, county) VALUES
('TS10 4DJ', 'The Lane', 'Small Village', 'Big City', 'Essex');
-- Prove it is in the database
SELECT * FROM address WHERE postcode = 'TS10 4DJ';
-- Attempt to insert a guest with an invalid phone number
INSERT INTO guest (guest_id, company_id, title, first_name, last_name, phone_number, email, house_name_number, postcode) VALUES
(81, NULL, 'Mr', 'Peter', 'Green', '01423123', 'peter.green@hotmail.co.uk', '15', 'TS10 4DJ');
-- rollback the transaction
ROLLBACK;
-- prove the address has been rolled back
SELECT * FROM address WHERE postcode = 'TS10 4DJ';



-------------------

-- 1) invalid postcode format
INSERT INTO address (postcode, address_line1, address_line2, city, county) VALUES
('ABC1AB', 'The Street', 'A Village', 'A City', 'A county');

-- 2) invalid phone number length
UPDATE guest SET phone_number = '0770123'
WHERE guest_id = 1;

-- 3) invalid phone number length using trigger on company_account table
UPDATE company_account SET admin_phone_number = '0770123'
WHERE company_id = 1;

-- 4) invalid status applied to room table
UPDATE room SET status = 'INV'
WHERE room_number = 101;

-- 5) invalid status_code applied to reservation table
UPDATE reservation SET status_code = 'ER'
WHERE reservation_id = 1;

-- 6) invalid type_of_clean applied to room_clean table
UPDATE room_clean SET type_of_clean = 'E'
WHERE room_number = 101;

-- 7) invalid email address applied to guest
UPDATE guest SET email = 'invalid.gmail.com'
WHERE guest_id = 1;


-----------------------------


-- 1) Check the reservation_with_end_date_view view can show all reservations
SELECT * FROM reservation_with_end_date_view;

-- 2) Check the room_details_view can show all Active rooms sorted by room_number with all their details and price
SELECT * FROM room_details_view WHERE status = 'ACT' ORDER BY room_number;

-- 3) show reservations that are currently checked_in
SELECT * FROM reservation_with_end_date_view WHERE status_code = "IN";

-- 4) show reservations that have checked_out on 19th Nov
SELECT * 
FROM 
	reservation_with_end_date_view 
WHERE status_code = "OT" AND end_of_stay = '2024-11-19'
ORDER BY room_number;

-- 5) Find guests who have made a reservation in the last 7 days
SELECT guest_id, first_name, last_name
FROM guest
WHERE guest_id IN (
    SELECT guest_id
    FROM reservation
    WHERE reservation_date_time >= CURDATE() - INTERVAL 7 DAY
);

-- 6) Find guests using a hotmail email address
SELECT g.guest_id, g.first_name, g.last_name, g.email
FROM guest g
WHERE g.email LIKE '%@hotmail%';

-- 7) Find the room number of a guest booked to be in the hotel today (using the current date) and searching by their last_name
SELECT 
	r.room_number,    
    CONCAT(g.title, ' ', g.first_name, ' ', g.last_name) AS guest_full_name,
    g.postcode,
    r.number_of_guests
FROM 
	reservation r
JOIN
	guest g
USING (guest_id)
WHERE
	g.last_name = 'Brown'
    AND CURDATE() BETWEEN r.start_of_stay AND DATE_ADD(r.start_of_stay, INTERVAL r.length_of_stay DAY);

-- 8) Use a stored procedure to find reserved/occupied rooms between 1st Dec and 5th Dec
call findReservedRooms('2024-12-01', '2024-12-05');

-- 9) Use a stored procedure to find available rooms (active status) that are not reserved/occupied rooms between 1st Dec and 5th Dec
call findAvailableRooms('2024-12-01', '2024-12-05');
    
-- 10) Report on complaints split by category code   
SELECT 
    c.category_code,
    cc.category_name,
    cc.severity,
    COUNT(*) AS complaint_count
FROM 
    complaint c
JOIN 
    complaint_category cc
ON 
    c.category_code = cc.category_code
GROUP BY 
    c.category_code
ORDER BY 
	complaint_count DESC;	
    
-- 11) Discover which guests have booked the most nights, limit to the top eight results
SELECT 
    g.guest_id,
    g.first_name,
    g.last_name,
    SUM(r.length_of_stay) AS total_nights
FROM 
    guest g
JOIN 
    reservation r
ON 
    g.guest_id = r.guest_id
GROUP BY 
    g.guest_id, g.first_name, g.last_name
ORDER BY 
    total_nights DESC
LIMIT 8;

-- 12) Discover which companies have booked the most nights
SELECT 
	ca.company_id,
    ca.company_name,
    SUM(r.length_of_stay) AS total_nights
FROM 
    company_account ca
JOIN 
    guest g ON ca.company_id = g.company_id
JOIN 
    reservation r ON g.guest_id = r.guest_id
GROUP BY 
    ca.company_id, ca.company_name
ORDER BY 
    total_nights DESC
LIMIT 3;

-- 13) Find reservations that checked-out more than a week ago without settling the invoice
SELECT 
    co.reservation_id,
    co.date_time,
    co.settled_invoice
FROM 
    check_out co
WHERE 
    co.settled_invoice = 0
    AND DATEDIFF(CURRENT_DATE, co.date_time) > 7
ORDER BY
	co.date_time DESC;
    
-- 14) Discover the smallest and largest invoice amounts
SELECT 
	MIN(i.amount_due) AS min_amount_invoiced,
    MAX(i.amount_due) AS max_amount_invoiced
FROM 
	invoice i;
    
-- 15) Report on total revenue by type of room    
SELECT 
    rt.room_type_name,
    SUM(i.amount_paid) AS total_earnings
FROM 
    invoice i
JOIN 
    reservation r ON i.invoice_number = r.invoice_number
JOIN 
    room rm ON r.room_number = rm.room_number
JOIN 
    room_type rt ON rm.room_type_code = rt.room_type_code
GROUP BY 
    rt.room_type_name
ORDER BY 
    total_earnings DESC;    

-- 16) Report on room occupancy rate from 1st Sept to 1st Nov
SELECT 
    r.room_number, rm.room_type_code, rt.room_type_name,
    SUM(
        CASE
            WHEN (r.start_of_stay <= '2024-11-01' AND r.last_night >= '2024-09-01')
            THEN 
                DATEDIFF(
                    LEAST(r.last_night, '2024-11-01'), 
                    GREATEST(r.start_of_stay, '2024-09-01')
                ) + 1
            ELSE 0
        END
    ) AS occupied_days,
    DATEDIFF('2024-11-01', '2024-09-01') + 1 AS total_days
FROM 
    reservation_with_end_date_view r
JOIN 
    room rm ON r.room_number = rm.room_number
JOIN 
    room_type rt ON rm.room_type_code = rt.room_type_code    
WHERE 
    r.start_of_stay <= '2024-11-01' AND r.last_night >= '2024-09-01'
GROUP BY 
    r.room_number
ORDER BY 
    room_type_code;
    

-- 16b) now wrap it in another Select statement to calculate the average occupancy by room_type
SELECT 
    room_type_code,
    room_type_name,
    AVG(occupied_days) AS avg_occupied_days,
    AVG(ROUND(occupied_days / total_days * 100, 2)) AS avg_occupied_percentage
FROM (
	SELECT 
		r.room_number, rm.room_type_code, rt.room_type_name,
		SUM(
        CASE
            WHEN (r.start_of_stay <= '2024-11-01' AND r.last_night >= '2024-09-01')
            THEN 
                DATEDIFF(
                    LEAST(r.last_night, '2024-11-01'), 
                    GREATEST(r.start_of_stay, '2024-09-01')
                ) + 1
            ELSE 0
        END
    ) AS occupied_days,
    DATEDIFF('2024-11-01', '2024-09-01') + 1 AS total_days
	FROM 
		reservation_with_end_date_view r
	JOIN 
		room rm ON r.room_number = rm.room_number
	JOIN 
		room_type rt ON rm.room_type_code = rt.room_type_code    
	WHERE 
		r.start_of_stay <= '2024-11-01' AND r.last_night >= '2024-09-01'
	GROUP BY 
		r.room_number, rm.room_type_code, rt.room_type_name      
) AS room_occupancy
GROUP BY     
    room_type_code, room_type_name
ORDER BY 
    avg_occupied_percentage DESC;
    
    
    
-- 17) Which promotion codes have been effective
SELECT 
    promotion_code,
    COUNT(*) AS promotion_usage_count
FROM 
    reservation
GROUP BY 
    promotion_code
ORDER BY 
    promotion_usage_count DESC;
    
    
-- 18) Report on the number of reservations/check-ins/check-outs processed by each member of staff
SELECT 
    s.staff_id,
    s.first_name,
    s.last_name,
    COUNT(DISTINCT r.reservation_id) AS total_reservations,
    COUNT(DISTINCT ci.reservation_id) AS total_checkins,
    COUNT(DISTINCT co.reservation_id) AS total_checkouts
FROM 
    staff s
LEFT JOIN 
    reservation r ON r.reservation_staff_id = s.staff_id
LEFT JOIN 
    check_in ci ON ci.staff_id = s.staff_id
LEFT JOIN 
    check_out co ON co.staff_id = s.staff_id
WHERE 
    s.role LIKE '%RECEP%'
GROUP BY 
    s.staff_id
ORDER BY 
    s.staff_id;
    
-- 18b) Repeat the query but use HAVING to only return staff with more than 100 total_checkins
SELECT 
    s.staff_id,
    s.first_name,
    s.last_name,
    COUNT(DISTINCT r.reservation_id) AS total_reservations,
    COUNT(DISTINCT ci.reservation_id) AS total_checkins,
    COUNT(DISTINCT co.reservation_id) AS total_checkouts
FROM 
    staff s
LEFT JOIN 
    reservation r ON r.reservation_staff_id = s.staff_id
LEFT JOIN 
    check_in ci ON ci.staff_id = s.staff_id
LEFT JOIN 
    check_out co ON co.staff_id = s.staff_id
WHERE 
    s.role LIKE '%RECEP%'
GROUP BY 
    s.staff_id
HAVING 
	total_checkins > 100
ORDER BY 
    s.staff_id;
    
-- 19) using a CROSS JOIN to find all possible combinations of room_type and bathroom_type
SELECT 
    *
FROM 
    room_type rt
CROSS JOIN 
    bathroom_type bt;
    
-- 20) show a list of guests that wish to receive marketing information about 
-- discounts (code would need to be 'DIS' or 'ALL') by phone call
-- Uses a Natural Join to link the two tables (by using guest_id)
SELECT
	m.guest_id,
    g.title,
    g.first_name,
    g.last_name,
    g.phone_number,
    m.contact_by_phone
FROM
	marketing m
NATURAL JOIN guest g
WHERE
	marketing_code IN ('DIS', 'ALL')
    AND contact_by_phone = 1;
    
-- 21) display the room cleaning schedule for 15th Nov 2024
SELECT 
	*
FROM
	room_cleaning_view rc
WHERE
	rc.date_of_clean = '2024-11-15'
ORDER BY
	rc.staff_id DESC,
    time_of_clean ASC;
    
    
----------------------------

INSERT INTO address (postcode, address_line1, address_line2, city, county) VALUES
('CB22 3AA', 'High Street', 'Great Shelford', 'Cambridge', 'Cambridgeshire'),
('NR14 6AB', 'Church Lane', 'Bramerton', 'Norwich', 'Norfolk'),
('IP28 8AA', 'The Green', 'Mildenhall', 'Bury St Edmunds', 'Suffolk'),
('CO10 0CD', 'The Street', 'Cavendish', 'Sudbury', 'Suffolk'),
('PE36 5DE', 'Main Road', 'Snettisham', 'Kings Lynn', 'Norfolk'),
('CM1 4FG', 'Back Lane', 'Little Waltham', 'Chelmsford', 'Essex'),
('CB24 9GH', 'Mill Lane', 'Willingham', 'Cambridge', 'Cambridgeshire'),
('IP7 6IJ', 'Mill Street', 'Hadleigh', 'Ipswich', 'Suffolk'),
('NR20 5KL', 'The Street', 'Horsham St Faith', 'Norwich', 'Norfolk'),
('CO10 7MN', 'Church Road', 'Long Melford', 'Sudbury', 'Suffolk'),
('IP1 2AN', 'Civic Dr', '', 'Ipswich', 'Suffolk'),
('CO11 1US', 'Riverside Ave E', 'Lawford', 'Manningtree', 'Suffolk'),
('TS1 1AA', 'Test Street 1', 'Test Town A', 'Test City 1', 'Test County 1'),
('TS1 2AA', 'Test Street 2', 'Test Town A', 'Test City 1', 'Test County 1'),
('TS1 3AA', 'Test Street 3', 'Test Town A', 'Test City 1', 'Test County 1'),
('TS1 4AA', 'Test Street 4', 'Test Town A', 'Test City 1', 'Test County 1'),
('TS1 5AA', 'Test Street 5', 'Test Town A', 'Test City 1', 'Test County 1'),
('TS1 6AA', 'Test Street 6', 'Test Town A', 'Test City 1', 'Test County 1'),
('TS1 7AA', 'Test Street 7', 'Test Town A', 'Test City 1', 'Test County 1'),
('TS1 8AA', 'Test Street 8', 'Test Town A', 'Test City 1', 'Test County 1'),
('TS1 9AA', 'Test Street 9', 'Test Town A', 'Test City 1', 'Test County 1'),
('TS2 0AB', 'Test Street 10', 'Test Town B', 'Test City 2', 'Test County 2'),
('TS2 1AB', 'Test Street 11', 'Test Town B', 'Test City 2', 'Test County 2'),
('TS2 2AB', 'Test Street 12', 'Test Town B', 'Test City 2', 'Test County 2'),
('TS2 3AB', 'Test Street 13', 'Test Town B', 'Test City 2', 'Test County 2'),
('TS2 4AB', 'Test Street 14', 'Test Town B', 'Test City 2', 'Test County 2'),
('TS2 5AB', 'Test Street 15', 'Test Town B', 'Test City 2', 'Test County 2'),
('TS2 6AB', 'Test Street 16', 'Test Town B', 'Test City 2', 'Test County 2'),
('TS2 7AB', 'Test Street 17', 'Test Town B', 'Test City 2', 'Test County 2'),
('TS2 8AB', 'Test Street 18', 'Test Town B', 'Test City 2', 'Test County 2'),
('TS2 9AB', 'Test Street 19', 'Test Town B', 'Test City 2', 'Test County 2'),
('TS3 0AC', 'Test Street 20', 'Test Town C', 'Test City 3', 'Test County 3'),
('TS3 1AC', 'Test Street 21', 'Test Town C', 'Test City 3', 'Test County 3'),
('TS3 2AC', 'Test Street 22', 'Test Town C', 'Test City 3', 'Test County 3'),
('TS3 3AC', 'Test Street 23', 'Test Town C', 'Test City 3', 'Test County 3');

INSERT INTO company_account (company_id, company_name, building, postcode, admin_title, admin_first_name, admin_last_name, admin_phone_number, admin_email) VALUES
(1, 'AXA Insurance', 'Brooke Lawrance House', 'IP1 2AN', 'Miss', 'Jane', 'Peters', '01473726352', 'j.peters@axa.co.uk'),
(2, 'Rose Builders Ltd', '1', 'CO11 1US', 'Mr', 'David', 'White', '01206123654', 'd.white@rosebuilders.co.uk'),
(3, 'Test Company One Ltd', '1', 'TS3 1AC', 'Mr', 'Test', 'Admin1', '01473100001', 'admin@testco1.co.uk'),
(4, 'Test Company Two Ltd', '2', 'TS3 2AC', 'Miss', 'Test', 'Admin2', '01473100002', 't.admin2@testco2.co.uk'),
(5, 'Test Company Three Ltd', '3', 'TS3 3AC', 'Ms', 'Test', 'Admin3', '01473100003', 'test.admin3@testco3.co.uk');

INSERT INTO guest (guest_id, company_id, title, first_name, last_name, phone_number, email, house_name_number, postcode) VALUES
(1, NULL, 'Mr', 'Oliver', 'Smith', '07123456789', 'oliver.smith@hotmail.co.uk', '12', 'CB22 3AA'),
(2, NULL, 'Mrs', 'Sophia', 'Johnson', '07234567890', 'sophia.johnson@gmail.co.uk', '34', 'NR14 6AB'),
(3, 1, 'Ms', 'Amelia', 'Brown', '07345678901', 'amelia.brown@outlook.co.uk', 'Ivy Cottage', 'IP28 8AA'),
(4, 1, 'Mr', 'Liam', 'Williams', '07456789012', 'liam.williams@btinternet.com', '78', 'CO10 0CD'),
(5, NULL, 'Dr', 'Emma', 'Jones', '07567890123', 'emma.jones@sky.com', '90', 'PE36 5DE'),
(6, NULL, 'Miss', 'Isabella', 'Garcia', '07678901234', 'isabella.garcia@plusnet.co.uk', '23', 'CM1 4FG'),
(7, 2, 'Mr', 'James', 'Martinez', '07789012345', 'james.martinez@gmail.com', '45', 'CB24 9GH'),
(8, NULL, 'Mrs', 'Mia', 'Taylor', '07890123456', 'mia.taylor@btinternet.com', '67', 'IP7 6IJ'),
(9, NULL, 'Mr', 'Ethan', 'Harris', '07901234567', 'ethan.harris@hotmail.co.uk', '89', 'NR20 5KL'),
(10, NULL, 'Ms', 'Ava', 'Thompson', '07012345678', 'ava.thompson@gmail.com', '11', 'CO10 7MN'),
(11, 3, 'Mr', 'Test', 'Tester1', '07701100011', 'tester1@gmail.com', '101', 'TS1 1AA'),
(12, NULL, 'Mr', 'Test', 'Tester2', '07701100012', 'tester2@gmail.com', '102', 'TS1 2AA'),
(13, NULL, 'Ms', 'Test', 'Tester3', '07701100013', 'tester3@gmail.com', '103', 'TS1 3AA'),
(14, 3, 'Mrs', 'Test', 'Tester4', '07701100014', 'tester4@gmail.com', '104', 'TS1 4AA'),
(15, 3, 'Mr', 'Test', 'Tester5', '07701100015', 'tester5@gmail.com', '105', 'TS1 5AA'),
(16, NULL, 'Miss', 'Test', 'Tester6', '07701100016', 'tester6@gmail.com', '106', 'TS1 6AA'),
(17, NULL, 'Mr', 'Test', 'Tester7', '07701100017', 'tester7@gmail.com', '107', 'TS1 7AA'),
(18, NULL, 'Mr', 'Test', 'Tester8', '07701100018', 'tester8@gmail.com', '108', 'TS1 8AA'),
(19, NULL, 'Mrs', 'Test', 'Tester9', '07701100019', 'tester9@gmail.com', '109', 'TS1 9AA'),
(20, 4, 'Mr', 'Test', 'Tester10', '07701100020', 'tester10@gmail.com', '110', 'TS2 0AB'),
(21, 4, 'Mr', 'Test', 'Tester11', '07701100021', 'tester11@gmail.com', '111', 'TS2 1AB'),
(22, NULL, 'Dr', 'Test', 'Tester12', '07701100022', 'tester12@gmail.com', '112', 'TS2 2AB'),
(23, NULL, 'Mr', 'Test', 'Tester13', '07701100023', 'tester13@gmail.com', '113', 'TS2 3AB'),
(24, NULL, 'Miss', 'Test', 'Tester14', '07701100024', 'tester14@gmail.com', '114', 'TS2 4AB'),
(25, 5, 'Mr', 'Test', 'Tester15', '07701100025', 'tester15@gmail.com', '115', 'TS2 5AB'),
(26, 5, 'Ms', 'Test', 'Tester16', '07701100026', 'tester16@gmail.com', '116', 'TS2 6AB'),
(27, 5, 'Mr', 'Test', 'Tester17', '07701100027', 'tester17@gmail.com', '117', 'TS2 7AB'),
(28, NULL, 'Mr', 'Test', 'Tester18', '07701100028', 'tester18@gmail.com', '118', 'TS2 8AB'),
(29, NULL, 'Mrs', 'Test', 'Tester19', '07701100029', 'tester19@gmail.com', '119', 'TS2 9AB'),
(30, NULL, 'Miss', 'Test', 'Tester20', '07701100030', 'tester20@gmail.com', '120', 'TS3 0AC');

INSERT INTO marketing (guest_id, marketing_code, contact_by_phone, contact_by_email, contact_by_post) VALUES
(1, 'DIS', 0, 1, 1),
(3, 'EVT', 1, 0, 0),
(5, 'ALL', 0, 1, 0),
(8, 'DIS', 0, 1, 0),
(10, 'ALL', 1, 1, 1),
(12, 'DIS', 0, 1, 0),
(13, 'ALL', 1, 1, 0),
(16, 'EVT', 0, 1, 1),
(18, 'DIS', 1, 0, 1),
(19, 'ALL', 1, 1, 0),
(20, 'ALL', 0, 1, 1),
(21, 'DIS', 0, 0, 1),
(23, 'EVT', 1, 1, 0),
(24, 'ALL', 0, 0, 1),
(25, 'DIS', 0, 1, 0),
(27, 'ALL', 1, 1, 0),
(28, 'EVT', 0, 1, 0),
(30, 'ALL', 0, 1, 1);

INSERT INTO payment_method (payment_code, payment_method) VALUES
('CC01', 'Visa Credit'),
('CC02', 'Mastercard Credit'),
('DB01', 'Visa Debit'),
('DB02', 'Mastercard Debit'),
('BA01', 'Bank Transfer'),
('CA01', 'Cash');

INSERT INTO invoice (invoice_number, invoice_date, amount_due, amount_paid, payment_code, payment_date, payment_reference) VALUES
(1, '2024-10-21', 94.50, 94.50, 'CC01', '2024-10-23', 'a72dkji8fvs67nk4j512cs3rw'),
(2, '2024-10-24', 75.00, 75.00, 'CC02', '2024-10-31', 's59p15grdxghz0cg8h92lcqz0'),
(3, '2024-10-25', 97.75, 97.75, 'BA01', '2024-10-29', 'kl9823jkbn284sf39dyu130ge'),
(4, '2024-08-13', 110, 110, 'CC01', '2024-08-18', 'apr8lk68uz1txeib9p2ou1wqa'),
(5, '2024-08-14', 75, 75, 'DB02', '2024-08-16', '9q5n14y8sw6wp3umjgz10tyr2'),
(6, '2024-08-15', 162.0, 162.0, 'DB02', '2024-08-18', '7bgkk1inu4psqn1cxqcsdaxj3'),
(7, '2024-08-15', 150, 150, 'BA01', '2024-08-16', NULL),
(8, '2024-08-16', 75, 0.00, NULL, NULL, NULL),
(9, '2024-08-16', 150, 150, 'CC01', '2024-08-18', '3cvw880ihp40ld9wmmmxkov7o'),
(10, '2024-08-17', 99.0, 99.0, 'CC02', '2024-08-19', '2fezz4kxg67zbl5stf8oqyibr'),
(11, '2024-08-17', 95, 95, 'CC01', '2024-08-21', '0ag3kpqyk6isls60czi6b8a55'),
(12, '2024-08-19', 96.0, 96.0, 'DB02', '2024-08-20', 'eov4gix7pd71r81isf8e4jk7e'),
(13, '2024-08-19', 65, 65, 'DB02', '2024-08-21', 'a9h1lfq2cqyiw08phhasasc19'),
(14, '2024-08-19', 150, 150, 'CC02', '2024-08-21', 'eqtrllep6ip4vk1iefisbf6yr'),
(15, '2024-08-20', 108.0, 108.0, 'CC01', '2024-08-23', '26wj5z7xk8wvgl9sycnqxircl'),
(16, '2024-08-20', 162.0, 162.0, 'CC02', '2024-08-22', 'py8orv09f5repjcwd3q8t6pir'),
(17, '2024-08-20', 75, 75, 'CC02', '2024-08-22', 'iizmolfg51h77to1e780g773s'),
(18, '2024-08-20', 115, 115, 'CC02', '2024-08-21', 'amat1djxed1dkuyqrhc2btho9'),
(19, '2024-08-21', 93.50, 93.50, 'CC01', '2024-08-24', '35vpbkktbhjx2um0rt0b48tst'),
(20, '2024-08-21', 110, 110, 'CC02', '2024-08-26', 'clwutdiikzltdo3ywj29267f2'),
(21, '2024-08-22', 90.0, 0.00, NULL, NULL, NULL),
(22, '2024-08-22', 90, 90, 'CC01', '2024-08-25', 'www0np4z56cic877xn84lx303'),
(23, '2024-08-23', 180, 0.00, NULL, NULL, NULL),
(24, '2024-08-23', 140, 140, 'CC01', '2024-08-24', 'szz20v67hotmjovzs8upkotn4'),
(25, '2024-08-23', 110, 110, 'CA01', '2024-08-28', NULL),
(26, '2024-08-23', 115, 115, 'CC02', '2024-08-24', '8ie18c1vfuvtxlwje8zc99o2d'),
(27, '2024-08-24', 110, 110, 'DB02', '2024-08-30', 'cioxgox959ey8zp5n0ppy92ml'),
(28, '2024-08-25', 105, 105, 'CC01', '2024-08-30', 'nq66skh4gx931tkpzv1u7a4bc'),
(29, '2024-08-25', 120, 120, 'DB02', '2024-08-26', '7rv4m1okiovqd5eq5h7eimstg'),
(30, '2024-08-25', 150, 150, 'DB01', '2024-08-28', 'u801u6h6nkh3b07pcruqhd1uy'),
(31, '2024-08-25', 80.75, 80.75, 'CC02', '2024-08-28', '2n122ptt76gpl9a07cudnsmrg'),
(32, '2024-08-25', 115, 115, 'CC02', '2024-08-27', '789obstr7h9uuhq4jx4twnhqv'),
(33, '2024-08-25', 55.25, 55.25, 'DB02', '2024-08-29', 'a96ax8fxw8btk6liy90te2h6k'),
(34, '2024-08-26', 120, 120, 'CC01', '2024-08-31', 'nc1cn6nilpcw66snvi84nlw8q'),
(35, '2024-08-26', 90, 90, 'CC01', '2024-09-01', 'cfe0exom8wpkxe4p3yx37hk1l'),
(36, '2024-08-26', 140, 140, 'DB01', '2024-08-27', 'auaxrdrc7m096j27l0thepe2u'),
(37, '2024-08-26', 180, 180, 'CC02', '2024-08-30', 'td20ic27vg5i1ygb2bf30xhjn'),
(38, '2024-08-26', 103.5, 103.5, 'CA01', '2024-09-01', NULL),
(39, '2024-08-27', 102.00, 102.00, 'CA01', '2024-08-30', NULL),
(40, '2024-08-27', 103.5, 103.5, 'BA01', '2024-08-30', NULL),
(41, '2024-08-27', 96.0, 96.0, 'CA01', '2024-08-31', NULL),
(42, '2024-08-28', 99.0, 99.0, 'CC01', '2024-08-29', 'hhgqp9n12p7fm9cv57ovygui2'),
(43, '2024-08-28', 115, 115, 'CC01', '2024-08-29', 'k87lcz53zw91y4buk8y0y8npa'),
(44, '2024-08-29', 100, 100, 'DB01', '2024-08-31', 'uq8y9t3izt3qpqe833cq3vepl'),
(45, '2024-08-29', 110, 110, 'CA01', '2024-09-04', NULL),
(46, '2024-08-30', 110, 110, 'CC02', '2024-08-31', 'cl1b1agn23z1ywwusz7jx1028'),
(47, '2024-08-30', 80, 80, 'DB01', '2024-09-02', '5r7em9wiqdyd6yycoi44mouyk'),
(48, '2024-08-31', 180, 180, 'CC02', '2024-09-03', 'dfrbviqzevp645sa7cjgqrool'),
(49, '2024-08-31', 150, 150, 'CC02', '2024-09-03', 'zqzkf7ve8d7v5gtovmg14467w'),
(50, '2024-08-31', 100, 100, 'CC01', '2024-09-02', 'ri57g0yviyt4qkas3dufn11iq'),
(51, '2024-09-01', 94.5, 94.5, 'DB01', '2024-09-04', 'pcja8dp6t3o0i48rdd79657n7'),
(52, '2024-09-01', 108.0, 108.0, 'CA01', '2024-09-02', NULL),
(53, '2024-09-01', 115, 115, 'CC01', '2024-09-02', '1smzxwg2udnkow0hux0qwqiq5'),
(54, '2024-09-01', 115, 115, 'DB01', '2024-09-05', '4q92yvjti1slzm7fa5kro1pxu'),
(55, '2024-09-02', 108.0, 108.0, 'DB02', '2024-09-07', 'p2jfpsk81he5v0mpcobbgrlku'),
(56, '2024-09-02', 108.0, 108.0, 'BA01', '2024-09-05', NULL),
(57, '2024-09-02', 140, 140, 'CC02', '2024-09-05', 'bk53uzhntib93hv4igcbliszg'),
(58, '2024-09-02', 120, 120, 'DB01', '2024-09-08', 'ij1me8ggqk8n40cjs7r9umuxv'),
(59, '2024-09-02', 85.5, 85.5, 'DB01', '2024-09-03', 'igl0qfvncl7kds5si14jslhp5'),
(60, '2024-09-02', 103.5, 103.5, 'CC02', '2024-09-06', '1x68vox4cika74dgwn6ucsi73'),
(61, '2024-09-03', 80, 80, 'CC02', '2024-09-06', 'va1jl6j9pul93bhv5cm0p47nj'),
(62, '2024-09-03', 92.0, 0.00, NULL, NULL, NULL),
(63, '2024-09-03', 99.0, 99.0, 'CC01', '2024-09-06', '303y9fv1knnra1so5vfkuxv80'),
(64, '2024-09-03', 100, 100, 'CC01', '2024-09-06', 'gusi9nipklcmcn7w0aety8pff'),
(65, '2024-09-04', 105, 105, 'CA01', '2024-09-06', NULL),
(66, '2024-09-04', 95, 95, 'CC02', '2024-09-06', 'jpsnzajvj6nf2j51vqiemdepl'),
(67, '2024-09-04', 75, 75, 'BA01', '2024-09-07', NULL),
(68, '2024-09-04', 75, 75, 'CA01', '2024-09-10', NULL),
(69, '2024-09-04', 93.50, 93.50, 'DB02', '2024-09-09', 'y8394atvc065zd0ar7u7dfyju'),
(70, '2024-09-05', 90, 0.00, NULL, NULL, NULL),
(71, '2024-09-05', 140, 140, 'DB01', '2024-09-06', 'wf88gu69u08mawy2bl6flccal'),
(72, '2024-09-05', 120, 120, 'CA01', '2024-09-08', NULL),
(73, '2024-09-06', 80, 80, 'CA01', '2024-09-09', NULL),
(74, '2024-09-06', 180, 180, 'CC02', '2024-09-09', 'rov9v08ykbgdm5g2ztsktptb5'),
(75, '2024-09-06', 150, 150, 'DB01', '2024-09-13', 'nzkrp7kauwo8fqg0w5wxx825c'),
(76, '2024-09-06', 110, 110, 'CC01', '2024-09-09', 'dz9t97ro0vjj3uiizpanqm1c5'),
(77, '2024-09-06', 95, 0.00, NULL, NULL, NULL),
(78, '2024-09-07', 105, 105, 'CC02', '2024-09-12', 'c0rglfgdoos6hkd5mv4osde2o'),
(79, '2024-09-07', 81.0, 81.0, 'DB02', '2024-09-09', '6w21cdu7fkik2zgjeox076xp3'),
(80, '2024-09-07', 119.00, 119.00, 'BA01', '2024-09-09', NULL),
(81, '2024-09-07', 110, 110, 'CA01', '2024-09-08', NULL),
(82, '2024-09-07', 90.0, 90.0, 'CC01', '2024-09-10', '60a5oiza9n7fr7lalrzhnew5c'),
(83, '2024-09-07', 120, 0.00, NULL, NULL, NULL),
(84, '2024-09-08', 85, 85, 'CC01', '2024-09-10', 'dmm4ldjlf54s6k5duz2de2ekw'),
(85, '2024-09-08', 103.5, 103.5, 'CC01', '2024-09-13', 'eildajl1y17o9l3c2bcmrxt8o'),
(86, '2024-09-08', 120, 0.00, NULL, NULL, NULL),
(87, '2024-09-09', 95, 95, 'CC02', '2024-09-13', 'kapj04nfqkd860t2uj462xgyq'),
(88, '2024-09-09', 75, 75, 'DB01', '2024-09-14', 'gbey5l9b41uzpb8m4etziq8ew'),
(89, '2024-09-09', 180, 180, 'CC01', '2024-09-10', 'o6hfnnbant7oeuc2h6t4739kh'),
(90, '2024-09-09', 60, 60, 'CC01', '2024-09-14', 'cr1uaafc00ti5o4mheo6zp7l0'),
(91, '2024-09-09', 110, 110, 'CC01', '2024-09-10', '8xeaczzhy1zv5zfb9dcbsdjv7'),
(92, '2024-09-10', 153.00, 153.00, 'BA01', '2024-09-13', NULL),
(93, '2024-09-10', 115, 115, 'DB01', '2024-09-12', '4g7dsssop7q0t3hvc79vz2iii'),
(94, '2024-09-10', 110, 110, 'DB02', '2024-09-15', 'y9rr0s7zizrf6lhme2b48d4gf'),
(95, '2024-09-10', 108.0, 108.0, 'CA01', '2024-09-11', NULL),
(96, '2024-09-11', 65, 65, 'CC01', '2024-09-14', 'dysiyq7myb39yicz2dc9q4nwt'),
(97, '2024-09-11', 90, 0.00, NULL, NULL, NULL),
(98, '2024-09-11', 140, 140, 'DB01', '2024-09-13', 'bdio6vcnzxi4e3gxmxx402ary'),
(99, '2024-09-11', 120, 120, 'CA01', '2024-09-15', NULL),
(100, '2024-09-11', 100, 100, 'CC01', '2024-09-14', '6vy0gbixw8wsbkkl850jk5yiw'),
(101, '2024-09-11', 80, 80, 'CC02', '2024-09-14', 'd53gpm3ow0au3m5z3m18x46a7'),
(102, '2024-09-11', 120, 120, 'CC01', '2024-09-13', 'gjsgwr6cek1ce48bzvcx9t2ic'),
(103, '2024-09-12', 105, 105, 'DB01', '2024-09-19', '3u1e8hb2qryauoq7y7mgorxwm'),
(104, '2024-09-12', 80, 80, 'CC02', '2024-09-19', '6jqbantdniw92kxhajiyznsel'),
(105, '2024-09-12', 110, 110, 'CC02', '2024-09-14', 's4kogrd5vclxu5eojfw2cmgyj'),
(106, '2024-09-12', 75, 75, 'CC01', '2024-09-15', 'nn5lqocuhjmbvxq8nzvekmb62'),
(107, '2024-09-13', 85, 0.00, NULL, NULL, NULL),
(108, '2024-09-13', 103.5, 103.5, 'CC02', '2024-09-18', 'v90afod9py7ixnkolyrn4pet1'),
(109, '2024-09-14', 153.00, 0.00, NULL, NULL, NULL),
(110, '2024-09-14', 150, 150, 'DB01', '2024-09-15', 'ysk0pgtsz2v8okdwbo7axbu1b'),
(111, '2024-09-14', 115, 115, 'CC02', '2024-09-17', 'r0pco4epq2l53vat7pum2dpa1'),
(112, '2024-09-14', 110, 110, 'CC01', '2024-09-16', '9p0xsk6b13h5myoxwy4rqy15x'),
(113, '2024-09-14', 100, 100, 'BA01', '2024-09-16', NULL),
(114, '2024-09-14', 120, 120, 'DB02', '2024-09-16', 'wulenfgqfhcwym4en1lx4au2h'),
(115, '2024-09-15', 75, 0.00, NULL, NULL, NULL),
(116, '2024-09-15', 85.5, 85.5, 'CA01', '2024-09-18', NULL),
(117, '2024-09-15', 115, 115, 'CC02', '2024-09-18', '0t7yvv9451gs724imog5hi1n6'),
(118, '2024-09-16', 81.0, 81.0, 'CC01', '2024-09-18', '54eufuzi3ez5w5yjaawkelvcs'),
(119, '2024-09-16', 140, 0.00, NULL, NULL, NULL),
(120, '2024-09-16', 72.0, 72.0, 'CA01', '2024-09-17', NULL),
(121, '2024-09-16', 108.0, 108.0, 'DB02', '2024-09-18', '2izxxfm0sneshsu1ql9tjbcm9'),
(122, '2024-09-16', 120, 0.00, NULL, NULL, NULL),
(123, '2024-09-16', 110, 110, 'CC02', '2024-09-19', 'fsg10emquf4981s4mztvqojut'),
(124, '2024-09-17', 153.00, 153.00, 'DB01', '2024-09-18', '9tar2l8w994ueycujppk8x2o0'),
(125, '2024-09-17', 120, 120, 'CC02', '2024-09-22', 'f8esd137jgbiar6b24yj3ywqa'),
(126, '2024-09-17', 110, 110, 'DB02', '2024-09-20', '716rrws6dx3yt5nun2c1cw940'),
(127, '2024-09-18', 150, 150, 'BA01', '2024-09-24', NULL),
(128, '2024-09-18', 115, 115, 'DB01', '2024-09-23', 'ooaddw7g9e9rbkjszg2cek0yu'),
(129, '2024-09-19', 140, 140, 'DB01', '2024-09-20', 'lln7ibjbi42q8w00zgg87cryk'),
(130, '2024-09-19', 115, 115, 'CC01', '2024-09-23', 'liwfadwze37j9r5gjh39l15rd'),
(131, '2024-09-20', 162.0, 162.0, 'CA01', '2024-09-23', NULL),
(132, '2024-09-20', 64.0, 64.0, 'CC01', '2024-09-24', 'z3s0891hxfserb18igaa70jup'),
(133, '2024-09-21', 75, 75, 'CC01', '2024-09-26', 'yiqhv7d1layfvitzclbt2b8qx'),
(134, '2024-09-21', 120, 120, 'CC02', '2024-09-24', 'sjk7osodawvaw76tze7rgkyi8'),
(135, '2024-09-21', 99.0, 99.0, 'CC02', '2024-09-23', 'ejocryiga1hyzv6vn3tnebm1d'),
(136, '2024-09-21', 100, 100, 'CC01', '2024-09-22', '7enu0bx5gitoe0300djeqmitr'),
(137, '2024-09-22', 54.0, 54.0, 'CC01', '2024-09-25', 'dqpqe47amv1rxdkk6j7l1v309'),
(138, '2024-09-22', 120, 120, 'CC02', '2024-09-26', 'dts43yrdx8g8fa1wd87wepznx'),
(139, '2024-09-22', 119.00, 119.00, 'CC01', '2024-09-23', '2x0e7o64cwkd6e5rh7gjge5ld'),
(140, '2024-09-22', 85.5, 85.5, 'CC02', '2024-09-23', 'ao1ob9q8gr8q038pwhaecan3y'),
(141, '2024-09-23', 140, 140, 'BA01', '2024-09-27', NULL),
(142, '2024-09-23', 90, 90, 'CC01', '2024-09-25', 't609t95v2zsbeyyvc8jgy6ims'),
(143, '2024-09-23', 99.0, 99.0, 'DB01', '2024-09-27', 'qftzh6b5be1urty7id5ll617h'),
(144, '2024-09-23', 115, 115, 'CC01', '2024-09-24', 'f6295gdnq3d9olzwwto0pfjgi'),
(145, '2024-09-24', 97.75, 97.75, 'DB01', '2024-09-26', '4avuvdo0buiouwd2p5akt9yky'),
(146, '2024-09-24', 108.0, 108.0, 'CC01', '2024-09-27', 'kej9zqvlcxowznwbfii5iqxht'),
(147, '2024-09-24', 95, 95, 'CC02', '2024-09-28', 'jxqwgz9mu85eouq055ioppo90'),
(148, '2024-09-24', 92.0, 92.0, 'CC02', '2024-09-27', '216rphu8qx23x7jbuugho4o94'),
(149, '2024-09-25', 180, 180, 'DB01', '2024-09-30', 'mbofj591rvjmy28aw9uyni4pi'),
(150, '2024-09-25', 150, 150, 'CC02', '2024-09-30', '8acm68uz21fhlk626wqrvc3ed'),
(151, '2024-09-25', 110, 110, 'DB02', '2024-09-28', '7nodzgr5qt472k2owaqn1iq34'),
(152, '2024-09-26', 85.00, 85.00, 'CC01', '2024-09-27', 'ksjv426h3uk2iqw9kknb73m98'),
(153, '2024-09-26', 110, 110, 'CC01', '2024-09-27', 'xvtrkoloixmnwecfshs1f73gr'),
(154, '2024-09-27', 105, 0.00, NULL, NULL, NULL),
(155, '2024-09-27', 120, 120, 'BA01', '2024-09-29', NULL),
(156, '2024-09-27', 99.0, 99.0, 'CC01', '2024-10-02', 'emrl7abxsgimjpclepa722729'),
(157, '2024-09-27', 90.0, 90.0, 'CC02', '2024-09-30', 'vpcccj16hatfmr8gdgz5g8i09'),
(158, '2024-09-28', 110, 110, 'CC02', '2024-09-30', 'bathqunomk66dw3usb9ewupfx'),
(159, '2024-09-28', 90, 90, 'CC02', '2024-10-01', '92kvxqey2htmo4h35vbi6mlky'),
(160, '2024-09-28', 115, 0.00, NULL, NULL, NULL),
(161, '2024-09-28', 110, 110, 'CC01', '2024-09-30', 'ljwse2krwz2nvkbfdgchzw31q'),
(162, '2024-09-28', 115, 115, 'CC01', '2024-09-29', 'r0uoa15urvz7nz9y16y6uiqyv'),
(163, '2024-09-28', 115, 115, 'DB02', '2024-10-01', 'ioo2ulyny8rkagjp7i1s8i9pw'),
(164, '2024-09-29', 95, 95, 'CC02', '2024-10-03', 'dvchsvbdz9x8qk9pv9r3s3nac'),
(165, '2024-09-29', 72.0, 72.0, 'CC02', '2024-10-03', 'mwovvc33xi3chv0ec32cx90kh'),
(166, '2024-09-29', 140, 140, 'DB02', '2024-10-02', 'gd5m7s4lo5vjl05z9tf5rhxkm'),
(167, '2024-09-29', 120, 120, 'CC01', '2024-10-04', 'k98l440ykcncbk6kuu1i5l8k3'),
(168, '2024-09-29', 120, 0.00, NULL, NULL, NULL),
(169, '2024-09-30', 162.0, 162.0, 'CC02', '2024-10-03', 'civ46n3sgxfk9l2rn1w2t40n5'),
(170, '2024-09-30', 120.0, 120.0, 'CC02', '2024-10-03', '1pa996iyaj693qk6ixc81y4hs'),
(171, '2024-09-30', 108.0, 108.0, 'DB02', '2024-10-06', 'e1f92u427oq9ad594ff28hfrd'),
(172, '2024-09-30', 110, 110, 'DB01', '2024-10-03', '2t5sul3rrs72k71to3rlklftd'),
(173, '2024-09-30', 100, 100, 'DB01', '2024-10-03', 'z0ydp870vofvq45uk0zu9s7kr'),
(174, '2024-09-30', 60, 60, 'CC02', '2024-10-03', '1tbhbv3luqc66ezzzhbr0bnrg'),
(175, '2024-10-01', 115, 115, 'DB01', '2024-10-03', '1bcobow48qped6wbf1zxh7bw0'),
(176, '2024-10-01', 115, 0.00, NULL, NULL, NULL),
(177, '2024-10-02', 110, 110, 'CC01', '2024-10-06', 'ctihb19x5etawhs2lh3xlws37'),
(178, '2024-10-02', 120, 120, 'DB01', '2024-10-06', 'raloq263h4sjypgtjvfreqj1p'),
(179, '2024-10-03', 105, 0.00, NULL, NULL, NULL),
(180, '2024-10-03', 140, 140, 'DB01', '2024-10-04', '1jffev1godou449m369pq8l8a'),
(181, '2024-10-03', 115, 0.00, NULL, NULL, NULL),
(182, '2024-10-04', 180, 0.00, NULL, NULL, NULL),
(183, '2024-10-04', 126.0, 126.0, 'CC02', '2024-10-07', 'v23n3o1dolylma0t9pnwoe1zg'),
(184, '2024-10-04', 81.0, 81.0, 'DB02', '2024-10-09', 'w72g9u4ejdpr3cdxmtnvlkw3z'),
(185, '2024-10-04', 110, 110, 'CC01', '2024-10-07', 'c05q7bgbsly2e1jaj13ww29qb'),
(186, '2024-10-05', 100, 100, 'BA01', '2024-10-07', NULL),
(187, '2024-10-05', 127.50, 127.50, 'DB02', '2024-10-08', 'thu3nmlcqmicqevr2efn3t8sm'),
(188, '2024-10-05', 95, 95, 'CC02', '2024-10-07', 'v7imdcq9vp2m5rw6sj0oo44pa'),
(189, '2024-10-06', 63.75, 63.75, 'DB01', '2024-10-07', 'x5af6nky7acs28xzok5a94141'),
(190, '2024-10-06', 115, 115, 'BA01', '2024-10-07', NULL),
(191, '2024-10-06', 115, 0.00, NULL, NULL, NULL),
(192, '2024-10-06', 72.0, 72.0, 'DB01', '2024-10-11', 'j59ol6atqhubulyph1yelcpje'),
(193, '2024-10-06', 120, 120, 'CC01', '2024-10-08', '3cul2pbnspam98sh4opmn0869'),
(194, '2024-10-07', 119.00, 119.00, 'CA01', '2024-10-08', NULL),
(195, '2024-10-07', 85.5, 0.00, NULL, NULL, NULL),
(196, '2024-10-07', 80.0, 80.0, 'CC01', '2024-10-10', 'd2jrw7802gmm6jqjzfoml9qgb'),
(197, '2024-10-08', 115, 115, 'DB02', '2024-10-12', 'q1yxpaapb3sf2rfj354i6tu7o'),
(198, '2024-10-09', 120, 120, 'DB01', '2024-10-12', '2qjrr06vq79j3znyib57si36h'),
(199, '2024-10-09', 105, 105, 'CC02', '2024-10-11', '307a3gabp870421yfnp9hooih'),
(200, '2024-10-09', 110, 110, 'CC02', '2024-10-11', 'jk31lxl5jhzjfomvrnbcm5ffo'),
(201, '2024-10-10', 108.0, 108.0, 'CC02', '2024-10-12', 'dkanlhy1c8i19ulez1ae8cv9u'),
(202, '2024-10-10', 97.75, 97.75, 'CA01', '2024-10-13', NULL),
(203, '2024-10-11', 76.5, 76.5, 'DB01', '2024-10-12', 'j2s682lbquk29kq4m5wutltqa'),
(204, '2024-10-11', 180, 180, 'DB01', '2024-10-14', '3vnwc9bnqdcbc5sfy8f81gkbx'),
(205, '2024-10-11', 150, 150, 'CC02', '2024-10-12', 'awn89qynlnztuykwye3boe6c7'),
(206, '2024-10-11', 140, 140, 'DB01', '2024-10-14', 'ckzmx6rdo3gmalojpi1gpvo0x'),
(207, '2024-10-11', 108.0, 108.0, 'DB01', '2024-10-16', 'ho3xpn14rwof1cbi7yk1xlat2'),
(208, '2024-10-11', 110, 110, 'CC01', '2024-10-14', '48u91ms4jg50fv4j0jpxy1ldr'),
(209, '2024-10-11', 110, 110, 'DB01', '2024-10-12', 'ovfjgwlqnyrlh31920dmy43a5'),
(210, '2024-10-11', 100, 0.00, NULL, NULL, NULL),
(211, '2024-10-11', 60, 60, 'CC02', '2024-10-13', 'danxqn63yifijego4t2enqlk0'),
(212, '2024-10-12', 120, 120, 'DB01', '2024-10-14', 'zszlnqlx66nsau4jf3buz7ipd'),
(213, '2024-10-13', 90, 90, 'BA01', '2024-10-16', NULL),
(214, '2024-10-13', 150, 150, 'CA01', '2024-10-14', NULL),
(215, '2024-10-13', 115, 115, 'CC02', '2024-10-14', 'jq2pwt1ljktww35kb31jkh093'),
(216, '2024-10-13', 110, 110, 'CC02', '2024-10-15', 'ov45niecord4m75ju7hx3o9ec'),
(217, '2024-10-13', 60.0, 60.0, 'CC01', '2024-10-16', 'm0soq9n2enx56nj5f8wopsuto'),
(218, '2024-10-14', 99.0, 99.0, 'CA01', '2024-10-17', NULL),
(219, '2024-10-14', 94.5, 94.5, 'CC01', '2024-10-21', 'acrwkkofz6nxxicrns10zib7d'),
(220, '2024-10-14', 140, 140, 'DB02', '2024-10-15', 'qp8fb17sb61n1gnoc7s9fxgsa'),
(221, '2024-10-15', 162.0, 162.0, 'DB01', '2024-10-20', '06vjwofq6ky5350t63hxy34ki'),
(222, '2024-10-15', 150, 150, 'CC01', '2024-10-19', 'jlewr4kxdnio14joecolce9r7'),
(223, '2024-10-15', 140, 140, 'CC02', '2024-10-16', 'quky2j49gbk8r8rwuyx2cyyw3'),
(224, '2024-10-15', 110, 110, 'CC01', '2024-10-16', 'nodhlwzqvl8pnfucv66sv08h2'),
(225, '2024-10-15', 115, 115, 'CC01', '2024-10-19', 'p5g1x0w9eta7ujrz3y6bk7wbe'),
(226, '2024-10-15', 72.0, 72.0, 'DB02', '2024-10-17', 'ga4hbrdilrjdndaoswq6op854'),
(227, '2024-10-16', 120, 120, 'CC02', '2024-10-18', '9z3z5xnzrdttgut70c5ojeqm0'),
(228, '2024-10-16', 140, 140, 'CC01', '2024-10-18', '5ijnune1f793562lkn13kb95j'),
(229, '2024-10-16', 120, 120, 'CC02', '2024-10-19', 'x9n3svcvxrck1chpiqxofeczr'),
(230, '2024-10-16', 115, 115, 'CA01', '2024-10-20', NULL),
(231, '2024-10-16', 115, 115, 'BA01', '2024-10-19', NULL),
(232, '2024-10-17', 65, 65, 'CA01', '2024-10-23', NULL),
(233, '2024-10-17', 90, 0.00, NULL, NULL, NULL),
(234, '2024-10-17', 76.5, 76.5, 'CC01', '2024-10-22', 'xfw31bjunj1znhn4wl6s3ugn5'),
(235, '2024-10-17', 99.0, 99.0, 'BA01', '2024-10-18', NULL),
(236, '2024-10-17', 90.0, 90.0, 'CC01', '2024-10-19', 'p8e1dithw5966oipiks6xlkqo'),
(237, '2024-10-17', 72.0, 72.0, 'DB02', '2024-10-19', 'yjh2stxb5sr4nf0ozzqj24bue'),
(238, '2024-10-18', 75, 75, 'CC01', '2024-10-22', 'olbxv0uha0p76cl1azp5f7ald'),
(239, '2024-10-18', 140, 140, 'DB01', '2024-10-20', 'hwoy1ny85elkkqpb66ckaq5zp'),
(240, '2024-10-18', 110, 110, 'BA01', '2024-10-21', NULL),
(241, '2024-10-18', 88.0, 88.0, 'BA01', '2024-10-19', NULL),
(242, '2024-10-18', 120, 120, 'BA01', '2024-10-20', NULL),
(243, '2024-10-19', 80, 80, 'DB02', '2024-10-22', 'uzhmnlu2ebe52nwkkt4u3u16r'),
(244, '2024-10-19', 100, 100, 'DB01', '2024-10-22', 'aua5hyz8pp7l3bbi7qz8om67a'),
(245, '2024-10-19', 115, 115, 'CC01', '2024-10-24', 'r61wrmyua2t4g1rhszqyhoo6w'),
(246, '2024-10-20', 95, 95, 'CC02', '2024-10-23', '7zqqadn371c1boo727jfhoxzw'),
(247, '2024-10-20', 90, 90, 'DB01', '2024-10-21', 'xzgrt03c7rq4zr444t1autsdh'),
(248, '2024-10-20', 68.00, 68.00, 'DB02', '2024-10-23', 'evs70xmc2eo16adh9p9brssgs'),
(249, '2024-10-20', 126.0, 126.0, 'DB01', '2024-10-25', 'y1bv46foicz43appl21k1ahl6'),
(250, '2024-10-20', 120, 120, 'CC02', '2024-10-21', 'h6z2vjfsi5fk0mo8caakf4aeh'),
(251, '2024-10-20', 115, 115, 'CC01', '2024-10-22', 'gxpdl2rpvvuof5i75qd2d6rhy'),
(252, '2024-10-20', 108.0, 108.0, 'CC01', '2024-10-23', 'ma8gsrykq4qb3x0zs9hkytivd'),
(253, '2024-10-20', 99.0, 99.0, 'CC02', '2024-10-23', '5rho6b7zs0zvwbqn5lak4zms2'),
(254, '2024-10-21', 180, 180, 'CA01', '2024-10-24', NULL),
(255, '2024-10-21', 93.50, 0.00, NULL, NULL, NULL),
(256, '2024-10-21', 110, 110, 'DB01', '2024-10-23', 'i4xvjzt88vuw8tl6iogfzwdz3'),
(257, '2024-10-21', 75, 75, 'CC02', '2024-10-26', 'gm9b10qqxvjpsl5rs2v6ubl53'),
(258, '2024-10-22', 120, 120, 'CC01', '2024-10-24', '74tt3gmg177ml7a593cr5a0o6'),
(259, '2024-10-23', 80, 80, 'CC02', '2024-10-25', 'gmjujmg84p4pgf7oqppfek3yu'),
(260, '2024-10-23', 90, 90, 'CA01', '2024-10-26', NULL),
(261, '2024-10-23', 99.0, 0.00, NULL, NULL, NULL),
(262, '2024-10-24', 95, 95, 'CC02', '2024-10-27', 'zy7g81wk2w9q5r9gosgk6rvhg'),
(263, '2024-10-24', 180, 180, 'DB01', '2024-10-30', '3njvj1ixtgx949lo8i4tqhbm8'),
(264, '2024-10-24', 127.50, 0.00, NULL, NULL, NULL),
(265, '2024-10-24', 120, 120, 'DB02', '2024-10-26', 'dvkuz3abch804fbehkqxsq0xd'),
(266, '2024-10-24', 115, 115, 'CC01', '2024-10-27', 'bs8bhu5kgbbbl26rdbk3njenh'),
(267, '2024-10-24', 110, 110, 'CC01', '2024-10-31', 'ipho9ywr834tz8hghsv6rmeqo'),
(268, '2024-10-24', 99.0, 0.00, NULL, NULL, NULL),
(269, '2024-10-24', 100, 100, 'DB02', '2024-10-26', 'gv57zvi1q27exxvnrbi6z7xhw'),
(270, '2024-10-24', 115, 115, 'CC01', '2024-10-26', '6xp1f8hlt9t95umcar7i06rbj'),
(271, '2024-10-24', 120, 120, 'CC02', '2024-10-25', '3ypyq15f9w3pmf1e1g0gt9if5'),
(272, '2024-10-25', 105, 105, 'CC01', '2024-10-28', 'i5qjokfhsvc02ou3e469z9wd3'),
(273, '2024-10-25', 85, 85, 'CC01', '2024-10-31', 'qse9jtxgjur4si79160u8biu5'),
(274, '2024-10-25', 80, 80, 'BA01', '2024-10-27', NULL),
(275, '2024-10-26', 90, 90, 'DB02', '2024-10-28', 'kgi5s04lygju351fumxx1wikj'),
(276, '2024-10-26', 150, 150, 'CC01', '2024-10-29', '2c6e4em7oiyjsd15ja6mgc07b'),
(277, '2024-10-26', 140, 140, 'DB01', '2024-10-28', 'vi61utsccjsh3qo3ibznh9w7y'),
(278, '2024-10-26', 120, 120, 'BA01', '2024-10-31', NULL),
(279, '2024-10-26', 120, 0.00, NULL, NULL, NULL),
(280, '2024-10-27', 65, 65, 'CC02', '2024-10-28', '1muym6dgvbjuoiop44oen49nv'),
(281, '2024-10-27', 72.0, 72.0, 'DB01', '2024-10-29', 'rtgc2s9s0wqgnk2ese7p34sbz'),
(282, '2024-10-27', 99.0, 99.0, 'CC01', '2024-10-29', 'qsyh0la9mjsgz06mxipraurzw'),
(283, '2024-10-28', 105, 105, 'CC01', '2024-10-29', 'vq9xzdc2rfuflx2k39l45xg6b'),
(284, '2024-10-28', 76.0, 76.0, 'CC02', '2024-10-31', 'ml9swirk72i3cojud82xqkw9k'),
(285, '2024-10-28', 110, 110, 'BA01', '2024-10-31', NULL),
(286, '2024-10-28', 80.0, 80.0, 'CC02', '2024-10-31', 'zsrocgj0091a58455bz9h7ov6'),
(287, '2024-10-28', 97.75, 97.75, 'DB01', '2024-11-03', 'gttlo8kiw3i6uias19visfdm6'),
(288, '2024-10-28', 102.00, 102.00, 'CC02', '2024-10-30', 'v3w02bcstum2yixl6zuvqmecw'),
(289, '2024-10-29', 150, 150, 'DB01', '2024-11-02', 'th37wzagptrfjtkdxwxu1l1kw'),
(290, '2024-10-29', 103.5, 103.5, 'DB01', '2024-11-03', '7sul1711hui1z8bswhd4hz7cb'),
(291, '2024-10-29', 115, 115, 'DB01', '2024-11-03', 'kekkn96iv9hoykooo4agu4xli'),
(292, '2024-10-29', 80, 80, 'CC02', '2024-10-31', '9zjjgbiq0u84en79if0yhug1e'),
(293, '2024-10-29', 60, 60, 'DB01', '2024-10-30', '6a3bghjsm60k8eomek7g6g76j'),
(294, '2024-10-29', 110, 0.00, NULL, NULL, NULL),
(295, '2024-10-30', 105, 105, 'DB01', '2024-11-02', '3up80sflukhwwhppjtfval9zh'),
(296, '2024-10-30', 90, 0.00, NULL, NULL, NULL),
(297, '2024-10-30', 140, 140, 'CC01', '2024-11-02', 'idayu3vtvrlcktzechaxl20sr'),
(298, '2024-10-30', 75, 75, 'DB01', '2024-11-05', '3ot5pqkarynpzfwmv4c7b2oc7'),
(299, '2024-10-30', 120, 120, 'CA01', '2024-11-02', NULL),
(300, '2024-10-31', 85.5, 85.5, 'CC02', '2024-11-03', '6cc8xpxxsz9s49ki2xb2u487p'),
(301, '2024-10-31', 180, 180, 'CC01', '2024-11-05', 'ovvxpav04fobbhijuymvan0ua'),
(302, '2024-10-31', 108.0, 108.0, 'DB01', '2024-11-02', '5wyaueziyfskqdfg5qnsg8d4h'),
(303, '2024-10-31', 99.0, 99.0, 'CA01', '2024-11-01', NULL),
(304, '2024-11-01', 99.0, 99.0, 'DB02', '2024-11-07', '6u92li46rsomwxe0mqlnk9ugt'),
(305, '2024-11-02', 94.5, 94.5, 'DB02', '2024-11-05', 'cv94esgl9eh2x1m5z6d1a2ca4'),
(306, '2024-11-02', 85, 85, 'DB02', '2024-11-03', '65wkmwm081grrvm2m7n0vk72b'),
(307, '2024-11-02', 126.0, 126.0, 'CC01', '2024-11-05', 'k08qhofcsaw6g87jxvioxcykt'),
(308, '2024-11-02', 120, 120, 'CA01', '2024-11-03', NULL),
(309, '2024-11-02', 110, 110, 'BA01', '2024-11-03', NULL),
(310, '2024-11-02', 100, 0.00, NULL, NULL, NULL),
(311, '2024-11-03', 108.0, 108.0, 'DB02', '2024-11-04', 'vep0bv83jiq3urglppszvx90k'),
(312, '2024-11-03', 85, 85, 'DB02', '2024-11-05', 'lyds726xl0bjagf46dn18qbph'),
(313, '2024-11-03', 99.0, 0.00, NULL, NULL, NULL),
(314, '2024-11-04', 95, 95, 'CC01', '2024-11-08', 'ht9fql0qzs6ku1vcmkc8u328a'),
(315, '2024-11-04', 58.5, 58.5, 'CC02', '2024-11-07', 'd0xfe2xdmtiw4ofnlxut0eam7'),
(316, '2024-11-04', 120.0, 120.0, 'CC01', '2024-11-05', 'q9q176xw3ydned9r935wyk5d8'),
(317, '2024-11-04', 120, 120, 'DB02', '2024-11-05', '671qd7abtn3onvudkbz1ppvof'),
(318, '2024-11-04', 115, 115, 'DB02', '2024-11-10', 'ttjxt1irqjy07m2loz2q120rf'),
(319, '2024-11-04', 103.5, 103.5, 'CA01', '2024-11-07', NULL),
(320, '2024-11-04', 115, 115, 'BA01', '2024-11-09', NULL),
(321, '2024-11-05', 54.0, 54.0, 'DB01', '2024-11-07', 'a7zn93cmz2ngdnt7x9zkidaol'),
(322, '2024-11-05', 120, 120, 'CC01', '2024-11-07', 'to4ww4mfgkvl95v0qkcql6yj7'),
(323, '2024-11-05', 94.5, 94.5, 'CA01', '2024-11-06', NULL),
(324, '2024-11-06', 144.0, 144.0, 'DB01', '2024-11-07', 'z9y41j16dk4t9w2at02jfuj2w'),
(325, '2024-11-06', 105, 105, 'CC02', '2024-11-07', 'zcy6lla3rzn9gqmywe61ly4re'),
(326, '2024-11-06', 110, 110, 'CA01', '2024-11-08', NULL),
(327, '2024-11-07', 120, 120, 'CC02', '2024-11-10', '5hnntpyaqx0osf4u28swm6903'),
(328, '2024-11-07', 150, 150, 'CC01', '2024-11-10', '0wn509p28b1adbl9akdfki989'),
(329, '2024-11-07', 180, 180, 'CC01', '2024-11-11', 'vxabkdazir1yz7xum4zc8h4lc'),
(330, '2024-11-07', 105, 105, 'CC02', '2024-11-10', '7gpa2ekevngtvu56yr2rd9e7r'),
(331, '2024-11-07', 126.0, 126.0, 'CC01', '2024-11-08', 'l6m5xgjpnj0sxt790qo1beif9'),
(332, '2024-11-07', 90, 90, 'CA01', '2024-11-10', NULL),
(333, '2024-11-07', 115, 115, 'CC01', '2024-11-10', 't40gs2eyondk7c8qg8crsfznv'),
(334, '2024-11-08', 72.0, 72.0, 'DB02', '2024-11-09', 'c7wstx9qi8662dh2yfhxh627u'),
(335, '2024-11-08', 126.0, 126.0, 'CC01', '2024-11-11', '3xwo2heyc5nn9r3qq1iou7ho2'),
(336, '2024-11-08', 110, 110, 'DB02', '2024-11-10', 'cix8817ql33ib3io2cuv50gsn'),
(337, '2024-11-08', 100, 100, 'CC02', '2024-11-11', '5jz5ckj2f0bac4rlvlenxe3r6'),
(338, '2024-11-09', 115, 115, 'BA01', '2024-11-11', NULL),
(339, '2024-11-10', 90, 90, 'CC02', '2024-11-11', 'w0fh9dxs6ftlnn4o3w1qi8xcw'),
(340, '2024-11-10', 120, 120, 'DB01', '2024-11-12', 'mmb9v9fyaf89jyl05d1c90ybx'),
(341, '2024-11-10', 115, 115, 'DB01', '2024-11-12', '2yh8lojpx70kk9nnk8byebrvy'),
(342, '2024-11-10', 110, 110, 'DB02', '2024-11-13', '67tt32wpvliy2hjcyd3po5ddp'),
(343, '2024-11-11', 48.0, 48.0, 'CA01', '2024-11-16', NULL),
(344, '2024-11-11', 94.5, 94.5, 'DB01', '2024-11-15', '5ntsjejbxgj8465l52nmz7fsz'),
(345, '2024-11-11', 110, 110, 'CA01', '2024-11-12', NULL),
(346, '2024-11-11', 162.0, 162.0, 'CC02', '2024-11-14', '7kc0ekx5faberrb6rxrt2smrx'),
(347, '2024-11-11', 150, 150, 'CA01', '2024-11-16', NULL),
(348, '2024-11-11', 115, 115, 'CA01', '2024-11-13', NULL),
(349, '2024-11-11', 99.0, 0.00, NULL, NULL, NULL),
(350, '2024-11-11', 100, 100, 'CC01', '2024-11-14', 'ffbc0eypcwr45up2lkvo8vdnr'),
(351, '2024-11-11', 75, 75, 'CC02', '2024-11-12', 'or4moban1xzzklfgs1hvjlc1s'),
(352, '2024-11-12', 140, 140, 'BA01', '2024-11-14', NULL),
(353, '2024-11-12', 120, 120, 'DB01', '2024-11-13', 'nze1a8cn9l4qh6fnna3pe09l7'),
(354, '2024-11-12', 110, 110, 'CC02', '2024-11-15', 'asdcoatmsximw3gcvcigoy227'),
(355, '2024-11-12', 120, 120, 'DB01', '2024-11-14', 'p3x46oaj988v5i4lshucxv72t'),
(356, '2024-11-12', 108.0, 0.00, NULL, NULL, NULL),
(357, '2024-11-13', 95, 0.00, NULL, NULL, NULL),
(358, '2024-11-13', 115, 115, 'BA01', '2024-11-14', NULL),
(359, '2024-11-14', 96.0, 96.0, 'CC01', '2024-11-19', '23sn62z7eot24kf0dzqq74dhp'),
(360, '2024-11-14', 180, 180, 'CC01', '2024-11-18', '7mex5espqvlf2zw8uinuzwv1d'),
(361, '2024-11-14', 76.5, 76.5, 'DB02', '2024-11-17', 'qvtysj2k1a9l0keh90o12g52u'),
(362, '2024-11-14', 120, 120, 'CC02', '2024-11-19', '3x2b1nazrhzvro02wkh12u9g8'),
(363, '2024-11-14', 90, 90, 'CA01', '2024-11-17', NULL),
(364, '2024-11-14', 65, 65, 'DB02', '2024-11-17', 'mjy8ulq48zqzjlvcd6kz0d28b'),
(365, '2024-11-15', 126.0, 126.0, 'CC01', '2024-11-18', 'gvl414xn2ym9l4rvjn61f0wql'),
(366, '2024-11-16', 80, 80, 'CC01', '2024-11-20', 'y8yqsrpfnka1yd5gfed7uqtf2'),
(367, '2024-11-16', 115, 0.00, NULL, NULL, NULL),
(368, '2024-11-16', 110, 0.00, NULL, NULL, NULL),
(369, '2024-11-16', 90.0, 90.0, 'DB02', '2024-11-17', '82twq02h4o8wa4bnvi40gbw7j'),
(370, '2024-11-16', 115, 115, 'CC01', '2024-11-19', 'lsb0fbionca8jiiw3yx8nn4ui'),
(371, '2024-11-16', 103.5, 103.5, 'CC02', '2024-11-17', '1qcs6zzemlzpk2r1d9lj7h1q6'),
(372, '2024-11-16', 75, 0.00, NULL, NULL, NULL),
(373, '2024-11-16', 120, 120, 'DB01', '2024-11-20', '4pcsoo9gdkittya8xct8me5xh'),
(374, '2024-11-17', 150, 150, 'DB02', '2024-11-20', '2qzfmvuq1f8awm79r1xjv38iz'),
(375, '2024-11-17', 99.0, 0.00, NULL, NULL, NULL),
(376, '2024-11-17', 100, 100, 'CC01', '2024-11-18', '9csetq54d64u5nwk6w058tw7q'),
(377, '2024-11-17', 115, 115, 'BA01', '2024-11-19', NULL),
(378, '2024-11-18', 95, 95, 'CC02', '2024-11-20', 'jsspc4sxmcw22nejkkpb7ilg9'),
(379, '2024-11-18', 85, 0.00, NULL, NULL, NULL),
(380, '2024-11-18', 162.0, 0.00, NULL, NULL, NULL),
(381, '2024-11-18', 140, 140, 'CC02', '2024-11-20', 'r54zrd74f8dkh9ag4ujfat4oa'),
(382, '2024-11-18', 110, 110, 'BA01', '2024-11-19', NULL),
(383, '2024-11-19', 108.0, 108.0, 'CC01', '2024-11-20', '4h1e67yxfnpkc37dh8lv5tak7'),
(384, '2024-11-20', 72.0, 0.00, NULL, NULL, NULL),
(385, '2024-11-20', 105, 0.00, NULL, NULL, NULL),
(386, '2024-11-20', 140, 0.00, NULL, NULL, NULL),
(387, '2024-11-20', 108.0, 0.00, NULL, NULL, NULL),
(388, '2024-11-20', 110, 0.00, NULL, NULL, NULL),
(389, '2024-11-20', 115, 0.00, NULL, NULL, NULL);

INSERT INTO promotion (promotion_code, promotion_name, discount_percentage) VALUES
('AUG10', 'August 10% discount', 10),
('AUG15', 'August 15% discount', 15),
('SEP10', 'September 10% discount', 10),
('SEP15', 'September 15% discount', 15),
('OCT10', 'October 10% discount', 10),
('OCT15', 'October 15% discount', 15),
('COM10', 'Company 10% discount', 10),
('COM20', 'Company 20% discount', 20),
('NOV10', 'November 10% discount', 10),
('DEC10', 'December 10% discount', 10);

INSERT INTO reservation (reservation_id, guest_id, room_number, invoice_number, promotion_code, reservation_staff_id, reservation_date_time, number_of_guests, start_of_stay, length_of_stay, status_code) VALUES
(1, 1, 110, 1, 'OCT10', 4, '2024-10-12 09:30:00', 3, '2024-10-21', 2, 'OT'),
(2, 3, 103, 2, NULL, 5, '2024-10-13 12:15:00', 1, '2024-10-24', 7, 'OT'),
(3, 1, 204, 3, 'OCT15', 3, '2024-10-16 14:10:00', 2, '2024-10-25', 4, 'OT'),
(4, 7, 101, NULL, 'COM20', 3, '2024-10-17 19:25:00', 1, '2024-10-26', 1, 'OT'),
(5, 4, 101, 343, 'COM20', 2, '2024-10-20 10:00:00', 1, '2024-11-11', 5, 'OT'),
(6, 23, 103, 8, NULL, 5, '2024-08-10 17:47:00', 1, '2024-08-16', 3, 'OT'),
(7, 14, 208, 4, NULL, 3, '2024-08-10 18:12:00', 4, '2024-08-13', 5, 'OT'),
(8, 12, 111, 27, NULL, 4, '2024-08-10 18:32:00', 1, '2024-08-24', 6, 'OT'),
(9, 23, 208, 25, NULL, 5, '2024-08-10 08:41:00', 4, '2024-08-23', 5, 'OT'),
(10, 27, 207, 20, NULL, 3, '2024-08-10 20:33:00', 3, '2024-08-21', 5, 'OT'),
(11, 17, 212, 14, NULL, 4, '2024-08-11 22:27:00', 4, '2024-08-19', 2, 'OT'),
(12, 10, 211, 24, NULL, 2, '2024-08-11 19:32:00', 4, '2024-08-23', 1, 'OT'),
(13, 30, 204, 26, NULL, 5, '2024-08-11 20:43:00', 2, '2024-08-23', 1, 'OT'),
(14, 5, 103, 17, NULL, 5, '2024-08-11 14:36:00', 1, '2024-08-20', 2, 'OT'),
(15, 14, 201, 15, 'COM10', 5, '2024-08-11 14:13:00', 2, '2024-08-20', 3, 'OT'),
(16, 9, 103, 5, NULL, 3, '2024-08-11 13:11:00', 1, '2024-08-14', 2, 'OT'),
(17, 17, 213, 6, 'AUG10', 2, '2024-08-11 10:22:00', 1, '2024-08-15', 3, 'OT'),
(18, 16, 212, 7, NULL, 5, '2024-08-11 13:30:00', 4, '2024-08-15', 1, 'OT'),
(19, 28, 111, 10, 'AUG10', 4, '2024-08-11 18:02:00', 2, '2024-08-17', 2, 'OT'),
(20, 18, 211, 36, NULL, 4, '2024-08-12 08:13:00', 2, '2024-08-26', 1, 'OT'),
(21, 21, 205, 43, NULL, 3, '2024-08-12 15:35:00', 1, '2024-08-28', 1, 'OT'),
(22, 24, 212, 30, NULL, 3, '2024-08-12 17:09:00', 3, '2024-08-25', 3, 'OT'),
(23, 21, 201, 12, 'COM20', 3, '2024-08-12 18:12:00', 2, '2024-08-19', 1, 'OT'),
(24, 7, 107, 22, NULL, 5, '2024-08-12 17:27:00', 1, '2024-08-22', 3, 'OT'),
(25, 25, 212, 9, NULL, 2, '2024-08-13 14:04:00', 4, '2024-08-16', 2, 'OT'),
(26, 17, 208, 63, 'SEP10', 2, '2024-08-14 17:09:00', 1, '2024-09-03', 3, 'OT'),
(27, 19, 206, 50, NULL, 4, '2024-08-14 17:02:00', 1, '2024-08-31', 2, 'OT'),
(28, 14, 209, 32, NULL, 4, '2024-08-14 07:22:00', 4, '2024-08-25', 2, 'OT'),
(29, 16, 204, 18, NULL, 3, '2024-08-14 07:00:00', 2, '2024-08-20', 1, 'OT'),
(30, 27, 203, 61, NULL, 3, '2024-08-15 08:03:00', 2, '2024-09-03', 3, 'OT'),
(31, 11, 209, 53, NULL, 2, '2024-08-15 07:28:00', 1, '2024-09-01', 1, 'OT'),
(32, 18, 102, 13, NULL, 4, '2024-08-15 09:00:00', 1, '2024-08-19', 2, 'OT'),
(33, 18, 111, 19, 'AUG15', 3, '2024-08-15 13:40:00', 2, '2024-08-21', 3, 'OT'),
(34, 11, 108, 11, NULL, 5, '2024-08-15 20:41:00', 2, '2024-08-17', 4, 'OT'),
(35, 21, 108, 59, 'COM10', 3, '2024-08-16 18:11:00', 1, '2024-09-02', 1, 'OT'),
(36, 9, 204, 38, 'AUG10', 2, '2024-08-16 17:07:00', 1, '2024-08-26', 6, 'OT'),
(37, 5, 107, 35, NULL, 3, '2024-08-16 18:40:00', 2, '2024-08-26', 6, 'OT'),
(38, 20, 112, 41, 'COM20', 5, '2024-08-16 21:21:00', 1, '2024-08-27', 4, 'OT'),
(39, 12, 212, 49, NULL, 3, '2024-08-16 08:57:00', 1, '2024-08-31', 3, 'OT'),
(40, 7, 110, 28, NULL, 3, '2024-08-17 08:17:00', 1, '2024-08-25', 5, 'OT'),
(41, 4, 213, 16, 'COM10', 4, '2024-08-17 16:28:00', 2, '2024-08-20', 2, 'OT'),
(42, 7, 204, 54, NULL, 2, '2024-08-17 07:46:00', 2, '2024-09-01', 4, 'OT'),
(43, 8, 210, 58, NULL, 2, '2024-08-17 12:15:00', 4, '2024-09-02', 6, 'OT'),
(44, 22, 210, 52, 'SEP10', 5, '2024-08-17 09:55:00', 2, '2024-09-01', 1, 'OT'),
(45, 10, 102, 33, 'AUG15', 2, '2024-08-17 18:04:00', 1, '2024-08-25', 4, 'OT'),
(46, 6, 213, 48, NULL, 2, '2024-08-17 18:09:00', 4, '2024-08-31', 3, 'OT'),
(47, 20, 212, 75, NULL, 5, '2024-08-17 13:55:00', 4, '2024-09-06', 7, 'OT'),
(48, 6, 210, 39, 'AUG15', 5, '2024-08-17 18:22:00', 2, '2024-08-27', 3, 'OT'),
(49, 2, 205, 60, 'SEP10', 2, '2024-08-18 22:01:00', 1, '2024-09-02', 4, 'OT'),
(50, 6, 206, 64, NULL, 2, '2024-08-18 10:33:00', 4, '2024-09-03', 3, 'OT'),
(51, 16, 211, 57, NULL, 2, '2024-08-18 21:40:00', 3, '2024-09-02', 3, 'OT'),
(52, 17, 213, 37, NULL, 5, '2024-08-18 19:40:00', 3, '2024-08-26', 4, 'OT'),
(53, 4, 112, 29, NULL, 5, '2024-08-19 14:02:00', 1, '2024-08-25', 1, 'OT'),
(54, 19, 111, 69, 'SEP15', 5, '2024-08-19 07:21:00', 2, '2024-09-04', 5, 'OT'),
(55, 14, 105, 47, NULL, 3, '2024-08-19 22:52:00', 1, '2024-08-30', 3, 'OT'),
(56, 19, 111, 46, NULL, 2, '2024-08-19 21:34:00', 1, '2024-08-30', 1, 'OT'),
(57, 19, 206, 21, 'AUG10', 3, '2024-08-19 21:23:00', 4, '2024-08-22', 3, 'OT'),
(58, 5, 107, 70, NULL, 2, '2024-08-19 08:19:00', 2, '2024-09-05', 1, 'OT'),
(59, 28, 108, 31, 'AUG15', 3, '2024-08-19 20:59:00', 2, '2024-08-25', 3, 'OT'),
(60, 22, 211, 71, NULL, 4, '2024-08-19 16:20:00', 3, '2024-09-05', 1, 'OT'),
(61, 16, 201, 34, NULL, 5, '2024-08-19 18:35:00', 2, '2024-08-26', 5, 'OT'),
(62, 27, 207, 42, 'COM10', 5, '2024-08-20 16:25:00', 3, '2024-08-28', 1, 'OT'),
(63, 4, 213, 23, NULL, 4, '2024-08-20 10:18:00', 1, '2024-08-23', 2, 'OT'),
(64, 4, 110, 78, NULL, 2, '2024-08-21 15:32:00', 1, '2024-09-07', 5, 'OT'),
(65, 11, 112, 72, NULL, 5, '2024-08-22 22:59:00', 2, '2024-09-05', 3, 'OT'),
(66, 23, 201, 55, 'SEP10', 2, '2024-08-22 22:33:00', 2, '2024-09-02', 5, 'OT'),
(67, 17, 211, 98, NULL, 2, '2024-08-23 21:52:00', 3, '2024-09-11', 2, 'OT'),
(68, 16, 107, 97, NULL, 2, '2024-08-23 20:27:00', 2, '2024-09-11', 3, 'OT'),
(69, 10, 206, 44, NULL, 5, '2024-08-23 14:38:00', 3, '2024-08-29', 2, 'OT'),
(70, 14, 112, 56, 'COM10', 4, '2024-08-25 15:52:00', 1, '2024-09-02', 3, 'OT'),
(71, 3, 110, 103, NULL, 4, '2024-08-25 16:30:00', 2, '2024-09-12', 7, 'OT'),
(72, 29, 209, 40, 'AUG10', 2, '2024-08-25 20:31:00', 3, '2024-08-27', 3, 'OT'),
(73, 16, 211, 80, 'SEP15', 4, '2024-08-26 16:29:00', 4, '2024-09-07', 2, 'OT'),
(74, 5, 110, 51, 'SEP10', 5, '2024-08-26 18:42:00', 2, '2024-09-01', 3, 'OT'),
(75, 16, 213, 89, NULL, 5, '2024-08-26 10:29:00', 3, '2024-09-09', 1, 'OT'),
(76, 20, 110, 65, NULL, 3, '2024-08-26 07:04:00', 1, '2024-09-04', 2, 'OT'),
(77, 24, 207, 45, NULL, 3, '2024-08-27 17:05:00', 2, '2024-08-29', 6, 'OT'),
(78, 5, 207, 76, NULL, 4, '2024-08-27 19:57:00', 4, '2024-09-06', 3, 'OT'),
(79, 1, 106, 107, NULL, 5, '2024-08-27 07:49:00', 1, '2024-09-13', 4, 'OT'),
(80, 7, 106, 84, NULL, 4, '2024-08-27 08:52:00', 1, '2024-09-08', 2, 'OT'),
(81, 27, 208, 105, NULL, 4, '2024-08-28 11:05:00', 3, '2024-09-12', 2, 'OT'),
(82, 10, 108, 66, NULL, 5, '2024-08-29 20:28:00', 2, '2024-09-04', 2, 'OT'),
(83, 30, 213, 124, 'SEP15', 2, '2024-08-29 11:07:00', 2, '2024-09-17', 1, 'OT'),
(84, 18, 107, 118, 'SEP10', 5, '2024-08-29 10:57:00', 2, '2024-09-16', 2, 'OT'),
(85, 13, 213, 109, 'SEP15', 3, '2024-08-29 10:25:00', 3, '2024-09-14', 3, 'OT'),
(86, 28, 108, 77, NULL, 4, '2024-08-29 22:57:00', 1, '2024-09-06', 3, 'OT'),
(87, 22, 210, 125, NULL, 5, '2024-08-29 16:31:00', 3, '2024-09-17', 5, 'OT'),
(88, 30, 203, 73, NULL, 5, '2024-08-30 12:48:00', 1, '2024-09-06', 3, 'OT'),
(89, 26, 213, 74, NULL, 5, '2024-08-30 16:45:00', 4, '2024-09-06', 3, 'OT'),
(90, 21, 209, 62, 'COM20', 5, '2024-08-30 14:56:00', 3, '2024-09-03', 7, 'OT'),
(91, 12, 202, 68, NULL, 4, '2024-08-31 16:01:00', 2, '2024-09-04', 6, 'OT'),
(92, 25, 209, 111, NULL, 4, '2024-08-31 21:06:00', 3, '2024-09-14', 3, 'OT'),
(93, 4, 103, 67, NULL, 2, '2024-08-31 20:52:00', 1, '2024-09-04', 3, 'OT'),
(94, 25, 111, 91, NULL, 2, '2024-08-31 21:50:00', 2, '2024-09-09', 1, 'OT'),
(95, 15, 208, 81, NULL, 4, '2024-09-01 14:48:00', 3, '2024-09-07', 1, 'OT'),
(96, 6, 202, 133, NULL, 5, '2024-09-01 16:38:00', 2, '2024-09-21', 5, 'OT'),
(97, 20, 111, 123, NULL, 5, '2024-09-01 19:24:00', 2, '2024-09-16', 3, 'OT'),
(98, 21, 205, 108, 'COM10', 3, '2024-09-02 13:03:00', 1, '2024-09-13', 5, 'OT'),
(99, 23, 112, 122, NULL, 4, '2024-09-02 17:15:00', 2, '2024-09-16', 5, 'OT'),
(100, 28, 108, 116, 'SEP10', 4, '2024-09-02 21:02:00', 2, '2024-09-15', 3, 'OT'),
(101, 27, 206, 82, 'COM10', 2, '2024-09-02 13:44:00', 2, '2024-09-07', 3, 'OT'),
(102, 19, 213, 131, 'SEP10', 5, '2024-09-02 18:54:00', 1, '2024-09-20', 3, 'OT'),
(103, 9, 211, 119, NULL, 3, '2024-09-02 15:09:00', 1, '2024-09-16', 2, 'OT'),
(104, 18, 107, 79, 'SEP10', 2, '2024-09-02 10:38:00', 2, '2024-09-07', 2, 'OT'),
(105, 29, 101, 90, NULL, 2, '2024-09-02 18:13:00', 1, '2024-09-09', 5, 'OT'),
(106, 8, 112, 86, NULL, 3, '2024-09-02 13:43:00', 2, '2024-09-08', 4, 'OT'),
(107, 4, 204, 117, NULL, 3, '2024-09-03 11:03:00', 2, '2024-09-15', 3, 'OT'),
(108, 28, 201, 102, NULL, 3, '2024-09-04 09:17:00', 1, '2024-09-11', 2, 'OT'),
(109, 30, 206, 113, NULL, 5, '2024-09-04 21:18:00', 2, '2024-09-14', 2, 'OT'),
(110, 22, 202, 106, NULL, 2, '2024-09-04 22:44:00', 1, '2024-09-12', 3, 'OT'),
(111, 18, 108, 87, NULL, 4, '2024-09-04 13:28:00', 1, '2024-09-09', 4, 'OT'),
(112, 11, 105, 104, NULL, 4, '2024-09-04 21:36:00', 2, '2024-09-12', 7, 'OT'),
(113, 7, 207, 94, NULL, 2, '2024-09-04 20:22:00', 4, '2024-09-10', 5, 'OT'),
(114, 18, 208, 112, NULL, 3, '2024-09-04 17:34:00', 4, '2024-09-14', 2, 'OT'),
(115, 7, 201, 121, 'COM10', 4, '2024-09-05 19:56:00', 1, '2024-09-16', 2, 'OT'),
(116, 2, 211, 139, 'SEP15', 5, '2024-09-05 17:25:00', 3, '2024-09-22', 1, 'OT'),
(117, 2, 210, 95, 'SEP10', 2, '2024-09-05 10:38:00', 2, '2024-09-10', 1, 'OT'),
(118, 27, 209, 93, NULL, 4, '2024-09-05 17:25:00', 2, '2024-09-10', 2, 'OT'),
(119, 10, 206, 100, NULL, 3, '2024-09-05 15:16:00', 4, '2024-09-11', 3, 'OT'),
(120, 13, 201, 83, NULL, 2, '2024-09-05 16:41:00', 1, '2024-09-07', 3, 'OT'),
(121, 29, 211, 141, NULL, 5, '2024-09-06 14:02:00', 4, '2024-09-23', 4, 'OT'),
(122, 23, 111, 153, NULL, 5, '2024-09-06 18:22:00', 2, '2024-09-26', 1, 'OT'),
(123, 23, 204, 85, 'SEP10', 3, '2024-09-06 17:13:00', 2, '2024-09-08', 5, 'OT'),
(124, 17, 201, 138, NULL, 2, '2024-09-07 22:06:00', 2, '2024-09-22', 4, 'OT'),
(125, 26, 210, 99, NULL, 3, '2024-09-07 16:34:00', 4, '2024-09-11', 4, 'OT'),
(126, 14, 103, 88, NULL, 4, '2024-09-07 18:16:00', 1, '2024-09-09', 5, 'OT'),
(127, 10, 201, 114, NULL, 4, '2024-09-07 07:06:00', 2, '2024-09-14', 2, 'OT'),
(128, 19, 213, 92, 'SEP15', 4, '2024-09-07 22:35:00', 4, '2024-09-10', 3, 'OT'),
(129, 13, 203, 101, NULL, 2, '2024-09-07 13:54:00', 1, '2024-09-11', 3, 'OT'),
(130, 30, 204, 144, NULL, 5, '2024-09-08 09:38:00', 2, '2024-09-23', 1, 'OT'),
(131, 25, 212, 127, NULL, 4, '2024-09-08 15:18:00', 2, '2024-09-18', 6, 'OT'),
(132, 26, 208, 126, NULL, 4, '2024-09-08 22:17:00', 2, '2024-09-17', 3, 'OT'),
(133, 9, 102, 96, NULL, 2, '2024-09-09 22:24:00', 1, '2024-09-11', 3, 'OT'),
(134, 11, 210, 146, 'COM10', 3, '2024-09-09 20:00:00', 1, '2024-09-24', 3, 'OT'),
(135, 21, 207, 143, 'COM10', 5, '2024-09-10 14:50:00', 4, '2024-09-23', 4, 'OT'),
(136, 17, 103, 115, NULL, 2, '2024-09-10 09:33:00', 1, '2024-09-15', 2, 'OT'),
(137, 1, 206, 173, NULL, 2, '2024-09-10 07:04:00', 2, '2024-09-30', 3, 'OT'),
(138, 3, 112, 134, NULL, 4, '2024-09-10 09:49:00', 2, '2024-09-21', 3, 'OT'),
(139, 29, 209, 128, NULL, 3, '2024-09-10 19:09:00', 4, '2024-09-18', 5, 'OT'),
(140, 5, 207, 156, 'SEP10', 5, '2024-09-10 09:31:00', 3, '2024-09-27', 5, 'OT'),
(141, 19, 210, 171, 'SEP10', 2, '2024-09-10 20:38:00', 3, '2024-09-30', 6, 'OT'),
(142, 4, 212, 110, NULL, 5, '2024-09-10 10:55:00', 2, '2024-09-14', 1, 'OT'),
(143, 15, 205, 130, NULL, 2, '2024-09-11 18:18:00', 1, '2024-09-19', 4, 'OT'),
(144, 25, 205, 162, NULL, 5, '2024-09-11 09:57:00', 1, '2024-09-28', 1, 'OT'),
(145, 4, 205, 148, 'COM20', 4, '2024-09-11 21:35:00', 2, '2024-09-24', 3, 'OT'),
(146, 14, 105, 132, 'COM20', 2, '2024-09-11 13:33:00', 1, '2024-09-20', 4, 'OT'),
(147, 30, 203, 120, 'SEP10', 5, '2024-09-11 09:37:00', 2, '2024-09-16', 1, 'OT'),
(148, 30, 211, 129, NULL, 5, '2024-09-11 17:47:00', 4, '2024-09-19', 1, 'OT'),
(149, 13, 211, 166, NULL, 4, '2024-09-11 18:20:00', 3, '2024-09-29', 3, 'OT'),
(150, 21, 208, 135, 'COM10', 5, '2024-09-12 07:35:00', 2, '2024-09-21', 2, 'OT'),
(151, 16, 212, 150, NULL, 4, '2024-09-12 16:44:00', 1, '2024-09-25', 5, 'OT'),
(152, 22, 213, 149, NULL, 5, '2024-09-13 22:39:00', 2, '2024-09-25', 5, 'OT'),
(153, 2, 206, 152, 'SEP15', 4, '2024-09-13 17:11:00', 1, '2024-09-26', 1, 'OT'),
(154, 29, 205, 175, NULL, 5, '2024-09-13 14:30:00', 1, '2024-10-01', 2, 'OT'),
(155, 8, 112, 168, NULL, 5, '2024-09-15 21:41:00', 2, '2024-09-29', 3, 'OT'),
(156, 25, 205, 191, NULL, 3, '2024-09-16 14:41:00', 2, '2024-10-06', 5, 'OT'),
(157, 9, 110, 154, NULL, 2, '2024-09-16 09:32:00', 2, '2024-09-27', 3, 'OT'),
(158, 5, 206, 136, NULL, 3, '2024-09-16 21:45:00', 1, '2024-09-21', 1, 'OT'),
(159, 3, 213, 182, NULL, 3, '2024-09-16 10:51:00', 1, '2024-10-04', 3, 'OT'),
(160, 23, 208, 172, NULL, 2, '2024-09-16 13:03:00', 2, '2024-09-30', 3, 'OT'),
(161, 26, 206, 157, 'COM10', 3, '2024-09-16 20:04:00', 3, '2024-09-27', 3, 'OT'),
(162, 21, 213, 169, 'COM10', 3, '2024-09-17 21:07:00', 2, '2024-09-30', 3, 'OT'),
(163, 27, 209, 160, NULL, 2, '2024-09-17 13:13:00', 1, '2024-09-28', 5, 'OT'),
(164, 7, 210, 155, NULL, 4, '2024-09-17 19:33:00', 4, '2024-09-27', 2, 'OT'),
(165, 14, 112, 193, NULL, 3, '2024-09-17 16:02:00', 1, '2024-10-06', 2, 'OT'),
(166, 24, 107, 159, NULL, 5, '2024-09-17 08:13:00', 2, '2024-09-28', 3, 'OT'),
(167, 22, 207, 177, NULL, 2, '2024-09-17 11:27:00', 4, '2024-10-02', 4, 'OT'),
(168, 14, 208, 161, NULL, 4, '2024-09-17 09:26:00', 3, '2024-09-28', 2, 'OT'),
(169, 11, 105, 165, 'COM10', 5, '2024-09-18 18:20:00', 1, '2024-09-29', 4, 'OT'),
(170, 5, 107, 142, NULL, 3, '2024-09-18 07:43:00', 1, '2024-09-23', 2, 'OT'),
(171, 24, 204, 176, NULL, 5, '2024-09-18 11:23:00', 2, '2024-10-01', 4, 'OT'),
(172, 13, 108, 195, 'OCT10', 5, '2024-09-18 19:59:00', 1, '2024-10-07', 3, 'OT'),
(173, 24, 209, 145, 'SEP15', 2, '2024-09-19 21:46:00', 3, '2024-09-24', 2, 'OT'),
(174, 15, 108, 164, NULL, 3, '2024-09-19 17:52:00', 2, '2024-09-29', 4, 'OT'),
(175, 28, 108, 140, 'SEP10', 3, '2024-09-19 07:00:00', 1, '2024-09-22', 1, 'OT'),
(176, 12, 204, 163, NULL, 5, '2024-09-19 10:24:00', 1, '2024-09-28', 3, 'OT'),
(177, 30, 111, 158, NULL, 3, '2024-09-19 09:24:00', 2, '2024-09-28', 2, 'OT'),
(178, 1, 111, 185, NULL, 4, '2024-09-20 17:06:00', 2, '2024-10-04', 3, 'OT'),
(179, 12, 208, 151, NULL, 5, '2024-09-20 21:35:00', 4, '2024-09-25', 3, 'OT'),
(180, 7, 205, 181, NULL, 2, '2024-09-20 18:42:00', 1, '2024-10-03', 3, 'OT'),
(181, 19, 108, 147, NULL, 5, '2024-09-20 09:32:00', 1, '2024-09-24', 4, 'OT'),
(182, 20, 110, 199, NULL, 4, '2024-09-20 10:49:00', 2, '2024-10-09', 2, 'OT'),
(183, 23, 101, 137, 'SEP10', 4, '2024-09-20 21:23:00', 1, '2024-09-22', 3, 'OT'),
(184, 6, 209, 197, NULL, 3, '2024-09-22 17:45:00', 2, '2024-10-08', 4, 'OT'),
(185, 11, 213, 204, NULL, 5, '2024-09-22 22:47:00', 3, '2024-10-11', 3, 'OT'),
(186, 7, 212, 170, 'COM20', 4, '2024-09-22 19:56:00', 1, '2024-09-30', 3, 'OT'),
(187, 3, 201, 167, NULL, 4, '2024-09-22 14:33:00', 2, '2024-09-29', 5, 'OT'),
(188, 26, 107, 184, 'COM10', 2, '2024-09-22 07:52:00', 2, '2024-10-04', 5, 'OT'),
(189, 29, 210, 207, 'OCT10', 2, '2024-09-22 07:10:00', 1, '2024-10-11', 5, 'OT'),
(190, 7, 208, 208, NULL, 4, '2024-09-23 08:52:00', 1, '2024-10-11', 3, 'OT'),
(191, 10, 101, 174, NULL, 4, '2024-09-24 07:20:00', 1, '2024-09-30', 3, 'OT'),
(192, 30, 211, 194, 'OCT15', 5, '2024-09-26 20:24:00', 1, '2024-10-07', 1, 'OT'),
(193, 17, 211, 223, NULL, 4, '2024-09-27 18:40:00', 1, '2024-10-15', 1, 'OT'),
(194, 10, 209, 215, NULL, 3, '2024-09-27 22:15:00', 2, '2024-10-13', 1, 'OT'),
(195, 12, 201, 212, NULL, 4, '2024-09-27 16:57:00', 2, '2024-10-12', 2, 'OT'),
(196, 27, 206, 210, NULL, 5, '2024-09-28 21:27:00', 4, '2024-10-11', 5, 'OT'),
(197, 28, 207, 209, NULL, 4, '2024-09-28 19:08:00', 3, '2024-10-11', 1, 'OT'),
(198, 4, 206, 196, 'COM20', 3, '2024-09-28 20:47:00', 3, '2024-10-07', 3, 'OT'),
(199, 8, 103, 189, 'OCT15', 3, '2024-09-28 10:42:00', 1, '2024-10-06', 1, 'OT'),
(200, 8, 212, 205, NULL, 5, '2024-09-28 21:06:00', 3, '2024-10-11', 1, 'OT'),
(201, 27, 108, 188, NULL, 5, '2024-09-29 19:20:00', 1, '2024-10-05', 2, 'OT'),
(202, 18, 203, 192, 'OCT10', 3, '2024-09-29 13:00:00', 2, '2024-10-06', 5, 'OT'),
(203, 14, 103, 217, 'COM20', 5, '2024-09-29 13:13:00', 1, '2024-10-13', 3, 'OT'),
(204, 25, 211, 206, NULL, 3, '2024-09-29 22:44:00', 3, '2024-10-11', 3, 'OT'),
(205, 28, 209, 230, NULL, 4, '2024-09-29 07:57:00', 1, '2024-10-16', 4, 'OT'),
(206, 11, 208, 224, NULL, 3, '2024-09-29 18:20:00', 3, '2024-10-15', 1, 'OT'),
(207, 12, 204, 231, NULL, 3, '2024-09-29 10:41:00', 2, '2024-10-16', 3, 'OT'),
(208, 6, 112, 178, NULL, 5, '2024-09-29 21:46:00', 1, '2024-10-02', 4, 'OT'),
(209, 11, 207, 241, 'COM20', 5, '2024-09-29 15:43:00', 1, '2024-10-18', 1, 'OT'),
(210, 27, 211, 249, 'COM10', 2, '2024-09-30 11:41:00', 3, '2024-10-20', 5, 'OT'),
(211, 15, 112, 201, 'COM10', 5, '2024-09-30 09:35:00', 2, '2024-10-10', 2, 'OT'),
(212, 30, 101, 211, NULL, 4, '2024-09-30 22:29:00', 1, '2024-10-11', 2, 'OT'),
(213, 15, 211, 180, NULL, 3, '2024-09-30 18:54:00', 3, '2024-10-03', 1, 'OT'),
(214, 23, 110, 179, NULL, 3, '2024-09-30 22:29:00', 2, '2024-10-03', 6, 'OT'),
(215, 28, 210, 250, NULL, 4, '2024-09-30 08:57:00', 2, '2024-10-20', 1, 'OT'),
(216, 19, 106, 203, 'OCT10', 2, '2024-10-01 20:26:00', 1, '2024-10-11', 1, 'OT'),
(217, 13, 204, 202, 'OCT15', 3, '2024-10-01 10:01:00', 2, '2024-10-10', 3, 'OT'),
(218, 17, 212, 187, 'OCT15', 4, '2024-10-01 16:57:00', 2, '2024-10-05', 3, 'OT'),
(219, 9, 201, 198, NULL, 5, '2024-10-01 17:06:00', 1, '2024-10-09', 3, 'OT'),
(220, 27, 112, 242, NULL, 2, '2024-10-02 10:51:00', 2, '2024-10-18', 2, 'OT'),
(221, 10, 206, 186, NULL, 4, '2024-10-02 09:34:00', 2, '2024-10-05', 2, 'OT'),
(222, 21, 211, 183, 'COM10', 5, '2024-10-02 08:23:00', 1, '2024-10-04', 3, 'OT'),
(223, 3, 207, 200, NULL, 4, '2024-10-02 21:19:00', 4, '2024-10-09', 2, 'OT'),
(224, 3, 111, 253, 'COM10', 3, '2024-10-02 21:28:00', 1, '2024-10-20', 3, 'OT'),
(225, 30, 108, 246, NULL, 5, '2024-10-02 18:54:00', 1, '2024-10-20', 3, 'OT'),
(226, 16, 210, 258, NULL, 4, '2024-10-02 09:27:00', 1, '2024-10-22', 2, 'OT'),
(227, 2, 212, 222, NULL, 3, '2024-10-02 13:39:00', 3, '2024-10-15', 4, 'OT'),
(228, 9, 211, 239, NULL, 5, '2024-10-03 09:03:00', 1, '2024-10-18', 2, 'OT'),
(229, 23, 111, 218, 'OCT10', 4, '2024-10-04 16:06:00', 1, '2024-10-14', 3, 'OT'),
(230, 9, 209, 190, NULL, 5, '2024-10-04 14:04:00', 4, '2024-10-06', 1, 'OT'),
(231, 4, 204, 251, NULL, 2, '2024-10-04 22:29:00', 1, '2024-10-20', 2, 'OT'),
(232, 19, 212, 214, NULL, 2, '2024-10-06 20:27:00', 3, '2024-10-13', 1, 'OT'),
(233, 29, 205, 270, NULL, 5, '2024-10-06 22:06:00', 1, '2024-10-24', 2, 'OT'),
(234, 3, 208, 235, 'COM10', 4, '2024-10-07 22:13:00', 4, '2024-10-17', 1, 'OT'),
(235, 18, 110, 219, 'OCT10', 5, '2024-10-07 19:28:00', 2, '2024-10-14', 7, 'OT'),
(236, 22, 203, 259, NULL, 2, '2024-10-07 08:16:00', 1, '2024-10-23', 2, 'OT'),
(237, 22, 107, 233, NULL, 4, '2024-10-07 13:32:00', 1, '2024-10-17', 1, 'OT'),
(238, 11, 107, 247, NULL, 2, '2024-10-07 12:54:00', 1, '2024-10-20', 1, 'OT'),
(239, 6, 208, 267, NULL, 2, '2024-10-07 19:47:00', 1, '2024-10-24', 7, 'OT'),
(240, 16, 112, 227, NULL, 5, '2024-10-07 12:55:00', 1, '2024-10-16', 2, 'OT'),
(241, 30, 107, 213, NULL, 5, '2024-10-07 07:32:00', 1, '2024-10-13', 3, 'OT'),
(242, 24, 210, 229, NULL, 4, '2024-10-07 16:18:00', 2, '2024-10-16', 3, 'OT'),
(243, 10, 213, 263, NULL, 2, '2024-10-08 14:16:00', 1, '2024-10-24', 6, 'OT'),
(244, 4, 209, 266, NULL, 2, '2024-10-08 21:51:00', 2, '2024-10-24', 3, 'OT'),
(245, 17, 212, 276, NULL, 3, '2024-10-08 10:22:00', 3, '2024-10-26', 3, 'OT'),
(246, 5, 201, 288, 'OCT15', 2, '2024-10-08 18:44:00', 2, '2024-10-28', 2, 'OT'),
(247, 5, 206, 244, NULL, 3, '2024-10-08 18:44:00', 2, '2024-10-19', 3, 'OT'),
(248, 22, 208, 240, NULL, 5, '2024-10-08 20:23:00', 4, '2024-10-18', 3, 'OT'),
(249, 7, 206, 286, 'COM20', 2, '2024-10-08 09:08:00', 2, '2024-10-28', 3, 'OT'),
(250, 21, 213, 221, 'COM10', 4, '2024-10-08 17:01:00', 4, '2024-10-15', 5, 'OT'),
(251, 17, 213, 254, NULL, 5, '2024-10-10 16:25:00', 3, '2024-10-21', 3, 'OT'),
(252, 16, 207, 268, 'OCT10', 4, '2024-10-10 22:09:00', 3, '2024-10-24', 3, 'OT'),
(253, 6, 105, 248, 'OCT15', 3, '2024-10-10 17:15:00', 1, '2024-10-20', 3, 'OT'),
(254, 5, 211, 220, NULL, 2, '2024-10-10 09:44:00', 2, '2024-10-14', 1, 'OT'),
(255, 8, 201, 252, 'OCT10', 3, '2024-10-11 13:43:00', 1, '2024-10-20', 3, 'OT'),
(256, 8, 207, 216, NULL, 3, '2024-10-11 17:29:00', 2, '2024-10-13', 2, 'OT'),
(257, 26, 207, 256, NULL, 5, '2024-10-11 11:43:00', 1, '2024-10-21', 2, 'OT'),
(258, 5, 206, 236, 'OCT10', 2, '2024-10-11 07:08:00', 3, '2024-10-17', 2, 'OT'),
(259, 15, 211, 277, NULL, 2, '2024-10-11 08:39:00', 2, '2024-10-26', 2, 'OT'),
(260, 25, 204, 291, NULL, 4, '2024-10-11 10:53:00', 2, '2024-10-29', 5, 'OT'),
(261, 27, 110, 295, NULL, 5, '2024-10-12 20:20:00', 1, '2024-10-30', 3, 'OT'),
(262, 4, 205, 225, NULL, 5, '2024-10-12 13:07:00', 1, '2024-10-15', 4, 'OT'),
(263, 24, 210, 278, NULL, 5, '2024-10-12 22:11:00', 4, '2024-10-26', 5, 'OT'),
(264, 1, 111, 304, 'NOV10', 2, '2024-10-12 22:28:00', 2, '2024-11-01', 6, 'OT'),
(265, 15, 106, 234, 'COM10', 5, '2024-10-12 08:29:00', 2, '2024-10-17', 5, 'OT'),
(266, 5, 211, 297, NULL, 2, '2024-10-12 18:01:00', 3, '2024-10-30', 3, 'OT'),
(267, 26, 102, 280, NULL, 5, '2024-10-12 14:43:00', 1, '2024-10-27', 1, 'OT'),
(268, 21, 207, 285, NULL, 5, '2024-10-13 20:57:00', 3, '2024-10-28', 3, 'OT'),
(269, 14, 108, 262, NULL, 3, '2024-10-13 11:12:00', 1, '2024-10-24', 3, 'OT'),
(270, 25, 205, 245, NULL, 5, '2024-10-13 11:44:00', 2, '2024-10-19', 5, 'OT'),
(271, 10, 105, 226, 'OCT10', 2, '2024-10-13 21:58:00', 1, '2024-10-15', 2, 'OT'),
(272, 12, 112, 279, NULL, 4, '2024-10-13 09:33:00', 1, '2024-10-26', 5, 'OT'),
(273, 29, 202, 298, NULL, 3, '2024-10-13 15:26:00', 2, '2024-10-30', 6, 'OT'),
(274, 8, 203, 237, 'OCT10', 4, '2024-10-14 10:54:00', 2, '2024-10-17', 2, 'OT'),
(275, 1, 211, 228, NULL, 5, '2024-10-14 15:04:00', 4, '2024-10-16', 2, 'OT'),
(276, 21, 108, 300, 'COM10', 5, '2024-10-14 18:43:00', 2, '2024-10-31', 3, 'OT'),
(277, 19, 103, 238, NULL, 2, '2024-10-14 18:33:00', 1, '2024-10-18', 4, 'OT'),
(278, 13, 205, 287, 'OCT15', 2, '2024-10-14 13:33:00', 2, '2024-10-28', 6, 'OT'),
(279, 10, 107, 296, NULL, 3, '2024-10-14 09:18:00', 2, '2024-10-30', 2, 'OT'),
(280, 15, 206, 269, NULL, 2, '2024-10-14 19:17:00', 3, '2024-10-24', 2, 'OT'),
(281, 9, 203, 274, NULL, 3, '2024-10-15 09:10:00', 1, '2024-10-25', 2, 'OT'),
(282, 7, 102, 232, NULL, 3, '2024-10-15 10:50:00', 1, '2024-10-17', 6, 'OT'),
(283, 28, 209, 318, NULL, 4, '2024-10-15 10:34:00', 1, '2024-11-04', 6, 'OT'),
(284, 14, 203, 243, NULL, 5, '2024-10-15 17:13:00', 2, '2024-10-19', 3, 'OT'),
(285, 19, 111, 261, 'OCT10', 5, '2024-10-15 13:07:00', 2, '2024-10-23', 4, 'OT'),
(286, 11, 202, 257, NULL, 2, '2024-10-15 13:16:00', 2, '2024-10-21', 5, 'OT'),
(287, 19, 111, 282, 'OCT10', 2, '2024-10-15 13:21:00', 2, '2024-10-27', 2, 'OT'),
(288, 7, 201, 311, 'COM10', 5, '2024-10-17 13:25:00', 2, '2024-11-03', 1, 'OT'),
(289, 2, 213, 301, NULL, 3, '2024-10-17 14:21:00', 4, '2024-10-31', 5, 'OT'),
(290, 11, 207, 309, NULL, 3, '2024-10-17 20:28:00', 2, '2024-11-02', 1, 'OT'),
(291, 12, 210, 265, NULL, 2, '2024-10-17 12:18:00', 2, '2024-10-24', 2, 'OT'),
(292, 16, 101, 321, 'NOV10', 3, '2024-10-17 15:49:00', 1, '2024-11-05', 2, 'OT'),
(293, 21, 201, 271, NULL, 5, '2024-10-17 09:51:00', 1, '2024-10-24', 1, 'OT'),
(294, 18, 208, 255, 'OCT15', 3, '2024-10-17 09:11:00', 3, '2024-10-21', 2, 'OT'),
(295, 25, 205, 319, 'COM10', 5, '2024-10-18 12:00:00', 1, '2024-11-04', 3, 'OT'),
(296, 18, 212, 264, 'OCT15', 5, '2024-10-18 21:10:00', 4, '2024-10-24', 2, 'OT'),
(297, 28, 106, 273, NULL, 2, '2024-10-18 12:14:00', 1, '2024-10-25', 6, 'OT'),
(298, 22, 209, 290, 'OCT10', 3, '2024-10-18 22:38:00', 3, '2024-10-29', 5, 'OT'),
(299, 27, 213, 324, 'COM20', 5, '2024-10-18 12:35:00', 4, '2024-11-06', 1, 'OT'),
(300, 11, 111, 294, NULL, 5, '2024-10-18 22:54:00', 1, '2024-10-29', 2, 'OT'),
(301, 5, 106, 306, NULL, 3, '2024-10-18 15:21:00', 1, '2024-11-02', 1, 'OT'),
(302, 30, 102, 315, 'NOV10', 3, '2024-10-18 10:18:00', 1, '2024-11-04', 3, 'OT'),
(303, 20, 201, 327, NULL, 2, '2024-10-18 21:55:00', 1, '2024-11-07', 3, 'OT'),
(304, 15, 212, 316, 'COM20', 4, '2024-10-19 22:45:00', 3, '2024-11-04', 1, 'OT'),
(305, 23, 107, 260, NULL, 4, '2024-10-19 15:32:00', 2, '2024-10-23', 3, 'OT'),
(306, 5, 112, 322, NULL, 4, '2024-10-19 16:18:00', 1, '2024-11-05', 2, 'OT'),
(307, 19, 203, 292, NULL, 5, '2024-10-19 08:29:00', 2, '2024-10-29', 2, 'OT'),
(308, 30, 212, 289, NULL, 4, '2024-10-19 11:01:00', 1, '2024-10-29', 4, 'OT'),
(309, 9, 107, 332, NULL, 2, '2024-10-19 08:15:00', 2, '2024-11-07', 3, 'OT'),
(310, 5, 213, 329, NULL, 5, '2024-10-21 09:00:00', 4, '2024-11-07', 4, 'OT'),
(311, 15, 108, 284, 'COM20', 3, '2024-10-21 17:52:00', 2, '2024-10-28', 3, 'OT'),
(312, 15, 205, 333, NULL, 4, '2024-10-21 08:19:00', 1, '2024-11-07', 3, 'OT'),
(313, 16, 105, 281, 'OCT10', 5, '2024-10-21 15:00:00', 2, '2024-10-27', 2, 'OT'),
(314, 30, 206, 350, NULL, 3, '2024-10-22 11:57:00', 1, '2024-11-11', 3, 'OT'),
(315, 20, 210, 317, NULL, 2, '2024-10-22 14:47:00', 3, '2024-11-04', 1, 'OT'),
(316, 2, 210, 340, NULL, 3, '2024-10-22 20:53:00', 4, '2024-11-10', 2, 'OT'),
(317, 21, 110, 330, NULL, 2, '2024-10-22 17:06:00', 1, '2024-11-07', 3, 'OT'),
(318, 20, 207, 342, NULL, 4, '2024-10-22 15:38:00', 4, '2024-11-10', 3, 'OT'),
(319, 5, 110, 272, NULL, 4, '2024-10-22 09:39:00', 1, '2024-10-25', 3, 'OT'),
(320, 4, 204, 320, NULL, 2, '2024-10-22 20:41:00', 1, '2024-11-04', 5, 'OT'),
(321, 8, 211, 331, 'NOV10', 2, '2024-10-24 18:03:00', 2, '2024-11-07', 1, 'OT'),
(322, 29, 110, 283, NULL, 3, '2024-10-24 11:38:00', 1, '2024-10-28', 1, 'OT'),
(323, 12, 201, 355, NULL, 2, '2024-10-24 19:50:00', 2, '2024-11-12', 2, 'OT'),
(324, 2, 107, 275, NULL, 2, '2024-10-24 17:03:00', 1, '2024-10-26', 2, 'OT'),
(325, 10, 208, 354, NULL, 5, '2024-10-24 08:24:00', 2, '2024-11-12', 3, 'OT'),
(326, 30, 210, 308, NULL, 4, '2024-10-24 09:14:00', 3, '2024-11-02', 1, 'OT'),
(327, 28, 206, 310, NULL, 3, '2024-10-25 15:03:00', 2, '2024-11-02', 2, 'OT'),
(328, 1, 103, 351, NULL, 5, '2024-10-25 21:38:00', 1, '2024-11-11', 1, 'OT'),
(329, 9, 112, 356, 'NOV10', 5, '2024-10-25 10:14:00', 2, '2024-11-12', 2, 'OT'),
(330, 18, 101, 293, NULL, 5, '2024-10-25 19:20:00', 1, '2024-10-29', 1, 'OT'),
(331, 7, 108, 314, NULL, 2, '2024-10-25 16:59:00', 1, '2024-11-04', 4, 'OT'),
(332, 10, 110, 305, 'NOV10', 3, '2024-10-26 07:32:00', 1, '2024-11-02', 3, 'OT'),
(333, 23, 110, 325, NULL, 3, '2024-10-26 09:10:00', 1, '2024-11-06', 1, 'OT'),
(334, 10, 208, 336, NULL, 4, '2024-10-27 11:39:00', 1, '2024-11-08', 2, 'OT'),
(335, 27, 209, 341, NULL, 2, '2024-10-27 20:46:00', 3, '2024-11-10', 2, 'OT'),
(336, 18, 201, 299, NULL, 3, '2024-10-27 14:18:00', 2, '2024-10-30', 3, 'OT'),
(337, 15, 208, 303, 'COM10', 5, '2024-10-27 15:56:00', 2, '2024-10-31', 1, 'OT'),
(338, 12, 110, 323, 'NOV10', 3, '2024-10-27 22:37:00', 2, '2024-11-05', 1, 'OT'),
(339, 19, 212, 347, NULL, 2, '2024-10-28 11:40:00', 2, '2024-11-11', 5, 'OT'),
(340, 23, 108, 357, NULL, 4, '2024-10-28 11:41:00', 1, '2024-11-13', 5, 'OT'),
(341, 25, 211, 335, 'COM10', 3, '2024-10-28 19:50:00', 4, '2024-11-08', 3, 'OT'),
(342, 6, 209, 367, NULL, 2, '2024-10-28 20:08:00', 1, '2024-11-16', 5, 'IN'),
(343, 18, 105, 366, NULL, 3, '2024-10-28 19:00:00', 1, '2024-11-16', 4, 'OT'),
(344, 14, 210, 362, NULL, 2, '2024-10-28 07:12:00', 1, '2024-11-14', 5, 'OT'),
(345, 8, 210, 302, 'OCT10', 4, '2024-10-28 09:40:00', 1, '2024-10-31', 2, 'OT'),
(346, 23, 211, 307, 'NOV10', 3, '2024-10-29 16:43:00', 4, '2024-11-02', 3, 'OT'),
(347, 22, 204, 338, NULL, 5, '2024-10-29 17:51:00', 2, '2024-11-09', 2, 'OT'),
(348, 12, 213, 380, 'NOV10', 4, '2024-10-29 17:46:00', 4, '2024-11-18', 7, 'IN'),
(349, 4, 206, 376, NULL, 3, '2024-10-29 10:25:00', 3, '2024-11-17', 1, 'OT'),
(350, 24, 212, 328, NULL, 3, '2024-10-29 10:26:00', 4, '2024-11-07', 3, 'OT'),
(351, 11, 205, 348, NULL, 5, '2024-10-29 10:23:00', 1, '2024-11-11', 2, 'OT'),
(352, 19, 208, 326, NULL, 4, '2024-10-29 08:13:00', 2, '2024-11-06', 2, 'OT'),
(353, 27, 208, 313, 'COM10', 3, '2024-10-30 20:37:00', 4, '2024-11-03', 2, 'OT'),
(354, 10, 212, 374, NULL, 2, '2024-10-30 08:01:00', 4, '2024-11-17', 3, 'OT'),
(355, 26, 106, 312, NULL, 5, '2024-11-01 09:12:00', 2, '2024-11-03', 2, 'OT'),
(356, 4, 107, 339, NULL, 4, '2024-11-01 16:18:00', 2, '2024-11-10', 1, 'OT'),
(357, 1, 205, 370, NULL, 2, '2024-11-01 21:57:00', 1, '2024-11-16', 3, 'OT'),
(358, 9, 204, 371, 'NOV10', 2, '2024-11-01 12:07:00', 2, '2024-11-16', 1, 'OT'),
(359, 14, 211, 352, NULL, 3, '2024-11-02 21:58:00', 1, '2024-11-12', 2, 'OT'),
(360, 30, 111, 382, NULL, 4, '2024-11-02 10:15:00', 1, '2024-11-18', 1, 'OT'),
(361, 29, 206, 369, 'NOV10', 3, '2024-11-02 11:50:00', 1, '2024-11-16', 1, 'OT'),
(362, 16, 203, NULL, 'NOV10', 4, '2024-11-04 10:48:00', 1, '2024-11-21', 3, 'RE'),
(363, 27, 205, 358, NULL, 5, '2024-11-04 09:12:00', 1, '2024-11-13', 1, 'OT'),
(364, 12, 211, 365, 'NOV10', 4, '2024-11-04 15:51:00', 2, '2024-11-15', 3, 'OT'),
(365, 28, 207, 368, NULL, 4, '2024-11-04 13:22:00', 4, '2024-11-16', 7, 'IN'),
(366, 21, 213, 360, NULL, 2, '2024-11-04 20:33:00', 4, '2024-11-14', 4, 'OT'),
(367, 28, 213, 346, 'NOV10', 4, '2024-11-04 18:36:00', 1, '2024-11-11', 3, 'OT'),
(368, 5, 206, NULL, NULL, 4, '2024-11-05 11:37:00', 4, '2024-11-21', 2, 'RE'),
(369, 27, 107, 363, NULL, 2, '2024-11-05 21:14:00', 2, '2024-11-14', 3, 'OT'),
(370, 22, 207, NULL, 'NOV10', 3, '2024-11-05 18:11:00', 4, '2024-11-24', 4, 'RE'),
(371, 16, 203, 334, 'NOV10', 3, '2024-11-05 21:43:00', 2, '2024-11-08', 1, 'OT'),
(372, 18, 111, 349, 'NOV10', 4, '2024-11-05 17:01:00', 2, '2024-11-11', 3, 'OT'),
(373, 26, 108, NULL, 'COM10', 4, '2024-11-05 13:57:00', 1, '2024-11-21', 6, 'RE'),
(374, 15, 210, 353, NULL, 5, '2024-11-06 12:56:00', 3, '2024-11-12', 1, 'OT'),
(375, 25, 208, 375, 'COM10', 5, '2024-11-06 10:48:00', 1, '2024-11-17', 2, 'OT'),
(376, 30, 211, 386, NULL, 5, '2024-11-06 19:52:00', 1, '2024-11-20', 1, 'IN'),
(377, 12, 206, 337, NULL, 5, '2024-11-06 22:42:00', 4, '2024-11-08', 3, 'OT'),
(378, 18, 210, NULL, 'NOV10', 2, '2024-11-08 13:16:00', 3, '2024-11-21', 3, 'RE'),
(379, 25, 211, NULL, NULL, 5, '2024-11-08 20:20:00', 3, '2024-11-22', 1, 'RE'),
(380, 1, 103, NULL, 'NOV10', 3, '2024-11-08 12:27:00', 1, '2024-11-21', 1, 'RE'),
(381, 21, 110, NULL, NULL, 5, '2024-11-08 17:46:00', 2, '2024-11-21', 3, 'RE'),
(382, 29, 202, NULL, 'NOV10', 2, '2024-11-09 07:42:00', 2, '2024-11-23', 2, 'RE'),
(383, 5, 110, 344, 'NOV10', 5, '2024-11-09 09:30:00', 1, '2024-11-11', 4, 'OT'),
(384, 2, 110, 385, NULL, 2, '2024-11-09 10:38:00', 1, '2024-11-20', 1, 'IN'),
(385, 1, 212, NULL, NULL, 5, '2024-11-09 19:36:00', 1, '2024-11-27', 4, 'RE'),
(386, 9, 208, 388, NULL, 2, '2024-11-09 15:12:00', 4, '2024-11-20', 2, 'IN'),
(387, 9, 208, 345, NULL, 3, '2024-11-09 18:46:00', 4, '2024-11-11', 1, 'OT'),
(388, 8, 108, 378, NULL, 4, '2024-11-09 09:31:00', 1, '2024-11-18', 2, 'OT'),
(389, 20, 111, NULL, NULL, 5, '2024-11-09 10:35:00', 2, '2024-11-25', 3, 'RE'),
(390, 3, 201, 359, 'COM20', 5, '2024-11-10 07:12:00', 2, '2024-11-14', 5, 'OT'),
(391, 19, 112, 373, NULL, 4, '2024-11-11 11:05:00', 1, '2024-11-16', 4, 'OT'),
(392, 20, 210, 387, 'COM10', 5, '2024-11-11 09:49:00', 2, '2024-11-20', 1, 'IN'),
(393, 20, 107, NULL, NULL, 4, '2024-11-11 17:40:00', 2, '2024-11-21', 2, 'RE'),
(394, 7, 106, NULL, NULL, 2, '2024-11-11 20:52:00', 2, '2024-11-24', 2, 'RE'),
(395, 3, 204, NULL, 'COM10', 4, '2024-11-11 16:31:00', 1, '2024-11-27', 2, 'RE'),
(396, 25, 213, NULL, NULL, 2, '2024-11-12 22:52:00', 4, '2024-12-02', 2, 'RE'),
(397, 12, 210, NULL, NULL, 5, '2024-11-12 11:57:00', 4, '2024-11-26', 7, 'RE'),
(398, 17, 204, 389, NULL, 2, '2024-11-12 08:09:00', 1, '2024-11-20', 3, 'IN'),
(399, 15, 204, 377, NULL, 5, '2024-11-12 18:09:00', 1, '2024-11-17', 2, 'OT'),
(400, 2, 106, 361, 'NOV10', 2, '2024-11-12 08:02:00', 1, '2024-11-14', 3, 'OT'),
(401, 13, 103, NULL, NULL, 4, '2024-11-12 22:37:00', 1, '2024-11-26', 6, 'RE'),
(402, 9, 209, NULL, NULL, 3, '2024-11-12 14:13:00', 3, '2024-11-22', 3, 'RE'),
(403, 20, 102, 364, NULL, 5, '2024-11-12 11:57:00', 1, '2024-11-14', 3, 'OT'),
(404, 13, 202, 372, NULL, 2, '2024-11-13 19:54:00', 1, '2024-11-16', 3, 'OT'),
(405, 23, 106, 379, NULL, 3, '2024-11-14 21:00:00', 1, '2024-11-18', 3, 'IN'),
(406, 10, 208, NULL, NULL, 3, '2024-11-14 20:09:00', 2, '2024-11-23', 1, 'RE'),
(407, 9, 211, 381, NULL, 2, '2024-11-14 16:58:00', 1, '2024-11-18', 2, 'OT'),
(408, 7, 211, NULL, 'COM10', 3, '2024-11-15 16:47:00', 4, '2024-11-26', 2, 'RE'),
(409, 20, 209, NULL, 'COM10', 4, '2024-11-15 16:42:00', 2, '2024-12-05', 3, 'RE'),
(410, 20, 105, NULL, NULL, 5, '2024-11-15 17:10:00', 1, '2024-11-30', 3, 'RE'),
(411, 13, 212, NULL, 'NOV10', 3, '2024-11-15 14:56:00', 2, '2024-11-22', 2, 'RE'),
(412, 22, 105, 384, 'NOV10', 2, '2024-11-15 21:03:00', 1, '2024-11-20', 2, 'IN'),
(413, 24, 206, NULL, NULL, 3, '2024-11-15 12:08:00', 3, '2024-11-24', 6, 'RE'),
(414, 30, 107, NULL, 'NOV10', 3, '2024-11-15 15:17:00', 2, '2024-11-29', 1, 'RE'),
(415, 6, 209, NULL, NULL, 4, '2024-11-16 09:14:00', 1, '2024-11-26', 3, 'RE'),
(416, 23, 211, NULL, NULL, 4, '2024-11-16 20:36:00', 3, '2024-12-02', 6, 'RE'),
(417, 30, 212, NULL, NULL, 4, '2024-11-16 14:50:00', 3, '2024-12-03', 2, 'RE'),
(418, 2, 106, NULL, NULL, 5, '2024-11-16 07:05:00', 1, '2024-11-21', 2, 'RE'),
(419, 25, 112, NULL, NULL, 2, '2024-11-16 22:27:00', 1, '2024-11-23', 5, 'RE'),
(420, 7, 210, 383, 'COM10', 2, '2024-11-16 14:47:00', 2, '2024-11-19', 1, 'OT'),
(421, 14, 213, NULL, NULL, 5, '2024-11-16 07:08:00', 2, '2024-11-27', 2, 'RE'),
(422, 6, 211, NULL, NULL, 3, '2024-11-16 15:55:00', 1, '2024-11-23', 3, 'RE'),
(423, 18, 111, NULL, NULL, 2, '2024-11-17 22:43:00', 1, '2024-12-07', 6, 'RE'),
(424, 15, 208, NULL, NULL, 2, '2024-11-17 22:19:00', 4, '2024-11-27', 1, 'RE'),
(425, 8, 108, NULL, 'NOV10', 4, '2024-11-18 12:18:00', 1, '2024-11-28', 1, 'RE'),
(426, 10, 201, NULL, NULL, 3, '2024-11-18 21:10:00', 2, '2024-12-04', 4, 'RE'),
(427, 7, 206, NULL, NULL, 4, '2024-11-18 10:52:00', 3, '2024-12-04', 1, 'RE'),
(428, 13, 112, NULL, 'DEC10', 5, '2024-11-18 10:57:00', 2, '2024-12-05', 6, 'RE'),
(429, 27, 213, NULL, NULL, 3, '2024-11-18 14:08:00', 1, '2024-11-29', 3, 'RE'),
(430, 18, 205, NULL, NULL, 5, '2024-11-18 07:51:00', 1, '2024-12-02', 2, 'RE'),
(431, 6, 212, NULL, NULL, 5, '2024-11-18 13:18:00', 2, '2024-12-08', 1, 'RE'),
(432, 10, 201, NULL, 'DEC10', 3, '2024-11-19 21:42:00', 2, '2024-12-02', 2, 'RE'),
(433, 15, 204, NULL, NULL, 4, '2024-11-19 13:41:00', 2, '2024-12-09', 1, 'RE'),
(434, 1, 212, NULL, NULL, 2, '2024-11-20 20:25:00', 2, '2024-12-01', 2, 'RE'),
(435, 25, 206, NULL, NULL, 3, '2024-11-23 08:00:00', 4, '2024-12-06', 3, 'RE'),
(436, 9, 208, NULL, NULL, 3, '2024-11-23 07:52:00', 3, '2024-11-29', 2, 'RE'),
(437, 16, 101, NULL, 'DEC10', 5, '2024-11-24 11:54:00', 1, '2024-12-04', 2, 'RE'),
(438, 3, 108, NULL, NULL, 3, '2024-11-25 17:03:00', 1, '2024-11-29', 2, 'RE'),
(439, 29, 213, NULL, NULL, 3, '2024-11-26 12:30:00', 3, '2024-12-09', 3, 'RE'),
(440, 1, 208, NULL, 'DEC10', 3, '2024-11-26 07:17:00', 1, '2024-12-07', 2, 'RE'),
(441, 3, 210, NULL, NULL, 5, '2024-11-26 07:45:00', 4, '2024-12-04', 4, 'RE'),
(442, 27, 108, NULL, 'COM10', 4, '2024-11-26 22:28:00', 2, '2024-12-02', 5, 'RE'),
(443, 5, 209, NULL, NULL, 5, '2024-11-26 12:44:00', 3, '2024-11-30', 3, 'RE'),
(444, 28, 207, NULL, NULL, 4, '2024-11-27 13:30:00', 3, '2024-12-08', 3, 'RE'),
(445, 11, 102, NULL, NULL, 3, '2024-11-27 11:19:00', 1, '2024-12-08', 1, 'RE'),
(446, 24, 208, NULL, NULL, 3, '2024-11-27 07:44:00', 2, '2024-12-03', 1, 'RE'),
(447, 16, 101, NULL, 'NOV10', 4, '2024-11-28 12:56:00', 1, '2024-11-30', 2, 'RE'),
(448, 15, 207, NULL, NULL, 2, '2024-11-28 16:36:00', 4, '2024-12-01', 5, 'RE'),
(449, 13, 112, NULL, 'DEC10', 5, '2024-11-28 16:20:00', 2, '2024-12-02', 1, 'RE'),
(450, 12, 107, NULL, 'DEC10', 2, '2024-11-28 14:36:00', 1, '2024-12-04', 2, 'RE'),
(451, 27, 107, NULL, NULL, 5, '2024-11-29 08:36:00', 1, '2024-12-08', 2, 'RE'),
(452, 24, 211, NULL, NULL, 2, '2024-11-29 18:02:00', 3, '2024-12-08', 1, 'RE'),
(453, 21, 110, NULL, NULL, 5, '2024-11-29 07:25:00', 1, '2024-12-06', 2, 'RE'),
(454, 25, 208, NULL, 'COM10', 2, '2024-12-01 16:25:00', 1, '2024-12-04', 2, 'RE'),
(455, 22, 103, NULL, NULL, 3, '2024-12-02 19:52:00', 1, '2024-12-08', 6, 'RE'),
(456, 23, 209, NULL, 'DEC10', 3, '2024-12-02 22:47:00', 3, '2024-12-08', 5, 'RE'),
(457, 2, 108, NULL, 'DEC10', 2, '2024-12-03 22:04:00', 1, '2024-12-08', 3, 'RE'),
(458, 8, 212, NULL, NULL, 5, '2024-12-03 14:18:00', 2, '2024-12-09', 3, 'RE'),
(459, 7, 213, NULL, 'COM10', 5, '2024-12-03 13:11:00', 3, '2024-12-07', 2, 'RE'),
(460, 9, 107, NULL, NULL, 4, '2024-12-04 15:27:00', 2, '2024-12-07', 1, 'RE'),
(461, 17, 205, NULL, NULL, 2, '2024-12-05 10:16:00', 2, '2024-12-07', 3, 'RE'),
(462, 12, 203, NULL, NULL, 3, '2024-12-05 18:31:00', 1, '2024-12-07', 4, 'RE'),
(463, 14, 211, NULL, 'COM20', 2, '2024-12-07 17:40:00', 4, '2024-12-09', 4, 'RE');

INSERT INTO staff (staff_id, manager_id, title, first_name, last_name, role) VALUES
(1, NULL, 'Mr', 'Simon', 'Rumsey', 'OWNER'),
(2, 1, 'Mrs', 'Jill', 'Smithers', 'RECEP_LEAD'),
(3, 2, 'Mr', 'James', 'Dilly', 'RECEP'),
(4, 2, 'Miss', 'Heather', 'Lewis', 'RECEP'),
(5, 2, 'Ms', 'Vicki', 'Green', 'RECEP'),
(6, 1, 'Mr', 'Stuart', 'Sanders', 'CLEAN_LEAD'),
(7, 6, 'Miss', 'Paula', 'Jones', 'CLEAN'),
(8, 6, 'Miss', 'Holly', 'Adams', 'CLEAN'),
(9, 6, 'Mr', 'Jack', 'York', 'CLEAN');

INSERT INTO room_type (room_type_code, room_type_name, modern_style, deluxe, maximum_guests) VALUES
('SI', 'Single', 0, 0, 1),
('SIM', 'Single Plus', 1, 0, 1),
('SIP', 'Single Premium', 0, 1, 1),
('DO', 'Double', 0, 0, 2),
('DOM', 'Double Plus', 1, 0, 2),
('DOP', 'Double Premium', 0, 1, 2),
('DOE', 'Double Executive', 1, 1, 2),
('TW', 'Twin', 0, 0, 2),
('TWE', 'Twin Executive', 1, 1, 2),
('FA', 'Family', 0, 0, 4),
('FAM', 'Family Plus', 1, 0, 4),
('FAP', 'Family Premium', 0, 1, 4),
('SUP', 'Suite Premium', 0, 1, 4),
('SUE', 'Suite Executive', 1, 1, 6);

INSERT INTO bathroom_type (bathroom_type_code, bathroom_type_name, seperate_shower, bath) VALUES
('B1', 'Shower Only', 1, 0),
('B2', 'Small', 0, 1),
('B3', 'Deluxe Bathroom', 1, 1),
('B4', 'Executive', 1, 1);

INSERT INTO room_price (room_type_code, bathroom_type_code, price) VALUES
('SI', 'B1', 60),
('SI', 'B2', 65),
('SIM', 'B2', 70),
('SIM', 'B3', 75),
('SIP', 'B2', 75),
('SIP', 'B3', 85),
('DO', 'B1', 80),
('DO', 'B2', 85),
('DOM', 'B1', 90),
('DOM', 'B2', 95),
('DOP', 'B3', 105),
('DOP', 'B4', 110),
('DOE', 'B4', 120),
('TW', 'B1', 75),
('TW', 'B2', 80),
('TWE', 'B4', 115),
('FA', 'B1', 100),
('FA', 'B3', 110),
('FAM', 'B2', 110),
('FAP', 'B2', 115),
('FAP', 'B3', 120),
('SUP', 'B3', 140),
('SUP', 'B4', 150),
('SUE', 'B4', 180);

INSERT INTO room (room_number, room_type_code, bathroom_type_code, status, key_serial_number) VALUES
(101, 'SI', 'B1', 'ACT', 'ABC12312'),
(102, 'SI', 'B2', 'ACT', 'BSD21432'),
(103, 'SIM', 'B3', 'ACT', 'JGF34673'),
(104, 'SIP', 'B2', 'CLN', 'PEH23563'),
(105, 'DO', 'B1', 'ACT', 'LWB32454'),
(106, 'DO', 'B2', 'ACT', 'MMD12134'),
(107, 'DOM', 'B1', 'ACT', 'FHG33445'),
(108, 'DOM', 'B2', 'ACT', 'OKD45563'),
(109, 'DOP', 'B3', 'CLN', 'KRW11465'),
(110, 'DOP', 'B3', 'ACT', 'KSJ73423'),
(111, 'DOP', 'B4', 'ACT', 'SSW22453'),
(112, 'DOE', 'B4', 'ACT', 'YTT22432'),
(201, 'DOE', 'B4', 'ACT', 'BBS11223'),
(202, 'TW', 'B1', 'ACT', 'GGS55442'),
(203, 'TW', 'B2', 'ACT', 'HHD11543'),
(204, 'TWE', 'B4', 'ACT', 'ZXX35672'),
(205, 'TWE', 'B4', 'ACT', 'SDD24341'),
(206, 'FA', 'B1', 'ACT', 'KKG66552'),
(207, 'FA', 'B3', 'ACT', 'LLI12343'),
(208, 'FAM', 'B2', 'ACT', 'PWK33221'),
(209, 'FAP', 'B2', 'ACT', 'LXC66876'),
(210, 'FAP', 'B3', 'ACT', 'LXC66876'),
(211, 'SUP', 'B3', 'ACT', 'LXC66876'),
(212, 'SUP', 'B4', 'ACT', 'LXC66876'),
(213, 'SUE', 'B4', 'ACT', 'LXC66876');

INSERT INTO complaint_category (category_code, category_name, severity) VALUES
('NO1', 'Noise', 2),
('NO2', 'Constant Noise', 4),
('RM1', 'Room Condition', 3),
('RM2', 'Bad Room Condition', 5),
('CS1', 'Poor Customer Service', 2),
('CS2', 'Slow Customer Service', 3),
('CS3', 'Rude Customer Service', 5),
('RE1', 'Reservation Issue', 3),
('RE2', 'Billing Query', 1),
('RE3', 'Billing Dispute', 5),
('SA1', 'Minor Safety Concern', 4),
('SA2', 'Major Safety Issue', 8),
('WI1', 'Wi-Fi Connection Issue', 3),
('WI2', 'Slow Wi-Fi', 2),
('EM1', 'Electrical Issue', 5),
('PL1', 'Plumbing Issue', 5),
('PR1', 'Parking Issue', 3),
('RS1', 'Unhappy With Room Size', 3),
('SM1', 'Smell outside the room', 2),
('SM2', 'Smell inside the room', 4);

INSERT INTO complaint (reservation_id, opened_date, category_code, opened_by, description) VALUES
(1, '2024-10-22 01:10:00', 'NO2', 3, 'Loud music from the next room during the night.'),
(1, '2024-10-23 09:15:00', 'RE2', 4, 'Discount not as big as expected.'),
(2, '2024-10-24 17:40:00', 'RM2', 4, 'Bathroom is not clean.'),
(16, '2024-08-16 06:44:00', 'CS1', 5, 'Complaint created as test data for reservation 16'),
(7, '2024-08-18 09:14:00', 'RE2', 2, 'Complaint created as test data for reservation 7'),
(17, '2024-08-18 05:59:00', 'SM2', 2, 'Complaint created as test data for reservation 17'),
(34, '2024-08-21 06:24:00', 'WI2', 2, 'Complaint created as test data for reservation 34'),
(13, '2024-08-24 09:01:00', 'CS3', 2, 'Complaint created as test data for reservation 13'),
(22, '2024-08-28 07:52:00', 'RE2', 4, 'Complaint created as test data for reservation 22'),
(45, '2024-08-29 07:47:00', 'CS1', 2, 'Complaint created as test data for reservation 45'),
(26, '2024-09-06 06:03:00', 'RE2', 5, 'Complaint created as test data for reservation 26'),
(66, '2024-09-07 06:09:00', 'SM2', 5, 'Complaint created as test data for reservation 66'),
(43, '2024-09-08 07:39:00', 'RE3', 2, 'Complaint created as test data for reservation 43'),
(89, '2024-09-09 09:13:00', 'SM2', 4, 'Complaint created as test data for reservation 89'),
(120, '2024-09-10 05:54:00', 'NO1', 5, 'Complaint created as test data for reservation 120'),
(80, '2024-09-10 07:42:00', 'SM1', 2, 'Complaint created as test data for reservation 80'),
(75, '2024-09-10 09:14:00', 'CS1', 3, 'Complaint created as test data for reservation 75'),
(64, '2024-09-12 08:45:00', 'SM1', 2, 'Complaint created as test data for reservation 64'),
(67, '2024-09-13 06:42:00', 'WI1', 3, 'Complaint created as test data for reservation 67'),
(105, '2024-09-14 05:56:00', 'NO1', 3, 'Complaint created as test data for reservation 105'),
(119, '2024-09-14 08:52:00', 'CS3', 4, 'Complaint created as test data for reservation 119'),
(85, '2024-09-17 08:59:00', 'SA2', 2, 'Complaint created as test data for reservation 85'),
(174, '2024-10-03 05:48:00', 'RS1', 3, 'Complaint created as test data for reservation 174'),
(169, '2024-10-03 08:01:00', 'RM1', 4, 'Complaint created as test data for reservation 169'),
(162, '2024-10-03 08:22:00', 'RE1', 3, 'Complaint created as test data for reservation 162'),
(187, '2024-10-04 05:35:00', 'RE2', 4, 'Complaint created as test data for reservation 187'),
(208, '2024-10-06 09:06:00', 'RE2', 4, 'Complaint created as test data for reservation 208'),
(222, '2024-10-07 05:43:00', 'RE1', 5, 'Complaint created as test data for reservation 222'),
(178, '2024-10-07 06:24:00', 'RM2', 2, 'Complaint created as test data for reservation 178'),
(199, '2024-10-07 08:32:00', 'PL1', 3, 'Complaint created as test data for reservation 199'),
(230, '2024-10-07 06:11:00', 'SM1', 3, 'Complaint created as test data for reservation 230'),
(184, '2024-10-12 08:42:00', 'WI2', 4, 'Complaint created as test data for reservation 184'),
(217, '2024-10-13 05:37:00', 'SA2', 3, 'Complaint created as test data for reservation 217'),
(196, '2024-10-16 06:05:00', 'RS1', 3, 'Complaint created as test data for reservation 196'),
(229, '2024-10-17 08:51:00', 'CS1', 4, 'Complaint created as test data for reservation 229'),
(240, '2024-10-18 09:03:00', 'SM2', 3, 'Complaint created as test data for reservation 240'),
(209, '2024-10-19 06:52:00', 'PR1', 4, 'Complaint created as test data for reservation 209'),
(205, '2024-10-20 07:19:00', 'WI2', 4, 'Complaint created as test data for reservation 205'),
(238, '2024-10-21 08:45:00', 'CS1', 5, 'Complaint created as test data for reservation 238'),
(215, '2024-10-21 07:37:00', 'CS1', 5, 'Complaint created as test data for reservation 215'),
(253, '2024-10-23 08:26:00', 'EM1', 2, 'Complaint created as test data for reservation 253'),
(294, '2024-10-23 05:53:00', 'RE1', 3, 'Complaint created as test data for reservation 294'),
(210, '2024-10-25 09:21:00', 'RM1', 4, 'Complaint created as test data for reservation 210'),
(244, '2024-10-27 07:41:00', 'WI2', 3, 'Complaint created as test data for reservation 244'),
(287, '2024-10-29 05:53:00', 'RM1', 5, 'Complaint created as test data for reservation 287'),
(2, '2024-10-31 05:57:00', 'SM1', 4, 'Complaint created as test data for reservation 2'),
(268, '2024-10-31 09:04:00', 'NO1', 5, 'Complaint created as test data for reservation 268'),
(249, '2024-10-31 08:21:00', 'PL1', 4, 'Complaint created as test data for reservation 249'),
(336, '2024-11-02 08:26:00', 'EM1', 4, 'Complaint created as test data for reservation 336'),
(301, '2024-11-03 05:46:00', 'RM2', 5, 'Complaint created as test data for reservation 301'),
(326, '2024-11-03 06:14:00', 'NO2', 4, 'Complaint created as test data for reservation 326'),
(289, '2024-11-05 07:18:00', 'RE2', 4, 'Complaint created as test data for reservation 289'),
(332, '2024-11-05 06:40:00', 'WI1', 5, 'Complaint created as test data for reservation 332'),
(355, '2024-11-05 05:52:00', 'WI2', 5, 'Complaint created as test data for reservation 355'),
(315, '2024-11-05 08:16:00', 'RE1', 5, 'Complaint created as test data for reservation 315'),
(302, '2024-11-07 05:36:00', 'EM1', 3, 'Complaint created as test data for reservation 302'),
(283, '2024-11-10 06:53:00', 'WI2', 5, 'Complaint created as test data for reservation 283'),
(309, '2024-11-10 09:05:00', 'NO1', 3, 'Complaint created as test data for reservation 309'),
(334, '2024-11-10 06:02:00', 'CS3', 4, 'Complaint created as test data for reservation 334'),
(310, '2024-11-11 06:29:00', 'WI1', 4, 'Complaint created as test data for reservation 310'),
(316, '2024-11-12 08:39:00', 'NO2', 5, 'Complaint created as test data for reservation 316'),
(335, '2024-11-12 06:38:00', 'CS3', 4, 'Complaint created as test data for reservation 335'),
(328, '2024-11-12 06:15:00', 'SA2', 3, 'Complaint created as test data for reservation 328'),
(318, '2024-11-13 09:28:00', 'PL1', 5, 'Complaint created as test data for reservation 318'),
(323, '2024-11-14 08:59:00', 'WI1', 4, 'Complaint created as test data for reservation 323'),
(5, '2024-11-16 08:41:00', 'RE2', 2, 'Complaint created as test data for reservation 5'),
(404, '2024-11-19 05:49:00', 'CS1', 4, 'Complaint created as test data for reservation 404'),
(420, '2024-11-20 07:15:00', 'RE2', 3, 'Complaint created as test data for reservation 420');

INSERT INTO complaint_resolution (reservation_id, opened_date, resolved_by, resolution, resolution_date) VALUES
(1, '2024-10-22 01:10:00', 3, 'Visited the room making the noise. They switched off the radio and apologised', '2024-10-22 01:15:00'),
(1, '2024-10-23 09:15:00', 2, 'Explained that a 10% promotion code had been used. Guest thought it was 15%. Guest satisfied', '2024-10-23 09:45:00'),
(2, '2024-10-24 17:40:00', 5, 'Sent cleaner to the room immediately and gave guest a free drink while waiting', '2024-10-24 18:30:00'),
(16, '2024-08-16 06:44:00', 5, 'Complaint resolved as test data for reservation 16', '2024-08-16 07:21:00'),
(7, '2024-08-18 09:14:00', 2, 'Complaint resolved as test data for reservation 7', '2024-08-18 09:51:00'),
(17, '2024-08-18 05:59:00', 2, 'Complaint resolved as test data for reservation 17', '2024-08-18 06:36:00'),
(34, '2024-08-21 06:24:00', 2, 'Complaint resolved as test data for reservation 34', '2024-08-21 07:01:00'),
(13, '2024-08-24 09:01:00', 2, 'Complaint resolved as test data for reservation 13', '2024-08-24 09:38:00'),
(22, '2024-08-28 07:52:00', 4, 'Complaint resolved as test data for reservation 22', '2024-08-28 08:29:00'),
(45, '2024-08-29 07:47:00', 2, 'Complaint resolved as test data for reservation 45', '2024-08-29 08:24:00'),
(26, '2024-09-06 06:03:00', 5, 'Complaint resolved as test data for reservation 26', '2024-09-06 06:40:00'),
(66, '2024-09-07 06:09:00', 5, 'Complaint resolved as test data for reservation 66', '2024-09-07 06:46:00'),
(43, '2024-09-08 07:39:00', 2, 'Complaint resolved as test data for reservation 43', '2024-09-08 08:16:00'),
(89, '2024-09-09 09:13:00', 4, 'Complaint resolved as test data for reservation 89', '2024-09-09 09:50:00'),
(120, '2024-09-10 05:54:00', 5, 'Complaint resolved as test data for reservation 120', '2024-09-10 06:31:00'),
(80, '2024-09-10 07:42:00', 2, 'Complaint resolved as test data for reservation 80', '2024-09-10 08:19:00'),
(75, '2024-09-10 09:14:00', 3, 'Complaint resolved as test data for reservation 75', '2024-09-10 09:51:00'),
(64, '2024-09-12 08:45:00', 2, 'Complaint resolved as test data for reservation 64', '2024-09-12 09:22:00'),
(67, '2024-09-13 06:42:00', 3, 'Complaint resolved as test data for reservation 67', '2024-09-13 07:19:00'),
(105, '2024-09-14 05:56:00', 3, 'Complaint resolved as test data for reservation 105', '2024-09-14 06:33:00'),
(119, '2024-09-14 08:52:00', 4, 'Complaint resolved as test data for reservation 119', '2024-09-14 09:29:00'),
(85, '2024-09-17 08:59:00', 2, 'Complaint resolved as test data for reservation 85', '2024-09-17 09:36:00'),
(174, '2024-10-03 05:48:00', 3, 'Complaint resolved as test data for reservation 174', '2024-10-03 06:25:00'),
(169, '2024-10-03 08:01:00', 4, 'Complaint resolved as test data for reservation 169', '2024-10-03 08:38:00'),
(162, '2024-10-03 08:22:00', 3, 'Complaint resolved as test data for reservation 162', '2024-10-03 08:59:00'),
(187, '2024-10-04 05:35:00', 4, 'Complaint resolved as test data for reservation 187', '2024-10-04 06:12:00'),
(208, '2024-10-06 09:06:00', 4, 'Complaint resolved as test data for reservation 208', '2024-10-06 09:43:00'),
(222, '2024-10-07 05:43:00', 5, 'Complaint resolved as test data for reservation 222', '2024-10-07 06:20:00'),
(178, '2024-10-07 06:24:00', 2, 'Complaint resolved as test data for reservation 178', '2024-10-07 07:01:00'),
(199, '2024-10-07 08:32:00', 3, 'Complaint resolved as test data for reservation 199', '2024-10-07 09:09:00'),
(230, '2024-10-07 06:11:00', 3, 'Complaint resolved as test data for reservation 230', '2024-10-07 06:48:00'),
(184, '2024-10-12 08:42:00', 4, 'Complaint resolved as test data for reservation 184', '2024-10-12 09:19:00'),
(217, '2024-10-13 05:37:00', 3, 'Complaint resolved as test data for reservation 217', '2024-10-13 06:14:00'),
(196, '2024-10-16 06:05:00', 3, 'Complaint resolved as test data for reservation 196', '2024-10-16 06:42:00'),
(229, '2024-10-17 08:51:00', 4, 'Complaint resolved as test data for reservation 229', '2024-10-17 09:28:00'),
(240, '2024-10-18 09:03:00', 3, 'Complaint resolved as test data for reservation 240', '2024-10-18 09:40:00'),
(209, '2024-10-19 06:52:00', 4, 'Complaint resolved as test data for reservation 209', '2024-10-19 07:29:00'),
(205, '2024-10-20 07:19:00', 4, 'Complaint resolved as test data for reservation 205', '2024-10-20 07:56:00'),
(238, '2024-10-21 08:45:00', 5, 'Complaint resolved as test data for reservation 238', '2024-10-21 09:22:00'),
(215, '2024-10-21 07:37:00', 5, 'Complaint resolved as test data for reservation 215', '2024-10-21 08:14:00'),
(253, '2024-10-23 08:26:00', 2, 'Complaint resolved as test data for reservation 253', '2024-10-23 09:03:00'),
(294, '2024-10-23 05:53:00', 3, 'Complaint resolved as test data for reservation 294', '2024-10-23 06:30:00'),
(210, '2024-10-25 09:21:00', 4, 'Complaint resolved as test data for reservation 210', '2024-10-25 09:58:00'),
(244, '2024-10-27 07:41:00', 3, 'Complaint resolved as test data for reservation 244', '2024-10-27 08:18:00'),
(287, '2024-10-29 05:53:00', 5, 'Complaint resolved as test data for reservation 287', '2024-10-29 06:30:00'),
(2, '2024-10-31 05:57:00', 4, 'Complaint resolved as test data for reservation 2', '2024-10-31 06:34:00'),
(268, '2024-10-31 09:04:00', 5, 'Complaint resolved as test data for reservation 268', '2024-10-31 09:41:00'),
(249, '2024-10-31 08:21:00', 4, 'Complaint resolved as test data for reservation 249', '2024-10-31 08:58:00'),
(336, '2024-11-02 08:26:00', 4, 'Complaint resolved as test data for reservation 336', '2024-11-02 09:03:00'),
(301, '2024-11-03 05:46:00', 5, 'Complaint resolved as test data for reservation 301', '2024-11-03 06:23:00'),
(326, '2024-11-03 06:14:00', 4, 'Complaint resolved as test data for reservation 326', '2024-11-03 06:51:00'),
(289, '2024-11-05 07:18:00', 4, 'Complaint resolved as test data for reservation 289', '2024-11-05 07:55:00'),
(332, '2024-11-05 06:40:00', 5, 'Complaint resolved as test data for reservation 332', '2024-11-05 07:17:00'),
(355, '2024-11-05 05:52:00', 5, 'Complaint resolved as test data for reservation 355', '2024-11-05 06:29:00'),
(315, '2024-11-05 08:16:00', 5, 'Complaint resolved as test data for reservation 315', '2024-11-05 08:53:00'),
(302, '2024-11-07 05:36:00', 3, 'Complaint resolved as test data for reservation 302', '2024-11-07 06:13:00'),
(283, '2024-11-10 06:53:00', 5, 'Complaint resolved as test data for reservation 283', '2024-11-10 07:30:00'),
(309, '2024-11-10 09:05:00', 3, 'Complaint resolved as test data for reservation 309', '2024-11-10 09:42:00'),
(334, '2024-11-10 06:02:00', 4, 'Complaint resolved as test data for reservation 334', '2024-11-10 06:39:00'),
(310, '2024-11-11 06:29:00', 4, 'Complaint resolved as test data for reservation 310', '2024-11-11 07:06:00'),
(316, '2024-11-12 08:39:00', 5, 'Complaint resolved as test data for reservation 316', '2024-11-12 09:16:00'),
(335, '2024-11-12 06:38:00', 4, 'Complaint resolved as test data for reservation 335', '2024-11-12 07:15:00'),
(328, '2024-11-12 06:15:00', 3, 'Complaint resolved as test data for reservation 328', '2024-11-12 06:52:00'),
(318, '2024-11-13 09:28:00', 5, 'Complaint resolved as test data for reservation 318', '2024-11-13 10:05:00'),
(323, '2024-11-14 08:59:00', 4, 'Complaint resolved as test data for reservation 323', '2024-11-14 09:36:00'),
(5, '2024-11-16 08:41:00', 2, 'Complaint resolved as test data for reservation 5', '2024-11-16 09:18:00'),
(404, '2024-11-19 05:49:00', 4, 'Complaint resolved as test data for reservation 404', '2024-11-19 06:26:00'),
(420, '2024-11-20 07:15:00', 3, 'Complaint resolved as test data for reservation 420', '2024-11-20 07:52:00');

INSERT INTO check_in (reservation_id, staff_id, date_time, notes) VALUES
(1, 2, '2024-10-21 16:14:00', NULL),
(2, 4, '2024-10-24 14:05:00', 'guest asked about the security of the car park'),
(3, 3, '2024-10-25 15:18:00', NULL),
(4, 3, '2024-10-26 18:51:00', 'advised guest about local restaurants'),
(7, 4, '2024-08-13 13:47:00', NULL),
(16, 4, '2024-08-14 21:45:00', NULL),
(17, 2, '2024-08-15 15:23:00', NULL),
(18, 2, '2024-08-15 21:27:00', 'This check-in for reservation 18 captured some notes as test data.'),
(6, 5, '2024-08-16 19:46:00', 'This check-in for reservation 6 captured some notes as test data.'),
(25, 4, '2024-08-16 14:13:00', NULL),
(19, 2, '2024-08-17 15:04:00', NULL),
(34, 2, '2024-08-17 13:37:00', NULL),
(23, 3, '2024-08-19 13:36:00', NULL),
(32, 3, '2024-08-19 20:12:00', NULL),
(11, 2, '2024-08-19 17:22:00', NULL),
(15, 4, '2024-08-20 15:41:00', NULL),
(41, 3, '2024-08-20 16:06:00', 'This check-in for reservation 41 captured some notes as test data.'),
(14, 5, '2024-08-20 18:36:00', NULL),
(29, 3, '2024-08-20 14:12:00', 'This check-in for reservation 29 captured some notes as test data.'),
(33, 2, '2024-08-21 21:42:00', NULL),
(10, 2, '2024-08-21 22:49:00', NULL),
(57, 2, '2024-08-22 18:24:00', NULL),
(24, 2, '2024-08-22 18:15:00', 'This check-in for reservation 24 captured some notes as test data.'),
(63, 2, '2024-08-23 15:03:00', NULL),
(12, 4, '2024-08-23 20:29:00', NULL),
(9, 2, '2024-08-23 13:10:00', NULL),
(13, 2, '2024-08-23 15:07:00', NULL),
(8, 5, '2024-08-24 15:25:00', NULL),
(40, 5, '2024-08-25 14:51:00', NULL),
(53, 2, '2024-08-25 19:53:00', NULL),
(22, 4, '2024-08-25 15:27:00', 'This check-in for reservation 22 captured some notes as test data.'),
(59, 4, '2024-08-25 15:03:00', NULL),
(28, 3, '2024-08-25 14:31:00', NULL),
(45, 4, '2024-08-25 18:30:00', NULL),
(61, 3, '2024-08-26 15:33:00', 'This check-in for reservation 61 captured some notes as test data.'),
(37, 3, '2024-08-26 14:25:00', NULL),
(20, 5, '2024-08-26 16:28:00', 'This check-in for reservation 20 captured some notes as test data.'),
(52, 4, '2024-08-26 14:12:00', NULL),
(36, 5, '2024-08-26 17:06:00', NULL),
(48, 5, '2024-08-27 14:35:00', NULL),
(72, 4, '2024-08-27 14:01:00', NULL),
(38, 2, '2024-08-27 17:04:00', NULL),
(62, 4, '2024-08-28 13:19:00', NULL),
(21, 5, '2024-08-28 19:09:00', NULL),
(69, 4, '2024-08-29 17:25:00', NULL),
(77, 4, '2024-08-29 17:13:00', NULL),
(56, 4, '2024-08-30 19:16:00', 'This check-in for reservation 56 captured some notes as test data.'),
(55, 5, '2024-08-30 14:30:00', NULL),
(46, 5, '2024-08-31 13:25:00', 'This check-in for reservation 46 captured some notes as test data.'),
(39, 4, '2024-08-31 19:59:00', NULL),
(27, 5, '2024-08-31 17:38:00', NULL),
(74, 4, '2024-09-01 13:35:00', NULL),
(44, 5, '2024-09-01 15:55:00', NULL),
(31, 2, '2024-09-01 19:25:00', 'This check-in for reservation 31 captured some notes as test data.'),
(42, 3, '2024-09-01 14:00:00', NULL),
(66, 2, '2024-09-02 14:38:00', NULL),
(70, 5, '2024-09-02 15:46:00', NULL),
(51, 5, '2024-09-02 15:34:00', NULL),
(43, 3, '2024-09-02 20:47:00', NULL),
(35, 3, '2024-09-02 15:24:00', NULL),
(49, 5, '2024-09-02 13:56:00', NULL),
(30, 4, '2024-09-03 20:51:00', 'This check-in for reservation 30 captured some notes as test data.'),
(90, 5, '2024-09-03 22:42:00', NULL),
(26, 2, '2024-09-03 20:35:00', 'This check-in for reservation 26 captured some notes as test data.'),
(50, 2, '2024-09-03 18:37:00', NULL),
(76, 5, '2024-09-04 18:38:00', 'This check-in for reservation 76 captured some notes as test data.'),
(82, 4, '2024-09-04 18:58:00', NULL),
(93, 3, '2024-09-04 18:22:00', NULL),
(91, 5, '2024-09-04 15:24:00', NULL),
(54, 3, '2024-09-04 15:17:00', NULL),
(58, 3, '2024-09-05 17:05:00', 'This check-in for reservation 58 captured some notes as test data.'),
(60, 3, '2024-09-05 16:06:00', NULL),
(65, 5, '2024-09-05 18:12:00', NULL),
(88, 4, '2024-09-06 16:40:00', 'This check-in for reservation 88 captured some notes as test data.'),
(89, 3, '2024-09-06 20:47:00', NULL),
(47, 5, '2024-09-06 19:09:00', NULL),
(78, 4, '2024-09-06 16:49:00', NULL),
(86, 5, '2024-09-06 21:54:00', NULL),
(64, 3, '2024-09-07 16:52:00', NULL),
(104, 5, '2024-09-07 22:25:00', NULL),
(73, 5, '2024-09-07 17:06:00', NULL),
(95, 2, '2024-09-07 20:11:00', NULL),
(101, 2, '2024-09-07 19:33:00', NULL),
(120, 3, '2024-09-07 14:32:00', 'This check-in for reservation 120 captured some notes as test data.'),
(80, 4, '2024-09-08 13:14:00', NULL),
(123, 4, '2024-09-08 14:31:00', NULL),
(106, 5, '2024-09-08 22:28:00', NULL),
(111, 4, '2024-09-09 22:09:00', NULL),
(126, 2, '2024-09-09 18:57:00', NULL),
(75, 3, '2024-09-09 22:57:00', NULL),
(105, 5, '2024-09-09 21:38:00', NULL),
(94, 5, '2024-09-09 19:22:00', NULL),
(128, 3, '2024-09-10 14:55:00', 'This check-in for reservation 128 captured some notes as test data.'),
(118, 2, '2024-09-10 20:48:00', NULL),
(113, 3, '2024-09-10 14:06:00', NULL),
(117, 2, '2024-09-10 14:38:00', NULL),
(133, 3, '2024-09-11 21:01:00', NULL),
(68, 5, '2024-09-11 13:05:00', NULL),
(67, 5, '2024-09-11 17:21:00', NULL),
(125, 5, '2024-09-11 13:22:00', 'This check-in for reservation 125 captured some notes as test data.'),
(119, 5, '2024-09-11 19:40:00', NULL),
(129, 3, '2024-09-11 17:26:00', NULL),
(108, 3, '2024-09-11 22:39:00', NULL),
(71, 3, '2024-09-12 15:19:00', NULL),
(112, 4, '2024-09-12 20:20:00', 'This check-in for reservation 112 captured some notes as test data.'),
(81, 4, '2024-09-12 13:38:00', NULL),
(110, 4, '2024-09-12 21:55:00', NULL),
(79, 4, '2024-09-13 22:59:00', 'This check-in for reservation 79 captured some notes as test data.'),
(98, 4, '2024-09-13 14:57:00', NULL),
(85, 4, '2024-09-14 21:31:00', NULL),
(142, 3, '2024-09-14 18:34:00', 'This check-in for reservation 142 captured some notes as test data.'),
(92, 5, '2024-09-14 16:21:00', 'This check-in for reservation 92 captured some notes as test data.'),
(114, 3, '2024-09-14 14:10:00', NULL),
(109, 5, '2024-09-14 20:04:00', 'This check-in for reservation 109 captured some notes as test data.'),
(127, 3, '2024-09-14 14:21:00', NULL),
(136, 3, '2024-09-15 13:58:00', NULL),
(100, 5, '2024-09-15 15:30:00', NULL),
(107, 4, '2024-09-15 15:45:00', 'This check-in for reservation 107 captured some notes as test data.'),
(84, 4, '2024-09-16 14:47:00', NULL),
(103, 3, '2024-09-16 19:22:00', NULL),
(147, 3, '2024-09-16 21:48:00', 'This check-in for reservation 147 captured some notes as test data.'),
(115, 2, '2024-09-16 21:08:00', NULL),
(99, 5, '2024-09-16 20:37:00', NULL),
(97, 2, '2024-09-16 16:40:00', NULL),
(83, 2, '2024-09-17 19:47:00', 'This check-in for reservation 83 captured some notes as test data.'),
(87, 2, '2024-09-17 14:45:00', NULL),
(132, 4, '2024-09-17 17:10:00', 'This check-in for reservation 132 captured some notes as test data.'),
(131, 4, '2024-09-18 20:32:00', NULL),
(139, 5, '2024-09-18 20:41:00', NULL),
(148, 2, '2024-09-19 15:25:00', 'This check-in for reservation 148 captured some notes as test data.'),
(143, 3, '2024-09-19 21:18:00', NULL),
(102, 3, '2024-09-20 18:03:00', NULL),
(146, 2, '2024-09-20 15:54:00', NULL),
(96, 5, '2024-09-21 17:39:00', NULL),
(138, 5, '2024-09-21 20:46:00', NULL),
(150, 3, '2024-09-21 18:32:00', NULL),
(158, 5, '2024-09-21 17:36:00', 'This check-in for reservation 158 captured some notes as test data.'),
(183, 5, '2024-09-22 21:27:00', NULL),
(124, 2, '2024-09-22 21:31:00', 'This check-in for reservation 124 captured some notes as test data.'),
(116, 4, '2024-09-22 16:33:00', 'This check-in for reservation 116 captured some notes as test data.'),
(175, 3, '2024-09-22 20:58:00', NULL),
(121, 2, '2024-09-23 19:05:00', NULL),
(170, 3, '2024-09-23 20:11:00', 'This check-in for reservation 170 captured some notes as test data.'),
(135, 3, '2024-09-23 14:26:00', NULL),
(130, 4, '2024-09-23 20:16:00', NULL),
(173, 5, '2024-09-24 20:03:00', NULL),
(134, 4, '2024-09-24 17:04:00', NULL),
(181, 4, '2024-09-24 13:30:00', NULL),
(145, 2, '2024-09-24 19:22:00', NULL),
(152, 3, '2024-09-25 15:41:00', NULL),
(151, 4, '2024-09-25 18:45:00', NULL),
(179, 3, '2024-09-25 17:59:00', NULL),
(153, 5, '2024-09-26 19:20:00', 'This check-in for reservation 153 captured some notes as test data.'),
(122, 3, '2024-09-26 22:32:00', NULL),
(157, 3, '2024-09-27 18:59:00', NULL),
(164, 2, '2024-09-27 15:38:00', 'This check-in for reservation 164 captured some notes as test data.'),
(140, 3, '2024-09-27 16:53:00', 'This check-in for reservation 140 captured some notes as test data.'),
(161, 2, '2024-09-27 20:56:00', NULL),
(177, 5, '2024-09-28 20:06:00', NULL),
(166, 4, '2024-09-28 13:52:00', NULL),
(163, 4, '2024-09-28 15:06:00', NULL),
(168, 4, '2024-09-28 19:36:00', NULL),
(144, 5, '2024-09-28 15:38:00', NULL),
(176, 3, '2024-09-28 22:28:00', 'This check-in for reservation 176 captured some notes as test data.'),
(174, 5, '2024-09-29 16:42:00', NULL),
(169, 3, '2024-09-29 15:37:00', NULL),
(149, 3, '2024-09-29 13:21:00', NULL),
(187, 5, '2024-09-29 22:52:00', NULL),
(155, 4, '2024-09-29 18:28:00', NULL),
(162, 5, '2024-09-30 17:28:00', NULL),
(186, 5, '2024-09-30 13:46:00', NULL),
(141, 2, '2024-09-30 20:56:00', NULL),
(160, 3, '2024-09-30 22:00:00', NULL),
(137, 4, '2024-09-30 14:41:00', 'This check-in for reservation 137 captured some notes as test data.'),
(191, 5, '2024-09-30 22:52:00', NULL),
(154, 2, '2024-10-01 16:26:00', NULL),
(171, 3, '2024-10-01 17:28:00', NULL),
(167, 3, '2024-10-02 15:43:00', 'This check-in for reservation 167 captured some notes as test data.'),
(208, 4, '2024-10-02 19:52:00', NULL),
(214, 4, '2024-10-03 13:09:00', 'This check-in for reservation 214 captured some notes as test data.'),
(213, 5, '2024-10-03 22:36:00', NULL),
(180, 3, '2024-10-03 16:35:00', NULL),
(159, 4, '2024-10-04 19:06:00', NULL),
(222, 4, '2024-10-04 22:57:00', NULL),
(188, 4, '2024-10-04 20:09:00', NULL),
(178, 3, '2024-10-04 22:45:00', NULL),
(221, 3, '2024-10-05 17:18:00', NULL),
(218, 3, '2024-10-05 17:55:00', 'This check-in for reservation 218 captured some notes as test data.'),
(201, 3, '2024-10-05 19:16:00', NULL),
(199, 3, '2024-10-06 18:59:00', 'This check-in for reservation 199 captured some notes as test data.'),
(230, 4, '2024-10-06 21:09:00', NULL),
(156, 5, '2024-10-06 22:37:00', NULL),
(202, 2, '2024-10-06 17:29:00', NULL),
(165, 4, '2024-10-06 18:30:00', NULL),
(192, 5, '2024-10-07 20:51:00', NULL),
(172, 2, '2024-10-07 20:49:00', NULL),
(198, 2, '2024-10-07 15:15:00', NULL),
(184, 2, '2024-10-08 14:19:00', NULL),
(219, 5, '2024-10-09 17:16:00', NULL),
(182, 5, '2024-10-09 13:59:00', NULL),
(223, 2, '2024-10-09 13:18:00', 'This check-in for reservation 223 captured some notes as test data.'),
(211, 3, '2024-10-10 14:53:00', 'This check-in for reservation 211 captured some notes as test data.'),
(217, 3, '2024-10-10 19:52:00', NULL),
(216, 4, '2024-10-11 14:53:00', NULL),
(185, 3, '2024-10-11 21:39:00', NULL),
(200, 3, '2024-10-11 18:07:00', NULL),
(204, 4, '2024-10-11 15:33:00', NULL),
(189, 2, '2024-10-11 16:04:00', NULL),
(190, 3, '2024-10-11 15:58:00', NULL),
(197, 3, '2024-10-11 22:09:00', NULL),
(196, 4, '2024-10-11 16:41:00', NULL),
(212, 5, '2024-10-11 18:04:00', NULL),
(195, 4, '2024-10-12 16:45:00', NULL),
(241, 3, '2024-10-13 19:04:00', 'This check-in for reservation 241 captured some notes as test data.'),
(232, 5, '2024-10-13 18:17:00', 'This check-in for reservation 232 captured some notes as test data.'),
(194, 2, '2024-10-13 21:31:00', NULL),
(256, 4, '2024-10-13 17:23:00', NULL),
(203, 5, '2024-10-13 15:39:00', NULL),
(229, 5, '2024-10-14 21:10:00', NULL),
(235, 4, '2024-10-14 13:44:00', NULL),
(254, 3, '2024-10-14 14:45:00', NULL),
(250, 2, '2024-10-15 22:11:00', NULL),
(227, 2, '2024-10-15 17:45:00', NULL),
(193, 3, '2024-10-15 20:29:00', 'This check-in for reservation 193 captured some notes as test data.'),
(206, 2, '2024-10-15 15:47:00', NULL),
(262, 5, '2024-10-15 17:26:00', NULL),
(271, 3, '2024-10-15 15:06:00', NULL),
(240, 3, '2024-10-16 18:58:00', NULL),
(275, 4, '2024-10-16 22:44:00', 'This check-in for reservation 275 captured some notes as test data.'),
(242, 4, '2024-10-16 13:05:00', NULL),
(205, 5, '2024-10-16 13:51:00', NULL),
(207, 4, '2024-10-16 20:43:00', NULL),
(282, 3, '2024-10-17 18:51:00', NULL),
(237, 2, '2024-10-17 13:05:00', NULL),
(265, 5, '2024-10-17 16:24:00', NULL),
(234, 5, '2024-10-17 19:33:00', NULL),
(258, 2, '2024-10-17 14:21:00', NULL),
(274, 5, '2024-10-17 15:59:00', NULL),
(277, 3, '2024-10-18 13:48:00', NULL),
(228, 3, '2024-10-18 18:58:00', NULL),
(248, 4, '2024-10-18 19:39:00', NULL),
(209, 4, '2024-10-18 18:40:00', NULL),
(220, 5, '2024-10-18 17:01:00', NULL),
(284, 2, '2024-10-19 17:17:00', NULL),
(247, 2, '2024-10-19 14:12:00', NULL),
(270, 2, '2024-10-19 18:05:00', NULL),
(225, 5, '2024-10-20 21:26:00', NULL),
(238, 2, '2024-10-20 16:08:00', NULL),
(253, 3, '2024-10-20 21:28:00', NULL),
(210, 3, '2024-10-20 15:35:00', NULL),
(215, 5, '2024-10-20 13:15:00', NULL),
(231, 4, '2024-10-20 17:59:00', NULL),
(255, 5, '2024-10-20 15:25:00', NULL),
(224, 2, '2024-10-20 22:23:00', NULL),
(251, 3, '2024-10-21 22:47:00', NULL),
(294, 4, '2024-10-21 20:47:00', 'This check-in for reservation 294 captured some notes as test data.'),
(257, 4, '2024-10-21 16:46:00', NULL),
(286, 3, '2024-10-21 18:06:00', NULL),
(226, 4, '2024-10-22 19:00:00', NULL),
(236, 4, '2024-10-23 16:28:00', NULL),
(305, 5, '2024-10-23 17:00:00', 'This check-in for reservation 305 captured some notes as test data.'),
(285, 5, '2024-10-23 16:36:00', NULL),
(269, 5, '2024-10-24 18:00:00', NULL),
(243, 5, '2024-10-24 14:35:00', NULL),
(296, 3, '2024-10-24 20:34:00', NULL),
(291, 2, '2024-10-24 19:22:00', NULL),
(244, 2, '2024-10-24 21:02:00', 'This check-in for reservation 244 captured some notes as test data.'),
(239, 4, '2024-10-24 20:45:00', NULL),
(252, 2, '2024-10-24 18:20:00', NULL),
(280, 2, '2024-10-24 13:23:00', NULL),
(233, 5, '2024-10-24 16:10:00', NULL),
(293, 2, '2024-10-24 14:32:00', NULL),
(319, 2, '2024-10-25 19:36:00', NULL),
(297, 3, '2024-10-25 19:26:00', NULL),
(281, 4, '2024-10-25 21:01:00', NULL),
(324, 3, '2024-10-26 21:23:00', NULL),
(245, 5, '2024-10-26 18:37:00', NULL),
(259, 2, '2024-10-26 17:13:00', NULL),
(263, 4, '2024-10-26 15:39:00', NULL),
(272, 3, '2024-10-26 19:58:00', NULL),
(267, 5, '2024-10-27 19:20:00', NULL),
(313, 4, '2024-10-27 21:41:00', NULL),
(287, 3, '2024-10-27 17:16:00', NULL),
(322, 3, '2024-10-28 22:32:00', NULL),
(311, 4, '2024-10-28 21:38:00', 'This check-in for reservation 311 captured some notes as test data.'),
(268, 5, '2024-10-28 13:30:00', NULL),
(249, 4, '2024-10-28 21:08:00', NULL),
(278, 5, '2024-10-28 16:51:00', NULL),
(246, 5, '2024-10-28 22:42:00', NULL),
(308, 3, '2024-10-29 17:02:00', NULL),
(298, 5, '2024-10-29 21:28:00', NULL),
(260, 5, '2024-10-29 17:09:00', 'This check-in for reservation 260 captured some notes as test data.'),
(307, 5, '2024-10-29 21:20:00', NULL),
(330, 3, '2024-10-29 22:20:00', NULL),
(300, 2, '2024-10-29 17:50:00', NULL),
(261, 5, '2024-10-30 16:02:00', NULL),
(279, 3, '2024-10-30 21:36:00', NULL),
(266, 4, '2024-10-30 18:59:00', NULL),
(273, 2, '2024-10-30 14:15:00', NULL),
(336, 5, '2024-10-30 20:53:00', NULL),
(276, 5, '2024-10-31 13:13:00', 'This check-in for reservation 276 captured some notes as test data.'),
(289, 4, '2024-10-31 17:30:00', 'This check-in for reservation 289 captured some notes as test data.'),
(345, 2, '2024-10-31 22:12:00', NULL),
(337, 2, '2024-10-31 22:44:00', NULL),
(264, 2, '2024-11-01 15:52:00', NULL),
(332, 3, '2024-11-02 19:06:00', NULL),
(301, 5, '2024-11-02 22:28:00', NULL),
(346, 3, '2024-11-02 22:38:00', NULL),
(326, 4, '2024-11-02 15:37:00', NULL),
(290, 2, '2024-11-02 19:37:00', NULL),
(327, 5, '2024-11-02 21:18:00', 'This check-in for reservation 327 captured some notes as test data.'),
(288, 2, '2024-11-03 17:18:00', NULL),
(355, 3, '2024-11-03 17:20:00', 'This check-in for reservation 355 captured some notes as test data.'),
(353, 4, '2024-11-03 22:44:00', NULL),
(331, 2, '2024-11-04 15:21:00', NULL),
(302, 5, '2024-11-04 19:07:00', NULL),
(304, 2, '2024-11-04 21:29:00', NULL),
(315, 3, '2024-11-04 14:08:00', NULL),
(283, 2, '2024-11-04 19:05:00', 'This check-in for reservation 283 captured some notes as test data.'),
(295, 3, '2024-11-04 13:26:00', 'This check-in for reservation 295 captured some notes as test data.'),
(320, 5, '2024-11-04 22:19:00', NULL),
(292, 2, '2024-11-05 16:52:00', 'This check-in for reservation 292 captured some notes as test data.'),
(306, 2, '2024-11-05 13:03:00', NULL),
(338, 5, '2024-11-05 21:57:00', 'This check-in for reservation 338 captured some notes as test data.'),
(299, 5, '2024-11-06 16:41:00', NULL),
(333, 3, '2024-11-06 15:16:00', NULL),
(352, 4, '2024-11-06 19:44:00', NULL),
(303, 5, '2024-11-07 13:45:00', NULL),
(350, 5, '2024-11-07 17:08:00', NULL),
(310, 2, '2024-11-07 21:01:00', NULL),
(317, 5, '2024-11-07 22:03:00', NULL),
(321, 5, '2024-11-07 19:26:00', 'This check-in for reservation 321 captured some notes as test data.'),
(309, 2, '2024-11-07 22:31:00', NULL),
(312, 4, '2024-11-07 21:15:00', NULL),
(371, 3, '2024-11-08 13:22:00', NULL),
(341, 3, '2024-11-08 17:46:00', NULL),
(334, 5, '2024-11-08 22:29:00', NULL),
(377, 3, '2024-11-08 21:15:00', NULL),
(347, 4, '2024-11-09 22:11:00', NULL),
(356, 3, '2024-11-10 16:47:00', NULL),
(316, 3, '2024-11-10 22:40:00', NULL),
(335, 2, '2024-11-10 14:07:00', NULL),
(318, 5, '2024-11-10 13:13:00', NULL),
(5, 5, '2024-11-11 14:35:00', NULL),
(383, 5, '2024-11-11 22:06:00', NULL),
(387, 2, '2024-11-11 17:48:00', 'This check-in for reservation 387 captured some notes as test data.'),
(367, 5, '2024-11-11 17:25:00', NULL),
(339, 5, '2024-11-11 16:22:00', NULL),
(351, 3, '2024-11-11 18:14:00', 'This check-in for reservation 351 captured some notes as test data.'),
(372, 2, '2024-11-11 16:04:00', NULL),
(314, 2, '2024-11-11 19:46:00', NULL),
(328, 5, '2024-11-11 16:10:00', NULL),
(359, 3, '2024-11-12 17:12:00', NULL),
(374, 5, '2024-11-12 18:28:00', NULL),
(325, 2, '2024-11-12 22:19:00', NULL),
(323, 2, '2024-11-12 17:30:00', NULL),
(329, 4, '2024-11-12 17:56:00', NULL),
(340, 5, '2024-11-13 18:51:00', NULL),
(363, 2, '2024-11-13 17:32:00', NULL),
(390, 3, '2024-11-14 18:57:00', NULL),
(366, 5, '2024-11-14 20:42:00', NULL),
(400, 2, '2024-11-14 20:29:00', NULL),
(344, 4, '2024-11-14 13:02:00', NULL),
(369, 5, '2024-11-14 19:25:00', 'This check-in for reservation 369 captured some notes as test data.'),
(403, 2, '2024-11-14 21:57:00', NULL),
(364, 3, '2024-11-15 22:30:00', NULL),
(343, 2, '2024-11-16 16:18:00', 'This check-in for reservation 343 captured some notes as test data.'),
(342, 2, '2024-11-16 17:57:00', NULL),
(365, 3, '2024-11-16 16:38:00', 'This check-in for reservation 365 captured some notes as test data.'),
(361, 4, '2024-11-16 21:23:00', NULL),
(357, 2, '2024-11-16 13:29:00', NULL),
(358, 3, '2024-11-16 13:33:00', NULL),
(404, 4, '2024-11-16 13:11:00', 'This check-in for reservation 404 captured some notes as test data.'),
(391, 3, '2024-11-16 17:04:00', NULL),
(354, 3, '2024-11-17 18:19:00', NULL),
(375, 3, '2024-11-17 20:03:00', NULL),
(349, 2, '2024-11-17 18:32:00', NULL),
(399, 2, '2024-11-17 15:54:00', NULL),
(388, 4, '2024-11-18 20:25:00', NULL),
(405, 5, '2024-11-18 20:08:00', NULL),
(348, 3, '2024-11-18 13:37:00', 'This check-in for reservation 348 captured some notes as test data.'),
(407, 4, '2024-11-18 20:36:00', NULL),
(360, 2, '2024-11-18 20:47:00', NULL),
(420, 2, '2024-11-19 20:25:00', NULL),
(412, 2, '2024-11-20 20:31:00', NULL),
(384, 4, '2024-11-20 21:26:00', NULL),
(376, 5, '2024-11-20 22:05:00', NULL),
(392, 3, '2024-11-20 18:57:00', NULL),
(386, 3, '2024-11-20 13:03:00', NULL),
(398, 4, '2024-11-20 21:12:00', NULL);

INSERT INTO check_out (reservation_id, staff_id, date_time, settled_invoice, notes) VALUES
(1, 2, '2024-10-23 09:46:00', 1, 'Discussed complaints with guest during check out'),
(16, 5, '2024-08-16 08:14:00', 1, NULL),
(18, 2, '2024-08-16 10:43:00', 1, NULL),
(7, 2, '2024-08-18 10:44:00', 1, NULL),
(17, 2, '2024-08-18 07:29:00', 1, NULL),
(25, 2, '2024-08-18 10:30:00', 1, NULL),
(6, 3, '2024-08-19 08:04:00', 0, NULL),
(19, 4, '2024-08-19 07:04:00', 1, 'This check-out for reservation 19 captured some notes as test data.'),
(23, 3, '2024-08-20 07:45:00', 1, NULL),
(34, 2, '2024-08-21 07:54:00', 1, NULL),
(32, 4, '2024-08-21 07:59:00', 1, 'This check-out for reservation 32 captured some notes as test data.'),
(11, 5, '2024-08-21 07:45:00', 1, NULL),
(29, 3, '2024-08-21 10:04:00', 1, NULL),
(41, 5, '2024-08-22 07:00:00', 1, NULL),
(14, 4, '2024-08-22 09:17:00', 1, NULL),
(15, 4, '2024-08-23 10:42:00', 1, NULL),
(33, 5, '2024-08-24 10:19:00', 1, 'This check-out for reservation 33 captured some notes as test data.'),
(12, 4, '2024-08-24 10:47:00', 1, NULL),
(13, 2, '2024-08-24 10:31:00', 1, NULL),
(57, 5, '2024-08-25 08:34:00', 0, NULL),
(24, 3, '2024-08-25 07:10:00', 1, NULL),
(63, 4, '2024-08-25 09:13:00', 0, NULL),
(10, 4, '2024-08-26 09:04:00', 1, 'This check-out for reservation 10 captured some notes as test data.'),
(53, 3, '2024-08-26 10:18:00', 1, NULL),
(28, 3, '2024-08-27 10:08:00', 1, NULL),
(20, 2, '2024-08-27 09:40:00', 1, NULL),
(9, 4, '2024-08-28 10:13:00', 1, 'This check-out for reservation 9 captured some notes as test data.'),
(22, 4, '2024-08-28 09:22:00', 1, NULL),
(59, 3, '2024-08-28 07:49:00', 1, NULL),
(45, 2, '2024-08-29 09:17:00', 1, NULL),
(62, 4, '2024-08-29 09:27:00', 1, NULL),
(21, 4, '2024-08-29 09:33:00', 1, NULL),
(8, 5, '2024-08-30 09:40:00', 1, NULL),
(40, 4, '2024-08-30 08:14:00', 1, NULL),
(52, 2, '2024-08-30 08:21:00', 1, NULL),
(48, 5, '2024-08-30 10:21:00', 1, 'This check-out for reservation 48 captured some notes as test data.'),
(72, 3, '2024-08-30 08:15:00', 1, NULL),
(61, 2, '2024-08-31 08:23:00', 1, NULL),
(38, 3, '2024-08-31 07:19:00', 1, 'This check-out for reservation 38 captured some notes as test data.'),
(69, 2, '2024-08-31 08:52:00', 1, NULL),
(56, 3, '2024-08-31 09:31:00', 1, 'This check-out for reservation 56 captured some notes as test data.'),
(37, 4, '2024-09-01 08:29:00', 1, NULL),
(36, 5, '2024-09-01 07:24:00', 1, NULL),
(55, 4, '2024-09-02 09:30:00', 1, NULL),
(27, 3, '2024-09-02 10:20:00', 1, NULL),
(44, 3, '2024-09-02 10:17:00', 1, NULL),
(31, 5, '2024-09-02 07:20:00', 1, 'This check-out for reservation 31 captured some notes as test data.'),
(46, 4, '2024-09-03 10:34:00', 1, 'This check-out for reservation 46 captured some notes as test data.'),
(39, 5, '2024-09-03 10:23:00', 1, NULL),
(35, 2, '2024-09-03 09:55:00', 1, NULL),
(77, 5, '2024-09-04 09:40:00', 1, NULL),
(74, 4, '2024-09-04 09:01:00', 1, NULL),
(42, 2, '2024-09-05 08:53:00', 1, 'This check-out for reservation 42 captured some notes as test data.'),
(70, 5, '2024-09-05 07:21:00', 1, NULL),
(51, 5, '2024-09-05 08:00:00', 1, NULL),
(49, 3, '2024-09-06 10:15:00', 1, NULL),
(30, 2, '2024-09-06 09:36:00', 1, 'This check-out for reservation 30 captured some notes as test data.'),
(26, 5, '2024-09-06 07:33:00', 1, NULL),
(50, 5, '2024-09-06 10:34:00', 1, NULL),
(76, 5, '2024-09-06 10:35:00', 1, NULL),
(82, 3, '2024-09-06 07:58:00', 1, NULL),
(58, 4, '2024-09-06 08:45:00', 0, NULL),
(60, 2, '2024-09-06 08:56:00', 1, NULL),
(66, 5, '2024-09-07 07:39:00', 1, 'This check-out for reservation 66 captured some notes as test data.'),
(93, 4, '2024-09-07 08:24:00', 1, NULL),
(43, 2, '2024-09-08 09:09:00', 1, NULL),
(65, 2, '2024-09-08 09:26:00', 1, NULL),
(95, 4, '2024-09-08 07:43:00', 1, NULL),
(54, 3, '2024-09-09 07:26:00', 1, NULL),
(88, 5, '2024-09-09 09:41:00', 1, NULL),
(89, 4, '2024-09-09 10:43:00', 1, NULL),
(78, 5, '2024-09-09 09:45:00', 1, 'This check-out for reservation 78 captured some notes as test data.'),
(86, 2, '2024-09-09 09:19:00', 0, NULL),
(104, 2, '2024-09-09 08:07:00', 1, 'This check-out for reservation 104 captured some notes as test data.'),
(73, 4, '2024-09-09 09:33:00', 1, NULL),
(90, 4, '2024-09-10 09:17:00', 0, NULL),
(91, 3, '2024-09-10 08:15:00', 1, NULL),
(101, 4, '2024-09-10 08:21:00', 1, NULL),
(120, 5, '2024-09-10 07:24:00', 0, NULL),
(80, 2, '2024-09-10 09:12:00', 1, NULL),
(75, 3, '2024-09-10 10:44:00', 1, 'This check-out for reservation 75 captured some notes as test data.'),
(94, 3, '2024-09-10 07:46:00', 1, NULL),
(117, 5, '2024-09-11 08:17:00', 1, 'This check-out for reservation 117 captured some notes as test data.'),
(64, 2, '2024-09-12 10:15:00', 1, NULL),
(106, 5, '2024-09-12 08:10:00', 0, NULL),
(118, 4, '2024-09-12 09:20:00', 1, NULL),
(47, 5, '2024-09-13 08:23:00', 1, NULL),
(123, 4, '2024-09-13 10:23:00', 1, NULL),
(111, 3, '2024-09-13 08:42:00', 1, NULL),
(128, 3, '2024-09-13 09:46:00', 1, 'This check-out for reservation 128 captured some notes as test data.'),
(67, 3, '2024-09-13 08:12:00', 1, NULL),
(108, 3, '2024-09-13 10:21:00', 1, NULL),
(126, 4, '2024-09-14 10:16:00', 1, NULL),
(105, 3, '2024-09-14 07:26:00', 1, NULL),
(133, 2, '2024-09-14 08:40:00', 1, 'This check-out for reservation 133 captured some notes as test data.'),
(68, 5, '2024-09-14 10:37:00', 0, 'This check-out for reservation 68 captured some notes as test data.'),
(119, 4, '2024-09-14 10:22:00', 1, NULL),
(129, 4, '2024-09-14 08:35:00', 1, 'This check-out for reservation 129 captured some notes as test data.'),
(81, 2, '2024-09-14 07:32:00', 1, NULL),
(113, 5, '2024-09-15 08:01:00', 1, NULL),
(125, 4, '2024-09-15 07:36:00', 1, NULL),
(110, 3, '2024-09-15 08:28:00', 1, NULL),
(142, 4, '2024-09-15 10:25:00', 1, NULL),
(114, 5, '2024-09-16 09:10:00', 1, NULL),
(109, 4, '2024-09-16 09:51:00', 1, 'This check-out for reservation 109 captured some notes as test data.'),
(127, 5, '2024-09-16 09:13:00', 1, NULL),
(79, 4, '2024-09-17 10:22:00', 0, NULL),
(85, 2, '2024-09-17 10:29:00', 0, NULL),
(92, 3, '2024-09-17 07:22:00', 1, NULL),
(136, 3, '2024-09-17 10:01:00', 0, NULL),
(147, 5, '2024-09-17 07:23:00', 1, NULL),
(98, 2, '2024-09-18 09:10:00', 1, NULL),
(100, 2, '2024-09-18 07:46:00', 1, 'This check-out for reservation 100 captured some notes as test data.'),
(107, 4, '2024-09-18 09:08:00', 1, NULL),
(84, 4, '2024-09-18 10:10:00', 1, 'This check-out for reservation 84 captured some notes as test data.'),
(103, 4, '2024-09-18 10:06:00', 0, NULL),
(115, 5, '2024-09-18 08:07:00', 1, NULL),
(83, 3, '2024-09-18 10:17:00', 1, NULL),
(71, 3, '2024-09-19 09:39:00', 1, NULL),
(112, 4, '2024-09-19 09:55:00', 1, NULL),
(97, 2, '2024-09-19 10:06:00', 1, 'This check-out for reservation 97 captured some notes as test data.'),
(132, 3, '2024-09-20 09:57:00', 1, 'This check-out for reservation 132 captured some notes as test data.'),
(148, 4, '2024-09-20 07:52:00', 1, NULL),
(99, 2, '2024-09-21 09:58:00', 0, NULL),
(87, 5, '2024-09-22 08:13:00', 1, 'This check-out for reservation 87 captured some notes as test data.'),
(158, 5, '2024-09-22 07:52:00', 1, NULL),
(139, 4, '2024-09-23 09:04:00', 1, NULL),
(143, 5, '2024-09-23 07:23:00', 1, NULL),
(102, 3, '2024-09-23 09:11:00', 1, NULL),
(150, 4, '2024-09-23 10:57:00', 1, NULL),
(116, 3, '2024-09-23 10:57:00', 1, 'This check-out for reservation 116 captured some notes as test data.'),
(175, 4, '2024-09-23 10:58:00', 1, NULL),
(131, 3, '2024-09-24 07:08:00', 1, 'This check-out for reservation 131 captured some notes as test data.'),
(146, 4, '2024-09-24 08:30:00', 1, NULL),
(138, 3, '2024-09-24 09:18:00', 1, 'This check-out for reservation 138 captured some notes as test data.'),
(130, 5, '2024-09-24 08:11:00', 1, 'This check-out for reservation 130 captured some notes as test data.'),
(183, 2, '2024-09-25 10:48:00', 1, NULL),
(170, 4, '2024-09-25 09:59:00', 1, NULL),
(96, 4, '2024-09-26 08:49:00', 1, NULL),
(124, 3, '2024-09-26 08:56:00', 1, NULL),
(173, 5, '2024-09-26 09:14:00', 1, NULL),
(121, 2, '2024-09-27 07:46:00', 1, NULL),
(135, 2, '2024-09-27 08:22:00', 1, NULL),
(134, 3, '2024-09-27 09:35:00', 1, 'This check-out for reservation 134 captured some notes as test data.'),
(145, 4, '2024-09-27 08:57:00', 1, 'This check-out for reservation 145 captured some notes as test data.'),
(153, 2, '2024-09-27 08:44:00', 1, NULL),
(122, 5, '2024-09-27 09:33:00', 1, NULL),
(181, 3, '2024-09-28 09:35:00', 1, NULL),
(179, 3, '2024-09-28 07:02:00', 1, 'This check-out for reservation 179 captured some notes as test data.'),
(164, 3, '2024-09-29 10:35:00', 1, NULL),
(144, 3, '2024-09-29 08:09:00', 1, NULL),
(152, 2, '2024-09-30 09:17:00', 1, NULL),
(151, 5, '2024-09-30 10:14:00', 1, NULL),
(157, 5, '2024-09-30 10:41:00', 0, NULL),
(161, 2, '2024-09-30 10:16:00', 1, NULL),
(177, 4, '2024-09-30 10:04:00', 1, NULL),
(168, 3, '2024-09-30 07:15:00', 1, NULL),
(166, 3, '2024-10-01 09:14:00', 1, NULL),
(176, 5, '2024-10-01 07:11:00', 1, NULL),
(140, 5, '2024-10-02 10:38:00', 1, NULL),
(149, 5, '2024-10-02 07:44:00', 1, 'This check-out for reservation 149 captured some notes as test data.'),
(155, 4, '2024-10-02 08:20:00', 0, NULL),
(163, 4, '2024-10-03 07:41:00', 0, NULL),
(174, 3, '2024-10-03 07:18:00', 1, 'This check-out for reservation 174 captured some notes as test data.'),
(169, 4, '2024-10-03 09:31:00', 1, NULL),
(162, 3, '2024-10-03 09:52:00', 1, NULL),
(186, 4, '2024-10-03 10:46:00', 1, NULL),
(160, 5, '2024-10-03 10:08:00', 1, NULL),
(137, 5, '2024-10-03 08:53:00', 1, NULL),
(191, 3, '2024-10-03 08:42:00', 1, NULL),
(154, 3, '2024-10-03 09:31:00', 1, 'This check-out for reservation 154 captured some notes as test data.'),
(187, 4, '2024-10-04 07:05:00', 1, NULL),
(213, 4, '2024-10-04 10:29:00', 1, NULL),
(171, 3, '2024-10-05 10:16:00', 0, NULL),
(141, 3, '2024-10-06 08:55:00', 1, NULL),
(167, 5, '2024-10-06 08:22:00', 1, NULL),
(208, 4, '2024-10-06 10:36:00', 1, NULL),
(180, 3, '2024-10-06 08:42:00', 0, 'This check-out for reservation 180 captured some notes as test data.'),
(159, 2, '2024-10-07 09:29:00', 0, 'This check-out for reservation 159 captured some notes as test data.'),
(222, 5, '2024-10-07 07:13:00', 1, 'This check-out for reservation 222 captured some notes as test data.'),
(178, 2, '2024-10-07 07:54:00', 1, NULL),
(221, 5, '2024-10-07 07:03:00', 1, NULL),
(201, 4, '2024-10-07 08:03:00', 1, NULL),
(199, 3, '2024-10-07 10:02:00', 1, 'This check-out for reservation 199 captured some notes as test data.'),
(230, 3, '2024-10-07 07:41:00', 1, NULL),
(218, 2, '2024-10-08 08:55:00', 1, NULL),
(165, 2, '2024-10-08 09:02:00', 1, NULL),
(192, 2, '2024-10-08 08:49:00', 1, 'This check-out for reservation 192 captured some notes as test data.'),
(214, 4, '2024-10-09 07:40:00', 0, NULL),
(188, 5, '2024-10-09 10:13:00', 1, 'This check-out for reservation 188 captured some notes as test data.'),
(172, 4, '2024-10-10 08:57:00', 0, NULL),
(198, 3, '2024-10-10 09:23:00', 1, NULL),
(156, 5, '2024-10-11 07:58:00', 0, NULL),
(202, 2, '2024-10-11 10:51:00', 1, 'This check-out for reservation 202 captured some notes as test data.'),
(182, 2, '2024-10-11 09:55:00', 1, NULL),
(223, 4, '2024-10-11 08:07:00', 1, NULL),
(184, 4, '2024-10-12 10:12:00', 1, NULL),
(219, 3, '2024-10-12 07:02:00', 1, NULL),
(211, 3, '2024-10-12 08:11:00', 1, NULL),
(216, 3, '2024-10-12 08:05:00', 1, NULL),
(200, 2, '2024-10-12 10:10:00', 1, NULL),
(197, 2, '2024-10-12 10:28:00', 1, NULL),
(217, 3, '2024-10-13 07:07:00', 1, NULL),
(212, 5, '2024-10-13 08:15:00', 1, NULL),
(185, 5, '2024-10-14 08:30:00', 1, NULL),
(204, 2, '2024-10-14 10:40:00', 1, NULL),
(190, 3, '2024-10-14 10:52:00', 1, NULL),
(195, 5, '2024-10-14 09:47:00', 1, NULL),
(232, 3, '2024-10-14 09:01:00', 1, NULL),
(194, 4, '2024-10-14 09:37:00', 1, 'This check-out for reservation 194 captured some notes as test data.'),
(256, 4, '2024-10-15 07:19:00', 1, NULL),
(254, 5, '2024-10-15 09:25:00', 1, NULL),
(189, 4, '2024-10-16 10:18:00', 1, NULL),
(196, 3, '2024-10-16 07:35:00', 0, NULL),
(241, 4, '2024-10-16 08:26:00', 1, NULL),
(203, 5, '2024-10-16 07:05:00', 1, NULL),
(193, 2, '2024-10-16 08:04:00', 1, NULL),
(206, 5, '2024-10-16 07:03:00', 1, NULL),
(229, 4, '2024-10-17 10:21:00', 1, NULL),
(271, 5, '2024-10-17 10:36:00', 1, NULL),
(240, 3, '2024-10-18 10:33:00', 1, 'This check-out for reservation 240 captured some notes as test data.'),
(275, 3, '2024-10-18 09:59:00', 1, NULL),
(237, 5, '2024-10-18 10:16:00', 0, NULL),
(234, 3, '2024-10-18 10:30:00', 1, NULL),
(227, 2, '2024-10-19 08:28:00', 1, NULL),
(262, 2, '2024-10-19 10:20:00', 1, 'This check-out for reservation 262 captured some notes as test data.'),
(242, 4, '2024-10-19 09:46:00', 1, 'This check-out for reservation 242 captured some notes as test data.'),
(207, 2, '2024-10-19 09:36:00', 1, NULL),
(258, 3, '2024-10-19 07:21:00', 1, NULL),
(274, 4, '2024-10-19 09:16:00', 1, 'This check-out for reservation 274 captured some notes as test data.'),
(209, 4, '2024-10-19 08:22:00', 1, NULL),
(250, 2, '2024-10-20 08:11:00', 1, NULL),
(205, 4, '2024-10-20 08:49:00', 1, 'This check-out for reservation 205 captured some notes as test data.'),
(228, 2, '2024-10-20 10:51:00', 1, NULL),
(220, 3, '2024-10-20 09:20:00', 1, 'This check-out for reservation 220 captured some notes as test data.'),
(235, 5, '2024-10-21 08:27:00', 1, NULL),
(248, 2, '2024-10-21 07:49:00', 1, 'This check-out for reservation 248 captured some notes as test data.'),
(238, 5, '2024-10-21 10:15:00', 1, NULL),
(215, 5, '2024-10-21 09:07:00', 1, NULL),
(265, 4, '2024-10-22 08:49:00', 1, NULL),
(277, 4, '2024-10-22 09:03:00', 1, NULL),
(284, 3, '2024-10-22 10:48:00', 1, 'This check-out for reservation 284 captured some notes as test data.'),
(247, 4, '2024-10-22 09:11:00', 1, NULL),
(231, 3, '2024-10-22 10:27:00', 1, 'This check-out for reservation 231 captured some notes as test data.'),
(282, 2, '2024-10-23 10:27:00', 1, NULL),
(225, 5, '2024-10-23 08:39:00', 1, NULL),
(253, 2, '2024-10-23 09:56:00', 1, NULL),
(255, 5, '2024-10-23 10:18:00', 1, NULL),
(224, 3, '2024-10-23 09:38:00', 1, NULL),
(294, 3, '2024-10-23 07:23:00', 0, 'This check-out for reservation 294 captured some notes as test data.'),
(257, 5, '2024-10-23 09:25:00', 1, NULL),
(270, 3, '2024-10-24 09:53:00', 1, NULL),
(251, 5, '2024-10-24 10:08:00', 1, NULL),
(226, 3, '2024-10-24 09:19:00', 1, 'This check-out for reservation 226 captured some notes as test data.'),
(210, 4, '2024-10-25 10:51:00', 1, NULL),
(236, 4, '2024-10-25 10:52:00', 1, NULL),
(293, 4, '2024-10-25 10:00:00', 1, NULL),
(286, 4, '2024-10-26 07:01:00', 1, NULL),
(305, 3, '2024-10-26 10:12:00', 1, NULL),
(296, 3, '2024-10-26 07:51:00', 0, NULL),
(291, 2, '2024-10-26 07:04:00', 1, NULL),
(280, 4, '2024-10-26 10:08:00', 1, 'This check-out for reservation 280 captured some notes as test data.'),
(233, 4, '2024-10-26 08:54:00', 1, NULL),
(4, 4, '2024-10-27 08:15:00', 1, NULL),
(285, 3, '2024-10-27 08:26:00', 0, NULL),
(269, 2, '2024-10-27 10:32:00', 1, NULL),
(244, 3, '2024-10-27 09:11:00', 1, NULL),
(252, 5, '2024-10-27 08:17:00', 0, NULL),
(281, 5, '2024-10-27 09:01:00', 1, NULL),
(319, 5, '2024-10-28 09:24:00', 1, NULL),
(324, 5, '2024-10-28 09:13:00', 1, NULL),
(259, 3, '2024-10-28 08:45:00', 1, NULL),
(267, 5, '2024-10-28 09:27:00', 1, NULL),
(3, 5, '2024-10-29 07:17:00', 1, NULL),
(245, 4, '2024-10-29 10:24:00', 1, NULL),
(313, 5, '2024-10-29 07:35:00', 1, NULL),
(287, 5, '2024-10-29 07:23:00', 1, NULL),
(322, 3, '2024-10-29 08:47:00', 1, NULL),
(243, 4, '2024-10-30 09:47:00', 1, 'This check-out for reservation 243 captured some notes as test data.'),
(246, 2, '2024-10-30 09:30:00', 1, NULL),
(330, 5, '2024-10-30 09:30:00', 1, 'This check-out for reservation 330 captured some notes as test data.'),
(2, 4, '2024-10-31 07:27:00', 1, NULL),
(239, 5, '2024-10-31 08:54:00', 1, NULL),
(297, 4, '2024-10-31 09:43:00', 1, NULL),
(263, 4, '2024-10-31 10:57:00', 1, NULL),
(272, 4, '2024-10-31 10:13:00', 0, NULL),
(311, 5, '2024-10-31 10:42:00', 1, NULL),
(268, 5, '2024-10-31 10:34:00', 1, NULL),
(249, 4, '2024-10-31 09:51:00', 1, NULL),
(307, 2, '2024-10-31 10:08:00', 1, NULL),
(300, 4, '2024-10-31 10:46:00', 0, NULL),
(279, 3, '2024-11-01 08:11:00', 0, NULL),
(337, 4, '2024-11-01 09:22:00', 1, NULL),
(308, 3, '2024-11-02 09:35:00', 1, NULL),
(261, 5, '2024-11-02 10:23:00', 1, NULL),
(266, 4, '2024-11-02 08:10:00', 1, 'This check-out for reservation 266 captured some notes as test data.'),
(336, 4, '2024-11-02 09:56:00', 1, NULL),
(345, 2, '2024-11-02 10:52:00', 1, NULL),
(278, 4, '2024-11-03 07:41:00', 1, NULL),
(298, 5, '2024-11-03 10:10:00', 1, NULL),
(260, 2, '2024-11-03 08:39:00', 1, NULL),
(276, 4, '2024-11-03 08:03:00', 1, NULL),
(301, 5, '2024-11-03 07:16:00', 1, NULL),
(326, 4, '2024-11-03 07:44:00', 1, NULL),
(290, 2, '2024-11-03 09:29:00', 1, NULL),
(327, 3, '2024-11-04 10:39:00', 0, 'This check-out for reservation 327 captured some notes as test data.'),
(288, 3, '2024-11-04 08:53:00', 1, NULL),
(273, 2, '2024-11-05 10:30:00', 1, NULL),
(289, 4, '2024-11-05 08:48:00', 1, NULL),
(332, 5, '2024-11-05 08:10:00', 1, NULL),
(346, 3, '2024-11-05 09:14:00', 1, NULL),
(355, 5, '2024-11-05 07:22:00', 1, NULL),
(353, 5, '2024-11-05 07:54:00', 0, NULL),
(304, 5, '2024-11-05 07:55:00', 1, NULL),
(315, 5, '2024-11-05 09:46:00', 1, NULL),
(338, 5, '2024-11-06 08:59:00', 1, NULL),
(264, 5, '2024-11-07 07:49:00', 1, NULL),
(302, 3, '2024-11-07 07:06:00', 1, 'This check-out for reservation 302 captured some notes as test data.'),
(295, 2, '2024-11-07 10:05:00', 1, NULL),
(292, 2, '2024-11-07 08:10:00', 1, NULL),
(306, 4, '2024-11-07 08:42:00', 1, NULL),
(299, 3, '2024-11-07 07:14:00', 1, NULL),
(333, 4, '2024-11-07 09:50:00', 1, NULL),
(331, 5, '2024-11-08 07:48:00', 1, 'This check-out for reservation 331 captured some notes as test data.'),
(352, 2, '2024-11-08 10:03:00', 1, NULL),
(321, 5, '2024-11-08 09:37:00', 1, 'This check-out for reservation 321 captured some notes as test data.'),
(320, 3, '2024-11-09 09:44:00', 1, 'This check-out for reservation 320 captured some notes as test data.'),
(371, 2, '2024-11-09 10:35:00', 1, 'This check-out for reservation 371 captured some notes as test data.'),
(283, 5, '2024-11-10 08:23:00', 1, 'This check-out for reservation 283 captured some notes as test data.'),
(303, 5, '2024-11-10 08:01:00', 1, NULL),
(350, 3, '2024-11-10 08:34:00', 1, 'This check-out for reservation 350 captured some notes as test data.'),
(317, 4, '2024-11-10 09:14:00', 1, NULL),
(309, 3, '2024-11-10 10:35:00', 1, NULL),
(312, 5, '2024-11-10 10:21:00', 1, NULL),
(334, 4, '2024-11-10 07:32:00', 1, NULL),
(310, 4, '2024-11-11 07:59:00', 1, NULL),
(341, 5, '2024-11-11 08:40:00', 1, NULL),
(377, 5, '2024-11-11 07:38:00', 1, NULL),
(347, 2, '2024-11-11 09:30:00', 1, 'This check-out for reservation 347 captured some notes as test data.'),
(356, 5, '2024-11-11 09:24:00', 1, NULL),
(316, 5, '2024-11-12 10:09:00', 1, NULL),
(335, 4, '2024-11-12 08:08:00', 1, 'This check-out for reservation 335 captured some notes as test data.'),
(387, 3, '2024-11-12 10:35:00', 1, NULL),
(328, 3, '2024-11-12 07:45:00', 1, NULL),
(318, 5, '2024-11-13 10:58:00', 1, NULL),
(351, 3, '2024-11-13 09:02:00', 1, 'This check-out for reservation 351 captured some notes as test data.'),
(374, 5, '2024-11-13 10:12:00', 1, NULL),
(367, 5, '2024-11-14 08:44:00', 1, NULL),
(372, 5, '2024-11-14 10:18:00', 0, NULL),
(314, 4, '2024-11-14 07:33:00', 1, NULL),
(359, 3, '2024-11-14 07:31:00', 1, NULL),
(323, 4, '2024-11-14 10:29:00', 1, NULL),
(329, 4, '2024-11-14 10:36:00', 0, NULL),
(363, 2, '2024-11-14 07:37:00', 1, NULL),
(383, 2, '2024-11-15 07:45:00', 1, 'This check-out for reservation 383 captured some notes as test data.'),
(325, 3, '2024-11-15 08:30:00', 1, NULL),
(5, 2, '2024-11-16 10:11:00', 1, NULL),
(339, 5, '2024-11-16 08:02:00', 1, NULL),
(400, 3, '2024-11-17 08:19:00', 1, NULL),
(369, 3, '2024-11-17 10:00:00', 1, NULL),
(403, 5, '2024-11-17 07:22:00', 1, NULL),
(361, 5, '2024-11-17 07:40:00', 1, 'This check-out for reservation 361 captured some notes as test data.'),
(358, 4, '2024-11-17 10:44:00', 1, NULL),
(340, 4, '2024-11-18 08:30:00', 0, NULL),
(366, 3, '2024-11-18 08:29:00', 1, 'This check-out for reservation 366 captured some notes as test data.'),
(364, 2, '2024-11-18 08:21:00', 1, NULL),
(349, 3, '2024-11-18 09:13:00', 1, NULL),
(390, 5, '2024-11-19 09:02:00', 1, 'This check-out for reservation 390 captured some notes as test data.'),
(344, 4, '2024-11-19 09:41:00', 1, NULL),
(357, 3, '2024-11-19 10:42:00', 1, NULL),
(404, 4, '2024-11-19 07:19:00', 0, 'This check-out for reservation 404 captured some notes as test data.'),
(375, 3, '2024-11-19 07:41:00', 0, NULL),
(399, 4, '2024-11-19 09:22:00', 1, NULL),
(360, 4, '2024-11-19 10:09:00', 1, NULL),
(343, 2, '2024-11-20 08:55:00', 1, NULL),
(391, 5, '2024-11-20 09:40:00', 1, NULL),
(354, 4, '2024-11-20 09:43:00', 1, NULL),
(388, 3, '2024-11-20 08:10:00', 1, NULL),
(407, 3, '2024-11-20 08:48:00', 1, NULL),
(420, 3, '2024-11-20 08:45:00', 1, NULL);

INSERT INTO cleaning_session (date_of_clean, staff_id, allocated_master_key) VALUES
('2024-10-21', 7, 'A'),
('2024-10-21', 8, 'C'),
('2024-10-22', 7, 'B'),
('2024-10-22', 8, 'C'),
('2024-10-23', 8, 'A'),
('2024-10-23', 9, 'F'),
('2024-11-11', 6, 'R'),
('2024-11-11', 8, 'H'),
('2024-11-11', 9, 'T'),
('2024-11-12', 6, 'G'),
('2024-11-12', 8, 'U'),
('2024-11-12', 9, 'X'),
('2024-11-13', 7, 'C'),
('2024-11-13', 8, 'L'),
('2024-11-13', 9, 'V'),
('2024-11-14', 7, 'F'),
('2024-11-14', 8, 'E'),
('2024-11-14', 9, 'Y'),
('2024-11-15', 6, 'U'),
('2024-11-15', 7, 'O'),
('2024-11-15', 8, 'G'),
('2024-11-16', 6, 'P'),
('2024-11-16', 8, 'C'),
('2024-11-16', 9, 'D'),
('2024-11-17', 6, 'G'),
('2024-11-17', 8, 'T'),
('2024-11-17', 9, 'E');

INSERT INTO room_clean (room_number, date_of_clean, staff_id, time_of_clean, type_of_clean) VALUES
(101, '2024-10-21', 7, '09:30', 'F'),
(102, '2024-10-21', 7, '10:00', 'L'),
(103, '2024-10-21', 7, '10:15', 'L'),
(201, '2024-10-21', 8, '09:30', 'F'),
(202, '2024-10-21', 8, '10:00', 'F'),
(203, '2024-10-21', 8, '10:30', 'L'),
(101, '2024-10-22', 7, '09:30', 'L'),
(102, '2024-10-22', 7, '09:45', 'F'),
(103, '2024-10-22', 7, '10:15', 'F'),
(201, '2024-10-22', 8, '09:30', 'L'),
(101, '2024-11-11', 6, '09:00', 'L'),
(102, '2024-11-11', 6, '09:15', 'L'),
(103, '2024-11-11', 6, '09:30', 'L'),
(104, '2024-11-11', 6, '09:45', 'L'),
(105, '2024-11-11', 6, '10:00', 'L'),
(106, '2024-11-11', 6, '10:15', 'L'),
(107, '2024-11-11', 6, '10:30', 'F'),
(108, '2024-11-11', 6, '11:00', 'L'),
(109, '2024-11-11', 6, '11:15', 'L'),
(110, '2024-11-11', 8, '09:00', 'L'),
(111, '2024-11-11', 8, '09:15', 'L'),
(112, '2024-11-11', 8, '09:30', 'L'),
(201, '2024-11-11', 8, '09:45', 'L'),
(202, '2024-11-11', 8, '10:00', 'L'),
(203, '2024-11-11', 8, '10:15', 'L'),
(204, '2024-11-11', 8, '10:30', 'F'),
(205, '2024-11-11', 8, '11:00', 'L'),
(206, '2024-11-11', 8, '11:15', 'F'),
(207, '2024-11-11', 9, '09:00', 'L'),
(208, '2024-11-11', 9, '09:15', 'L'),
(209, '2024-11-11', 9, '09:30', 'L'),
(210, '2024-11-11', 9, '09:45', 'L'),
(211, '2024-11-11', 9, '10:00', 'F'),
(212, '2024-11-11', 9, '10:30', 'L'),
(213, '2024-11-11', 9, '10:45', 'F'),
(101, '2024-11-12', 6, '09:00', 'L'),
(102, '2024-11-12', 6, '09:15', 'L'),
(103, '2024-11-12', 6, '09:30', 'F'),
(104, '2024-11-12', 6, '10:00', 'L'),
(105, '2024-11-12', 6, '10:15', 'L'),
(106, '2024-11-12', 6, '10:30', 'L'),
(107, '2024-11-12', 6, '10:45', 'L'),
(108, '2024-11-12', 6, '11:00', 'L'),
(109, '2024-11-12', 6, '11:15', 'L'),
(110, '2024-11-12', 8, '09:00', 'L'),
(111, '2024-11-12', 8, '09:15', 'L'),
(112, '2024-11-12', 8, '09:30', 'L'),
(201, '2024-11-12', 8, '09:45', 'L'),
(202, '2024-11-12', 8, '10:00', 'L'),
(203, '2024-11-12', 8, '10:15', 'L'),
(204, '2024-11-12', 8, '10:30', 'L'),
(205, '2024-11-12', 8, '10:45', 'L'),
(206, '2024-11-12', 8, '11:00', 'L'),
(207, '2024-11-12', 8, '11:15', 'L'),
(208, '2024-11-12', 9, '09:00', 'F'),
(209, '2024-11-12', 9, '09:30', 'F'),
(210, '2024-11-12', 9, '10:00', 'F'),
(211, '2024-11-12', 9, '10:30', 'L'),
(212, '2024-11-12', 9, '10:45', 'L'),
(213, '2024-11-12', 9, '11:00', 'L'),
(101, '2024-11-13', 7, '09:00', 'L'),
(102, '2024-11-13', 7, '09:15', 'L'),
(103, '2024-11-13', 7, '09:30', 'L'),
(104, '2024-11-13', 7, '09:45', 'L'),
(105, '2024-11-13', 7, '10:00', 'L'),
(106, '2024-11-13', 7, '10:15', 'L'),
(107, '2024-11-13', 7, '10:30', 'L'),
(108, '2024-11-13', 7, '10:45', 'L'),
(109, '2024-11-13', 7, '11:00', 'L'),
(110, '2024-11-13', 7, '11:15', 'L'),
(111, '2024-11-13', 8, '09:00', 'L'),
(112, '2024-11-13', 8, '09:15', 'L'),
(201, '2024-11-13', 8, '09:30', 'L'),
(202, '2024-11-13', 8, '09:45', 'L'),
(203, '2024-11-13', 8, '10:00', 'L'),
(204, '2024-11-13', 8, '10:15', 'L'),
(205, '2024-11-13', 8, '10:30', 'F'),
(206, '2024-11-13', 8, '11:00', 'L'),
(207, '2024-11-13', 8, '11:15', 'F'),
(208, '2024-11-13', 9, '09:00', 'L'),
(209, '2024-11-13', 9, '09:15', 'L'),
(210, '2024-11-13', 9, '09:30', 'F'),
(211, '2024-11-13', 9, '10:00', 'L'),
(212, '2024-11-13', 9, '10:15', 'L'),
(213, '2024-11-13', 9, '10:30', 'L'),
(101, '2024-11-14', 7, '09:00', 'L'),
(102, '2024-11-14', 7, '09:15', 'L'),
(103, '2024-11-14', 7, '09:30', 'L'),
(104, '2024-11-14', 7, '09:45', 'L'),
(105, '2024-11-14', 7, '10:00', 'L'),
(106, '2024-11-14', 7, '10:15', 'L'),
(107, '2024-11-14', 7, '10:30', 'L'),
(108, '2024-11-14', 7, '10:45', 'L'),
(109, '2024-11-14', 7, '11:00', 'L'),
(110, '2024-11-14', 7, '11:15', 'L'),
(111, '2024-11-14', 7, '11:30', 'F'),
(112, '2024-11-14', 8, '09:00', 'F'),
(201, '2024-11-14', 8, '09:30', 'F'),
(202, '2024-11-14', 8, '10:00', 'L'),
(203, '2024-11-14', 8, '10:15', 'L'),
(204, '2024-11-14', 8, '10:30', 'L'),
(205, '2024-11-14', 8, '10:45', 'F'),
(206, '2024-11-14', 8, '11:15', 'F'),
(207, '2024-11-14', 9, '09:00', 'L'),
(208, '2024-11-14', 9, '09:15', 'L'),
(209, '2024-11-14', 9, '09:30', 'L'),
(210, '2024-11-14', 9, '09:45', 'L'),
(211, '2024-11-14', 9, '10:00', 'F'),
(212, '2024-11-14', 9, '10:30', 'L'),
(213, '2024-11-14', 9, '10:45', 'F'),
(101, '2024-11-15', 6, '09:00', 'L'),
(102, '2024-11-15', 6, '09:15', 'L'),
(103, '2024-11-15', 6, '09:30', 'L'),
(104, '2024-11-15', 6, '09:45', 'L'),
(105, '2024-11-15', 6, '10:00', 'L'),
(106, '2024-11-15', 6, '10:15', 'L'),
(107, '2024-11-15', 6, '10:30', 'L'),
(108, '2024-11-15', 6, '10:45', 'L'),
(109, '2024-11-15', 6, '11:00', 'L'),
(110, '2024-11-15', 7, '09:00', 'F'),
(111, '2024-11-15', 7, '09:30', 'L'),
(112, '2024-11-15', 7, '09:45', 'L'),
(201, '2024-11-15', 7, '10:00', 'L'),
(202, '2024-11-15', 7, '10:15', 'L'),
(203, '2024-11-15', 7, '10:30', 'L'),
(204, '2024-11-15', 7, '10:45', 'L'),
(205, '2024-11-15', 7, '11:00', 'L'),
(206, '2024-11-15', 8, '09:00', 'L'),
(207, '2024-11-15', 8, '09:15', 'L'),
(208, '2024-11-15', 8, '09:30', 'F'),
(209, '2024-11-15', 8, '10:00', 'L'),
(210, '2024-11-15', 8, '10:15', 'L'),
(211, '2024-11-15', 8, '10:30', 'L'),
(212, '2024-11-15', 8, '10:45', 'L'),
(213, '2024-11-15', 8, '11:00', 'L'),
(101, '2024-11-16', 6, '09:00', 'F'),
(102, '2024-11-16', 6, '09:30', 'L'),
(103, '2024-11-16', 6, '09:45', 'L'),
(104, '2024-11-16', 6, '10:00', 'L'),
(105, '2024-11-16', 6, '10:15', 'L'),
(106, '2024-11-16', 6, '10:30', 'L'),
(107, '2024-11-16', 6, '10:45', 'L'),
(108, '2024-11-16', 6, '11:00', 'L'),
(109, '2024-11-16', 8, '09:00', 'L'),
(110, '2024-11-16', 8, '09:15', 'L'),
(111, '2024-11-16', 8, '09:30', 'L'),
(112, '2024-11-16', 8, '09:45', 'L'),
(201, '2024-11-16', 8, '10:00', 'L'),
(202, '2024-11-16', 8, '10:15', 'L'),
(203, '2024-11-16', 8, '10:30', 'L'),
(204, '2024-11-16', 8, '10:45', 'L'),
(205, '2024-11-16', 8, '11:00', 'L'),
(206, '2024-11-16', 9, '09:00', 'L'),
(207, '2024-11-16', 9, '09:15', 'L'),
(208, '2024-11-16', 9, '09:30', 'L'),
(209, '2024-11-16', 9, '09:45', 'L'),
(210, '2024-11-16', 9, '10:00', 'L'),
(211, '2024-11-16', 9, '10:15', 'L'),
(212, '2024-11-16', 9, '10:30', 'F'),
(213, '2024-11-16', 9, '11:00', 'L'),
(101, '2024-11-17', 6, '09:00', 'L'),
(102, '2024-11-17', 6, '09:15', 'F'),
(103, '2024-11-17', 6, '09:45', 'L'),
(104, '2024-11-17', 6, '10:00', 'L'),
(105, '2024-11-17', 6, '10:15', 'L'),
(106, '2024-11-17', 6, '10:30', 'F'),
(107, '2024-11-17', 6, '11:00', 'F'),
(108, '2024-11-17', 8, '09:00', 'L'),
(109, '2024-11-17', 8, '09:15', 'L'),
(110, '2024-11-17', 8, '09:30', 'L'),
(111, '2024-11-17', 8, '09:45', 'L'),
(112, '2024-11-17', 8, '10:00', 'L'),
(201, '2024-11-17', 8, '10:15', 'L'),
(202, '2024-11-17', 8, '10:30', 'L'),
(203, '2024-11-17', 8, '10:45', 'L'),
(204, '2024-11-17', 8, '11:00', 'F'),
(205, '2024-11-17', 9, '09:00', 'L'),
(206, '2024-11-17', 9, '09:15', 'F'),
(207, '2024-11-17', 9, '09:45', 'L'),
(208, '2024-11-17', 9, '10:00', 'L'),
(209, '2024-11-17', 9, '10:15', 'L'),
(210, '2024-11-17', 9, '10:30', 'L'),
(211, '2024-11-17', 9, '10:45', 'L'),
(212, '2024-11-17', 9, '11:00', 'L'),
(213, '2024-11-17', 9, '11:15', 'L');


----------------------------

CREATE DATABASE  IF NOT EXISTS `hotel_db` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `hotel_db`;
-- MySQL dump 10.13  Distrib 8.0.40, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: hotel_db
-- ------------------------------------------------------
-- Server version	8.0.40

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `address`
--

DROP TABLE IF EXISTS `address`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `address` (
  `postcode` varchar(8) NOT NULL,
  `address_line1` varchar(80) NOT NULL,
  `address_line2` varchar(80) DEFAULT NULL,
  `city` varchar(80) NOT NULL,
  `county` varchar(80) NOT NULL,
  PRIMARY KEY (`postcode`),
  CONSTRAINT `CHK_postcode` CHECK (regexp_like(`postcode`,_utf8mb4'^[A-Z]{1,2}[0-9][0-9A-Z]? [0-9][A-Z]{2}$'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `address`
--

LOCK TABLES `address` WRITE;
/*!40000 ALTER TABLE `address` DISABLE KEYS */;
INSERT INTO `address` VALUES ('CB22 3AA','High Street','Great Shelford','Cambridge','Cambridgeshire'),('CB24 9GH','Mill Lane','Willingham','Cambridge','Cambridgeshire'),('CM1 4FG','Back Lane','Little Waltham','Chelmsford','Essex'),('CO10 1CD','The Street','Cavendish','Sudbury','Suffolk'),('CO10 7MN','Church Road','Long Melford','Sudbury','Suffolk'),('CO11 1US','Riverside Ave E','Lawford','Manningtree','Suffolk'),('IP1 2AN','Civic Dr','','Ipswich','Suffolk'),('IP28 8AA','The Green','Mildenhall','Bury St Edmunds','Suffolk'),('IP7 6IJ','Mill Street','Hadleigh','Ipswich','Suffolk'),('NR14 6AB','Church Lane','Bramerton','Norwich','Norfolk'),('NR20 5KL','The Street','Horsham St Faith','Norwich','Norfolk'),('PE36 5DE','Main Road','Snettisham','Kings Lynn','Norfolk'),('TS1 1AA','Test Street 1','Test Town A','Test City 1','Test County 1'),('TS1 2AA','Test Street 2','Test Town A','Test City 1','Test County 1'),('TS1 3AA','Test Street 3','Test Town A','Test City 1','Test County 1'),('TS1 4AA','Test Street 4','Test Town A','Test City 1','Test County 1'),('TS1 5AA','Test Street 5','Test Town A','Test City 1','Test County 1'),('TS1 6AA','Test Street 6','Test Town A','Test City 1','Test County 1'),('TS1 7AA','Test Street 7','Test Town A','Test City 1','Test County 1'),('TS1 8AA','Test Street 8','Test Town A','Test City 1','Test County 1'),('TS1 9AA','Test Street 9','Test Town A','Test City 1','Test County 1'),('TS2 0AB','Test Street 10','Test Town B','Test City 2','Test County 2'),('TS2 1AB','Test Street 11','Test Town B','Test City 2','Test County 2'),('TS2 2AB','Test Street 12','Test Town B','Test City 2','Test County 2'),('TS2 3AB','Test Street 13','Test Town B','Test City 2','Test County 2'),('TS2 4AB','Test Street 14','Test Town B','Test City 2','Test County 2'),('TS2 5AB','Test Street 15','Test Town B','Test City 2','Test County 2'),('TS2 6AB','Test Street 16','Test Town B','Test City 2','Test County 2'),('TS2 7AB','Test Street 17','Test Town B','Test City 2','Test County 2'),('TS2 8AB','Test Street 18','Test Town B','Test City 2','Test County 2'),('TS2 9AB','Test Street 19','Test Town B','Test City 2','Test County 2'),('TS3 0AC','Test Street 20','Test Town C','Test City 3','Test County 3'),('TS3 1AC','Test Street 21','Test Town C','Test City 3','Test County 3'),('TS3 2AC','Test Street 22','Test Town C','Test City 3','Test County 3'),('TS3 3AC','Test Street 23','Test Town C','Test City 3','Test County 3');
/*!40000 ALTER TABLE `address` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bathroom_type`
--

DROP TABLE IF EXISTS `bathroom_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bathroom_type` (
  `bathroom_type_code` char(2) NOT NULL,
  `bathroom_type_name` varchar(50) NOT NULL,
  `seperate_shower` tinyint NOT NULL,
  `bath` tinyint NOT NULL,
  PRIMARY KEY (`bathroom_type_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bathroom_type`
--

LOCK TABLES `bathroom_type` WRITE;
/*!40000 ALTER TABLE `bathroom_type` DISABLE KEYS */;
INSERT INTO `bathroom_type` VALUES ('B1','Shower Only',1,0),('B2','Small',0,1),('B3','Deluxe Bathroom',1,1),('B4','Executive',1,1);
/*!40000 ALTER TABLE `bathroom_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `check_in`
--

DROP TABLE IF EXISTS `check_in`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `check_in` (
  `reservation_id` int NOT NULL,
  `staff_id` smallint NOT NULL,
  `date_time` datetime NOT NULL,
  `notes` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`reservation_id`),
  KEY `staff_id` (`staff_id`),
  CONSTRAINT `check_in_ibfk_1` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`staff_id`),
  CONSTRAINT `check_in_ibfk_2` FOREIGN KEY (`reservation_id`) REFERENCES `reservation` (`reservation_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `check_in`
--

LOCK TABLES `check_in` WRITE;
/*!40000 ALTER TABLE `check_in` DISABLE KEYS */;
INSERT INTO `check_in` VALUES (1,2,'2024-10-21 16:14:00',NULL),(2,4,'2024-10-24 14:05:00','guest asked about the security of the car park'),(3,3,'2024-10-25 15:18:00',NULL),(4,3,'2024-10-26 18:51:00','advised guest about local restaurants'),(5,5,'2024-11-11 14:35:00',NULL),(6,5,'2024-08-16 19:46:00','This check-in for reservation 6 captured some notes as test data.'),(7,4,'2024-08-13 13:47:00',NULL),(8,5,'2024-08-24 15:25:00',NULL),(9,2,'2024-08-23 13:10:00',NULL),(10,2,'2024-08-21 22:49:00',NULL),(11,2,'2024-08-19 17:22:00',NULL),(12,4,'2024-08-23 20:29:00',NULL),(13,2,'2024-08-23 15:07:00',NULL),(14,5,'2024-08-20 18:36:00',NULL),(15,4,'2024-08-20 15:41:00',NULL),(16,4,'2024-08-14 21:45:00',NULL),(17,2,'2024-08-15 15:23:00',NULL),(18,2,'2024-08-15 21:27:00','This check-in for reservation 18 captured some notes as test data.'),(19,2,'2024-08-17 15:04:00',NULL),(20,5,'2024-08-26 16:28:00','This check-in for reservation 20 captured some notes as test data.'),(21,5,'2024-08-28 19:09:00',NULL),(22,4,'2024-08-25 15:27:00','This check-in for reservation 22 captured some notes as test data.'),(23,3,'2024-08-19 13:36:00',NULL),(24,2,'2024-08-22 18:15:00','This check-in for reservation 24 captured some notes as test data.'),(25,4,'2024-08-16 14:13:00',NULL),(26,2,'2024-09-03 20:35:00','This check-in for reservation 26 captured some notes as test data.'),(27,5,'2024-08-31 17:38:00',NULL),(28,3,'2024-08-25 14:31:00',NULL),(29,3,'2024-08-20 14:12:00','This check-in for reservation 29 captured some notes as test data.'),(30,4,'2024-09-03 20:51:00','This check-in for reservation 30 captured some notes as test data.'),(31,2,'2024-09-01 19:25:00','This check-in for reservation 31 captured some notes as test data.'),(32,3,'2024-08-19 20:12:00',NULL),(33,2,'2024-08-21 21:42:00',NULL),(34,2,'2024-08-17 13:37:00',NULL),(35,3,'2024-09-02 15:24:00',NULL),(36,5,'2024-08-26 17:06:00',NULL),(37,3,'2024-08-26 14:25:00',NULL),(38,2,'2024-08-27 17:04:00',NULL),(39,4,'2024-08-31 19:59:00',NULL),(40,5,'2024-08-25 14:51:00',NULL),(41,3,'2024-08-20 16:06:00','This check-in for reservation 41 captured some notes as test data.'),(42,3,'2024-09-01 14:00:00',NULL),(43,3,'2024-09-02 20:47:00',NULL),(44,5,'2024-09-01 15:55:00',NULL),(45,4,'2024-08-25 18:30:00',NULL),(46,5,'2024-08-31 13:25:00','This check-in for reservation 46 captured some notes as test data.'),(47,5,'2024-09-06 19:09:00',NULL),(48,5,'2024-08-27 14:35:00',NULL),(49,5,'2024-09-02 13:56:00',NULL),(50,2,'2024-09-03 18:37:00',NULL),(51,5,'2024-09-02 15:34:00',NULL),(52,4,'2024-08-26 14:12:00',NULL),(53,2,'2024-08-25 19:53:00',NULL),(54,3,'2024-09-04 15:17:00',NULL),(55,5,'2024-08-30 14:30:00',NULL),(56,4,'2024-08-30 19:16:00','This check-in for reservation 56 captured some notes as test data.'),(57,2,'2024-08-22 18:24:00',NULL),(58,3,'2024-09-05 17:05:00','This check-in for reservation 58 captured some notes as test data.'),(59,4,'2024-08-25 15:03:00',NULL),(60,3,'2024-09-05 16:06:00',NULL),(61,3,'2024-08-26 15:33:00','This check-in for reservation 61 captured some notes as test data.'),(62,4,'2024-08-28 13:19:00',NULL),(63,2,'2024-08-23 15:03:00',NULL),(64,3,'2024-09-07 16:52:00',NULL),(65,5,'2024-09-05 18:12:00',NULL),(66,2,'2024-09-02 14:38:00',NULL),(67,5,'2024-09-11 17:21:00',NULL),(68,5,'2024-09-11 13:05:00',NULL),(69,4,'2024-08-29 17:25:00',NULL),(70,5,'2024-09-02 15:46:00',NULL),(71,3,'2024-09-12 15:19:00',NULL),(72,4,'2024-08-27 14:01:00',NULL),(73,5,'2024-09-07 17:06:00',NULL),(74,4,'2024-09-01 13:35:00',NULL),(75,3,'2024-09-09 22:57:00',NULL),(76,5,'2024-09-04 18:38:00','This check-in for reservation 76 captured some notes as test data.'),(77,4,'2024-08-29 17:13:00',NULL),(78,4,'2024-09-06 16:49:00',NULL),(79,4,'2024-09-13 22:59:00','This check-in for reservation 79 captured some notes as test data.'),(80,4,'2024-09-08 13:14:00',NULL),(81,4,'2024-09-12 13:38:00',NULL),(82,4,'2024-09-04 18:58:00',NULL),(83,2,'2024-09-17 19:47:00','This check-in for reservation 83 captured some notes as test data.'),(84,4,'2024-09-16 14:47:00',NULL),(85,4,'2024-09-14 21:31:00',NULL),(86,5,'2024-09-06 21:54:00',NULL),(87,2,'2024-09-17 14:45:00',NULL),(88,4,'2024-09-06 16:40:00','This check-in for reservation 88 captured some notes as test data.'),(89,3,'2024-09-06 20:47:00',NULL),(90,5,'2024-09-03 22:42:00',NULL),(91,5,'2024-09-04 15:24:00',NULL),(92,5,'2024-09-14 16:21:00','This check-in for reservation 92 captured some notes as test data.'),(93,3,'2024-09-04 18:22:00',NULL),(94,5,'2024-09-09 19:22:00',NULL),(95,2,'2024-09-07 20:11:00',NULL),(96,5,'2024-09-21 17:39:00',NULL),(97,2,'2024-09-16 16:40:00',NULL),(98,4,'2024-09-13 14:57:00',NULL),(99,5,'2024-09-16 20:37:00',NULL),(100,5,'2024-09-15 15:30:00',NULL),(101,2,'2024-09-07 19:33:00',NULL),(102,3,'2024-09-20 18:03:00',NULL),(103,3,'2024-09-16 19:22:00',NULL),(104,5,'2024-09-07 22:25:00',NULL),(105,5,'2024-09-09 21:38:00',NULL),(106,5,'2024-09-08 22:28:00',NULL),(107,4,'2024-09-15 15:45:00','This check-in for reservation 107 captured some notes as test data.'),(108,3,'2024-09-11 22:39:00',NULL),(109,5,'2024-09-14 20:04:00','This check-in for reservation 109 captured some notes as test data.'),(110,4,'2024-09-12 21:55:00',NULL),(111,4,'2024-09-09 22:09:00',NULL),(112,4,'2024-09-12 20:20:00','This check-in for reservation 112 captured some notes as test data.'),(113,3,'2024-09-10 14:06:00',NULL),(114,3,'2024-09-14 14:10:00',NULL),(115,2,'2024-09-16 21:08:00',NULL),(116,4,'2024-09-22 16:33:00','This check-in for reservation 116 captured some notes as test data.'),(117,2,'2024-09-10 14:38:00',NULL),(118,2,'2024-09-10 20:48:00',NULL),(119,5,'2024-09-11 19:40:00',NULL),(120,3,'2024-09-07 14:32:00','This check-in for reservation 120 captured some notes as test data.'),(121,2,'2024-09-23 19:05:00',NULL),(122,3,'2024-09-26 22:32:00',NULL),(123,4,'2024-09-08 14:31:00',NULL),(124,2,'2024-09-22 21:31:00','This check-in for reservation 124 captured some notes as test data.'),(125,5,'2024-09-11 13:22:00','This check-in for reservation 125 captured some notes as test data.'),(126,2,'2024-09-09 18:57:00',NULL),(127,3,'2024-09-14 14:21:00',NULL),(128,3,'2024-09-10 14:55:00','This check-in for reservation 128 captured some notes as test data.'),(129,3,'2024-09-11 17:26:00',NULL),(130,4,'2024-09-23 20:16:00',NULL),(131,4,'2024-09-18 20:32:00',NULL),(132,4,'2024-09-17 17:10:00','This check-in for reservation 132 captured some notes as test data.'),(133,3,'2024-09-11 21:01:00',NULL),(134,4,'2024-09-24 17:04:00',NULL),(135,3,'2024-09-23 14:26:00',NULL),(136,3,'2024-09-15 13:58:00',NULL),(137,4,'2024-09-30 14:41:00','This check-in for reservation 137 captured some notes as test data.'),(138,5,'2024-09-21 20:46:00',NULL),(139,5,'2024-09-18 20:41:00',NULL),(140,3,'2024-09-27 16:53:00','This check-in for reservation 140 captured some notes as test data.'),(141,2,'2024-09-30 20:56:00',NULL),(142,3,'2024-09-14 18:34:00','This check-in for reservation 142 captured some notes as test data.'),(143,3,'2024-09-19 21:18:00',NULL),(144,5,'2024-09-28 15:38:00',NULL),(145,2,'2024-09-24 19:22:00',NULL),(146,2,'2024-09-20 15:54:00',NULL),(147,3,'2024-09-16 21:48:00','This check-in for reservation 147 captured some notes as test data.'),(148,2,'2024-09-19 15:25:00','This check-in for reservation 148 captured some notes as test data.'),(149,3,'2024-09-29 13:21:00',NULL),(150,3,'2024-09-21 18:32:00',NULL),(151,4,'2024-09-25 18:45:00',NULL),(152,3,'2024-09-25 15:41:00',NULL),(153,5,'2024-09-26 19:20:00','This check-in for reservation 153 captured some notes as test data.'),(154,2,'2024-10-01 16:26:00',NULL),(155,4,'2024-09-29 18:28:00',NULL),(156,5,'2024-10-06 22:37:00',NULL),(157,3,'2024-09-27 18:59:00',NULL),(158,5,'2024-09-21 17:36:00','This check-in for reservation 158 captured some notes as test data.'),(159,4,'2024-10-04 19:06:00',NULL),(160,3,'2024-09-30 22:00:00',NULL),(161,2,'2024-09-27 20:56:00',NULL),(162,5,'2024-09-30 17:28:00',NULL),(163,4,'2024-09-28 15:06:00',NULL),(164,2,'2024-09-27 15:38:00','This check-in for reservation 164 captured some notes as test data.'),(165,4,'2024-10-06 18:30:00',NULL),(166,4,'2024-09-28 13:52:00',NULL),(167,3,'2024-10-02 15:43:00','This check-in for reservation 167 captured some notes as test data.'),(168,4,'2024-09-28 19:36:00',NULL),(169,3,'2024-09-29 15:37:00',NULL),(170,3,'2024-09-23 20:11:00','This check-in for reservation 170 captured some notes as test data.'),(171,3,'2024-10-01 17:28:00',NULL),(172,2,'2024-10-07 20:49:00',NULL),(173,5,'2024-09-24 20:03:00',NULL),(174,5,'2024-09-29 16:42:00',NULL),(175,3,'2024-09-22 20:58:00',NULL),(176,3,'2024-09-28 22:28:00','This check-in for reservation 176 captured some notes as test data.'),(177,5,'2024-09-28 20:06:00',NULL),(178,3,'2024-10-04 22:45:00',NULL),(179,3,'2024-09-25 17:59:00',NULL),(180,3,'2024-10-03 16:35:00',NULL),(181,4,'2024-09-24 13:30:00',NULL),(182,5,'2024-10-09 13:59:00',NULL),(183,5,'2024-09-22 21:27:00',NULL),(184,2,'2024-10-08 14:19:00',NULL),(185,3,'2024-10-11 21:39:00',NULL),(186,5,'2024-09-30 13:46:00',NULL),(187,5,'2024-09-29 22:52:00',NULL),(188,4,'2024-10-04 20:09:00',NULL),(189,2,'2024-10-11 16:04:00',NULL),(190,3,'2024-10-11 15:58:00',NULL),(191,5,'2024-09-30 22:52:00',NULL),(192,5,'2024-10-07 20:51:00',NULL),(193,3,'2024-10-15 20:29:00','This check-in for reservation 193 captured some notes as test data.'),(194,2,'2024-10-13 21:31:00',NULL),(195,4,'2024-10-12 16:45:00',NULL),(196,4,'2024-10-11 16:41:00',NULL),(197,3,'2024-10-11 22:09:00',NULL),(198,2,'2024-10-07 15:15:00',NULL),(199,3,'2024-10-06 18:59:00','This check-in for reservation 199 captured some notes as test data.'),(200,3,'2024-10-11 18:07:00',NULL),(201,3,'2024-10-05 19:16:00',NULL),(202,2,'2024-10-06 17:29:00',NULL),(203,5,'2024-10-13 15:39:00',NULL),(204,4,'2024-10-11 15:33:00',NULL),(205,5,'2024-10-16 13:51:00',NULL),(206,2,'2024-10-15 15:47:00',NULL),(207,4,'2024-10-16 20:43:00',NULL),(208,4,'2024-10-02 19:52:00',NULL),(209,4,'2024-10-18 18:40:00',NULL),(210,3,'2024-10-20 15:35:00',NULL),(211,3,'2024-10-10 14:53:00','This check-in for reservation 211 captured some notes as test data.'),(212,5,'2024-10-11 18:04:00',NULL),(213,5,'2024-10-03 22:36:00',NULL),(214,4,'2024-10-03 13:09:00','This check-in for reservation 214 captured some notes as test data.'),(215,5,'2024-10-20 13:15:00',NULL),(216,4,'2024-10-11 14:53:00',NULL),(217,3,'2024-10-10 19:52:00',NULL),(218,3,'2024-10-05 17:55:00','This check-in for reservation 218 captured some notes as test data.'),(219,5,'2024-10-09 17:16:00',NULL),(220,5,'2024-10-18 17:01:00',NULL),(221,3,'2024-10-05 17:18:00',NULL),(222,4,'2024-10-04 22:57:00',NULL),(223,2,'2024-10-09 13:18:00','This check-in for reservation 223 captured some notes as test data.'),(224,2,'2024-10-20 22:23:00',NULL),(225,5,'2024-10-20 21:26:00',NULL),(226,4,'2024-10-22 19:00:00',NULL),(227,2,'2024-10-15 17:45:00',NULL),(228,3,'2024-10-18 18:58:00',NULL),(229,5,'2024-10-14 21:10:00',NULL),(230,4,'2024-10-06 21:09:00',NULL),(231,4,'2024-10-20 17:59:00',NULL),(232,5,'2024-10-13 18:17:00','This check-in for reservation 232 captured some notes as test data.'),(233,5,'2024-10-24 16:10:00',NULL),(234,5,'2024-10-17 19:33:00',NULL),(235,4,'2024-10-14 13:44:00',NULL),(236,4,'2024-10-23 16:28:00',NULL),(237,2,'2024-10-17 13:05:00',NULL),(238,2,'2024-10-20 16:08:00',NULL),(239,4,'2024-10-24 20:45:00',NULL),(240,3,'2024-10-16 18:58:00',NULL),(241,3,'2024-10-13 19:04:00','This check-in for reservation 241 captured some notes as test data.'),(242,4,'2024-10-16 13:05:00',NULL),(243,5,'2024-10-24 14:35:00',NULL),(244,2,'2024-10-24 21:02:00','This check-in for reservation 244 captured some notes as test data.'),(245,5,'2024-10-26 18:37:00',NULL),(246,5,'2024-10-28 22:42:00',NULL),(247,2,'2024-10-19 14:12:00',NULL),(248,4,'2024-10-18 19:39:00',NULL),(249,4,'2024-10-28 21:08:00',NULL),(250,2,'2024-10-15 22:11:00',NULL),(251,3,'2024-10-21 22:47:00',NULL),(252,2,'2024-10-24 18:20:00',NULL),(253,3,'2024-10-20 21:28:00',NULL),(254,3,'2024-10-14 14:45:00',NULL),(255,5,'2024-10-20 15:25:00',NULL),(256,4,'2024-10-13 17:23:00',NULL),(257,4,'2024-10-21 16:46:00',NULL),(258,2,'2024-10-17 14:21:00',NULL),(259,2,'2024-10-26 17:13:00',NULL),(260,5,'2024-10-29 17:09:00','This check-in for reservation 260 captured some notes as test data.'),(261,5,'2024-10-30 16:02:00',NULL),(262,5,'2024-10-15 17:26:00',NULL),(263,4,'2024-10-26 15:39:00',NULL),(264,2,'2024-11-01 15:52:00',NULL),(265,5,'2024-10-17 16:24:00',NULL),(266,4,'2024-10-30 18:59:00',NULL),(267,5,'2024-10-27 19:20:00',NULL),(268,5,'2024-10-28 13:30:00',NULL),(269,5,'2024-10-24 18:00:00',NULL),(270,2,'2024-10-19 18:05:00',NULL),(271,3,'2024-10-15 15:06:00',NULL),(272,3,'2024-10-26 19:58:00',NULL),(273,2,'2024-10-30 14:15:00',NULL),(274,5,'2024-10-17 15:59:00',NULL),(275,4,'2024-10-16 22:44:00','This check-in for reservation 275 captured some notes as test data.'),(276,5,'2024-10-31 13:13:00','This check-in for reservation 276 captured some notes as test data.'),(277,3,'2024-10-18 13:48:00',NULL),(278,5,'2024-10-28 16:51:00',NULL),(279,3,'2024-10-30 21:36:00',NULL),(280,2,'2024-10-24 13:23:00',NULL),(281,4,'2024-10-25 21:01:00',NULL),(282,3,'2024-10-17 18:51:00',NULL),(283,2,'2024-11-04 19:05:00','This check-in for reservation 283 captured some notes as test data.'),(284,2,'2024-10-19 17:17:00',NULL),(285,5,'2024-10-23 16:36:00',NULL),(286,3,'2024-10-21 18:06:00',NULL),(287,3,'2024-10-27 17:16:00',NULL),(288,2,'2024-11-03 17:18:00',NULL),(289,4,'2024-10-31 17:30:00','This check-in for reservation 289 captured some notes as test data.'),(290,2,'2024-11-02 19:37:00',NULL),(291,2,'2024-10-24 19:22:00',NULL),(292,2,'2024-11-05 16:52:00','This check-in for reservation 292 captured some notes as test data.'),(293,2,'2024-10-24 14:32:00',NULL),(294,4,'2024-10-21 20:47:00','This check-in for reservation 294 captured some notes as test data.'),(295,3,'2024-11-04 13:26:00','This check-in for reservation 295 captured some notes as test data.'),(296,3,'2024-10-24 20:34:00',NULL),(297,3,'2024-10-25 19:26:00',NULL),(298,5,'2024-10-29 21:28:00',NULL),(299,5,'2024-11-06 16:41:00',NULL),(300,2,'2024-10-29 17:50:00',NULL),(301,5,'2024-11-02 22:28:00',NULL),(302,5,'2024-11-04 19:07:00',NULL),(303,5,'2024-11-07 13:45:00',NULL),(304,2,'2024-11-04 21:29:00',NULL),(305,5,'2024-10-23 17:00:00','This check-in for reservation 305 captured some notes as test data.'),(306,2,'2024-11-05 13:03:00',NULL),(307,5,'2024-10-29 21:20:00',NULL),(308,3,'2024-10-29 17:02:00',NULL),(309,2,'2024-11-07 22:31:00',NULL),(310,2,'2024-11-07 21:01:00',NULL),(311,4,'2024-10-28 21:38:00','This check-in for reservation 311 captured some notes as test data.'),(312,4,'2024-11-07 21:15:00',NULL),(313,4,'2024-10-27 21:41:00',NULL),(314,2,'2024-11-11 19:46:00',NULL),(315,3,'2024-11-04 14:08:00',NULL),(316,3,'2024-11-10 22:40:00',NULL),(317,5,'2024-11-07 22:03:00',NULL),(318,5,'2024-11-10 13:13:00',NULL),(319,2,'2024-10-25 19:36:00',NULL),(320,5,'2024-11-04 22:19:00',NULL),(321,5,'2024-11-07 19:26:00','This check-in for reservation 321 captured some notes as test data.'),(322,3,'2024-10-28 22:32:00',NULL),(323,2,'2024-11-12 17:30:00',NULL),(324,3,'2024-10-26 21:23:00',NULL),(325,2,'2024-11-12 22:19:00',NULL),(326,4,'2024-11-02 15:37:00',NULL),(327,5,'2024-11-02 21:18:00','This check-in for reservation 327 captured some notes as test data.'),(328,5,'2024-11-11 16:10:00',NULL),(329,4,'2024-11-12 17:56:00',NULL),(330,3,'2024-10-29 22:20:00',NULL),(331,2,'2024-11-04 15:21:00',NULL),(332,3,'2024-11-02 19:06:00',NULL),(333,3,'2024-11-06 15:16:00',NULL),(334,5,'2024-11-08 22:29:00',NULL),(335,2,'2024-11-10 14:07:00',NULL),(336,5,'2024-10-30 20:53:00',NULL),(337,2,'2024-10-31 22:44:00',NULL),(338,5,'2024-11-05 21:57:00','This check-in for reservation 338 captured some notes as test data.'),(339,5,'2024-11-11 16:22:00',NULL),(340,5,'2024-11-13 18:51:00',NULL),(341,3,'2024-11-08 17:46:00',NULL),(342,2,'2024-11-16 17:57:00',NULL),(343,2,'2024-11-16 16:18:00','This check-in for reservation 343 captured some notes as test data.'),(344,4,'2024-11-14 13:02:00',NULL),(345,2,'2024-10-31 22:12:00',NULL),(346,3,'2024-11-02 22:38:00',NULL),(347,4,'2024-11-09 22:11:00',NULL),(348,3,'2024-11-18 13:37:00','This check-in for reservation 348 captured some notes as test data.'),(349,2,'2024-11-17 18:32:00',NULL),(350,5,'2024-11-07 17:08:00',NULL),(351,3,'2024-11-11 18:14:00','This check-in for reservation 351 captured some notes as test data.'),(352,4,'2024-11-06 19:44:00',NULL),(353,4,'2024-11-03 22:44:00',NULL),(354,3,'2024-11-17 18:19:00',NULL),(355,3,'2024-11-03 17:20:00','This check-in for reservation 355 captured some notes as test data.'),(356,3,'2024-11-10 16:47:00',NULL),(357,2,'2024-11-16 13:29:00',NULL),(358,3,'2024-11-16 13:33:00',NULL),(359,3,'2024-11-12 17:12:00',NULL),(360,2,'2024-11-18 20:47:00',NULL),(361,4,'2024-11-16 21:23:00',NULL),(363,2,'2024-11-13 17:32:00',NULL),(364,3,'2024-11-15 22:30:00',NULL),(365,3,'2024-11-16 16:38:00','This check-in for reservation 365 captured some notes as test data.'),(366,5,'2024-11-14 20:42:00',NULL),(367,5,'2024-11-11 17:25:00',NULL),(369,5,'2024-11-14 19:25:00','This check-in for reservation 369 captured some notes as test data.'),(371,3,'2024-11-08 13:22:00',NULL),(372,2,'2024-11-11 16:04:00',NULL),(374,5,'2024-11-12 18:28:00',NULL),(375,3,'2024-11-17 20:03:00',NULL),(376,5,'2024-11-20 22:05:00',NULL),(377,3,'2024-11-08 21:15:00',NULL),(383,5,'2024-11-11 22:06:00',NULL),(384,4,'2024-11-20 21:26:00',NULL),(386,3,'2024-11-20 13:03:00',NULL),(387,2,'2024-11-11 17:48:00','This check-in for reservation 387 captured some notes as test data.'),(388,4,'2024-11-18 20:25:00',NULL),(390,3,'2024-11-14 18:57:00',NULL),(391,3,'2024-11-16 17:04:00',NULL),(392,3,'2024-11-20 18:57:00',NULL),(398,4,'2024-11-20 21:12:00',NULL),(399,2,'2024-11-17 15:54:00',NULL),(400,2,'2024-11-14 20:29:00',NULL),(403,2,'2024-11-14 21:57:00',NULL),(404,4,'2024-11-16 13:11:00','This check-in for reservation 404 captured some notes as test data.'),(405,5,'2024-11-18 20:08:00',NULL),(407,4,'2024-11-18 20:36:00',NULL),(412,2,'2024-11-20 20:31:00',NULL),(420,2,'2024-11-19 20:25:00',NULL);
/*!40000 ALTER TABLE `check_in` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `check_out`
--

DROP TABLE IF EXISTS `check_out`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `check_out` (
  `reservation_id` int NOT NULL,
  `staff_id` smallint NOT NULL,
  `date_time` datetime NOT NULL,
  `settled_invoice` tinyint NOT NULL COMMENT '0 or 1 to indicate no/yes regarding if invoice was fully paid at the time of check-out.',
  `notes` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`reservation_id`),
  KEY `staff_id` (`staff_id`),
  CONSTRAINT `check_out_ibfk_1` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`staff_id`),
  CONSTRAINT `check_out_ibfk_2` FOREIGN KEY (`reservation_id`) REFERENCES `reservation` (`reservation_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `check_out`
--

LOCK TABLES `check_out` WRITE;
/*!40000 ALTER TABLE `check_out` DISABLE KEYS */;
INSERT INTO `check_out` VALUES (1,2,'2024-10-23 09:46:00',1,'Discussed complaints with guest during check out'),(2,4,'2024-10-31 07:27:00',1,NULL),(3,5,'2024-10-29 07:17:00',1,NULL),(4,4,'2024-10-27 08:15:00',1,NULL),(5,2,'2024-11-16 10:11:00',1,NULL),(6,3,'2024-08-19 08:04:00',0,NULL),(7,2,'2024-08-18 10:44:00',1,NULL),(8,5,'2024-08-30 09:40:00',1,NULL),(9,4,'2024-08-28 10:13:00',1,'This check-out for reservation 9 captured some notes as test data.'),(10,4,'2024-08-26 09:04:00',1,'This check-out for reservation 10 captured some notes as test data.'),(11,5,'2024-08-21 07:45:00',1,NULL),(12,4,'2024-08-24 10:47:00',1,NULL),(13,2,'2024-08-24 10:31:00',1,NULL),(14,4,'2024-08-22 09:17:00',1,NULL),(15,4,'2024-08-23 10:42:00',1,NULL),(16,5,'2024-08-16 08:14:00',1,NULL),(17,2,'2024-08-18 07:29:00',1,NULL),(18,2,'2024-08-16 10:43:00',1,NULL),(19,4,'2024-08-19 07:04:00',1,'This check-out for reservation 19 captured some notes as test data.'),(20,2,'2024-08-27 09:40:00',1,NULL),(21,4,'2024-08-29 09:33:00',1,NULL),(22,4,'2024-08-28 09:22:00',1,NULL),(23,3,'2024-08-20 07:45:00',1,NULL),(24,3,'2024-08-25 07:10:00',1,NULL),(25,2,'2024-08-18 10:30:00',1,NULL),(26,5,'2024-09-06 07:33:00',1,NULL),(27,3,'2024-09-02 10:20:00',1,NULL),(28,3,'2024-08-27 10:08:00',1,NULL),(29,3,'2024-08-21 10:04:00',1,NULL),(30,2,'2024-09-06 09:36:00',1,'This check-out for reservation 30 captured some notes as test data.'),(31,5,'2024-09-02 07:20:00',1,'This check-out for reservation 31 captured some notes as test data.'),(32,4,'2024-08-21 07:59:00',1,'This check-out for reservation 32 captured some notes as test data.'),(33,5,'2024-08-24 10:19:00',1,'This check-out for reservation 33 captured some notes as test data.'),(34,2,'2024-08-21 07:54:00',1,NULL),(35,2,'2024-09-03 09:55:00',1,NULL),(36,5,'2024-09-01 07:24:00',1,NULL),(37,4,'2024-09-01 08:29:00',1,NULL),(38,3,'2024-08-31 07:19:00',1,'This check-out for reservation 38 captured some notes as test data.'),(39,5,'2024-09-03 10:23:00',1,NULL),(40,4,'2024-08-30 08:14:00',1,NULL),(41,5,'2024-08-22 07:00:00',1,NULL),(42,2,'2024-09-05 08:53:00',1,'This check-out for reservation 42 captured some notes as test data.'),(43,2,'2024-09-08 09:09:00',1,NULL),(44,3,'2024-09-02 10:17:00',1,NULL),(45,2,'2024-08-29 09:17:00',1,NULL),(46,4,'2024-09-03 10:34:00',1,'This check-out for reservation 46 captured some notes as test data.'),(47,5,'2024-09-13 08:23:00',1,NULL),(48,5,'2024-08-30 10:21:00',1,'This check-out for reservation 48 captured some notes as test data.'),(49,3,'2024-09-06 10:15:00',1,NULL),(50,5,'2024-09-06 10:34:00',1,NULL),(51,5,'2024-09-05 08:00:00',1,NULL),(52,2,'2024-08-30 08:21:00',1,NULL),(53,3,'2024-08-26 10:18:00',1,NULL),(54,3,'2024-09-09 07:26:00',1,NULL),(55,4,'2024-09-02 09:30:00',1,NULL),(56,3,'2024-08-31 09:31:00',1,'This check-out for reservation 56 captured some notes as test data.'),(57,5,'2024-08-25 08:34:00',0,NULL),(58,4,'2024-09-06 08:45:00',0,NULL),(59,3,'2024-08-28 07:49:00',1,NULL),(60,2,'2024-09-06 08:56:00',1,NULL),(61,2,'2024-08-31 08:23:00',1,NULL),(62,4,'2024-08-29 09:27:00',1,NULL),(63,4,'2024-08-25 09:13:00',0,NULL),(64,2,'2024-09-12 10:15:00',1,NULL),(65,2,'2024-09-08 09:26:00',1,NULL),(66,5,'2024-09-07 07:39:00',1,'This check-out for reservation 66 captured some notes as test data.'),(67,3,'2024-09-13 08:12:00',1,NULL),(68,5,'2024-09-14 10:37:00',0,'This check-out for reservation 68 captured some notes as test data.'),(69,2,'2024-08-31 08:52:00',1,NULL),(70,5,'2024-09-05 07:21:00',1,NULL),(71,3,'2024-09-19 09:39:00',1,NULL),(72,3,'2024-08-30 08:15:00',1,NULL),(73,4,'2024-09-09 09:33:00',1,NULL),(74,4,'2024-09-04 09:01:00',1,NULL),(75,3,'2024-09-10 10:44:00',1,'This check-out for reservation 75 captured some notes as test data.'),(76,5,'2024-09-06 10:35:00',1,NULL),(77,5,'2024-09-04 09:40:00',1,NULL),(78,5,'2024-09-09 09:45:00',1,'This check-out for reservation 78 captured some notes as test data.'),(79,4,'2024-09-17 10:22:00',0,NULL),(80,2,'2024-09-10 09:12:00',1,NULL),(81,2,'2024-09-14 07:32:00',1,NULL),(82,3,'2024-09-06 07:58:00',1,NULL),(83,3,'2024-09-18 10:17:00',1,NULL),(84,4,'2024-09-18 10:10:00',1,'This check-out for reservation 84 captured some notes as test data.'),(85,2,'2024-09-17 10:29:00',0,NULL),(86,2,'2024-09-09 09:19:00',0,NULL),(87,5,'2024-09-22 08:13:00',1,'This check-out for reservation 87 captured some notes as test data.'),(88,5,'2024-09-09 09:41:00',1,NULL),(89,4,'2024-09-09 10:43:00',1,NULL),(90,4,'2024-09-10 09:17:00',0,NULL),(91,3,'2024-09-10 08:15:00',1,NULL),(92,3,'2024-09-17 07:22:00',1,NULL),(93,4,'2024-09-07 08:24:00',1,NULL),(94,3,'2024-09-10 07:46:00',1,NULL),(95,4,'2024-09-08 07:43:00',1,NULL),(96,4,'2024-09-26 08:49:00',1,NULL),(97,2,'2024-09-19 10:06:00',1,'This check-out for reservation 97 captured some notes as test data.'),(98,2,'2024-09-18 09:10:00',1,NULL),(99,2,'2024-09-21 09:58:00',0,NULL),(100,2,'2024-09-18 07:46:00',1,'This check-out for reservation 100 captured some notes as test data.'),(101,4,'2024-09-10 08:21:00',1,NULL),(102,3,'2024-09-23 09:11:00',1,NULL),(103,4,'2024-09-18 10:06:00',0,NULL),(104,2,'2024-09-09 08:07:00',1,'This check-out for reservation 104 captured some notes as test data.'),(105,3,'2024-09-14 07:26:00',1,NULL),(106,5,'2024-09-12 08:10:00',0,NULL),(107,4,'2024-09-18 09:08:00',1,NULL),(108,3,'2024-09-13 10:21:00',1,NULL),(109,4,'2024-09-16 09:51:00',1,'This check-out for reservation 109 captured some notes as test data.'),(110,3,'2024-09-15 08:28:00',1,NULL),(111,3,'2024-09-13 08:42:00',1,NULL),(112,4,'2024-09-19 09:55:00',1,NULL),(113,5,'2024-09-15 08:01:00',1,NULL),(114,5,'2024-09-16 09:10:00',1,NULL),(115,5,'2024-09-18 08:07:00',1,NULL),(116,3,'2024-09-23 10:57:00',1,'This check-out for reservation 116 captured some notes as test data.'),(117,5,'2024-09-11 08:17:00',1,'This check-out for reservation 117 captured some notes as test data.'),(118,4,'2024-09-12 09:20:00',1,NULL),(119,4,'2024-09-14 10:22:00',1,NULL),(120,5,'2024-09-10 07:24:00',0,NULL),(121,2,'2024-09-27 07:46:00',1,NULL),(122,5,'2024-09-27 09:33:00',1,NULL),(123,4,'2024-09-13 10:23:00',1,NULL),(124,3,'2024-09-26 08:56:00',1,NULL),(125,4,'2024-09-15 07:36:00',1,NULL),(126,4,'2024-09-14 10:16:00',1,NULL),(127,5,'2024-09-16 09:13:00',1,NULL),(128,3,'2024-09-13 09:46:00',1,'This check-out for reservation 128 captured some notes as test data.'),(129,4,'2024-09-14 08:35:00',1,'This check-out for reservation 129 captured some notes as test data.'),(130,5,'2024-09-24 08:11:00',1,'This check-out for reservation 130 captured some notes as test data.'),(131,3,'2024-09-24 07:08:00',1,'This check-out for reservation 131 captured some notes as test data.'),(132,3,'2024-09-20 09:57:00',1,'This check-out for reservation 132 captured some notes as test data.'),(133,2,'2024-09-14 08:40:00',1,'This check-out for reservation 133 captured some notes as test data.'),(134,3,'2024-09-27 09:35:00',1,'This check-out for reservation 134 captured some notes as test data.'),(135,2,'2024-09-27 08:22:00',1,NULL),(136,3,'2024-09-17 10:01:00',0,NULL),(137,5,'2024-10-03 08:53:00',1,NULL),(138,3,'2024-09-24 09:18:00',1,'This check-out for reservation 138 captured some notes as test data.'),(139,4,'2024-09-23 09:04:00',1,NULL),(140,5,'2024-10-02 10:38:00',1,NULL),(141,3,'2024-10-06 08:55:00',1,NULL),(142,4,'2024-09-15 10:25:00',1,NULL),(143,5,'2024-09-23 07:23:00',1,NULL),(144,3,'2024-09-29 08:09:00',1,NULL),(145,4,'2024-09-27 08:57:00',1,'This check-out for reservation 145 captured some notes as test data.'),(146,4,'2024-09-24 08:30:00',1,NULL),(147,5,'2024-09-17 07:23:00',1,NULL),(148,4,'2024-09-20 07:52:00',1,NULL),(149,5,'2024-10-02 07:44:00',1,'This check-out for reservation 149 captured some notes as test data.'),(150,4,'2024-09-23 10:57:00',1,NULL),(151,5,'2024-09-30 10:14:00',1,NULL),(152,2,'2024-09-30 09:17:00',1,NULL),(153,2,'2024-09-27 08:44:00',1,NULL),(154,3,'2024-10-03 09:31:00',1,'This check-out for reservation 154 captured some notes as test data.'),(155,4,'2024-10-02 08:20:00',0,NULL),(156,5,'2024-10-11 07:58:00',0,NULL),(157,5,'2024-09-30 10:41:00',0,NULL),(158,5,'2024-09-22 07:52:00',1,NULL),(159,2,'2024-10-07 09:29:00',0,'This check-out for reservation 159 captured some notes as test data.'),(160,5,'2024-10-03 10:08:00',1,NULL),(161,2,'2024-09-30 10:16:00',1,NULL),(162,3,'2024-10-03 09:52:00',1,NULL),(163,4,'2024-10-03 07:41:00',0,NULL),(164,3,'2024-09-29 10:35:00',1,NULL),(165,2,'2024-10-08 09:02:00',1,NULL),(166,3,'2024-10-01 09:14:00',1,NULL),(167,5,'2024-10-06 08:22:00',1,NULL),(168,3,'2024-09-30 07:15:00',1,NULL),(169,4,'2024-10-03 09:31:00',1,NULL),(170,4,'2024-09-25 09:59:00',1,NULL),(171,3,'2024-10-05 10:16:00',0,NULL),(172,4,'2024-10-10 08:57:00',0,NULL),(173,5,'2024-09-26 09:14:00',1,NULL),(174,3,'2024-10-03 07:18:00',1,'This check-out for reservation 174 captured some notes as test data.'),(175,4,'2024-09-23 10:58:00',1,NULL),(176,5,'2024-10-01 07:11:00',1,NULL),(177,4,'2024-09-30 10:04:00',1,NULL),(178,2,'2024-10-07 07:54:00',1,NULL),(179,3,'2024-09-28 07:02:00',1,'This check-out for reservation 179 captured some notes as test data.'),(180,3,'2024-10-06 08:42:00',0,'This check-out for reservation 180 captured some notes as test data.'),(181,3,'2024-09-28 09:35:00',1,NULL),(182,2,'2024-10-11 09:55:00',1,NULL),(183,2,'2024-09-25 10:48:00',1,NULL),(184,4,'2024-10-12 10:12:00',1,NULL),(185,5,'2024-10-14 08:30:00',1,NULL),(186,4,'2024-10-03 10:46:00',1,NULL),(187,4,'2024-10-04 07:05:00',1,NULL),(188,5,'2024-10-09 10:13:00',1,'This check-out for reservation 188 captured some notes as test data.'),(189,4,'2024-10-16 10:18:00',1,NULL),(190,3,'2024-10-14 10:52:00',1,NULL),(191,3,'2024-10-03 08:42:00',1,NULL),(192,2,'2024-10-08 08:49:00',1,'This check-out for reservation 192 captured some notes as test data.'),(193,2,'2024-10-16 08:04:00',1,NULL),(194,4,'2024-10-14 09:37:00',1,'This check-out for reservation 194 captured some notes as test data.'),(195,5,'2024-10-14 09:47:00',1,NULL),(196,3,'2024-10-16 07:35:00',0,NULL),(197,2,'2024-10-12 10:28:00',1,NULL),(198,3,'2024-10-10 09:23:00',1,NULL),(199,3,'2024-10-07 10:02:00',1,'This check-out for reservation 199 captured some notes as test data.'),(200,2,'2024-10-12 10:10:00',1,NULL),(201,4,'2024-10-07 08:03:00',1,NULL),(202,2,'2024-10-11 10:51:00',1,'This check-out for reservation 202 captured some notes as test data.'),(203,5,'2024-10-16 07:05:00',1,NULL),(204,2,'2024-10-14 10:40:00',1,NULL),(205,4,'2024-10-20 08:49:00',1,'This check-out for reservation 205 captured some notes as test data.'),(206,5,'2024-10-16 07:03:00',1,NULL),(207,2,'2024-10-19 09:36:00',1,NULL),(208,4,'2024-10-06 10:36:00',1,NULL),(209,4,'2024-10-19 08:22:00',1,NULL),(210,4,'2024-10-25 10:51:00',1,NULL),(211,3,'2024-10-12 08:11:00',1,NULL),(212,5,'2024-10-13 08:15:00',1,NULL),(213,4,'2024-10-04 10:29:00',1,NULL),(214,4,'2024-10-09 07:40:00',0,NULL),(215,5,'2024-10-21 09:07:00',1,NULL),(216,3,'2024-10-12 08:05:00',1,NULL),(217,3,'2024-10-13 07:07:00',1,NULL),(218,2,'2024-10-08 08:55:00',1,NULL),(219,3,'2024-10-12 07:02:00',1,NULL),(220,3,'2024-10-20 09:20:00',1,'This check-out for reservation 220 captured some notes as test data.'),(221,5,'2024-10-07 07:03:00',1,NULL),(222,5,'2024-10-07 07:13:00',1,'This check-out for reservation 222 captured some notes as test data.'),(223,4,'2024-10-11 08:07:00',1,NULL),(224,3,'2024-10-23 09:38:00',1,NULL),(225,5,'2024-10-23 08:39:00',1,NULL),(226,3,'2024-10-24 09:19:00',1,'This check-out for reservation 226 captured some notes as test data.'),(227,2,'2024-10-19 08:28:00',1,NULL),(228,2,'2024-10-20 10:51:00',1,NULL),(229,4,'2024-10-17 10:21:00',1,NULL),(230,3,'2024-10-07 07:41:00',1,NULL),(231,3,'2024-10-22 10:27:00',1,'This check-out for reservation 231 captured some notes as test data.'),(232,3,'2024-10-14 09:01:00',1,NULL),(233,4,'2024-10-26 08:54:00',1,NULL),(234,3,'2024-10-18 10:30:00',1,NULL),(235,5,'2024-10-21 08:27:00',1,NULL),(236,4,'2024-10-25 10:52:00',1,NULL),(237,5,'2024-10-18 10:16:00',0,NULL),(238,5,'2024-10-21 10:15:00',1,NULL),(239,5,'2024-10-31 08:54:00',1,NULL),(240,3,'2024-10-18 10:33:00',1,'This check-out for reservation 240 captured some notes as test data.'),(241,4,'2024-10-16 08:26:00',1,NULL),(242,4,'2024-10-19 09:46:00',1,'This check-out for reservation 242 captured some notes as test data.'),(243,4,'2024-10-30 09:47:00',1,'This check-out for reservation 243 captured some notes as test data.'),(244,3,'2024-10-27 09:11:00',1,NULL),(245,4,'2024-10-29 10:24:00',1,NULL),(246,2,'2024-10-30 09:30:00',1,NULL),(247,4,'2024-10-22 09:11:00',1,NULL),(248,2,'2024-10-21 07:49:00',1,'This check-out for reservation 248 captured some notes as test data.'),(249,4,'2024-10-31 09:51:00',1,NULL),(250,2,'2024-10-20 08:11:00',1,NULL),(251,5,'2024-10-24 10:08:00',1,NULL),(252,5,'2024-10-27 08:17:00',0,NULL),(253,2,'2024-10-23 09:56:00',1,NULL),(254,5,'2024-10-15 09:25:00',1,NULL),(255,5,'2024-10-23 10:18:00',1,NULL),(256,4,'2024-10-15 07:19:00',1,NULL),(257,5,'2024-10-23 09:25:00',1,NULL),(258,3,'2024-10-19 07:21:00',1,NULL),(259,3,'2024-10-28 08:45:00',1,NULL),(260,2,'2024-11-03 08:39:00',1,NULL),(261,5,'2024-11-02 10:23:00',1,NULL),(262,2,'2024-10-19 10:20:00',1,'This check-out for reservation 262 captured some notes as test data.'),(263,4,'2024-10-31 10:57:00',1,NULL),(264,5,'2024-11-07 07:49:00',1,NULL),(265,4,'2024-10-22 08:49:00',1,NULL),(266,4,'2024-11-02 08:10:00',1,'This check-out for reservation 266 captured some notes as test data.'),(267,5,'2024-10-28 09:27:00',1,NULL),(268,5,'2024-10-31 10:34:00',1,NULL),(269,2,'2024-10-27 10:32:00',1,NULL),(270,3,'2024-10-24 09:53:00',1,NULL),(271,5,'2024-10-17 10:36:00',1,NULL),(272,4,'2024-10-31 10:13:00',0,NULL),(273,2,'2024-11-05 10:30:00',1,NULL),(274,4,'2024-10-19 09:16:00',1,'This check-out for reservation 274 captured some notes as test data.'),(275,3,'2024-10-18 09:59:00',1,NULL),(276,4,'2024-11-03 08:03:00',1,NULL),(277,4,'2024-10-22 09:03:00',1,NULL),(278,4,'2024-11-03 07:41:00',1,NULL),(279,3,'2024-11-01 08:11:00',0,NULL),(280,4,'2024-10-26 10:08:00',1,'This check-out for reservation 280 captured some notes as test data.'),(281,5,'2024-10-27 09:01:00',1,NULL),(282,2,'2024-10-23 10:27:00',1,NULL),(283,5,'2024-11-10 08:23:00',1,'This check-out for reservation 283 captured some notes as test data.'),(284,3,'2024-10-22 10:48:00',1,'This check-out for reservation 284 captured some notes as test data.'),(285,3,'2024-10-27 08:26:00',0,NULL),(286,4,'2024-10-26 07:01:00',1,NULL),(287,5,'2024-10-29 07:23:00',1,NULL),(288,3,'2024-11-04 08:53:00',1,NULL),(289,4,'2024-11-05 08:48:00',1,NULL),(290,2,'2024-11-03 09:29:00',1,NULL),(291,2,'2024-10-26 07:04:00',1,NULL),(292,2,'2024-11-07 08:10:00',1,NULL),(293,4,'2024-10-25 10:00:00',1,NULL),(294,3,'2024-10-23 07:23:00',0,'This check-out for reservation 294 captured some notes as test data.'),(295,2,'2024-11-07 10:05:00',1,NULL),(296,3,'2024-10-26 07:51:00',0,NULL),(297,4,'2024-10-31 09:43:00',1,NULL),(298,5,'2024-11-03 10:10:00',1,NULL),(299,3,'2024-11-07 07:14:00',1,NULL),(300,4,'2024-10-31 10:46:00',0,NULL),(301,5,'2024-11-03 07:16:00',1,NULL),(302,3,'2024-11-07 07:06:00',1,'This check-out for reservation 302 captured some notes as test data.'),(303,5,'2024-11-10 08:01:00',1,NULL),(304,5,'2024-11-05 07:55:00',1,NULL),(305,3,'2024-10-26 10:12:00',1,NULL),(306,4,'2024-11-07 08:42:00',1,NULL),(307,2,'2024-10-31 10:08:00',1,NULL),(308,3,'2024-11-02 09:35:00',1,NULL),(309,3,'2024-11-10 10:35:00',1,NULL),(310,4,'2024-11-11 07:59:00',1,NULL),(311,5,'2024-10-31 10:42:00',1,NULL),(312,5,'2024-11-10 10:21:00',1,NULL),(313,5,'2024-10-29 07:35:00',1,NULL),(314,4,'2024-11-14 07:33:00',1,NULL),(315,5,'2024-11-05 09:46:00',1,NULL),(316,5,'2024-11-12 10:09:00',1,NULL),(317,4,'2024-11-10 09:14:00',1,NULL),(318,5,'2024-11-13 10:58:00',1,NULL),(319,5,'2024-10-28 09:24:00',1,NULL),(320,3,'2024-11-09 09:44:00',1,'This check-out for reservation 320 captured some notes as test data.'),(321,5,'2024-11-08 09:37:00',1,'This check-out for reservation 321 captured some notes as test data.'),(322,3,'2024-10-29 08:47:00',1,NULL),(323,4,'2024-11-14 10:29:00',1,NULL),(324,5,'2024-10-28 09:13:00',1,NULL),(325,3,'2024-11-15 08:30:00',1,NULL),(326,4,'2024-11-03 07:44:00',1,NULL),(327,3,'2024-11-04 10:39:00',0,'This check-out for reservation 327 captured some notes as test data.'),(328,3,'2024-11-12 07:45:00',1,NULL),(329,4,'2024-11-14 10:36:00',0,NULL),(330,5,'2024-10-30 09:30:00',1,'This check-out for reservation 330 captured some notes as test data.'),(331,5,'2024-11-08 07:48:00',1,'This check-out for reservation 331 captured some notes as test data.'),(332,5,'2024-11-05 08:10:00',1,NULL),(333,4,'2024-11-07 09:50:00',1,NULL),(334,4,'2024-11-10 07:32:00',1,NULL),(335,4,'2024-11-12 08:08:00',1,'This check-out for reservation 335 captured some notes as test data.'),(336,4,'2024-11-02 09:56:00',1,NULL),(337,4,'2024-11-01 09:22:00',1,NULL),(338,5,'2024-11-06 08:59:00',1,NULL),(339,5,'2024-11-16 08:02:00',1,NULL),(340,4,'2024-11-18 08:30:00',0,NULL),(341,5,'2024-11-11 08:40:00',1,NULL),(343,2,'2024-11-20 08:55:00',1,NULL),(344,4,'2024-11-19 09:41:00',1,NULL),(345,2,'2024-11-02 10:52:00',1,NULL),(346,3,'2024-11-05 09:14:00',1,NULL),(347,2,'2024-11-11 09:30:00',1,'This check-out for reservation 347 captured some notes as test data.'),(349,3,'2024-11-18 09:13:00',1,NULL),(350,3,'2024-11-10 08:34:00',1,'This check-out for reservation 350 captured some notes as test data.'),(351,3,'2024-11-13 09:02:00',1,'This check-out for reservation 351 captured some notes as test data.'),(352,2,'2024-11-08 10:03:00',1,NULL),(353,5,'2024-11-05 07:54:00',0,NULL),(354,4,'2024-11-20 09:43:00',1,NULL),(355,5,'2024-11-05 07:22:00',1,NULL),(356,5,'2024-11-11 09:24:00',1,NULL),(357,3,'2024-11-19 10:42:00',1,NULL),(358,4,'2024-11-17 10:44:00',1,NULL),(359,3,'2024-11-14 07:31:00',1,NULL),(360,4,'2024-11-19 10:09:00',1,NULL),(361,5,'2024-11-17 07:40:00',1,'This check-out for reservation 361 captured some notes as test data.'),(363,2,'2024-11-14 07:37:00',1,NULL),(364,2,'2024-11-18 08:21:00',1,NULL),(366,3,'2024-11-18 08:29:00',1,'This check-out for reservation 366 captured some notes as test data.'),(367,5,'2024-11-14 08:44:00',1,NULL),(369,3,'2024-11-17 10:00:00',1,NULL),(371,2,'2024-11-09 10:35:00',1,'This check-out for reservation 371 captured some notes as test data.'),(372,5,'2024-11-14 10:18:00',0,NULL),(374,5,'2024-11-13 10:12:00',1,NULL),(375,3,'2024-11-19 07:41:00',0,NULL),(377,5,'2024-11-11 07:38:00',1,NULL),(383,2,'2024-11-15 07:45:00',1,'This check-out for reservation 383 captured some notes as test data.'),(387,3,'2024-11-12 10:35:00',1,NULL),(388,3,'2024-11-20 08:10:00',1,NULL),(390,5,'2024-11-19 09:02:00',1,'This check-out for reservation 390 captured some notes as test data.'),(391,5,'2024-11-20 09:40:00',1,NULL),(399,4,'2024-11-19 09:22:00',1,NULL),(400,3,'2024-11-17 08:19:00',1,NULL),(403,5,'2024-11-17 07:22:00',1,NULL),(404,4,'2024-11-19 07:19:00',0,'This check-out for reservation 404 captured some notes as test data.'),(407,3,'2024-11-20 08:48:00',1,NULL),(420,3,'2024-11-20 08:45:00',1,NULL);
/*!40000 ALTER TABLE `check_out` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cleaning_session`
--

DROP TABLE IF EXISTS `cleaning_session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cleaning_session` (
  `date_of_clean` date NOT NULL,
  `staff_id` smallint NOT NULL,
  `allocated_master_key` char(1) NOT NULL,
  PRIMARY KEY (`date_of_clean`,`staff_id`),
  KEY `staff_id` (`staff_id`),
  CONSTRAINT `cleaning_session_ibfk_1` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`staff_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cleaning_session`
--

LOCK TABLES `cleaning_session` WRITE;
/*!40000 ALTER TABLE `cleaning_session` DISABLE KEYS */;
INSERT INTO `cleaning_session` VALUES ('2024-10-21',7,'A'),('2024-10-21',8,'C'),('2024-10-22',7,'B'),('2024-10-22',8,'C'),('2024-10-23',8,'A'),('2024-10-23',9,'F'),('2024-11-11',6,'R'),('2024-11-11',8,'H'),('2024-11-11',9,'T'),('2024-11-12',6,'G'),('2024-11-12',8,'U'),('2024-11-12',9,'X'),('2024-11-13',7,'C'),('2024-11-13',8,'L'),('2024-11-13',9,'V'),('2024-11-14',7,'F'),('2024-11-14',8,'E'),('2024-11-14',9,'Y'),('2024-11-15',6,'U'),('2024-11-15',7,'O'),('2024-11-15',8,'G'),('2024-11-16',6,'P'),('2024-11-16',8,'C'),('2024-11-16',9,'D'),('2024-11-17',6,'G'),('2024-11-17',8,'T'),('2024-11-17',9,'E');
/*!40000 ALTER TABLE `cleaning_session` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `company_account`
--

DROP TABLE IF EXISTS `company_account`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `company_account` (
  `company_id` int NOT NULL AUTO_INCREMENT,
  `company_name` varchar(255) NOT NULL,
  `building` varchar(50) NOT NULL,
  `postcode` varchar(8) NOT NULL,
  `admin_title` varchar(10) NOT NULL,
  `admin_first_name` varchar(80) NOT NULL,
  `admin_last_name` varchar(80) NOT NULL,
  `admin_phone_number` varchar(11) NOT NULL,
  `admin_email` varchar(320) NOT NULL,
  PRIMARY KEY (`company_id`),
  KEY `postcode` (`postcode`),
  KEY `IDX_company_name` (`company_name`),
  CONSTRAINT `company_account_ibfk_1` FOREIGN KEY (`postcode`) REFERENCES `address` (`postcode`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `CHK_admin_email` CHECK (regexp_like(`admin_email`,_utf8mb4'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+.[a-zA-Z]{2,}$'))
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `company_account`
--

LOCK TABLES `company_account` WRITE;
/*!40000 ALTER TABLE `company_account` DISABLE KEYS */;
INSERT INTO `company_account` VALUES (1,'AXA Insurance','Brooke Lawrance House','IP1 2AN','Miss','Jane','Peters','01473726352','j.peters@axa.co.uk'),(2,'Rose Builders Ltd','1','CO11 1US','Mr','David','White','01206123654','d.white@rosebuilders.co.uk'),(3,'Test Company One Ltd','1','TS3 1AC','Mr','Test','Admin1','01473100001','admin@testco1.co.uk'),(4,'Test Company Two Ltd','2','TS3 2AC','Miss','Test','Admin2','01473100002','t.admin2@testco2.co.uk'),(5,'Test Company Three Ltd','3','TS3 3AC','Ms','Test','Admin3','01473100003','test.admin3@testco3.co.uk');
/*!40000 ALTER TABLE `company_account` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `validate_phone_before_insert` BEFORE INSERT ON `company_account` FOR EACH ROW BEGIN
    CALL validate_phone_number(NEW.admin_phone_number);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `validate_phone_before_update` BEFORE UPDATE ON `company_account` FOR EACH ROW BEGIN
    CALL validate_phone_number(NEW.admin_phone_number);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `complaint`
--

DROP TABLE IF EXISTS `complaint`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `complaint` (
  `reservation_id` int NOT NULL,
  `opened_date` datetime NOT NULL,
  `category_code` char(4) NOT NULL,
  `opened_by` smallint NOT NULL,
  `description` varchar(255) NOT NULL,
  PRIMARY KEY (`reservation_id`,`opened_date`),
  KEY `opened_by` (`opened_by`),
  KEY `IDX_complaint_category` (`category_code`),
  CONSTRAINT `complaint_ibfk_1` FOREIGN KEY (`reservation_id`) REFERENCES `reservation` (`reservation_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `complaint_ibfk_2` FOREIGN KEY (`category_code`) REFERENCES `complaint_category` (`category_code`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `complaint_ibfk_3` FOREIGN KEY (`opened_by`) REFERENCES `staff` (`staff_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `complaint`
--

LOCK TABLES `complaint` WRITE;
/*!40000 ALTER TABLE `complaint` DISABLE KEYS */;
INSERT INTO `complaint` VALUES (1,'2024-10-22 01:10:00','NO2',3,'Loud music from the next room during the night.'),(1,'2024-10-23 09:15:00','RE2',4,'Discount not as big as expected.'),(2,'2024-10-24 17:40:00','RM2',4,'Bathroom is not clean.'),(2,'2024-10-31 05:57:00','SM1',4,'Complaint created as test data for reservation 2'),(5,'2024-11-16 08:41:00','RE2',2,'Complaint created as test data for reservation 5'),(7,'2024-08-18 09:14:00','RE2',2,'Complaint created as test data for reservation 7'),(13,'2024-08-24 09:01:00','CS3',2,'Complaint created as test data for reservation 13'),(16,'2024-08-16 06:44:00','CS1',5,'Complaint created as test data for reservation 16'),(17,'2024-08-18 05:59:00','SM2',2,'Complaint created as test data for reservation 17'),(22,'2024-08-28 07:52:00','RE2',4,'Complaint created as test data for reservation 22'),(26,'2024-09-06 06:03:00','RE2',5,'Complaint created as test data for reservation 26'),(34,'2024-08-21 06:24:00','WI2',2,'Complaint created as test data for reservation 34'),(43,'2024-09-08 07:39:00','RE3',2,'Complaint created as test data for reservation 43'),(45,'2024-08-29 07:47:00','CS1',2,'Complaint created as test data for reservation 45'),(64,'2024-09-12 08:45:00','SM1',2,'Complaint created as test data for reservation 64'),(66,'2024-09-07 06:09:00','SM2',5,'Complaint created as test data for reservation 66'),(67,'2024-09-13 06:42:00','WI1',3,'Complaint created as test data for reservation 67'),(75,'2024-09-10 09:14:00','CS1',3,'Complaint created as test data for reservation 75'),(80,'2024-09-10 07:42:00','SM1',2,'Complaint created as test data for reservation 80'),(85,'2024-09-17 08:59:00','SA2',2,'Complaint created as test data for reservation 85'),(89,'2024-09-09 09:13:00','SM2',4,'Complaint created as test data for reservation 89'),(105,'2024-09-14 05:56:00','NO1',3,'Complaint created as test data for reservation 105'),(119,'2024-09-14 08:52:00','CS3',4,'Complaint created as test data for reservation 119'),(120,'2024-09-10 05:54:00','NO1',5,'Complaint created as test data for reservation 120'),(162,'2024-10-03 08:22:00','RE1',3,'Complaint created as test data for reservation 162'),(169,'2024-10-03 08:01:00','RM1',4,'Complaint created as test data for reservation 169'),(174,'2024-10-03 05:48:00','RS1',3,'Complaint created as test data for reservation 174'),(178,'2024-10-07 06:24:00','RM2',2,'Complaint created as test data for reservation 178'),(184,'2024-10-12 08:42:00','WI2',4,'Complaint created as test data for reservation 184'),(187,'2024-10-04 05:35:00','RE2',4,'Complaint created as test data for reservation 187'),(196,'2024-10-16 06:05:00','RS1',3,'Complaint created as test data for reservation 196'),(199,'2024-10-07 08:32:00','PL1',3,'Complaint created as test data for reservation 199'),(205,'2024-10-20 07:19:00','WI2',4,'Complaint created as test data for reservation 205'),(208,'2024-10-06 09:06:00','RE2',4,'Complaint created as test data for reservation 208'),(209,'2024-10-19 06:52:00','PR1',4,'Complaint created as test data for reservation 209'),(210,'2024-10-25 09:21:00','RM1',4,'Complaint created as test data for reservation 210'),(215,'2024-10-21 07:37:00','CS1',5,'Complaint created as test data for reservation 215'),(217,'2024-10-13 05:37:00','SA2',3,'Complaint created as test data for reservation 217'),(222,'2024-10-07 05:43:00','RE1',5,'Complaint created as test data for reservation 222'),(229,'2024-10-17 08:51:00','CS1',4,'Complaint created as test data for reservation 229'),(230,'2024-10-07 06:11:00','SM1',3,'Complaint created as test data for reservation 230'),(238,'2024-10-21 08:45:00','CS1',5,'Complaint created as test data for reservation 238'),(240,'2024-10-18 09:03:00','SM2',3,'Complaint created as test data for reservation 240'),(244,'2024-10-27 07:41:00','WI2',3,'Complaint created as test data for reservation 244'),(249,'2024-10-31 08:21:00','PL1',4,'Complaint created as test data for reservation 249'),(253,'2024-10-23 08:26:00','EM1',2,'Complaint created as test data for reservation 253'),(268,'2024-10-31 09:04:00','NO1',5,'Complaint created as test data for reservation 268'),(283,'2024-11-10 06:53:00','WI2',5,'Complaint created as test data for reservation 283'),(287,'2024-10-29 05:53:00','RM1',5,'Complaint created as test data for reservation 287'),(289,'2024-11-05 07:18:00','RE2',4,'Complaint created as test data for reservation 289'),(294,'2024-10-23 05:53:00','RE1',3,'Complaint created as test data for reservation 294'),(301,'2024-11-03 05:46:00','RM2',5,'Complaint created as test data for reservation 301'),(302,'2024-11-07 05:36:00','EM1',3,'Complaint created as test data for reservation 302'),(309,'2024-11-10 09:05:00','NO1',3,'Complaint created as test data for reservation 309'),(310,'2024-11-11 06:29:00','WI1',4,'Complaint created as test data for reservation 310'),(315,'2024-11-05 08:16:00','RE1',5,'Complaint created as test data for reservation 315'),(316,'2024-11-12 08:39:00','NO2',5,'Complaint created as test data for reservation 316'),(318,'2024-11-13 09:28:00','PL1',5,'Complaint created as test data for reservation 318'),(323,'2024-11-14 08:59:00','WI1',4,'Complaint created as test data for reservation 323'),(326,'2024-11-03 06:14:00','NO2',4,'Complaint created as test data for reservation 326'),(328,'2024-11-12 06:15:00','SA2',3,'Complaint created as test data for reservation 328'),(332,'2024-11-05 06:40:00','WI1',5,'Complaint created as test data for reservation 332'),(334,'2024-11-10 06:02:00','CS3',4,'Complaint created as test data for reservation 334'),(335,'2024-11-12 06:38:00','CS3',4,'Complaint created as test data for reservation 335'),(336,'2024-11-02 08:26:00','EM1',4,'Complaint created as test data for reservation 336'),(355,'2024-11-05 05:52:00','WI2',5,'Complaint created as test data for reservation 355'),(404,'2024-11-19 05:49:00','CS1',4,'Complaint created as test data for reservation 404'),(420,'2024-11-20 07:15:00','RE2',3,'Complaint created as test data for reservation 420');
/*!40000 ALTER TABLE `complaint` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `complaint_category`
--

DROP TABLE IF EXISTS `complaint_category`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `complaint_category` (
  `category_code` char(4) NOT NULL,
  `category_name` varchar(80) NOT NULL,
  `severity` int NOT NULL,
  PRIMARY KEY (`category_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `complaint_category`
--

LOCK TABLES `complaint_category` WRITE;
/*!40000 ALTER TABLE `complaint_category` DISABLE KEYS */;
INSERT INTO `complaint_category` VALUES ('CS1','Poor Customer Service',2),('CS2','Slow Customer Service',3),('CS3','Rude Customer Service',5),('EM1','Electrical Issue',5),('NO1','Noise',2),('NO2','Constant Noise',4),('PL1','Plumbing Issue',5),('PR1','Parking Issue',3),('RE1','Reservation Issue',3),('RE2','Billing Query',1),('RE3','Billing Dispute',5),('RM1','Room Condition',3),('RM2','Bad Room Condition',5),('RS1','Unhappy With Room Size',3),('SA1','Minor Safety Concern',4),('SA2','Major Safety Issue',8),('SM1','Smell outside the room',2),('SM2','Smell inside the room',4),('WI1','Wi-Fi Connection Issue',3),('WI2','Slow Wi-Fi',2);
/*!40000 ALTER TABLE `complaint_category` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `complaint_resolution`
--

DROP TABLE IF EXISTS `complaint_resolution`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `complaint_resolution` (
  `reservation_id` int NOT NULL,
  `opened_date` datetime NOT NULL,
  `resolved_by` smallint NOT NULL,
  `resolution` varchar(255) NOT NULL,
  `resolution_date` datetime NOT NULL,
  PRIMARY KEY (`reservation_id`,`opened_date`),
  KEY `resolved_by` (`resolved_by`),
  CONSTRAINT `complaint_resolution_ibfk_1` FOREIGN KEY (`reservation_id`, `opened_date`) REFERENCES `complaint` (`reservation_id`, `opened_date`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `complaint_resolution_ibfk_2` FOREIGN KEY (`resolved_by`) REFERENCES `staff` (`staff_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `complaint_resolution`
--

LOCK TABLES `complaint_resolution` WRITE;
/*!40000 ALTER TABLE `complaint_resolution` DISABLE KEYS */;
INSERT INTO `complaint_resolution` VALUES (1,'2024-10-22 01:10:00',3,'Visited the room making the noise. They switched off the radio and apologised','2024-10-22 01:15:00'),(1,'2024-10-23 09:15:00',2,'Explained that a 10% promotion code had been used. Guest thought it was 15%. Guest satisfied','2024-10-23 09:45:00'),(2,'2024-10-24 17:40:00',5,'Sent cleaner to the room immediately and gave guest a free drink while waiting','2024-10-24 18:30:00'),(2,'2024-10-31 05:57:00',4,'Complaint resolved as test data for reservation 2','2024-10-31 06:34:00'),(5,'2024-11-16 08:41:00',2,'Complaint resolved as test data for reservation 5','2024-11-16 09:18:00'),(7,'2024-08-18 09:14:00',2,'Complaint resolved as test data for reservation 7','2024-08-18 09:51:00'),(13,'2024-08-24 09:01:00',2,'Complaint resolved as test data for reservation 13','2024-08-24 09:38:00'),(16,'2024-08-16 06:44:00',5,'Complaint resolved as test data for reservation 16','2024-08-16 07:21:00'),(17,'2024-08-18 05:59:00',2,'Complaint resolved as test data for reservation 17','2024-08-18 06:36:00'),(22,'2024-08-28 07:52:00',4,'Complaint resolved as test data for reservation 22','2024-08-28 08:29:00'),(26,'2024-09-06 06:03:00',5,'Complaint resolved as test data for reservation 26','2024-09-06 06:40:00'),(34,'2024-08-21 06:24:00',2,'Complaint resolved as test data for reservation 34','2024-08-21 07:01:00'),(43,'2024-09-08 07:39:00',2,'Complaint resolved as test data for reservation 43','2024-09-08 08:16:00'),(45,'2024-08-29 07:47:00',2,'Complaint resolved as test data for reservation 45','2024-08-29 08:24:00'),(64,'2024-09-12 08:45:00',2,'Complaint resolved as test data for reservation 64','2024-09-12 09:22:00'),(66,'2024-09-07 06:09:00',5,'Complaint resolved as test data for reservation 66','2024-09-07 06:46:00'),(67,'2024-09-13 06:42:00',3,'Complaint resolved as test data for reservation 67','2024-09-13 07:19:00'),(75,'2024-09-10 09:14:00',3,'Complaint resolved as test data for reservation 75','2024-09-10 09:51:00'),(80,'2024-09-10 07:42:00',2,'Complaint resolved as test data for reservation 80','2024-09-10 08:19:00'),(85,'2024-09-17 08:59:00',2,'Complaint resolved as test data for reservation 85','2024-09-17 09:36:00'),(89,'2024-09-09 09:13:00',4,'Complaint resolved as test data for reservation 89','2024-09-09 09:50:00'),(105,'2024-09-14 05:56:00',3,'Complaint resolved as test data for reservation 105','2024-09-14 06:33:00'),(119,'2024-09-14 08:52:00',4,'Complaint resolved as test data for reservation 119','2024-09-14 09:29:00'),(120,'2024-09-10 05:54:00',5,'Complaint resolved as test data for reservation 120','2024-09-10 06:31:00'),(162,'2024-10-03 08:22:00',3,'Complaint resolved as test data for reservation 162','2024-10-03 08:59:00'),(169,'2024-10-03 08:01:00',4,'Complaint resolved as test data for reservation 169','2024-10-03 08:38:00'),(174,'2024-10-03 05:48:00',3,'Complaint resolved as test data for reservation 174','2024-10-03 06:25:00'),(178,'2024-10-07 06:24:00',2,'Complaint resolved as test data for reservation 178','2024-10-07 07:01:00'),(184,'2024-10-12 08:42:00',4,'Complaint resolved as test data for reservation 184','2024-10-12 09:19:00'),(187,'2024-10-04 05:35:00',4,'Complaint resolved as test data for reservation 187','2024-10-04 06:12:00'),(196,'2024-10-16 06:05:00',3,'Complaint resolved as test data for reservation 196','2024-10-16 06:42:00'),(199,'2024-10-07 08:32:00',3,'Complaint resolved as test data for reservation 199','2024-10-07 09:09:00'),(205,'2024-10-20 07:19:00',4,'Complaint resolved as test data for reservation 205','2024-10-20 07:56:00'),(208,'2024-10-06 09:06:00',4,'Complaint resolved as test data for reservation 208','2024-10-06 09:43:00'),(209,'2024-10-19 06:52:00',4,'Complaint resolved as test data for reservation 209','2024-10-19 07:29:00'),(210,'2024-10-25 09:21:00',4,'Complaint resolved as test data for reservation 210','2024-10-25 09:58:00'),(215,'2024-10-21 07:37:00',5,'Complaint resolved as test data for reservation 215','2024-10-21 08:14:00'),(217,'2024-10-13 05:37:00',3,'Complaint resolved as test data for reservation 217','2024-10-13 06:14:00'),(222,'2024-10-07 05:43:00',5,'Complaint resolved as test data for reservation 222','2024-10-07 06:20:00'),(229,'2024-10-17 08:51:00',4,'Complaint resolved as test data for reservation 229','2024-10-17 09:28:00'),(230,'2024-10-07 06:11:00',3,'Complaint resolved as test data for reservation 230','2024-10-07 06:48:00'),(238,'2024-10-21 08:45:00',5,'Complaint resolved as test data for reservation 238','2024-10-21 09:22:00'),(240,'2024-10-18 09:03:00',3,'Complaint resolved as test data for reservation 240','2024-10-18 09:40:00'),(244,'2024-10-27 07:41:00',3,'Complaint resolved as test data for reservation 244','2024-10-27 08:18:00'),(249,'2024-10-31 08:21:00',4,'Complaint resolved as test data for reservation 249','2024-10-31 08:58:00'),(253,'2024-10-23 08:26:00',2,'Complaint resolved as test data for reservation 253','2024-10-23 09:03:00'),(268,'2024-10-31 09:04:00',5,'Complaint resolved as test data for reservation 268','2024-10-31 09:41:00'),(283,'2024-11-10 06:53:00',5,'Complaint resolved as test data for reservation 283','2024-11-10 07:30:00'),(287,'2024-10-29 05:53:00',5,'Complaint resolved as test data for reservation 287','2024-10-29 06:30:00'),(289,'2024-11-05 07:18:00',4,'Complaint resolved as test data for reservation 289','2024-11-05 07:55:00'),(294,'2024-10-23 05:53:00',3,'Complaint resolved as test data for reservation 294','2024-10-23 06:30:00'),(301,'2024-11-03 05:46:00',5,'Complaint resolved as test data for reservation 301','2024-11-03 06:23:00'),(302,'2024-11-07 05:36:00',3,'Complaint resolved as test data for reservation 302','2024-11-07 06:13:00'),(309,'2024-11-10 09:05:00',3,'Complaint resolved as test data for reservation 309','2024-11-10 09:42:00'),(310,'2024-11-11 06:29:00',4,'Complaint resolved as test data for reservation 310','2024-11-11 07:06:00'),(315,'2024-11-05 08:16:00',5,'Complaint resolved as test data for reservation 315','2024-11-05 08:53:00'),(316,'2024-11-12 08:39:00',5,'Complaint resolved as test data for reservation 316','2024-11-12 09:16:00'),(318,'2024-11-13 09:28:00',5,'Complaint resolved as test data for reservation 318','2024-11-13 10:05:00'),(323,'2024-11-14 08:59:00',4,'Complaint resolved as test data for reservation 323','2024-11-14 09:36:00'),(326,'2024-11-03 06:14:00',4,'Complaint resolved as test data for reservation 326','2024-11-03 06:51:00'),(328,'2024-11-12 06:15:00',3,'Complaint resolved as test data for reservation 328','2024-11-12 06:52:00'),(332,'2024-11-05 06:40:00',5,'Complaint resolved as test data for reservation 332','2024-11-05 07:17:00'),(334,'2024-11-10 06:02:00',4,'Complaint resolved as test data for reservation 334','2024-11-10 06:39:00'),(335,'2024-11-12 06:38:00',4,'Complaint resolved as test data for reservation 335','2024-11-12 07:15:00'),(336,'2024-11-02 08:26:00',4,'Complaint resolved as test data for reservation 336','2024-11-02 09:03:00'),(355,'2024-11-05 05:52:00',5,'Complaint resolved as test data for reservation 355','2024-11-05 06:29:00'),(404,'2024-11-19 05:49:00',4,'Complaint resolved as test data for reservation 404','2024-11-19 06:26:00'),(420,'2024-11-20 07:15:00',3,'Complaint resolved as test data for reservation 420','2024-11-20 07:52:00');
/*!40000 ALTER TABLE `complaint_resolution` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `guest`
--

DROP TABLE IF EXISTS `guest`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `guest` (
  `guest_id` int NOT NULL AUTO_INCREMENT,
  `company_id` int DEFAULT NULL,
  `title` varchar(10) NOT NULL,
  `first_name` varchar(80) NOT NULL,
  `last_name` varchar(80) NOT NULL,
  `phone_number` varchar(11) NOT NULL,
  `email` varchar(320) NOT NULL,
  `house_name_number` varchar(50) NOT NULL,
  `postcode` varchar(8) NOT NULL,
  `deleted` tinyint DEFAULT '0',
  PRIMARY KEY (`guest_id`),
  KEY `IDX_guest_company_id` (`company_id`),
  KEY `IDX_guest_last_name` (`last_name`),
  KEY `IDX_guest_postcode` (`postcode`),
  CONSTRAINT `guest_ibfk_1` FOREIGN KEY (`company_id`) REFERENCES `company_account` (`company_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `guest_ibfk_2` FOREIGN KEY (`postcode`) REFERENCES `address` (`postcode`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `CHK_email` CHECK (regexp_like(`email`,_utf8mb4'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+.[a-zA-Z]{2,}$')),
  CONSTRAINT `CHK_phone_number` CHECK (regexp_like(`phone_number`,_utf8mb4'^[0-9]{10,11}$'))
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `guest`
--

LOCK TABLES `guest` WRITE;
/*!40000 ALTER TABLE `guest` DISABLE KEYS */;
INSERT INTO `guest` VALUES (1,NULL,'Mr','Oliver','Smith','07123456789','oliver.smith@hotmail.co.uk','12','CB22 3AA',0),(2,NULL,'Mrs','Sophia','Johnson','07234567890','sophia.johnson@gmail.co.uk','34','NR14 6AB',0),(3,1,'Ms','Amelia','Brown','07345678901','amelia.brown@outlook.co.uk','Ivy Cottage','IP28 8AA',0),(4,1,'Mr','Liam','Williams','07456789012','liam.williams@btinternet.com','78','CO10 1CD',0),(5,NULL,'Dr','Emma','Jones','07567890123','emma.jones@sky.com','90','PE36 5DE',0),(6,NULL,'Miss','Isabella','Garcia','07678901234','isabella.garcia@plusnet.co.uk','23','CM1 4FG',0),(7,2,'Mr','James','Martinez','07789012345','james.martinez@gmail.com','45','CB24 9GH',1),(8,NULL,'Mrs','Mia','Taylor','07890123456','mia.taylor@btinternet.com','67','IP7 6IJ',0),(9,NULL,'Mr','Ethan','Harris','07901234567','ethan.harris@hotmail.co.uk','89','NR20 5KL',0),(10,NULL,'Ms','Ava','Thompson','07012345678','ava.thompson@gmail.com','11','CO10 7MN',0),(11,3,'Mr','Test','Tester1','07701100011','tester1@gmail.com','101','TS1 1AA',0),(12,NULL,'Mr','Test','Tester2','07701100012','tester2@gmail.com','102','TS1 2AA',0),(13,NULL,'Ms','Test','Tester3','07701100013','tester3@gmail.com','103','TS1 3AA',0),(14,3,'Mrs','Test','Tester4','07701100014','tester4@gmail.com','104','TS1 4AA',0),(15,3,'Mr','Test','Tester5','07701100015','tester5@gmail.com','105','TS1 5AA',0),(16,NULL,'Miss','Test','Tester6','07701100016','tester6@gmail.com','106','TS1 6AA',0),(17,NULL,'Mr','Test','Tester7','07701100017','tester7@gmail.com','107','TS1 7AA',0),(18,NULL,'Mr','Test','Tester8','07701100018','tester8@gmail.com','108','TS1 8AA',0),(19,NULL,'Mrs','Test','Tester9','07701100019','tester9@gmail.com','109','TS1 9AA',0),(20,4,'Mr','Test','Tester10','07701100020','tester10@gmail.com','110','TS2 0AB',0),(21,4,'Mr','Test','Tester11','07701100021','tester11@gmail.com','111','TS2 1AB',0),(22,NULL,'Dr','Test','Tester12','07701100022','tester12@gmail.com','112','TS2 2AB',0),(23,NULL,'Mr','Test','Tester13','07701100023','tester13@gmail.com','113','TS2 3AB',0),(24,NULL,'Miss','Test','Tester14','07701100024','tester14@gmail.com','114','TS2 4AB',0),(25,5,'Mr','Test','Tester15','07701100025','tester15@gmail.com','115','TS2 5AB',0),(26,5,'Ms','Test','Tester16','07701100026','tester16@gmail.com','116','TS2 6AB',0),(27,5,'Mr','Test','Tester17','07701100027','tester17@gmail.com','117','TS2 7AB',0),(28,NULL,'Mr','Test','Tester18','07701100028','tester18@gmail.com','118','TS2 8AB',0),(29,NULL,'Mrs','Test','Tester19','07701100029','tester19@gmail.com','119','TS2 9AB',0),(30,NULL,'Miss','Test','Tester20','07701100030','tester20@gmail.com','120','TS3 0AC',0);
/*!40000 ALTER TABLE `guest` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `invoice`
--

DROP TABLE IF EXISTS `invoice`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `invoice` (
  `invoice_number` mediumint NOT NULL AUTO_INCREMENT,
  `invoice_date` date NOT NULL,
  `amount_due` decimal(7,2) NOT NULL,
  `amount_paid` decimal(7,2) NOT NULL,
  `payment_code` char(4) DEFAULT NULL,
  `payment_date` date DEFAULT NULL,
  `payment_reference` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`invoice_number`),
  KEY `FK_payment_code` (`payment_code`),
  CONSTRAINT `FK_payment_code` FOREIGN KEY (`payment_code`) REFERENCES `payment_method` (`payment_code`) ON DELETE SET NULL ON UPDATE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=390 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `invoice`
--

LOCK TABLES `invoice` WRITE;
/*!40000 ALTER TABLE `invoice` DISABLE KEYS */;
INSERT INTO `invoice` VALUES (1,'2024-10-21',94.50,94.50,'CC01','2024-10-23','a72dkji8fvs67nk4j512cs3rw'),(2,'2024-10-24',75.00,75.00,'CC02','2024-10-31','s59p15grdxghz0cg8h92lcqz0'),(3,'2024-10-25',97.75,97.75,'BA01','2024-10-29','kl9823jkbn284sf39dyu130ge'),(4,'2024-08-13',110.00,110.00,'CC01','2024-08-18','apr8lk68uz1txeib9p2ou1wqa'),(5,'2024-08-14',75.00,75.00,'DB02','2024-08-16','9q5n14y8sw6wp3umjgz10tyr2'),(6,'2024-08-15',162.00,162.00,'DB02','2024-08-18','7bgkk1inu4psqn1cxqcsdaxj3'),(7,'2024-08-15',150.00,150.00,'BA01','2024-08-16',NULL),(8,'2024-08-16',75.00,0.00,NULL,NULL,NULL),(9,'2024-08-16',150.00,150.00,'CC01','2024-08-18','3cvw880ihp40ld9wmmmxkov7o'),(10,'2024-08-17',99.00,99.00,'CC02','2024-08-19','2fezz4kxg67zbl5stf8oqyibr'),(11,'2024-08-17',95.00,95.00,'CC01','2024-08-21','0ag3kpqyk6isls60czi6b8a55'),(12,'2024-08-19',96.00,96.00,'DB02','2024-08-20','eov4gix7pd71r81isf8e4jk7e'),(13,'2024-08-19',65.00,65.00,'DB02','2024-08-21','a9h1lfq2cqyiw08phhasasc19'),(14,'2024-08-19',150.00,150.00,'CC02','2024-08-21','eqtrllep6ip4vk1iefisbf6yr'),(15,'2024-08-20',108.00,108.00,'CC01','2024-08-23','26wj5z7xk8wvgl9sycnqxircl'),(16,'2024-08-20',162.00,162.00,'CC02','2024-08-22','py8orv09f5repjcwd3q8t6pir'),(17,'2024-08-20',75.00,75.00,'CC02','2024-08-22','iizmolfg51h77to1e780g773s'),(18,'2024-08-20',115.00,115.00,'CC02','2024-08-21','amat1djxed1dkuyqrhc2btho9'),(19,'2024-08-21',93.50,93.50,'CC01','2024-08-24','35vpbkktbhjx2um0rt0b48tst'),(20,'2024-08-21',110.00,110.00,'CC02','2024-08-26','clwutdiikzltdo3ywj29267f2'),(21,'2024-08-22',90.00,0.00,NULL,NULL,NULL),(22,'2024-08-22',90.00,90.00,'CC01','2024-08-25','www0np4z56cic877xn84lx303'),(23,'2024-08-23',180.00,0.00,NULL,NULL,NULL),(24,'2024-08-23',140.00,140.00,'CC01','2024-08-24','szz20v67hotmjovzs8upkotn4'),(25,'2024-08-23',110.00,110.00,'CA01','2024-08-28',NULL),(26,'2024-08-23',115.00,115.00,'CC02','2024-08-24','8ie18c1vfuvtxlwje8zc99o2d'),(27,'2024-08-24',110.00,110.00,'DB02','2024-08-30','cioxgox959ey8zp5n0ppy92ml'),(28,'2024-08-25',105.00,105.00,'CC01','2024-08-30','nq66skh4gx931tkpzv1u7a4bc'),(29,'2024-08-25',120.00,120.00,'DB02','2024-08-26','7rv4m1okiovqd5eq5h7eimstg'),(30,'2024-08-25',150.00,150.00,'DB01','2024-08-28','u801u6h6nkh3b07pcruqhd1uy'),(31,'2024-08-25',80.75,80.75,'CC02','2024-08-28','2n122ptt76gpl9a07cudnsmrg'),(32,'2024-08-25',115.00,115.00,'CC02','2024-08-27','789obstr7h9uuhq4jx4twnhqv'),(33,'2024-08-25',55.25,55.25,'DB02','2024-08-29','a96ax8fxw8btk6liy90te2h6k'),(34,'2024-08-26',120.00,120.00,'CC01','2024-08-31','nc1cn6nilpcw66snvi84nlw8q'),(35,'2024-08-26',90.00,90.00,'CC01','2024-09-01','cfe0exom8wpkxe4p3yx37hk1l'),(36,'2024-08-26',140.00,140.00,'DB01','2024-08-27','auaxrdrc7m096j27l0thepe2u'),(37,'2024-08-26',180.00,180.00,'CC02','2024-08-30','td20ic27vg5i1ygb2bf30xhjn'),(38,'2024-08-26',103.50,103.50,'CA01','2024-09-01',NULL),(39,'2024-08-27',102.00,102.00,'CA01','2024-08-30',NULL),(40,'2024-08-27',103.50,103.50,'BA01','2024-08-30',NULL),(41,'2024-08-27',96.00,96.00,'CA01','2024-08-31',NULL),(42,'2024-08-28',99.00,99.00,'CC01','2024-08-29','hhgqp9n12p7fm9cv57ovygui2'),(43,'2024-08-28',115.00,115.00,'CC01','2024-08-29','k87lcz53zw91y4buk8y0y8npa'),(44,'2024-08-29',100.00,100.00,'DB01','2024-08-31','uq8y9t3izt3qpqe833cq3vepl'),(45,'2024-08-29',110.00,110.00,'CA01','2024-09-04',NULL),(46,'2024-08-30',110.00,110.00,'CC02','2024-08-31','cl1b1agn23z1ywwusz7jx1028'),(47,'2024-08-30',80.00,80.00,'DB01','2024-09-02','5r7em9wiqdyd6yycoi44mouyk'),(48,'2024-08-31',180.00,180.00,'CC02','2024-09-03','dfrbviqzevp645sa7cjgqrool'),(49,'2024-08-31',150.00,150.00,'CC02','2024-09-03','zqzkf7ve8d7v5gtovmg14467w'),(50,'2024-08-31',100.00,100.00,'CC01','2024-09-02','ri57g0yviyt4qkas3dufn11iq'),(51,'2024-09-01',94.50,94.50,'DB01','2024-09-04','pcja8dp6t3o0i48rdd79657n7'),(52,'2024-09-01',108.00,108.00,'CA01','2024-09-02',NULL),(53,'2024-09-01',115.00,115.00,'CC01','2024-09-02','1smzxwg2udnkow0hux0qwqiq5'),(54,'2024-09-01',115.00,115.00,'DB01','2024-09-05','4q92yvjti1slzm7fa5kro1pxu'),(55,'2024-09-02',108.00,108.00,'DB02','2024-09-07','p2jfpsk81he5v0mpcobbgrlku'),(56,'2024-09-02',108.00,108.00,'BA01','2024-09-05',NULL),(57,'2024-09-02',140.00,140.00,'CC02','2024-09-05','bk53uzhntib93hv4igcbliszg'),(58,'2024-09-02',120.00,120.00,'DB01','2024-09-08','ij1me8ggqk8n40cjs7r9umuxv'),(59,'2024-09-02',85.50,85.50,'DB01','2024-09-03','igl0qfvncl7kds5si14jslhp5'),(60,'2024-09-02',103.50,103.50,'CC02','2024-09-06','1x68vox4cika74dgwn6ucsi73'),(61,'2024-09-03',80.00,80.00,'CC02','2024-09-06','va1jl6j9pul93bhv5cm0p47nj'),(62,'2024-09-03',92.00,0.00,NULL,NULL,NULL),(63,'2024-09-03',99.00,99.00,'CC01','2024-09-06','303y9fv1knnra1so5vfkuxv80'),(64,'2024-09-03',100.00,100.00,'CC01','2024-09-06','gusi9nipklcmcn7w0aety8pff'),(65,'2024-09-04',105.00,105.00,'CA01','2024-09-06',NULL),(66,'2024-09-04',95.00,95.00,'CC02','2024-09-06','jpsnzajvj6nf2j51vqiemdepl'),(67,'2024-09-04',75.00,75.00,'BA01','2024-09-07',NULL),(68,'2024-09-04',75.00,75.00,'CA01','2024-09-10',NULL),(69,'2024-09-04',93.50,93.50,'DB02','2024-09-09','y8394atvc065zd0ar7u7dfyju'),(70,'2024-09-05',90.00,0.00,NULL,NULL,NULL),(71,'2024-09-05',140.00,140.00,'DB01','2024-09-06','wf88gu69u08mawy2bl6flccal'),(72,'2024-09-05',120.00,120.00,'CA01','2024-09-08',NULL),(73,'2024-09-06',80.00,80.00,'CA01','2024-09-09',NULL),(74,'2024-09-06',180.00,180.00,'CC02','2024-09-09','rov9v08ykbgdm5g2ztsktptb5'),(75,'2024-09-06',150.00,150.00,'DB01','2024-09-13','nzkrp7kauwo8fqg0w5wxx825c'),(76,'2024-09-06',110.00,110.00,'CC01','2024-09-09','dz9t97ro0vjj3uiizpanqm1c5'),(77,'2024-09-06',95.00,0.00,NULL,NULL,NULL),(78,'2024-09-07',105.00,105.00,'CC02','2024-09-12','c0rglfgdoos6hkd5mv4osde2o'),(79,'2024-09-07',81.00,81.00,'DB02','2024-09-09','6w21cdu7fkik2zgjeox076xp3'),(80,'2024-09-07',119.00,119.00,'BA01','2024-09-09',NULL),(81,'2024-09-07',110.00,110.00,'CA01','2024-09-08',NULL),(82,'2024-09-07',90.00,90.00,'CC01','2024-09-10','60a5oiza9n7fr7lalrzhnew5c'),(83,'2024-09-07',120.00,0.00,NULL,NULL,NULL),(84,'2024-09-08',85.00,85.00,'CC01','2024-09-10','dmm4ldjlf54s6k5duz2de2ekw'),(85,'2024-09-08',103.50,103.50,'CC01','2024-09-13','eildajl1y17o9l3c2bcmrxt8o'),(86,'2024-09-08',120.00,0.00,NULL,NULL,NULL),(87,'2024-09-09',95.00,95.00,'CC02','2024-09-13','kapj04nfqkd860t2uj462xgyq'),(88,'2024-09-09',75.00,75.00,'DB01','2024-09-14','gbey5l9b41uzpb8m4etziq8ew'),(89,'2024-09-09',180.00,180.00,'CC01','2024-09-10','o6hfnnbant7oeuc2h6t4739kh'),(90,'2024-09-09',60.00,60.00,'CC01','2024-09-14','cr1uaafc00ti5o4mheo6zp7l0'),(91,'2024-09-09',110.00,110.00,'CC01','2024-09-10','8xeaczzhy1zv5zfb9dcbsdjv7'),(92,'2024-09-10',153.00,153.00,'BA01','2024-09-13',NULL),(93,'2024-09-10',115.00,115.00,'DB01','2024-09-12','4g7dsssop7q0t3hvc79vz2iii'),(94,'2024-09-10',110.00,110.00,'DB02','2024-09-15','y9rr0s7zizrf6lhme2b48d4gf'),(95,'2024-09-10',108.00,108.00,'CA01','2024-09-11',NULL),(96,'2024-09-11',65.00,65.00,'CC01','2024-09-14','dysiyq7myb39yicz2dc9q4nwt'),(97,'2024-09-11',90.00,0.00,NULL,NULL,NULL),(98,'2024-09-11',140.00,140.00,'DB01','2024-09-13','bdio6vcnzxi4e3gxmxx402ary'),(99,'2024-09-11',120.00,120.00,'CA01','2024-09-15',NULL),(100,'2024-09-11',100.00,100.00,'CC01','2024-09-14','6vy0gbixw8wsbkkl850jk5yiw'),(101,'2024-09-11',80.00,80.00,'CC02','2024-09-14','d53gpm3ow0au3m5z3m18x46a7'),(102,'2024-09-11',120.00,120.00,'CC01','2024-09-13','gjsgwr6cek1ce48bzvcx9t2ic'),(103,'2024-09-12',105.00,105.00,'DB01','2024-09-19','3u1e8hb2qryauoq7y7mgorxwm'),(104,'2024-09-12',80.00,80.00,'CC02','2024-09-19','6jqbantdniw92kxhajiyznsel'),(105,'2024-09-12',110.00,110.00,'CC02','2024-09-14','s4kogrd5vclxu5eojfw2cmgyj'),(106,'2024-09-12',75.00,75.00,'CC01','2024-09-15','nn5lqocuhjmbvxq8nzvekmb62'),(107,'2024-09-13',85.00,0.00,NULL,NULL,NULL),(108,'2024-09-13',103.50,103.50,'CC02','2024-09-18','v90afod9py7ixnkolyrn4pet1'),(109,'2024-09-14',153.00,0.00,NULL,NULL,NULL),(110,'2024-09-14',150.00,150.00,'DB01','2024-09-15','ysk0pgtsz2v8okdwbo7axbu1b'),(111,'2024-09-14',115.00,115.00,'CC02','2024-09-17','r0pco4epq2l53vat7pum2dpa1'),(112,'2024-09-14',110.00,110.00,'CC01','2024-09-16','9p0xsk6b13h5myoxwy4rqy15x'),(113,'2024-09-14',100.00,100.00,'BA01','2024-09-16',NULL),(114,'2024-09-14',120.00,120.00,'DB02','2024-09-16','wulenfgqfhcwym4en1lx4au2h'),(115,'2024-09-15',75.00,0.00,NULL,NULL,NULL),(116,'2024-09-15',85.50,85.50,'CA01','2024-09-18',NULL),(117,'2024-09-15',115.00,115.00,'CC02','2024-09-18','0t7yvv9451gs724imog5hi1n6'),(118,'2024-09-16',81.00,81.00,'CC01','2024-09-18','54eufuzi3ez5w5yjaawkelvcs'),(119,'2024-09-16',140.00,0.00,NULL,NULL,NULL),(120,'2024-09-16',72.00,72.00,'CA01','2024-09-17',NULL),(121,'2024-09-16',108.00,108.00,'DB02','2024-09-18','2izxxfm0sneshsu1ql9tjbcm9'),(122,'2024-09-16',120.00,0.00,NULL,NULL,NULL),(123,'2024-09-16',110.00,110.00,'CC02','2024-09-19','fsg10emquf4981s4mztvqojut'),(124,'2024-09-17',153.00,153.00,'DB01','2024-09-18','9tar2l8w994ueycujppk8x2o0'),(125,'2024-09-17',120.00,120.00,'CC02','2024-09-22','f8esd137jgbiar6b24yj3ywqa'),(126,'2024-09-17',110.00,110.00,'DB02','2024-09-20','716rrws6dx3yt5nun2c1cw940'),(127,'2024-09-18',150.00,150.00,'BA01','2024-09-24',NULL),(128,'2024-09-18',115.00,115.00,'DB01','2024-09-23','ooaddw7g9e9rbkjszg2cek0yu'),(129,'2024-09-19',140.00,140.00,'DB01','2024-09-20','lln7ibjbi42q8w00zgg87cryk'),(130,'2024-09-19',115.00,115.00,'CC01','2024-09-23','liwfadwze37j9r5gjh39l15rd'),(131,'2024-09-20',162.00,162.00,'CA01','2024-09-23',NULL),(132,'2024-09-20',64.00,64.00,'CC01','2024-09-24','z3s0891hxfserb18igaa70jup'),(133,'2024-09-21',75.00,75.00,'CC01','2024-09-26','yiqhv7d1layfvitzclbt2b8qx'),(134,'2024-09-21',120.00,120.00,'CC02','2024-09-24','sjk7osodawvaw76tze7rgkyi8'),(135,'2024-09-21',99.00,99.00,'CC02','2024-09-23','ejocryiga1hyzv6vn3tnebm1d'),(136,'2024-09-21',100.00,100.00,'CC01','2024-09-22','7enu0bx5gitoe0300djeqmitr'),(137,'2024-09-22',54.00,54.00,'CC01','2024-09-25','dqpqe47amv1rxdkk6j7l1v309'),(138,'2024-09-22',120.00,120.00,'CC02','2024-09-26','dts43yrdx8g8fa1wd87wepznx'),(139,'2024-09-22',119.00,119.00,'CC01','2024-09-23','2x0e7o64cwkd6e5rh7gjge5ld'),(140,'2024-09-22',85.50,85.50,'CC02','2024-09-23','ao1ob9q8gr8q038pwhaecan3y'),(141,'2024-09-23',140.00,140.00,'BA01','2024-09-27',NULL),(142,'2024-09-23',90.00,90.00,'CC01','2024-09-25','t609t95v2zsbeyyvc8jgy6ims'),(143,'2024-09-23',99.00,99.00,'DB01','2024-09-27','qftzh6b5be1urty7id5ll617h'),(144,'2024-09-23',115.00,115.00,'CC01','2024-09-24','f6295gdnq3d9olzwwto0pfjgi'),(145,'2024-09-24',97.75,97.75,'DB01','2024-09-26','4avuvdo0buiouwd2p5akt9yky'),(146,'2024-09-24',108.00,108.00,'CC01','2024-09-27','kej9zqvlcxowznwbfii5iqxht'),(147,'2024-09-24',95.00,95.00,'CC02','2024-09-28','jxqwgz9mu85eouq055ioppo90'),(148,'2024-09-24',92.00,92.00,'CC02','2024-09-27','216rphu8qx23x7jbuugho4o94'),(149,'2024-09-25',180.00,180.00,'DB01','2024-09-30','mbofj591rvjmy28aw9uyni4pi'),(150,'2024-09-25',150.00,150.00,'CC02','2024-09-30','8acm68uz21fhlk626wqrvc3ed'),(151,'2024-09-25',110.00,110.00,'DB02','2024-09-28','7nodzgr5qt472k2owaqn1iq34'),(152,'2024-09-26',85.00,85.00,'CC01','2024-09-27','ksjv426h3uk2iqw9kknb73m98'),(153,'2024-09-26',110.00,110.00,'CC01','2024-09-27','xvtrkoloixmnwecfshs1f73gr'),(154,'2024-09-27',105.00,0.00,NULL,NULL,NULL),(155,'2024-09-27',120.00,120.00,'BA01','2024-09-29',NULL),(156,'2024-09-27',99.00,99.00,'CC01','2024-10-02','emrl7abxsgimjpclepa722729'),(157,'2024-09-27',90.00,90.00,'CC02','2024-09-30','vpcccj16hatfmr8gdgz5g8i09'),(158,'2024-09-28',110.00,110.00,'CC02','2024-09-30','bathqunomk66dw3usb9ewupfx'),(159,'2024-09-28',90.00,90.00,'CC02','2024-10-01','92kvxqey2htmo4h35vbi6mlky'),(160,'2024-09-28',115.00,0.00,NULL,NULL,NULL),(161,'2024-09-28',110.00,110.00,'CC01','2024-09-30','ljwse2krwz2nvkbfdgchzw31q'),(162,'2024-09-28',115.00,115.00,'CC01','2024-09-29','r0uoa15urvz7nz9y16y6uiqyv'),(163,'2024-09-28',115.00,115.00,'DB02','2024-10-01','ioo2ulyny8rkagjp7i1s8i9pw'),(164,'2024-09-29',95.00,95.00,'CC02','2024-10-03','dvchsvbdz9x8qk9pv9r3s3nac'),(165,'2024-09-29',72.00,72.00,'CC02','2024-10-03','mwovvc33xi3chv0ec32cx90kh'),(166,'2024-09-29',140.00,140.00,'DB02','2024-10-02','gd5m7s4lo5vjl05z9tf5rhxkm'),(167,'2024-09-29',120.00,120.00,'CC01','2024-10-04','k98l440ykcncbk6kuu1i5l8k3'),(168,'2024-09-29',120.00,0.00,NULL,NULL,NULL),(169,'2024-09-30',162.00,162.00,'CC02','2024-10-03','civ46n3sgxfk9l2rn1w2t40n5'),(170,'2024-09-30',120.00,120.00,'CC02','2024-10-03','1pa996iyaj693qk6ixc81y4hs'),(171,'2024-09-30',108.00,108.00,'DB02','2024-10-06','e1f92u427oq9ad594ff28hfrd'),(172,'2024-09-30',110.00,110.00,'DB01','2024-10-03','2t5sul3rrs72k71to3rlklftd'),(173,'2024-09-30',100.00,100.00,'DB01','2024-10-03','z0ydp870vofvq45uk0zu9s7kr'),(174,'2024-09-30',60.00,60.00,'CC02','2024-10-03','1tbhbv3luqc66ezzzhbr0bnrg'),(175,'2024-10-01',115.00,115.00,'DB01','2024-10-03','1bcobow48qped6wbf1zxh7bw0'),(176,'2024-10-01',115.00,0.00,NULL,NULL,NULL),(177,'2024-10-02',110.00,110.00,'CC01','2024-10-06','ctihb19x5etawhs2lh3xlws37'),(178,'2024-10-02',120.00,120.00,'DB01','2024-10-06','raloq263h4sjypgtjvfreqj1p'),(179,'2024-10-03',105.00,0.00,NULL,NULL,NULL),(180,'2024-10-03',140.00,140.00,'DB01','2024-10-04','1jffev1godou449m369pq8l8a'),(181,'2024-10-03',115.00,0.00,NULL,NULL,NULL),(182,'2024-10-04',180.00,0.00,NULL,NULL,NULL),(183,'2024-10-04',126.00,126.00,'CC02','2024-10-07','v23n3o1dolylma0t9pnwoe1zg'),(184,'2024-10-04',81.00,81.00,'DB02','2024-10-09','w72g9u4ejdpr3cdxmtnvlkw3z'),(185,'2024-10-04',110.00,110.00,'CC01','2024-10-07','c05q7bgbsly2e1jaj13ww29qb'),(186,'2024-10-05',100.00,100.00,'BA01','2024-10-07',NULL),(187,'2024-10-05',127.50,127.50,'DB02','2024-10-08','thu3nmlcqmicqevr2efn3t8sm'),(188,'2024-10-05',95.00,95.00,'CC02','2024-10-07','v7imdcq9vp2m5rw6sj0oo44pa'),(189,'2024-10-06',63.75,63.75,'DB01','2024-10-07','x5af6nky7acs28xzok5a94141'),(190,'2024-10-06',115.00,115.00,'BA01','2024-10-07',NULL),(191,'2024-10-06',115.00,0.00,NULL,NULL,NULL),(192,'2024-10-06',72.00,72.00,'DB01','2024-10-11','j59ol6atqhubulyph1yelcpje'),(193,'2024-10-06',120.00,120.00,'CC01','2024-10-08','3cul2pbnspam98sh4opmn0869'),(194,'2024-10-07',119.00,119.00,'CA01','2024-10-08',NULL),(195,'2024-10-07',85.50,0.00,NULL,NULL,NULL),(196,'2024-10-07',80.00,80.00,'CC01','2024-10-10','d2jrw7802gmm6jqjzfoml9qgb'),(197,'2024-10-08',115.00,115.00,'DB02','2024-10-12','q1yxpaapb3sf2rfj354i6tu7o'),(198,'2024-10-09',120.00,120.00,'DB01','2024-10-12','2qjrr06vq79j3znyib57si36h'),(199,'2024-10-09',105.00,105.00,'CC02','2024-10-11','307a3gabp870421yfnp9hooih'),(200,'2024-10-09',110.00,110.00,'CC02','2024-10-11','jk31lxl5jhzjfomvrnbcm5ffo'),(201,'2024-10-10',108.00,108.00,'CC02','2024-10-12','dkanlhy1c8i19ulez1ae8cv9u'),(202,'2024-10-10',97.75,97.75,'CA01','2024-10-13',NULL),(203,'2024-10-11',76.50,76.50,'DB01','2024-10-12','j2s682lbquk29kq4m5wutltqa'),(204,'2024-10-11',180.00,180.00,'DB01','2024-10-14','3vnwc9bnqdcbc5sfy8f81gkbx'),(205,'2024-10-11',150.00,150.00,'CC02','2024-10-12','awn89qynlnztuykwye3boe6c7'),(206,'2024-10-11',140.00,140.00,'DB01','2024-10-14','ckzmx6rdo3gmalojpi1gpvo0x'),(207,'2024-10-11',108.00,108.00,'DB01','2024-10-16','ho3xpn14rwof1cbi7yk1xlat2'),(208,'2024-10-11',110.00,110.00,'CC01','2024-10-14','48u91ms4jg50fv4j0jpxy1ldr'),(209,'2024-10-11',110.00,110.00,'DB01','2024-10-12','ovfjgwlqnyrlh31920dmy43a5'),(210,'2024-10-11',100.00,0.00,NULL,NULL,NULL),(211,'2024-10-11',60.00,60.00,'CC02','2024-10-13','danxqn63yifijego4t2enqlk0'),(212,'2024-10-12',120.00,120.00,'DB01','2024-10-14','zszlnqlx66nsau4jf3buz7ipd'),(213,'2024-10-13',90.00,90.00,'BA01','2024-10-16',NULL),(214,'2024-10-13',150.00,150.00,'CA01','2024-10-14',NULL),(215,'2024-10-13',115.00,115.00,'CC02','2024-10-14','jq2pwt1ljktww35kb31jkh093'),(216,'2024-10-13',110.00,110.00,'CC02','2024-10-15','ov45niecord4m75ju7hx3o9ec'),(217,'2024-10-13',60.00,60.00,'CC01','2024-10-16','m0soq9n2enx56nj5f8wopsuto'),(218,'2024-10-14',99.00,99.00,'CA01','2024-10-17',NULL),(219,'2024-10-14',94.50,94.50,'CC01','2024-10-21','acrwkkofz6nxxicrns10zib7d'),(220,'2024-10-14',140.00,140.00,'DB02','2024-10-15','qp8fb17sb61n1gnoc7s9fxgsa'),(221,'2024-10-15',162.00,162.00,'DB01','2024-10-20','06vjwofq6ky5350t63hxy34ki'),(222,'2024-10-15',150.00,150.00,'CC01','2024-10-19','jlewr4kxdnio14joecolce9r7'),(223,'2024-10-15',140.00,140.00,'CC02','2024-10-16','quky2j49gbk8r8rwuyx2cyyw3'),(224,'2024-10-15',110.00,110.00,'CC01','2024-10-16','nodhlwzqvl8pnfucv66sv08h2'),(225,'2024-10-15',115.00,115.00,'CC01','2024-10-19','p5g1x0w9eta7ujrz3y6bk7wbe'),(226,'2024-10-15',72.00,72.00,'DB02','2024-10-17','ga4hbrdilrjdndaoswq6op854'),(227,'2024-10-16',120.00,120.00,'CC02','2024-10-18','9z3z5xnzrdttgut70c5ojeqm0'),(228,'2024-10-16',140.00,140.00,'CC01','2024-10-18','5ijnune1f793562lkn13kb95j'),(229,'2024-10-16',120.00,120.00,'CC02','2024-10-19','x9n3svcvxrck1chpiqxofeczr'),(230,'2024-10-16',115.00,115.00,'CA01','2024-10-20',NULL),(231,'2024-10-16',115.00,115.00,'BA01','2024-10-19',NULL),(232,'2024-10-17',65.00,65.00,'CA01','2024-10-23',NULL),(233,'2024-10-17',90.00,0.00,NULL,NULL,NULL),(234,'2024-10-17',76.50,76.50,'CC01','2024-10-22','xfw31bjunj1znhn4wl6s3ugn5'),(235,'2024-10-17',99.00,99.00,'BA01','2024-10-18',NULL),(236,'2024-10-17',90.00,90.00,'CC01','2024-10-19','p8e1dithw5966oipiks6xlkqo'),(237,'2024-10-17',72.00,72.00,'DB02','2024-10-19','yjh2stxb5sr4nf0ozzqj24bue'),(238,'2024-10-18',75.00,75.00,'CC01','2024-10-22','olbxv0uha0p76cl1azp5f7ald'),(239,'2024-10-18',140.00,140.00,'DB01','2024-10-20','hwoy1ny85elkkqpb66ckaq5zp'),(240,'2024-10-18',110.00,110.00,'BA01','2024-10-21',NULL),(241,'2024-10-18',88.00,88.00,'BA01','2024-10-19',NULL),(242,'2024-10-18',120.00,120.00,'BA01','2024-10-20',NULL),(243,'2024-10-19',80.00,80.00,'DB02','2024-10-22','uzhmnlu2ebe52nwkkt4u3u16r'),(244,'2024-10-19',100.00,100.00,'DB01','2024-10-22','aua5hyz8pp7l3bbi7qz8om67a'),(245,'2024-10-19',115.00,115.00,'CC01','2024-10-24','r61wrmyua2t4g1rhszqyhoo6w'),(246,'2024-10-20',95.00,95.00,'CC02','2024-10-23','7zqqadn371c1boo727jfhoxzw'),(247,'2024-10-20',90.00,90.00,'DB01','2024-10-21','xzgrt03c7rq4zr444t1autsdh'),(248,'2024-10-20',68.00,68.00,'DB02','2024-10-23','evs70xmc2eo16adh9p9brssgs'),(249,'2024-10-20',126.00,126.00,'DB01','2024-10-25','y1bv46foicz43appl21k1ahl6'),(250,'2024-10-20',120.00,120.00,'CC02','2024-10-21','h6z2vjfsi5fk0mo8caakf4aeh'),(251,'2024-10-20',115.00,115.00,'CC01','2024-10-22','gxpdl2rpvvuof5i75qd2d6rhy'),(252,'2024-10-20',108.00,108.00,'CC01','2024-10-23','ma8gsrykq4qb3x0zs9hkytivd'),(253,'2024-10-20',99.00,99.00,'CC02','2024-10-23','5rho6b7zs0zvwbqn5lak4zms2'),(254,'2024-10-21',180.00,180.00,'CA01','2024-10-24',NULL),(255,'2024-10-21',93.50,0.00,NULL,NULL,NULL),(256,'2024-10-21',110.00,110.00,'DB01','2024-10-23','i4xvjzt88vuw8tl6iogfzwdz3'),(257,'2024-10-21',75.00,75.00,'CC02','2024-10-26','gm9b10qqxvjpsl5rs2v6ubl53'),(258,'2024-10-22',120.00,120.00,'CC01','2024-10-24','74tt3gmg177ml7a593cr5a0o6'),(259,'2024-10-23',80.00,80.00,'CC02','2024-10-25','gmjujmg84p4pgf7oqppfek3yu'),(260,'2024-10-23',90.00,90.00,'CA01','2024-10-26',NULL),(261,'2024-10-23',99.00,0.00,NULL,NULL,NULL),(262,'2024-10-24',95.00,95.00,'CC02','2024-10-27','zy7g81wk2w9q5r9gosgk6rvhg'),(263,'2024-10-24',180.00,180.00,'DB01','2024-10-30','3njvj1ixtgx949lo8i4tqhbm8'),(264,'2024-10-24',127.50,0.00,NULL,NULL,NULL),(265,'2024-10-24',120.00,120.00,'DB02','2024-10-26','dvkuz3abch804fbehkqxsq0xd'),(266,'2024-10-24',115.00,115.00,'CC01','2024-10-27','bs8bhu5kgbbbl26rdbk3njenh'),(267,'2024-10-24',110.00,110.00,'CC01','2024-10-31','ipho9ywr834tz8hghsv6rmeqo'),(268,'2024-10-24',99.00,0.00,NULL,NULL,NULL),(269,'2024-10-24',100.00,100.00,'DB02','2024-10-26','gv57zvi1q27exxvnrbi6z7xhw'),(270,'2024-10-24',115.00,115.00,'CC01','2024-10-26','6xp1f8hlt9t95umcar7i06rbj'),(271,'2024-10-24',120.00,120.00,'CC02','2024-10-25','3ypyq15f9w3pmf1e1g0gt9if5'),(272,'2024-10-25',105.00,105.00,'CC01','2024-10-28','i5qjokfhsvc02ou3e469z9wd3'),(273,'2024-10-25',85.00,85.00,'CC01','2024-10-31','qse9jtxgjur4si79160u8biu5'),(274,'2024-10-25',80.00,80.00,'BA01','2024-10-27',NULL),(275,'2024-10-26',90.00,90.00,'DB02','2024-10-28','kgi5s04lygju351fumxx1wikj'),(276,'2024-10-26',150.00,150.00,'CC01','2024-10-29','2c6e4em7oiyjsd15ja6mgc07b'),(277,'2024-10-26',140.00,140.00,'DB01','2024-10-28','vi61utsccjsh3qo3ibznh9w7y'),(278,'2024-10-26',120.00,120.00,'BA01','2024-10-31',NULL),(279,'2024-10-26',120.00,0.00,NULL,NULL,NULL),(280,'2024-10-27',65.00,65.00,'CC02','2024-10-28','1muym6dgvbjuoiop44oen49nv'),(281,'2024-10-27',72.00,72.00,'DB01','2024-10-29','rtgc2s9s0wqgnk2ese7p34sbz'),(282,'2024-10-27',99.00,99.00,'CC01','2024-10-29','qsyh0la9mjsgz06mxipraurzw'),(283,'2024-10-28',105.00,105.00,'CC01','2024-10-29','vq9xzdc2rfuflx2k39l45xg6b'),(284,'2024-10-28',76.00,76.00,'CC02','2024-10-31','ml9swirk72i3cojud82xqkw9k'),(285,'2024-10-28',110.00,110.00,'BA01','2024-10-31',NULL),(286,'2024-10-28',80.00,80.00,'CC02','2024-10-31','zsrocgj0091a58455bz9h7ov6'),(287,'2024-10-28',97.75,97.75,'DB01','2024-11-03','gttlo8kiw3i6uias19visfdm6'),(288,'2024-10-28',102.00,102.00,'CC02','2024-10-30','v3w02bcstum2yixl6zuvqmecw'),(289,'2024-10-29',150.00,150.00,'DB01','2024-11-02','th37wzagptrfjtkdxwxu1l1kw'),(290,'2024-10-29',103.50,103.50,'DB01','2024-11-03','7sul1711hui1z8bswhd4hz7cb'),(291,'2024-10-29',115.00,115.00,'DB01','2024-11-03','kekkn96iv9hoykooo4agu4xli'),(292,'2024-10-29',80.00,80.00,'CC02','2024-10-31','9zjjgbiq0u84en79if0yhug1e'),(293,'2024-10-29',60.00,60.00,'DB01','2024-10-30','6a3bghjsm60k8eomek7g6g76j'),(294,'2024-10-29',110.00,0.00,NULL,NULL,NULL),(295,'2024-10-30',105.00,105.00,'DB01','2024-11-02','3up80sflukhwwhppjtfval9zh'),(296,'2024-10-30',90.00,0.00,NULL,NULL,NULL),(297,'2024-10-30',140.00,140.00,'CC01','2024-11-02','idayu3vtvrlcktzechaxl20sr'),(298,'2024-10-30',75.00,75.00,'DB01','2024-11-05','3ot5pqkarynpzfwmv4c7b2oc7'),(299,'2024-10-30',120.00,120.00,'CA01','2024-11-02',NULL),(300,'2024-10-31',85.50,85.50,'CC02','2024-11-03','6cc8xpxxsz9s49ki2xb2u487p'),(301,'2024-10-31',180.00,180.00,'CC01','2024-11-05','ovvxpav04fobbhijuymvan0ua'),(302,'2024-10-31',108.00,108.00,'DB01','2024-11-02','5wyaueziyfskqdfg5qnsg8d4h'),(303,'2024-10-31',99.00,99.00,'CA01','2024-11-01',NULL),(304,'2024-11-01',99.00,99.00,'DB02','2024-11-07','6u92li46rsomwxe0mqlnk9ugt'),(305,'2024-11-02',94.50,94.50,'DB02','2024-11-05','cv94esgl9eh2x1m5z6d1a2ca4'),(306,'2024-11-02',85.00,85.00,'DB02','2024-11-03','65wkmwm081grrvm2m7n0vk72b'),(307,'2024-11-02',126.00,126.00,'CC01','2024-11-05','k08qhofcsaw6g87jxvioxcykt'),(308,'2024-11-02',120.00,120.00,'CA01','2024-11-03',NULL),(309,'2024-11-02',110.00,110.00,'BA01','2024-11-03',NULL),(310,'2024-11-02',100.00,0.00,NULL,NULL,NULL),(311,'2024-11-03',108.00,108.00,'DB02','2024-11-04','vep0bv83jiq3urglppszvx90k'),(312,'2024-11-03',85.00,85.00,'DB02','2024-11-05','lyds726xl0bjagf46dn18qbph'),(313,'2024-11-03',99.00,0.00,NULL,NULL,NULL),(314,'2024-11-04',95.00,95.00,'CC01','2024-11-08','ht9fql0qzs6ku1vcmkc8u328a'),(315,'2024-11-04',58.50,58.50,'CC02','2024-11-07','d0xfe2xdmtiw4ofnlxut0eam7'),(316,'2024-11-04',120.00,120.00,'CC01','2024-11-05','q9q176xw3ydned9r935wyk5d8'),(317,'2024-11-04',120.00,120.00,'DB02','2024-11-05','671qd7abtn3onvudkbz1ppvof'),(318,'2024-11-04',115.00,115.00,'DB02','2024-11-10','ttjxt1irqjy07m2loz2q120rf'),(319,'2024-11-04',103.50,103.50,'CA01','2024-11-07',NULL),(320,'2024-11-04',115.00,115.00,'BA01','2024-11-09',NULL),(321,'2024-11-05',54.00,54.00,'DB01','2024-11-07','a7zn93cmz2ngdnt7x9zkidaol'),(322,'2024-11-05',120.00,120.00,'CC01','2024-11-07','to4ww4mfgkvl95v0qkcql6yj7'),(323,'2024-11-05',94.50,94.50,'CA01','2024-11-06',NULL),(324,'2024-11-06',144.00,144.00,'DB01','2024-11-07','z9y41j16dk4t9w2at02jfuj2w'),(325,'2024-11-06',105.00,105.00,'CC02','2024-11-07','zcy6lla3rzn9gqmywe61ly4re'),(326,'2024-11-06',110.00,110.00,'CA01','2024-11-08',NULL),(327,'2024-11-07',120.00,120.00,'CC02','2024-11-10','5hnntpyaqx0osf4u28swm6903'),(328,'2024-11-07',150.00,150.00,'CC01','2024-11-10','0wn509p28b1adbl9akdfki989'),(329,'2024-11-07',180.00,180.00,'CC01','2024-11-11','vxabkdazir1yz7xum4zc8h4lc'),(330,'2024-11-07',105.00,105.00,'CC02','2024-11-10','7gpa2ekevngtvu56yr2rd9e7r'),(331,'2024-11-07',126.00,126.00,'CC01','2024-11-08','l6m5xgjpnj0sxt790qo1beif9'),(332,'2024-11-07',90.00,90.00,'CA01','2024-11-10',NULL),(333,'2024-11-07',115.00,115.00,'CC01','2024-11-10','t40gs2eyondk7c8qg8crsfznv'),(334,'2024-11-08',72.00,72.00,'DB02','2024-11-09','c7wstx9qi8662dh2yfhxh627u'),(335,'2024-11-08',126.00,126.00,'CC01','2024-11-11','3xwo2heyc5nn9r3qq1iou7ho2'),(336,'2024-11-08',110.00,110.00,'DB02','2024-11-10','cix8817ql33ib3io2cuv50gsn'),(337,'2024-11-08',100.00,100.00,'CC02','2024-11-11','5jz5ckj2f0bac4rlvlenxe3r6'),(338,'2024-11-09',115.00,115.00,'BA01','2024-11-11',NULL),(339,'2024-11-10',90.00,90.00,'CC02','2024-11-11','w0fh9dxs6ftlnn4o3w1qi8xcw'),(340,'2024-11-10',120.00,120.00,'DB01','2024-11-12','mmb9v9fyaf89jyl05d1c90ybx'),(341,'2024-11-10',115.00,115.00,'DB01','2024-11-12','2yh8lojpx70kk9nnk8byebrvy'),(342,'2024-11-10',110.00,110.00,'DB02','2024-11-13','67tt32wpvliy2hjcyd3po5ddp'),(343,'2024-11-11',48.00,48.00,'CA01','2024-11-16',NULL),(344,'2024-11-11',94.50,94.50,'DB01','2024-11-15','5ntsjejbxgj8465l52nmz7fsz'),(345,'2024-11-11',110.00,110.00,'CA01','2024-11-12',NULL),(346,'2024-11-11',162.00,162.00,'CC02','2024-11-14','7kc0ekx5faberrb6rxrt2smrx'),(347,'2024-11-11',150.00,150.00,'CA01','2024-11-16',NULL),(348,'2024-11-11',115.00,115.00,'CA01','2024-11-13',NULL),(349,'2024-11-11',99.00,0.00,NULL,NULL,NULL),(350,'2024-11-11',100.00,100.00,'CC01','2024-11-14','ffbc0eypcwr45up2lkvo8vdnr'),(351,'2024-11-11',75.00,75.00,'CC02','2024-11-12','or4moban1xzzklfgs1hvjlc1s'),(352,'2024-11-12',140.00,140.00,'BA01','2024-11-14',NULL),(353,'2024-11-12',120.00,120.00,'DB01','2024-11-13','nze1a8cn9l4qh6fnna3pe09l7'),(354,'2024-11-12',110.00,110.00,'CC02','2024-11-15','asdcoatmsximw3gcvcigoy227'),(355,'2024-11-12',120.00,120.00,'DB01','2024-11-14','p3x46oaj988v5i4lshucxv72t'),(356,'2024-11-12',108.00,0.00,NULL,NULL,NULL),(357,'2024-11-13',95.00,0.00,NULL,NULL,NULL),(358,'2024-11-13',115.00,115.00,'BA01','2024-11-14',NULL),(359,'2024-11-14',96.00,96.00,'CC01','2024-11-19','23sn62z7eot24kf0dzqq74dhp'),(360,'2024-11-14',180.00,180.00,'CC01','2024-11-18','7mex5espqvlf2zw8uinuzwv1d'),(361,'2024-11-14',76.50,76.50,'DB02','2024-11-17','qvtysj2k1a9l0keh90o12g52u'),(362,'2024-11-14',120.00,120.00,'CC02','2024-11-19','3x2b1nazrhzvro02wkh12u9g8'),(363,'2024-11-14',90.00,90.00,'CA01','2024-11-17',NULL),(364,'2024-11-14',65.00,65.00,'DB02','2024-11-17','mjy8ulq48zqzjlvcd6kz0d28b'),(365,'2024-11-15',126.00,126.00,'CC01','2024-11-18','gvl414xn2ym9l4rvjn61f0wql'),(366,'2024-11-16',80.00,80.00,'CC01','2024-11-20','y8yqsrpfnka1yd5gfed7uqtf2'),(367,'2024-11-16',115.00,0.00,NULL,NULL,NULL),(368,'2024-11-16',110.00,0.00,NULL,NULL,NULL),(369,'2024-11-16',90.00,90.00,'DB02','2024-11-17','82twq02h4o8wa4bnvi40gbw7j'),(370,'2024-11-16',115.00,115.00,'CC01','2024-11-19','lsb0fbionca8jiiw3yx8nn4ui'),(371,'2024-11-16',103.50,103.50,'CC02','2024-11-17','1qcs6zzemlzpk2r1d9lj7h1q6'),(372,'2024-11-16',75.00,0.00,NULL,NULL,NULL),(373,'2024-11-16',120.00,120.00,'DB01','2024-11-20','4pcsoo9gdkittya8xct8me5xh'),(374,'2024-11-17',150.00,150.00,'DB02','2024-11-20','2qzfmvuq1f8awm79r1xjv38iz'),(375,'2024-11-17',99.00,0.00,NULL,NULL,NULL),(376,'2024-11-17',100.00,100.00,'CC01','2024-11-18','9csetq54d64u5nwk6w058tw7q'),(377,'2024-11-17',115.00,115.00,'BA01','2024-11-19',NULL),(378,'2024-11-18',95.00,95.00,'CC02','2024-11-20','jsspc4sxmcw22nejkkpb7ilg9'),(379,'2024-11-18',85.00,0.00,NULL,NULL,NULL),(380,'2024-11-18',162.00,0.00,NULL,NULL,NULL),(381,'2024-11-18',140.00,140.00,'CC02','2024-11-20','r54zrd74f8dkh9ag4ujfat4oa'),(382,'2024-11-18',110.00,110.00,'BA01','2024-11-19',NULL),(383,'2024-11-19',108.00,108.00,'CC01','2024-11-20','4h1e67yxfnpkc37dh8lv5tak7'),(384,'2024-11-20',72.00,0.00,NULL,NULL,NULL),(385,'2024-11-20',105.00,0.00,NULL,NULL,NULL),(386,'2024-11-20',140.00,0.00,NULL,NULL,NULL),(387,'2024-11-20',108.00,0.00,NULL,NULL,NULL),(388,'2024-11-20',110.00,0.00,NULL,NULL,NULL),(389,'2024-11-20',115.00,0.00,NULL,NULL,NULL);
/*!40000 ALTER TABLE `invoice` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `marketing`
--

DROP TABLE IF EXISTS `marketing`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `marketing` (
  `guest_id` int NOT NULL,
  `marketing_code` char(3) NOT NULL,
  `contact_by_phone` tinyint NOT NULL COMMENT '0 or 1 to represent no/yes',
  `contact_by_email` tinyint NOT NULL COMMENT '0 or 1 to represent no/yes',
  `contact_by_post` tinyint NOT NULL COMMENT '0 or 1 to represent no/yes',
  PRIMARY KEY (`guest_id`),
  KEY `IDX_marketing_code` (`marketing_code`),
  CONSTRAINT `marketing_ibfk_1` FOREIGN KEY (`guest_id`) REFERENCES `guest` (`guest_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `marketing`
--

LOCK TABLES `marketing` WRITE;
/*!40000 ALTER TABLE `marketing` DISABLE KEYS */;
INSERT INTO `marketing` VALUES (1,'DIS',0,1,1),(3,'EVT',1,0,0),(5,'ALL',0,1,0),(8,'DIS',0,1,0),(10,'ALL',1,1,1),(12,'DIS',0,1,0),(13,'ALL',1,1,0),(16,'EVT',0,1,1),(18,'DIS',1,0,1),(19,'ALL',1,1,0),(20,'ALL',0,1,1),(21,'DIS',0,0,1),(23,'EVT',1,1,0),(24,'ALL',0,0,1),(25,'DIS',0,1,0),(27,'ALL',1,1,0),(28,'EVT',0,1,0),(30,'ALL',0,1,1);
/*!40000 ALTER TABLE `marketing` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `payment_method`
--

DROP TABLE IF EXISTS `payment_method`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payment_method` (
  `payment_code` char(4) NOT NULL,
  `payment_method` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`payment_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payment_method`
--

LOCK TABLES `payment_method` WRITE;
/*!40000 ALTER TABLE `payment_method` DISABLE KEYS */;
INSERT INTO `payment_method` VALUES ('BA01','Bank Transfer'),('CA01','Cash'),('CC01','Visa Credit'),('CC02','Mastercard Credit'),('DB01','Visa Debit'),('DB02','Mastercard Debit');
/*!40000 ALTER TABLE `payment_method` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `promotion`
--

DROP TABLE IF EXISTS `promotion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `promotion` (
  `promotion_code` char(10) NOT NULL,
  `promotion_name` varchar(50) NOT NULL,
  `discount_percentage` decimal(5,2) NOT NULL,
  PRIMARY KEY (`promotion_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `promotion`
--

LOCK TABLES `promotion` WRITE;
/*!40000 ALTER TABLE `promotion` DISABLE KEYS */;
INSERT INTO `promotion` VALUES ('AUG10','August 10% discount',10.00),('AUG15','August 15% discount',15.00),('COM10','Company 10% discount',10.00),('COM20','Company 20% discount',20.00),('DEC10','December 10% discount',10.00),('NOV10','November 10% discount',10.00),('OCT10','October 10% discount',10.00),('OCT15','October 15% discount',15.00),('SEP10','September 10% discount',10.00),('SEP15','September 15% discount',15.00);
/*!40000 ALTER TABLE `promotion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reservation`
--

DROP TABLE IF EXISTS `reservation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reservation` (
  `reservation_id` int NOT NULL AUTO_INCREMENT,
  `guest_id` int NOT NULL,
  `room_number` smallint NOT NULL,
  `invoice_number` mediumint DEFAULT NULL,
  `promotion_code` char(10) DEFAULT NULL,
  `reservation_staff_id` smallint NOT NULL,
  `reservation_date_time` datetime NOT NULL,
  `number_of_guests` tinyint NOT NULL,
  `start_of_stay` date NOT NULL,
  `length_of_stay` smallint NOT NULL,
  `status_code` char(2) NOT NULL DEFAULT 'RE' COMMENT 'RE - reserved, IN - checked in, OT - checked out',
  PRIMARY KEY (`reservation_id`),
  KEY `invoice_number` (`invoice_number`),
  KEY `IDX_reservation_guest` (`guest_id`),
  KEY `IDX_reservation_room_number` (`room_number`),
  KEY `IDX_reservation_promotion` (`promotion_code`),
  KEY `IDX_reservation_staff` (`reservation_staff_id`),
  KEY `IDX_reservation_status_code` (`status_code`),
  CONSTRAINT `reservation_ibfk_1` FOREIGN KEY (`invoice_number`) REFERENCES `invoice` (`invoice_number`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `reservation_ibfk_2` FOREIGN KEY (`promotion_code`) REFERENCES `promotion` (`promotion_code`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `reservation_ibfk_3` FOREIGN KEY (`guest_id`) REFERENCES `guest` (`guest_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `reservation_chk_1` CHECK ((`status_code` in (_utf8mb4'RE',_utf8mb4'IN',_utf8mb4'OT')))
) ENGINE=InnoDB AUTO_INCREMENT=464 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reservation`
--

LOCK TABLES `reservation` WRITE;
/*!40000 ALTER TABLE `reservation` DISABLE KEYS */;
INSERT INTO `reservation` VALUES (1,1,110,1,'OCT10',4,'2024-10-12 09:30:00',3,'2024-10-21',2,'OT'),(2,3,103,2,NULL,5,'2024-10-13 12:15:00',1,'2024-10-24',7,'OT'),(3,1,204,3,'OCT15',3,'2024-10-16 14:10:00',2,'2024-10-25',4,'OT'),(4,7,101,NULL,'COM20',3,'2024-10-17 19:25:00',1,'2024-10-26',1,'OT'),(5,4,101,343,'COM20',2,'2024-10-20 10:00:00',1,'2024-11-11',5,'OT'),(6,23,103,8,NULL,5,'2024-08-10 17:47:00',1,'2024-08-16',3,'OT'),(7,14,208,4,NULL,3,'2024-08-10 18:12:00',4,'2024-08-13',5,'OT'),(8,12,111,27,NULL,4,'2024-08-10 18:32:00',1,'2024-08-24',6,'OT'),(9,23,208,25,NULL,5,'2024-08-10 08:41:00',4,'2024-08-23',5,'OT'),(10,27,207,20,NULL,3,'2024-08-10 20:33:00',3,'2024-08-21',5,'OT'),(11,17,212,14,NULL,4,'2024-08-11 22:27:00',4,'2024-08-19',2,'OT'),(12,10,211,24,NULL,2,'2024-08-11 19:32:00',4,'2024-08-23',1,'OT'),(13,30,204,26,NULL,5,'2024-08-11 20:43:00',2,'2024-08-23',1,'OT'),(14,5,103,17,NULL,5,'2024-08-11 14:36:00',1,'2024-08-20',2,'OT'),(15,14,201,15,'COM10',5,'2024-08-11 14:13:00',2,'2024-08-20',3,'OT'),(16,9,103,5,NULL,3,'2024-08-11 13:11:00',1,'2024-08-14',2,'OT'),(17,17,213,6,'AUG10',2,'2024-08-11 10:22:00',1,'2024-08-15',3,'OT'),(18,16,212,7,NULL,5,'2024-08-11 13:30:00',4,'2024-08-15',1,'OT'),(19,28,111,10,'AUG10',4,'2024-08-11 18:02:00',2,'2024-08-17',2,'OT'),(20,18,211,36,NULL,4,'2024-08-12 08:13:00',2,'2024-08-26',1,'OT'),(21,21,205,43,NULL,3,'2024-08-12 15:35:00',1,'2024-08-28',1,'OT'),(22,24,212,30,NULL,3,'2024-08-12 17:09:00',3,'2024-08-25',3,'OT'),(23,21,201,12,'COM20',3,'2024-08-12 18:12:00',2,'2024-08-19',1,'OT'),(24,7,107,22,NULL,5,'2024-08-12 17:27:00',1,'2024-08-22',3,'OT'),(25,25,212,9,NULL,2,'2024-08-13 14:04:00',4,'2024-08-16',2,'OT'),(26,17,208,63,'SEP10',2,'2024-08-14 17:09:00',1,'2024-09-03',3,'OT'),(27,19,206,50,NULL,4,'2024-08-14 17:02:00',1,'2024-08-31',2,'OT'),(28,14,209,32,NULL,4,'2024-08-14 07:22:00',4,'2024-08-25',2,'OT'),(29,16,204,18,NULL,3,'2024-08-14 07:00:00',2,'2024-08-20',1,'OT'),(30,27,203,61,NULL,3,'2024-08-15 08:03:00',2,'2024-09-03',3,'OT'),(31,11,209,53,NULL,2,'2024-08-15 07:28:00',1,'2024-09-01',1,'OT'),(32,18,102,13,NULL,4,'2024-08-15 09:00:00',1,'2024-08-19',2,'OT'),(33,18,111,19,'AUG15',3,'2024-08-15 13:40:00',2,'2024-08-21',3,'OT'),(34,11,108,11,NULL,5,'2024-08-15 20:41:00',2,'2024-08-17',4,'OT'),(35,21,108,59,'COM10',3,'2024-08-16 18:11:00',1,'2024-09-02',1,'OT'),(36,9,204,38,'AUG10',2,'2024-08-16 17:07:00',1,'2024-08-26',6,'OT'),(37,5,107,35,NULL,3,'2024-08-16 18:40:00',2,'2024-08-26',6,'OT'),(38,20,112,41,'COM20',5,'2024-08-16 21:21:00',1,'2024-08-27',4,'OT'),(39,12,212,49,NULL,3,'2024-08-16 08:57:00',1,'2024-08-31',3,'OT'),(40,7,110,28,NULL,3,'2024-08-17 08:17:00',1,'2024-08-25',5,'OT'),(41,4,213,16,'COM10',4,'2024-08-17 16:28:00',2,'2024-08-20',2,'OT'),(42,7,204,54,NULL,2,'2024-08-17 07:46:00',2,'2024-09-01',4,'OT'),(43,8,210,58,NULL,2,'2024-08-17 12:15:00',4,'2024-09-02',6,'OT'),(44,22,210,52,'SEP10',5,'2024-08-17 09:55:00',2,'2024-09-01',1,'OT'),(45,10,102,33,'AUG15',2,'2024-08-17 18:04:00',1,'2024-08-25',4,'OT'),(46,6,213,48,NULL,2,'2024-08-17 18:09:00',4,'2024-08-31',3,'OT'),(47,20,212,75,NULL,5,'2024-08-17 13:55:00',4,'2024-09-06',7,'OT'),(48,6,210,39,'AUG15',5,'2024-08-17 18:22:00',2,'2024-08-27',3,'OT'),(49,2,205,60,'SEP10',2,'2024-08-18 22:01:00',1,'2024-09-02',4,'OT'),(50,6,206,64,NULL,2,'2024-08-18 10:33:00',4,'2024-09-03',3,'OT'),(51,16,211,57,NULL,2,'2024-08-18 21:40:00',3,'2024-09-02',3,'OT'),(52,17,213,37,NULL,5,'2024-08-18 19:40:00',3,'2024-08-26',4,'OT'),(53,4,112,29,NULL,5,'2024-08-19 14:02:00',1,'2024-08-25',1,'OT'),(54,19,111,69,'SEP15',5,'2024-08-19 07:21:00',2,'2024-09-04',5,'OT'),(55,14,105,47,NULL,3,'2024-08-19 22:52:00',1,'2024-08-30',3,'OT'),(56,19,111,46,NULL,2,'2024-08-19 21:34:00',1,'2024-08-30',1,'OT'),(57,19,206,21,'AUG10',3,'2024-08-19 21:23:00',4,'2024-08-22',3,'OT'),(58,5,107,70,NULL,2,'2024-08-19 08:19:00',2,'2024-09-05',1,'OT'),(59,28,108,31,'AUG15',3,'2024-08-19 20:59:00',2,'2024-08-25',3,'OT'),(60,22,211,71,NULL,4,'2024-08-19 16:20:00',3,'2024-09-05',1,'OT'),(61,16,201,34,NULL,5,'2024-08-19 18:35:00',2,'2024-08-26',5,'OT'),(62,27,207,42,'COM10',5,'2024-08-20 16:25:00',3,'2024-08-28',1,'OT'),(63,4,213,23,NULL,4,'2024-08-20 10:18:00',1,'2024-08-23',2,'OT'),(64,4,110,78,NULL,2,'2024-08-21 15:32:00',1,'2024-09-07',5,'OT'),(65,11,112,72,NULL,5,'2024-08-22 22:59:00',2,'2024-09-05',3,'OT'),(66,23,201,55,'SEP10',2,'2024-08-22 22:33:00',2,'2024-09-02',5,'OT'),(67,17,211,98,NULL,2,'2024-08-23 21:52:00',3,'2024-09-11',2,'OT'),(68,16,107,97,NULL,2,'2024-08-23 20:27:00',2,'2024-09-11',3,'OT'),(69,10,206,44,NULL,5,'2024-08-23 14:38:00',3,'2024-08-29',2,'OT'),(70,14,112,56,'COM10',4,'2024-08-25 15:52:00',1,'2024-09-02',3,'OT'),(71,3,110,103,NULL,4,'2024-08-25 16:30:00',2,'2024-09-12',7,'OT'),(72,29,209,40,'AUG10',2,'2024-08-25 20:31:00',3,'2024-08-27',3,'OT'),(73,16,211,80,'SEP15',4,'2024-08-26 16:29:00',4,'2024-09-07',2,'OT'),(74,5,110,51,'SEP10',5,'2024-08-26 18:42:00',2,'2024-09-01',3,'OT'),(75,16,213,89,NULL,5,'2024-08-26 10:29:00',3,'2024-09-09',1,'OT'),(76,20,110,65,NULL,3,'2024-08-26 07:04:00',1,'2024-09-04',2,'OT'),(77,24,207,45,NULL,3,'2024-08-27 17:05:00',2,'2024-08-29',6,'OT'),(78,5,207,76,NULL,4,'2024-08-27 19:57:00',4,'2024-09-06',3,'OT'),(79,1,106,107,NULL,5,'2024-08-27 07:49:00',1,'2024-09-13',4,'OT'),(80,7,106,84,NULL,4,'2024-08-27 08:52:00',1,'2024-09-08',2,'OT'),(81,27,208,105,NULL,4,'2024-08-28 11:05:00',3,'2024-09-12',2,'OT'),(82,10,108,66,NULL,5,'2024-08-29 20:28:00',2,'2024-09-04',2,'OT'),(83,30,213,124,'SEP15',2,'2024-08-29 11:07:00',2,'2024-09-17',1,'OT'),(84,18,107,118,'SEP10',5,'2024-08-29 10:57:00',2,'2024-09-16',2,'OT'),(85,13,213,109,'SEP15',3,'2024-08-29 10:25:00',3,'2024-09-14',3,'OT'),(86,28,108,77,NULL,4,'2024-08-29 22:57:00',1,'2024-09-06',3,'OT'),(87,22,210,125,NULL,5,'2024-08-29 16:31:00',3,'2024-09-17',5,'OT'),(88,30,203,73,NULL,5,'2024-08-30 12:48:00',1,'2024-09-06',3,'OT'),(89,26,213,74,NULL,5,'2024-08-30 16:45:00',4,'2024-09-06',3,'OT'),(90,21,209,62,'COM20',5,'2024-08-30 14:56:00',3,'2024-09-03',7,'OT'),(91,12,202,68,NULL,4,'2024-08-31 16:01:00',2,'2024-09-04',6,'OT'),(92,25,209,111,NULL,4,'2024-08-31 21:06:00',3,'2024-09-14',3,'OT'),(93,4,103,67,NULL,2,'2024-08-31 20:52:00',1,'2024-09-04',3,'OT'),(94,25,111,91,NULL,2,'2024-08-31 21:50:00',2,'2024-09-09',1,'OT'),(95,15,208,81,NULL,4,'2024-09-01 14:48:00',3,'2024-09-07',1,'OT'),(96,6,202,133,NULL,5,'2024-09-01 16:38:00',2,'2024-09-21',5,'OT'),(97,20,111,123,NULL,5,'2024-09-01 19:24:00',2,'2024-09-16',3,'OT'),(98,21,205,108,'COM10',3,'2024-09-02 13:03:00',1,'2024-09-13',5,'OT'),(99,23,112,122,NULL,4,'2024-09-02 17:15:00',2,'2024-09-16',5,'OT'),(100,28,108,116,'SEP10',4,'2024-09-02 21:02:00',2,'2024-09-15',3,'OT'),(101,27,206,82,'COM10',2,'2024-09-02 13:44:00',2,'2024-09-07',3,'OT'),(102,19,213,131,'SEP10',5,'2024-09-02 18:54:00',1,'2024-09-20',3,'OT'),(103,9,211,119,NULL,3,'2024-09-02 15:09:00',1,'2024-09-16',2,'OT'),(104,18,107,79,'SEP10',2,'2024-09-02 10:38:00',2,'2024-09-07',2,'OT'),(105,29,101,90,NULL,2,'2024-09-02 18:13:00',1,'2024-09-09',5,'OT'),(106,8,112,86,NULL,3,'2024-09-02 13:43:00',2,'2024-09-08',4,'OT'),(107,4,204,117,NULL,3,'2024-09-03 11:03:00',2,'2024-09-15',3,'OT'),(108,28,201,102,NULL,3,'2024-09-04 09:17:00',1,'2024-09-11',2,'OT'),(109,30,206,113,NULL,5,'2024-09-04 21:18:00',2,'2024-09-14',2,'OT'),(110,22,202,106,NULL,2,'2024-09-04 22:44:00',1,'2024-09-12',3,'OT'),(111,18,108,87,NULL,4,'2024-09-04 13:28:00',1,'2024-09-09',4,'OT'),(112,11,105,104,NULL,4,'2024-09-04 21:36:00',2,'2024-09-12',7,'OT'),(113,7,207,94,NULL,2,'2024-09-04 20:22:00',4,'2024-09-10',5,'OT'),(114,18,208,112,NULL,3,'2024-09-04 17:34:00',4,'2024-09-14',2,'OT'),(115,7,201,121,'COM10',4,'2024-09-05 19:56:00',1,'2024-09-16',2,'OT'),(116,2,211,139,'SEP15',5,'2024-09-05 17:25:00',3,'2024-09-22',1,'OT'),(117,2,210,95,'SEP10',2,'2024-09-05 10:38:00',2,'2024-09-10',1,'OT'),(118,27,209,93,NULL,4,'2024-09-05 17:25:00',2,'2024-09-10',2,'OT'),(119,10,206,100,NULL,3,'2024-09-05 15:16:00',4,'2024-09-11',3,'OT'),(120,13,201,83,NULL,2,'2024-09-05 16:41:00',1,'2024-09-07',3,'OT'),(121,29,211,141,NULL,5,'2024-09-06 14:02:00',4,'2024-09-23',4,'OT'),(122,23,111,153,NULL,5,'2024-09-06 18:22:00',2,'2024-09-26',1,'OT'),(123,23,204,85,'SEP10',3,'2024-09-06 17:13:00',2,'2024-09-08',5,'OT'),(124,17,201,138,NULL,2,'2024-09-07 22:06:00',2,'2024-09-22',4,'OT'),(125,26,210,99,NULL,3,'2024-09-07 16:34:00',4,'2024-09-11',4,'OT'),(126,14,103,88,NULL,4,'2024-09-07 18:16:00',1,'2024-09-09',5,'OT'),(127,10,201,114,NULL,4,'2024-09-07 07:06:00',2,'2024-09-14',2,'OT'),(128,19,213,92,'SEP15',4,'2024-09-07 22:35:00',4,'2024-09-10',3,'OT'),(129,13,203,101,NULL,2,'2024-09-07 13:54:00',1,'2024-09-11',3,'OT'),(130,30,204,144,NULL,5,'2024-09-08 09:38:00',2,'2024-09-23',1,'OT'),(131,25,212,127,NULL,4,'2024-09-08 15:18:00',2,'2024-09-18',6,'OT'),(132,26,208,126,NULL,4,'2024-09-08 22:17:00',2,'2024-09-17',3,'OT'),(133,9,102,96,NULL,2,'2024-09-09 22:24:00',1,'2024-09-11',3,'OT'),(134,11,210,146,'COM10',3,'2024-09-09 20:00:00',1,'2024-09-24',3,'OT'),(135,21,207,143,'COM10',5,'2024-09-10 14:50:00',4,'2024-09-23',4,'OT'),(136,17,103,115,NULL,2,'2024-09-10 09:33:00',1,'2024-09-15',2,'OT'),(137,1,206,173,NULL,2,'2024-09-10 07:04:00',2,'2024-09-30',3,'OT'),(138,3,112,134,NULL,4,'2024-09-10 09:49:00',2,'2024-09-21',3,'OT'),(139,29,209,128,NULL,3,'2024-09-10 19:09:00',4,'2024-09-18',5,'OT'),(140,5,207,156,'SEP10',5,'2024-09-10 09:31:00',3,'2024-09-27',5,'OT'),(141,19,210,171,'SEP10',2,'2024-09-10 20:38:00',3,'2024-09-30',6,'OT'),(142,4,212,110,NULL,5,'2024-09-10 10:55:00',2,'2024-09-14',1,'OT'),(143,15,205,130,NULL,2,'2024-09-11 18:18:00',1,'2024-09-19',4,'OT'),(144,25,205,162,NULL,5,'2024-09-11 09:57:00',1,'2024-09-28',1,'OT'),(145,4,205,148,'COM20',4,'2024-09-11 21:35:00',2,'2024-09-24',3,'OT'),(146,14,105,132,'COM20',2,'2024-09-11 13:33:00',1,'2024-09-20',4,'OT'),(147,30,203,120,'SEP10',5,'2024-09-11 09:37:00',2,'2024-09-16',1,'OT'),(148,30,211,129,NULL,5,'2024-09-11 17:47:00',4,'2024-09-19',1,'OT'),(149,13,211,166,NULL,4,'2024-09-11 18:20:00',3,'2024-09-29',3,'OT'),(150,21,208,135,'COM10',5,'2024-09-12 07:35:00',2,'2024-09-21',2,'OT'),(151,16,212,150,NULL,4,'2024-09-12 16:44:00',1,'2024-09-25',5,'OT'),(152,22,213,149,NULL,5,'2024-09-13 22:39:00',2,'2024-09-25',5,'OT'),(153,2,206,152,'SEP15',4,'2024-09-13 17:11:00',1,'2024-09-26',1,'OT'),(154,29,205,175,NULL,5,'2024-09-13 14:30:00',1,'2024-10-01',2,'OT'),(155,8,112,168,NULL,5,'2024-09-15 21:41:00',2,'2024-09-29',3,'OT'),(156,25,205,191,NULL,3,'2024-09-16 14:41:00',2,'2024-10-06',5,'OT'),(157,9,110,154,NULL,2,'2024-09-16 09:32:00',2,'2024-09-27',3,'OT'),(158,5,206,136,NULL,3,'2024-09-16 21:45:00',1,'2024-09-21',1,'OT'),(159,3,213,182,NULL,3,'2024-09-16 10:51:00',1,'2024-10-04',3,'OT'),(160,23,208,172,NULL,2,'2024-09-16 13:03:00',2,'2024-09-30',3,'OT'),(161,26,206,157,'COM10',3,'2024-09-16 20:04:00',3,'2024-09-27',3,'OT'),(162,21,213,169,'COM10',3,'2024-09-17 21:07:00',2,'2024-09-30',3,'OT'),(163,27,209,160,NULL,2,'2024-09-17 13:13:00',1,'2024-09-28',5,'OT'),(164,7,210,155,NULL,4,'2024-09-17 19:33:00',4,'2024-09-27',2,'OT'),(165,14,112,193,NULL,3,'2024-09-17 16:02:00',1,'2024-10-06',2,'OT'),(166,24,107,159,NULL,5,'2024-09-17 08:13:00',2,'2024-09-28',3,'OT'),(167,22,207,177,NULL,2,'2024-09-17 11:27:00',4,'2024-10-02',4,'OT'),(168,14,208,161,NULL,4,'2024-09-17 09:26:00',3,'2024-09-28',2,'OT'),(169,11,105,165,'COM10',5,'2024-09-18 18:20:00',1,'2024-09-29',4,'OT'),(170,5,107,142,NULL,3,'2024-09-18 07:43:00',1,'2024-09-23',2,'OT'),(171,24,204,176,NULL,5,'2024-09-18 11:23:00',2,'2024-10-01',4,'OT'),(172,13,108,195,'OCT10',5,'2024-09-18 19:59:00',1,'2024-10-07',3,'OT'),(173,24,209,145,'SEP15',2,'2024-09-19 21:46:00',3,'2024-09-24',2,'OT'),(174,15,108,164,NULL,3,'2024-09-19 17:52:00',2,'2024-09-29',4,'OT'),(175,28,108,140,'SEP10',3,'2024-09-19 07:00:00',1,'2024-09-22',1,'OT'),(176,12,204,163,NULL,5,'2024-09-19 10:24:00',1,'2024-09-28',3,'OT'),(177,30,111,158,NULL,3,'2024-09-19 09:24:00',2,'2024-09-28',2,'OT'),(178,1,111,185,NULL,4,'2024-09-20 17:06:00',2,'2024-10-04',3,'OT'),(179,12,208,151,NULL,5,'2024-09-20 21:35:00',4,'2024-09-25',3,'OT'),(180,7,205,181,NULL,2,'2024-09-20 18:42:00',1,'2024-10-03',3,'OT'),(181,19,108,147,NULL,5,'2024-09-20 09:32:00',1,'2024-09-24',4,'OT'),(182,20,110,199,NULL,4,'2024-09-20 10:49:00',2,'2024-10-09',2,'OT'),(183,23,101,137,'SEP10',4,'2024-09-20 21:23:00',1,'2024-09-22',3,'OT'),(184,6,209,197,NULL,3,'2024-09-22 17:45:00',2,'2024-10-08',4,'OT'),(185,11,213,204,NULL,5,'2024-09-22 22:47:00',3,'2024-10-11',3,'OT'),(186,7,212,170,'COM20',4,'2024-09-22 19:56:00',1,'2024-09-30',3,'OT'),(187,3,201,167,NULL,4,'2024-09-22 14:33:00',2,'2024-09-29',5,'OT'),(188,26,107,184,'COM10',2,'2024-09-22 07:52:00',2,'2024-10-04',5,'OT'),(189,29,210,207,'OCT10',2,'2024-09-22 07:10:00',1,'2024-10-11',5,'OT'),(190,7,208,208,NULL,4,'2024-09-23 08:52:00',1,'2024-10-11',3,'OT'),(191,10,101,174,NULL,4,'2024-09-24 07:20:00',1,'2024-09-30',3,'OT'),(192,30,211,194,'OCT15',5,'2024-09-26 20:24:00',1,'2024-10-07',1,'OT'),(193,17,211,223,NULL,4,'2024-09-27 18:40:00',1,'2024-10-15',1,'OT'),(194,10,209,215,NULL,3,'2024-09-27 22:15:00',2,'2024-10-13',1,'OT'),(195,12,201,212,NULL,4,'2024-09-27 16:57:00',2,'2024-10-12',2,'OT'),(196,27,206,210,NULL,5,'2024-09-28 21:27:00',4,'2024-10-11',5,'OT'),(197,28,207,209,NULL,4,'2024-09-28 19:08:00',3,'2024-10-11',1,'OT'),(198,4,206,196,'COM20',3,'2024-09-28 20:47:00',3,'2024-10-07',3,'OT'),(199,8,103,189,'OCT15',3,'2024-09-28 10:42:00',1,'2024-10-06',1,'OT'),(200,8,212,205,NULL,5,'2024-09-28 21:06:00',3,'2024-10-11',1,'OT'),(201,27,108,188,NULL,5,'2024-09-29 19:20:00',1,'2024-10-05',2,'OT'),(202,18,203,192,'OCT10',3,'2024-09-29 13:00:00',2,'2024-10-06',5,'OT'),(203,14,103,217,'COM20',5,'2024-09-29 13:13:00',1,'2024-10-13',3,'OT'),(204,25,211,206,NULL,3,'2024-09-29 22:44:00',3,'2024-10-11',3,'OT'),(205,28,209,230,NULL,4,'2024-09-29 07:57:00',1,'2024-10-16',4,'OT'),(206,11,208,224,NULL,3,'2024-09-29 18:20:00',3,'2024-10-15',1,'OT'),(207,12,204,231,NULL,3,'2024-09-29 10:41:00',2,'2024-10-16',3,'OT'),(208,6,112,178,NULL,5,'2024-09-29 21:46:00',1,'2024-10-02',4,'OT'),(209,11,207,241,'COM20',5,'2024-09-29 15:43:00',1,'2024-10-18',1,'OT'),(210,27,211,249,'COM10',2,'2024-09-30 11:41:00',3,'2024-10-20',5,'OT'),(211,15,112,201,'COM10',5,'2024-09-30 09:35:00',2,'2024-10-10',2,'OT'),(212,30,101,211,NULL,4,'2024-09-30 22:29:00',1,'2024-10-11',2,'OT'),(213,15,211,180,NULL,3,'2024-09-30 18:54:00',3,'2024-10-03',1,'OT'),(214,23,110,179,NULL,3,'2024-09-30 22:29:00',2,'2024-10-03',6,'OT'),(215,28,210,250,NULL,4,'2024-09-30 08:57:00',2,'2024-10-20',1,'OT'),(216,19,106,203,'OCT10',2,'2024-10-01 20:26:00',1,'2024-10-11',1,'OT'),(217,13,204,202,'OCT15',3,'2024-10-01 10:01:00',2,'2024-10-10',3,'OT'),(218,17,212,187,'OCT15',4,'2024-10-01 16:57:00',2,'2024-10-05',3,'OT'),(219,9,201,198,NULL,5,'2024-10-01 17:06:00',1,'2024-10-09',3,'OT'),(220,27,112,242,NULL,2,'2024-10-02 10:51:00',2,'2024-10-18',2,'OT'),(221,10,206,186,NULL,4,'2024-10-02 09:34:00',2,'2024-10-05',2,'OT'),(222,21,211,183,'COM10',5,'2024-10-02 08:23:00',1,'2024-10-04',3,'OT'),(223,3,207,200,NULL,4,'2024-10-02 21:19:00',4,'2024-10-09',2,'OT'),(224,3,111,253,'COM10',3,'2024-10-02 21:28:00',1,'2024-10-20',3,'OT'),(225,30,108,246,NULL,5,'2024-10-02 18:54:00',1,'2024-10-20',3,'OT'),(226,16,210,258,NULL,4,'2024-10-02 09:27:00',1,'2024-10-22',2,'OT'),(227,2,212,222,NULL,3,'2024-10-02 13:39:00',3,'2024-10-15',4,'OT'),(228,9,211,239,NULL,5,'2024-10-03 09:03:00',1,'2024-10-18',2,'OT'),(229,23,111,218,'OCT10',4,'2024-10-04 16:06:00',1,'2024-10-14',3,'OT'),(230,9,209,190,NULL,5,'2024-10-04 14:04:00',4,'2024-10-06',1,'OT'),(231,4,204,251,NULL,2,'2024-10-04 22:29:00',1,'2024-10-20',2,'OT'),(232,19,212,214,NULL,2,'2024-10-06 20:27:00',3,'2024-10-13',1,'OT'),(233,29,205,270,NULL,5,'2024-10-06 22:06:00',1,'2024-10-24',2,'OT'),(234,3,208,235,'COM10',4,'2024-10-07 22:13:00',4,'2024-10-17',1,'OT'),(235,18,110,219,'OCT10',5,'2024-10-07 19:28:00',2,'2024-10-14',7,'OT'),(236,22,203,259,NULL,2,'2024-10-07 08:16:00',1,'2024-10-23',2,'OT'),(237,22,107,233,NULL,4,'2024-10-07 13:32:00',1,'2024-10-17',1,'OT'),(238,11,107,247,NULL,2,'2024-10-07 12:54:00',1,'2024-10-20',1,'OT'),(239,6,208,267,NULL,2,'2024-10-07 19:47:00',1,'2024-10-24',7,'OT'),(240,16,112,227,NULL,5,'2024-10-07 12:55:00',1,'2024-10-16',2,'OT'),(241,30,107,213,NULL,5,'2024-10-07 07:32:00',1,'2024-10-13',3,'OT'),(242,24,210,229,NULL,4,'2024-10-07 16:18:00',2,'2024-10-16',3,'OT'),(243,10,213,263,NULL,2,'2024-10-08 14:16:00',1,'2024-10-24',6,'OT'),(244,4,209,266,NULL,2,'2024-10-08 21:51:00',2,'2024-10-24',3,'OT'),(245,17,212,276,NULL,3,'2024-10-08 10:22:00',3,'2024-10-26',3,'OT'),(246,5,201,288,'OCT15',2,'2024-10-08 18:44:00',2,'2024-10-28',2,'OT'),(247,5,206,244,NULL,3,'2024-10-08 18:44:00',2,'2024-10-19',3,'OT'),(248,22,208,240,NULL,5,'2024-10-08 20:23:00',4,'2024-10-18',3,'OT'),(249,7,206,286,'COM20',2,'2024-10-08 09:08:00',2,'2024-10-28',3,'OT'),(250,21,213,221,'COM10',4,'2024-10-08 17:01:00',4,'2024-10-15',5,'OT'),(251,17,213,254,NULL,5,'2024-10-10 16:25:00',3,'2024-10-21',3,'OT'),(252,16,207,268,'OCT10',4,'2024-10-10 22:09:00',3,'2024-10-24',3,'OT'),(253,6,105,248,'OCT15',3,'2024-10-10 17:15:00',1,'2024-10-20',3,'OT'),(254,5,211,220,NULL,2,'2024-10-10 09:44:00',2,'2024-10-14',1,'OT'),(255,8,201,252,'OCT10',3,'2024-10-11 13:43:00',1,'2024-10-20',3,'OT'),(256,8,207,216,NULL,3,'2024-10-11 17:29:00',2,'2024-10-13',2,'OT'),(257,26,207,256,NULL,5,'2024-10-11 11:43:00',1,'2024-10-21',2,'OT'),(258,5,206,236,'OCT10',2,'2024-10-11 07:08:00',3,'2024-10-17',2,'OT'),(259,15,211,277,NULL,2,'2024-10-11 08:39:00',2,'2024-10-26',2,'OT'),(260,25,204,291,NULL,4,'2024-10-11 10:53:00',2,'2024-10-29',5,'OT'),(261,27,110,295,NULL,5,'2024-10-12 20:20:00',1,'2024-10-30',3,'OT'),(262,4,205,225,NULL,5,'2024-10-12 13:07:00',1,'2024-10-15',4,'OT'),(263,24,210,278,NULL,5,'2024-10-12 22:11:00',4,'2024-10-26',5,'OT'),(264,1,111,304,'NOV10',2,'2024-10-12 22:28:00',2,'2024-11-01',6,'OT'),(265,15,106,234,'COM10',5,'2024-10-12 08:29:00',2,'2024-10-17',5,'OT'),(266,5,211,297,NULL,2,'2024-10-12 18:01:00',3,'2024-10-30',3,'OT'),(267,26,102,280,NULL,5,'2024-10-12 14:43:00',1,'2024-10-27',1,'OT'),(268,21,207,285,NULL,5,'2024-10-13 20:57:00',3,'2024-10-28',3,'OT'),(269,14,108,262,NULL,3,'2024-10-13 11:12:00',1,'2024-10-24',3,'OT'),(270,25,205,245,NULL,5,'2024-10-13 11:44:00',2,'2024-10-19',5,'OT'),(271,10,105,226,'OCT10',2,'2024-10-13 21:58:00',1,'2024-10-15',2,'OT'),(272,12,112,279,NULL,4,'2024-10-13 09:33:00',1,'2024-10-26',5,'OT'),(273,29,202,298,NULL,3,'2024-10-13 15:26:00',2,'2024-10-30',6,'OT'),(274,8,203,237,'OCT10',4,'2024-10-14 10:54:00',2,'2024-10-17',2,'OT'),(275,1,211,228,NULL,5,'2024-10-14 15:04:00',4,'2024-10-16',2,'OT'),(276,21,108,300,'COM10',5,'2024-10-14 18:43:00',2,'2024-10-31',3,'OT'),(277,19,103,238,NULL,2,'2024-10-14 18:33:00',1,'2024-10-18',4,'OT'),(278,13,205,287,'OCT15',2,'2024-10-14 13:33:00',2,'2024-10-28',6,'OT'),(279,10,107,296,NULL,3,'2024-10-14 09:18:00',2,'2024-10-30',2,'OT'),(280,15,206,269,NULL,2,'2024-10-14 19:17:00',3,'2024-10-24',2,'OT'),(281,9,203,274,NULL,3,'2024-10-15 09:10:00',1,'2024-10-25',2,'OT'),(282,7,102,232,NULL,3,'2024-10-15 10:50:00',1,'2024-10-17',6,'OT'),(283,28,209,318,NULL,4,'2024-10-15 10:34:00',1,'2024-11-04',6,'OT'),(284,14,203,243,NULL,5,'2024-10-15 17:13:00',2,'2024-10-19',3,'OT'),(285,19,111,261,'OCT10',5,'2024-10-15 13:07:00',2,'2024-10-23',4,'OT'),(286,11,202,257,NULL,2,'2024-10-15 13:16:00',2,'2024-10-21',5,'OT'),(287,19,111,282,'OCT10',2,'2024-10-15 13:21:00',2,'2024-10-27',2,'OT'),(288,7,201,311,'COM10',5,'2024-10-17 13:25:00',2,'2024-11-03',1,'OT'),(289,2,213,301,NULL,3,'2024-10-17 14:21:00',4,'2024-10-31',5,'OT'),(290,11,207,309,NULL,3,'2024-10-17 20:28:00',2,'2024-11-02',1,'OT'),(291,12,210,265,NULL,2,'2024-10-17 12:18:00',2,'2024-10-24',2,'OT'),(292,16,101,321,'NOV10',3,'2024-10-17 15:49:00',1,'2024-11-05',2,'OT'),(293,21,201,271,NULL,5,'2024-10-17 09:51:00',1,'2024-10-24',1,'OT'),(294,18,208,255,'OCT15',3,'2024-10-17 09:11:00',3,'2024-10-21',2,'OT'),(295,25,205,319,'COM10',5,'2024-10-18 12:00:00',1,'2024-11-04',3,'OT'),(296,18,212,264,'OCT15',5,'2024-10-18 21:10:00',4,'2024-10-24',2,'OT'),(297,28,106,273,NULL,2,'2024-10-18 12:14:00',1,'2024-10-25',6,'OT'),(298,22,209,290,'OCT10',3,'2024-10-18 22:38:00',3,'2024-10-29',5,'OT'),(299,27,213,324,'COM20',5,'2024-10-18 12:35:00',4,'2024-11-06',1,'OT'),(300,11,111,294,NULL,5,'2024-10-18 22:54:00',1,'2024-10-29',2,'OT'),(301,5,106,306,NULL,3,'2024-10-18 15:21:00',1,'2024-11-02',1,'OT'),(302,30,102,315,'NOV10',3,'2024-10-18 10:18:00',1,'2024-11-04',3,'OT'),(303,20,201,327,NULL,2,'2024-10-18 21:55:00',1,'2024-11-07',3,'OT'),(304,15,212,316,'COM20',4,'2024-10-19 22:45:00',3,'2024-11-04',1,'OT'),(305,23,107,260,NULL,4,'2024-10-19 15:32:00',2,'2024-10-23',3,'OT'),(306,5,112,322,NULL,4,'2024-10-19 16:18:00',1,'2024-11-05',2,'OT'),(307,19,203,292,NULL,5,'2024-10-19 08:29:00',2,'2024-10-29',2,'OT'),(308,30,212,289,NULL,4,'2024-10-19 11:01:00',1,'2024-10-29',4,'OT'),(309,9,107,332,NULL,2,'2024-10-19 08:15:00',2,'2024-11-07',3,'OT'),(310,5,213,329,NULL,5,'2024-10-21 09:00:00',4,'2024-11-07',4,'OT'),(311,15,108,284,'COM20',3,'2024-10-21 17:52:00',2,'2024-10-28',3,'OT'),(312,15,205,333,NULL,4,'2024-10-21 08:19:00',1,'2024-11-07',3,'OT'),(313,16,105,281,'OCT10',5,'2024-10-21 15:00:00',2,'2024-10-27',2,'OT'),(314,30,206,350,NULL,3,'2024-10-22 11:57:00',1,'2024-11-11',3,'OT'),(315,20,210,317,NULL,2,'2024-10-22 14:47:00',3,'2024-11-04',1,'OT'),(316,2,210,340,NULL,3,'2024-10-22 20:53:00',4,'2024-11-10',2,'OT'),(317,21,110,330,NULL,2,'2024-10-22 17:06:00',1,'2024-11-07',3,'OT'),(318,20,207,342,NULL,4,'2024-10-22 15:38:00',4,'2024-11-10',3,'OT'),(319,5,110,272,NULL,4,'2024-10-22 09:39:00',1,'2024-10-25',3,'OT'),(320,4,204,320,NULL,2,'2024-10-22 20:41:00',1,'2024-11-04',5,'OT'),(321,8,211,331,'NOV10',2,'2024-10-24 18:03:00',2,'2024-11-07',1,'OT'),(322,29,110,283,NULL,3,'2024-10-24 11:38:00',1,'2024-10-28',1,'OT'),(323,12,201,355,NULL,2,'2024-10-24 19:50:00',2,'2024-11-12',2,'OT'),(324,2,107,275,NULL,2,'2024-10-24 17:03:00',1,'2024-10-26',2,'OT'),(325,10,208,354,NULL,5,'2024-10-24 08:24:00',2,'2024-11-12',3,'OT'),(326,30,210,308,NULL,4,'2024-10-24 09:14:00',3,'2024-11-02',1,'OT'),(327,28,206,310,NULL,3,'2024-10-25 15:03:00',2,'2024-11-02',2,'OT'),(328,1,103,351,NULL,5,'2024-10-25 21:38:00',1,'2024-11-11',1,'OT'),(329,9,112,356,'NOV10',5,'2024-10-25 10:14:00',2,'2024-11-12',2,'OT'),(330,18,101,293,NULL,5,'2024-10-25 19:20:00',1,'2024-10-29',1,'OT'),(331,7,108,314,NULL,2,'2024-10-25 16:59:00',1,'2024-11-04',4,'OT'),(332,10,110,305,'NOV10',3,'2024-10-26 07:32:00',1,'2024-11-02',3,'OT'),(333,23,110,325,NULL,3,'2024-10-26 09:10:00',1,'2024-11-06',1,'OT'),(334,10,208,336,NULL,4,'2024-10-27 11:39:00',1,'2024-11-08',2,'OT'),(335,27,209,341,NULL,2,'2024-10-27 20:46:00',3,'2024-11-10',2,'OT'),(336,18,201,299,NULL,3,'2024-10-27 14:18:00',2,'2024-10-30',3,'OT'),(337,15,208,303,'COM10',5,'2024-10-27 15:56:00',2,'2024-10-31',1,'OT'),(338,12,110,323,'NOV10',3,'2024-10-27 22:37:00',2,'2024-11-05',1,'OT'),(339,19,212,347,NULL,2,'2024-10-28 11:40:00',2,'2024-11-11',5,'OT'),(340,23,108,357,NULL,4,'2024-10-28 11:41:00',1,'2024-11-13',5,'OT'),(341,25,211,335,'COM10',3,'2024-10-28 19:50:00',4,'2024-11-08',3,'OT'),(342,6,209,367,NULL,2,'2024-10-28 20:08:00',1,'2024-11-16',5,'IN'),(343,18,105,366,NULL,3,'2024-10-28 19:00:00',1,'2024-11-16',4,'OT'),(344,14,210,362,NULL,2,'2024-10-28 07:12:00',1,'2024-11-14',5,'OT'),(345,8,210,302,'OCT10',4,'2024-10-28 09:40:00',1,'2024-10-31',2,'OT'),(346,23,211,307,'NOV10',3,'2024-10-29 16:43:00',4,'2024-11-02',3,'OT'),(347,22,204,338,NULL,5,'2024-10-29 17:51:00',2,'2024-11-09',2,'OT'),(348,12,213,380,'NOV10',4,'2024-10-29 17:46:00',4,'2024-11-18',7,'IN'),(349,4,206,376,NULL,3,'2024-10-29 10:25:00',3,'2024-11-17',1,'OT'),(350,24,212,328,NULL,3,'2024-10-29 10:26:00',4,'2024-11-07',3,'OT'),(351,11,205,348,NULL,5,'2024-10-29 10:23:00',1,'2024-11-11',2,'OT'),(352,19,208,326,NULL,4,'2024-10-29 08:13:00',2,'2024-11-06',2,'OT'),(353,27,208,313,'COM10',3,'2024-10-30 20:37:00',4,'2024-11-03',2,'OT'),(354,10,212,374,NULL,2,'2024-10-30 08:01:00',4,'2024-11-17',3,'OT'),(355,26,106,312,NULL,5,'2024-11-01 09:12:00',2,'2024-11-03',2,'OT'),(356,4,107,339,NULL,4,'2024-11-01 16:18:00',2,'2024-11-10',1,'OT'),(357,1,205,370,NULL,2,'2024-11-01 21:57:00',1,'2024-11-16',3,'OT'),(358,9,204,371,'NOV10',2,'2024-11-01 12:07:00',2,'2024-11-16',1,'OT'),(359,14,211,352,NULL,3,'2024-11-02 21:58:00',1,'2024-11-12',2,'OT'),(360,30,111,382,NULL,4,'2024-11-02 10:15:00',1,'2024-11-18',1,'OT'),(361,29,206,369,'NOV10',3,'2024-11-02 11:50:00',1,'2024-11-16',1,'OT'),(362,16,203,NULL,'NOV10',4,'2024-11-04 10:48:00',1,'2024-11-21',3,'RE'),(363,27,205,358,NULL,5,'2024-11-04 09:12:00',1,'2024-11-13',1,'OT'),(364,12,211,365,'NOV10',4,'2024-11-04 15:51:00',2,'2024-11-15',3,'OT'),(365,28,207,368,NULL,4,'2024-11-04 13:22:00',4,'2024-11-16',7,'IN'),(366,21,213,360,NULL,2,'2024-11-04 20:33:00',4,'2024-11-14',4,'OT'),(367,28,213,346,'NOV10',4,'2024-11-04 18:36:00',1,'2024-11-11',3,'OT'),(368,5,206,NULL,NULL,4,'2024-11-05 11:37:00',4,'2024-11-21',2,'RE'),(369,27,107,363,NULL,2,'2024-11-05 21:14:00',2,'2024-11-14',3,'OT'),(370,22,207,NULL,'NOV10',3,'2024-11-05 18:11:00',4,'2024-11-24',4,'RE'),(371,16,203,334,'NOV10',3,'2024-11-05 21:43:00',2,'2024-11-08',1,'OT'),(372,18,111,349,'NOV10',4,'2024-11-05 17:01:00',2,'2024-11-11',3,'OT'),(373,26,108,NULL,'COM10',4,'2024-11-05 13:57:00',1,'2024-11-21',6,'RE'),(374,15,210,353,NULL,5,'2024-11-06 12:56:00',3,'2024-11-12',1,'OT'),(375,25,208,375,'COM10',5,'2024-11-06 10:48:00',1,'2024-11-17',2,'OT'),(376,30,211,386,NULL,5,'2024-11-06 19:52:00',1,'2024-11-20',1,'IN'),(377,12,206,337,NULL,5,'2024-11-06 22:42:00',4,'2024-11-08',3,'OT'),(378,18,210,NULL,'NOV10',2,'2024-11-08 13:16:00',3,'2024-11-21',3,'RE'),(379,25,211,NULL,NULL,5,'2024-11-08 20:20:00',3,'2024-11-22',1,'RE'),(380,1,103,NULL,'NOV10',3,'2024-11-08 12:27:00',1,'2024-11-21',1,'RE'),(381,21,110,NULL,NULL,5,'2024-11-08 17:46:00',2,'2024-11-21',3,'RE'),(382,29,202,NULL,'NOV10',2,'2024-11-09 07:42:00',2,'2024-11-23',2,'RE'),(383,5,110,344,'NOV10',5,'2024-11-09 09:30:00',1,'2024-11-11',4,'OT'),(384,2,110,385,NULL,2,'2024-11-09 10:38:00',1,'2024-11-20',1,'IN'),(385,1,212,NULL,NULL,5,'2024-11-09 19:36:00',1,'2024-11-27',4,'RE'),(386,9,208,388,NULL,2,'2024-11-09 15:12:00',4,'2024-11-20',2,'IN'),(387,9,208,345,NULL,3,'2024-11-09 18:46:00',4,'2024-11-11',1,'OT'),(388,8,108,378,NULL,4,'2024-11-09 09:31:00',1,'2024-11-18',2,'OT'),(389,20,111,NULL,NULL,5,'2024-11-09 10:35:00',2,'2024-11-25',3,'RE'),(390,3,201,359,'COM20',5,'2024-11-10 07:12:00',2,'2024-11-14',5,'OT'),(391,19,112,373,NULL,4,'2024-11-11 11:05:00',1,'2024-11-16',4,'OT'),(392,20,210,387,'COM10',5,'2024-11-11 09:49:00',2,'2024-11-20',1,'IN'),(393,20,107,NULL,NULL,4,'2024-11-11 17:40:00',2,'2024-11-21',2,'RE'),(394,7,106,NULL,NULL,2,'2024-11-11 20:52:00',2,'2024-11-24',2,'RE'),(395,3,204,NULL,'COM10',4,'2024-11-11 16:31:00',1,'2024-11-27',2,'RE'),(396,25,213,NULL,NULL,2,'2024-11-12 22:52:00',4,'2024-12-02',2,'RE'),(397,12,210,NULL,NULL,5,'2024-11-12 11:57:00',4,'2024-11-26',7,'RE'),(398,17,204,389,NULL,2,'2024-11-12 08:09:00',1,'2024-11-20',3,'IN'),(399,15,204,377,NULL,5,'2024-11-12 18:09:00',1,'2024-11-17',2,'OT'),(400,2,106,361,'NOV10',2,'2024-11-12 08:02:00',1,'2024-11-14',3,'OT'),(401,13,103,NULL,NULL,4,'2024-11-12 22:37:00',1,'2024-11-26',6,'RE'),(402,9,209,NULL,NULL,3,'2024-11-12 14:13:00',3,'2024-11-22',3,'RE'),(403,20,102,364,NULL,5,'2024-11-12 11:57:00',1,'2024-11-14',3,'OT'),(404,13,202,372,NULL,2,'2024-11-13 19:54:00',1,'2024-11-16',3,'OT'),(405,23,106,379,NULL,3,'2024-11-14 21:00:00',1,'2024-11-18',3,'IN'),(406,10,208,NULL,NULL,3,'2024-11-14 20:09:00',2,'2024-11-23',1,'RE'),(407,9,211,381,NULL,2,'2024-11-14 16:58:00',1,'2024-11-18',2,'OT'),(408,7,211,NULL,'COM10',3,'2024-11-15 16:47:00',4,'2024-11-26',2,'RE'),(409,20,209,NULL,'COM10',4,'2024-11-15 16:42:00',2,'2024-12-05',3,'RE'),(410,20,105,NULL,NULL,5,'2024-11-15 17:10:00',1,'2024-11-30',3,'RE'),(411,13,212,NULL,'NOV10',3,'2024-11-15 14:56:00',2,'2024-11-22',2,'RE'),(412,22,105,384,'NOV10',2,'2024-11-15 21:03:00',1,'2024-11-20',2,'IN'),(413,24,206,NULL,NULL,3,'2024-11-15 12:08:00',3,'2024-11-24',6,'RE'),(414,30,107,NULL,'NOV10',3,'2024-11-15 15:17:00',2,'2024-11-29',1,'RE'),(415,6,209,NULL,NULL,4,'2024-11-16 09:14:00',1,'2024-11-26',3,'RE'),(416,23,211,NULL,NULL,4,'2024-11-16 20:36:00',3,'2024-12-02',6,'RE'),(417,30,212,NULL,NULL,4,'2024-11-16 14:50:00',3,'2024-12-03',2,'RE'),(418,2,106,NULL,NULL,5,'2024-11-16 07:05:00',1,'2024-11-21',2,'RE'),(419,25,112,NULL,NULL,2,'2024-11-16 22:27:00',1,'2024-11-23',5,'RE'),(420,7,210,383,'COM10',2,'2024-11-16 14:47:00',2,'2024-11-19',1,'OT'),(421,14,213,NULL,NULL,5,'2024-11-16 07:08:00',2,'2024-11-27',2,'RE'),(422,6,211,NULL,NULL,3,'2024-11-16 15:55:00',1,'2024-11-23',3,'RE'),(423,18,111,NULL,NULL,2,'2024-11-17 22:43:00',1,'2024-12-07',6,'RE'),(424,15,208,NULL,NULL,2,'2024-11-17 22:19:00',4,'2024-11-27',1,'RE'),(425,8,108,NULL,'NOV10',4,'2024-11-18 12:18:00',1,'2024-11-28',1,'RE'),(426,10,201,NULL,NULL,3,'2024-11-18 21:10:00',2,'2024-12-04',4,'RE'),(427,7,206,NULL,NULL,4,'2024-11-18 10:52:00',3,'2024-12-04',1,'RE'),(428,13,112,NULL,'DEC10',5,'2024-11-18 10:57:00',2,'2024-12-05',6,'RE'),(429,27,213,NULL,NULL,3,'2024-11-18 14:08:00',1,'2024-11-29',3,'RE'),(430,18,205,NULL,NULL,5,'2024-11-18 07:51:00',1,'2024-12-02',2,'RE'),(431,6,212,NULL,NULL,5,'2024-11-18 13:18:00',2,'2024-12-08',1,'RE'),(432,10,201,NULL,'DEC10',3,'2024-11-19 21:42:00',2,'2024-12-02',2,'RE'),(433,15,204,NULL,NULL,4,'2024-11-19 13:41:00',2,'2024-12-09',1,'RE'),(434,1,212,NULL,NULL,2,'2024-11-20 20:25:00',2,'2024-12-01',2,'RE'),(435,25,206,NULL,NULL,3,'2024-11-23 08:00:00',4,'2024-12-06',3,'RE'),(436,9,208,NULL,NULL,3,'2024-11-23 07:52:00',3,'2024-11-29',2,'RE'),(437,16,101,NULL,'DEC10',5,'2024-11-24 11:54:00',1,'2024-12-04',2,'RE'),(438,3,108,NULL,NULL,3,'2024-11-25 17:03:00',1,'2024-11-29',2,'RE'),(439,29,213,NULL,NULL,3,'2024-11-26 12:30:00',3,'2024-12-09',3,'RE'),(440,1,208,NULL,'DEC10',3,'2024-11-26 07:17:00',1,'2024-12-07',2,'RE'),(441,3,210,NULL,NULL,5,'2024-11-26 07:45:00',4,'2024-12-04',4,'RE'),(442,27,108,NULL,'COM10',4,'2024-11-26 22:28:00',2,'2024-12-02',5,'RE'),(443,5,209,NULL,NULL,5,'2024-11-26 12:44:00',3,'2024-11-30',3,'RE'),(444,28,207,NULL,NULL,4,'2024-11-27 13:30:00',3,'2024-12-08',3,'RE'),(445,11,102,NULL,NULL,3,'2024-11-27 11:19:00',1,'2024-12-08',1,'RE'),(446,24,208,NULL,NULL,3,'2024-11-27 07:44:00',2,'2024-12-03',1,'RE'),(447,16,101,NULL,'NOV10',4,'2024-11-28 12:56:00',1,'2024-11-30',2,'RE'),(448,15,207,NULL,NULL,2,'2024-11-28 16:36:00',4,'2024-12-01',5,'RE'),(449,13,112,NULL,'DEC10',5,'2024-11-28 16:20:00',2,'2024-12-02',1,'RE'),(450,12,107,NULL,'DEC10',2,'2024-11-28 14:36:00',1,'2024-12-04',2,'RE'),(451,27,107,NULL,NULL,5,'2024-11-29 08:36:00',1,'2024-12-08',2,'RE'),(452,24,211,NULL,NULL,2,'2024-11-29 18:02:00',3,'2024-12-08',1,'RE'),(453,21,110,NULL,NULL,5,'2024-11-29 07:25:00',1,'2024-12-06',2,'RE'),(454,25,208,NULL,'COM10',2,'2024-12-01 16:25:00',1,'2024-12-04',2,'RE'),(455,22,103,NULL,NULL,3,'2024-12-02 19:52:00',1,'2024-12-08',6,'RE'),(456,23,209,NULL,'DEC10',3,'2024-12-02 22:47:00',3,'2024-12-08',5,'RE'),(457,2,108,NULL,'DEC10',2,'2024-12-03 22:04:00',1,'2024-12-08',3,'RE'),(458,8,212,NULL,NULL,5,'2024-12-03 14:18:00',2,'2024-12-09',3,'RE'),(459,7,213,NULL,'COM10',5,'2024-12-03 13:11:00',3,'2024-12-07',2,'RE'),(460,9,107,NULL,NULL,4,'2024-12-04 15:27:00',2,'2024-12-07',1,'RE'),(461,17,205,NULL,NULL,2,'2024-12-05 10:16:00',2,'2024-12-07',3,'RE'),(462,12,203,NULL,NULL,3,'2024-12-05 18:31:00',1,'2024-12-07',4,'RE'),(463,14,211,NULL,'COM20',2,'2024-12-07 17:40:00',4,'2024-12-09',4,'RE');
/*!40000 ALTER TABLE `reservation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `reservation_with_end_date_view`
--

DROP TABLE IF EXISTS `reservation_with_end_date_view`;
/*!50001 DROP VIEW IF EXISTS `reservation_with_end_date_view`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `reservation_with_end_date_view` AS SELECT 
 1 AS `reservation_id`,
 1 AS `guest_id`,
 1 AS `room_number`,
 1 AS `invoice_number`,
 1 AS `promotion_code`,
 1 AS `reservation_staff_id`,
 1 AS `reservation_date_time`,
 1 AS `number_of_guests`,
 1 AS `start_of_stay`,
 1 AS `length_of_stay`,
 1 AS `end_of_stay`,
 1 AS `last_night`,
 1 AS `status_code`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `room`
--

DROP TABLE IF EXISTS `room`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `room` (
  `room_number` smallint NOT NULL,
  `room_type_code` char(3) NOT NULL,
  `bathroom_type_code` char(2) NOT NULL,
  `status` char(3) NOT NULL DEFAULT 'ACT' COMMENT 'ACT = room active, CLN = room requires deep cleaning, REP = room requires repair',
  `key_serial_number` varchar(15) NOT NULL,
  PRIMARY KEY (`room_number`),
  KEY `FK_room_type` (`room_type_code`,`bathroom_type_code`),
  CONSTRAINT `FK_room_type` FOREIGN KEY (`room_type_code`, `bathroom_type_code`) REFERENCES `room_price` (`room_type_code`, `bathroom_type_code`),
  CONSTRAINT `room_chk_1` CHECK ((`status` in (_utf8mb4'ACT',_utf8mb4'CLN',_utf8mb4'REP')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `room`
--

LOCK TABLES `room` WRITE;
/*!40000 ALTER TABLE `room` DISABLE KEYS */;
INSERT INTO `room` VALUES (101,'SI','B1','ACT','ABC12312'),(102,'SI','B2','ACT','BSD21432'),(103,'SIM','B3','ACT','JGF34673'),(104,'SIP','B2','CLN','PEH23563'),(105,'DO','B1','ACT','LWB32454'),(106,'DO','B2','ACT','MMD12134'),(107,'DOM','B1','ACT','FHG33445'),(108,'DOM','B2','ACT','OKD45563'),(109,'DOP','B3','CLN','KRW11465'),(110,'DOP','B3','ACT','KSJ73423'),(111,'DOP','B4','ACT','SSW22453'),(112,'DOE','B4','ACT','YTT22432'),(201,'DOE','B4','ACT','BBS11223'),(202,'TW','B1','ACT','GGS55442'),(203,'TW','B2','ACT','HHD11543'),(204,'TWE','B4','ACT','ZXX35672'),(205,'TWE','B4','ACT','SDD24341'),(206,'FA','B1','ACT','KKG66552'),(207,'FA','B3','ACT','LLI12343'),(208,'FAM','B2','ACT','PWK33221'),(209,'FAP','B2','ACT','LXC66876'),(210,'FAP','B3','ACT','LXC66876'),(211,'SUP','B3','ACT','LXC66876'),(212,'SUP','B4','ACT','LXC66876'),(213,'SUE','B4','ACT','LXC66876');
/*!40000 ALTER TABLE `room` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `room_clean`
--

DROP TABLE IF EXISTS `room_clean`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `room_clean` (
  `room_number` smallint NOT NULL,
  `date_of_clean` date NOT NULL,
  `staff_id` smallint NOT NULL,
  `time_of_clean` time NOT NULL,
  `type_of_clean` char(1) NOT NULL DEFAULT 'L' COMMENT 'L = Light, F = Full',
  PRIMARY KEY (`room_number`,`date_of_clean`),
  KEY `date_of_clean` (`date_of_clean`,`staff_id`),
  KEY `IDX_staff_id` (`staff_id`),
  CONSTRAINT `room_clean_ibfk_1` FOREIGN KEY (`room_number`) REFERENCES `room` (`room_number`),
  CONSTRAINT `room_clean_ibfk_2` FOREIGN KEY (`date_of_clean`, `staff_id`) REFERENCES `cleaning_session` (`date_of_clean`, `staff_id`),
  CONSTRAINT `room_clean_chk_1` CHECK ((`type_of_clean` in (_utf8mb4'L',_utf8mb4'F')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `room_clean`
--

LOCK TABLES `room_clean` WRITE;
/*!40000 ALTER TABLE `room_clean` DISABLE KEYS */;
INSERT INTO `room_clean` VALUES (101,'2024-10-21',7,'09:30:00','F'),(101,'2024-10-22',7,'09:30:00','L'),(101,'2024-11-11',6,'09:00:00','L'),(101,'2024-11-12',6,'09:00:00','L'),(101,'2024-11-13',7,'09:00:00','L'),(101,'2024-11-14',7,'09:00:00','L'),(101,'2024-11-15',6,'09:00:00','L'),(101,'2024-11-16',6,'09:00:00','F'),(101,'2024-11-17',6,'09:00:00','L'),(102,'2024-10-21',7,'10:00:00','L'),(102,'2024-10-22',7,'09:45:00','F'),(102,'2024-11-11',6,'09:15:00','L'),(102,'2024-11-12',6,'09:15:00','L'),(102,'2024-11-13',7,'09:15:00','L'),(102,'2024-11-14',7,'09:15:00','L'),(102,'2024-11-15',6,'09:15:00','L'),(102,'2024-11-16',6,'09:30:00','L'),(102,'2024-11-17',6,'09:15:00','F'),(103,'2024-10-21',7,'10:15:00','L'),(103,'2024-10-22',7,'10:15:00','F'),(103,'2024-11-11',6,'09:30:00','L'),(103,'2024-11-12',6,'09:30:00','F'),(103,'2024-11-13',7,'09:30:00','L'),(103,'2024-11-14',7,'09:30:00','L'),(103,'2024-11-15',6,'09:30:00','L'),(103,'2024-11-16',6,'09:45:00','L'),(103,'2024-11-17',6,'09:45:00','L'),(104,'2024-11-11',6,'09:45:00','L'),(104,'2024-11-12',6,'10:00:00','L'),(104,'2024-11-13',7,'09:45:00','L'),(104,'2024-11-14',7,'09:45:00','L'),(104,'2024-11-15',6,'09:45:00','L'),(104,'2024-11-16',6,'10:00:00','L'),(104,'2024-11-17',6,'10:00:00','L'),(105,'2024-11-11',6,'10:00:00','L'),(105,'2024-11-12',6,'10:15:00','L'),(105,'2024-11-13',7,'10:00:00','L'),(105,'2024-11-14',7,'10:00:00','L'),(105,'2024-11-15',6,'10:00:00','L'),(105,'2024-11-16',6,'10:15:00','L'),(105,'2024-11-17',6,'10:15:00','L'),(106,'2024-11-11',6,'10:15:00','L'),(106,'2024-11-12',6,'10:30:00','L'),(106,'2024-11-13',7,'10:15:00','L'),(106,'2024-11-14',7,'10:15:00','L'),(106,'2024-11-15',6,'10:15:00','L'),(106,'2024-11-16',6,'10:30:00','L'),(106,'2024-11-17',6,'10:30:00','F'),(107,'2024-11-11',6,'10:30:00','F'),(107,'2024-11-12',6,'10:45:00','L'),(107,'2024-11-13',7,'10:30:00','L'),(107,'2024-11-14',7,'10:30:00','L'),(107,'2024-11-15',6,'10:30:00','L'),(107,'2024-11-16',6,'10:45:00','L'),(107,'2024-11-17',6,'11:00:00','F'),(108,'2024-11-11',6,'11:00:00','L'),(108,'2024-11-12',6,'11:00:00','L'),(108,'2024-11-13',7,'10:45:00','L'),(108,'2024-11-14',7,'10:45:00','L'),(108,'2024-11-15',6,'10:45:00','L'),(108,'2024-11-16',6,'11:00:00','L'),(108,'2024-11-17',8,'09:00:00','L'),(109,'2024-11-11',6,'11:15:00','L'),(109,'2024-11-12',6,'11:15:00','L'),(109,'2024-11-13',7,'11:00:00','L'),(109,'2024-11-14',7,'11:00:00','L'),(109,'2024-11-15',6,'11:00:00','L'),(109,'2024-11-16',8,'09:00:00','L'),(109,'2024-11-17',8,'09:15:00','L'),(110,'2024-11-11',8,'09:00:00','L'),(110,'2024-11-12',8,'09:00:00','L'),(110,'2024-11-13',7,'11:15:00','L'),(110,'2024-11-14',7,'11:15:00','L'),(110,'2024-11-15',7,'09:00:00','F'),(110,'2024-11-16',8,'09:15:00','L'),(110,'2024-11-17',8,'09:30:00','L'),(111,'2024-11-11',8,'09:15:00','L'),(111,'2024-11-12',8,'09:15:00','L'),(111,'2024-11-13',8,'09:00:00','L'),(111,'2024-11-14',7,'11:30:00','F'),(111,'2024-11-15',7,'09:30:00','L'),(111,'2024-11-16',8,'09:30:00','L'),(111,'2024-11-17',8,'09:45:00','L'),(112,'2024-11-11',8,'09:30:00','L'),(112,'2024-11-12',8,'09:30:00','L'),(112,'2024-11-13',8,'09:15:00','L'),(112,'2024-11-14',8,'09:00:00','F'),(112,'2024-11-15',7,'09:45:00','L'),(112,'2024-11-16',8,'09:45:00','L'),(112,'2024-11-17',8,'10:00:00','L'),(201,'2024-10-21',8,'09:30:00','F'),(201,'2024-10-22',8,'09:30:00','L'),(201,'2024-11-11',8,'09:45:00','L'),(201,'2024-11-12',8,'09:45:00','L'),(201,'2024-11-13',8,'09:30:00','L'),(201,'2024-11-14',8,'09:30:00','F'),(201,'2024-11-15',7,'10:00:00','L'),(201,'2024-11-16',8,'10:00:00','L'),(201,'2024-11-17',8,'10:15:00','L'),(202,'2024-10-21',8,'10:00:00','F'),(202,'2024-11-11',8,'10:00:00','L'),(202,'2024-11-12',8,'10:00:00','L'),(202,'2024-11-13',8,'09:45:00','L'),(202,'2024-11-14',8,'10:00:00','L'),(202,'2024-11-15',7,'10:15:00','L'),(202,'2024-11-16',8,'10:15:00','L'),(202,'2024-11-17',8,'10:30:00','L'),(203,'2024-10-21',8,'10:30:00','L'),(203,'2024-11-11',8,'10:15:00','L'),(203,'2024-11-12',8,'10:15:00','L'),(203,'2024-11-13',8,'10:00:00','L'),(203,'2024-11-14',8,'10:15:00','L'),(203,'2024-11-15',7,'10:30:00','L'),(203,'2024-11-16',8,'10:30:00','L'),(203,'2024-11-17',8,'10:45:00','L'),(204,'2024-11-11',8,'10:30:00','F'),(204,'2024-11-12',8,'10:30:00','L'),(204,'2024-11-13',8,'10:15:00','L'),(204,'2024-11-14',8,'10:30:00','L'),(204,'2024-11-15',7,'10:45:00','L'),(204,'2024-11-16',8,'10:45:00','L'),(204,'2024-11-17',8,'11:00:00','F'),(205,'2024-11-11',8,'11:00:00','L'),(205,'2024-11-12',8,'10:45:00','L'),(205,'2024-11-13',8,'10:30:00','F'),(205,'2024-11-14',8,'10:45:00','F'),(205,'2024-11-15',7,'11:00:00','L'),(205,'2024-11-16',8,'11:00:00','L'),(205,'2024-11-17',9,'09:00:00','L'),(206,'2024-11-11',8,'11:15:00','F'),(206,'2024-11-12',8,'11:00:00','L'),(206,'2024-11-13',8,'11:00:00','L'),(206,'2024-11-14',8,'11:15:00','F'),(206,'2024-11-15',8,'09:00:00','L'),(206,'2024-11-16',9,'09:00:00','L'),(206,'2024-11-17',9,'09:15:00','F'),(207,'2024-11-11',9,'09:00:00','L'),(207,'2024-11-12',8,'11:15:00','L'),(207,'2024-11-13',8,'11:15:00','F'),(207,'2024-11-14',9,'09:00:00','L'),(207,'2024-11-15',8,'09:15:00','L'),(207,'2024-11-16',9,'09:15:00','L'),(207,'2024-11-17',9,'09:45:00','L'),(208,'2024-11-11',9,'09:15:00','L'),(208,'2024-11-12',9,'09:00:00','F'),(208,'2024-11-13',9,'09:00:00','L'),(208,'2024-11-14',9,'09:15:00','L'),(208,'2024-11-15',8,'09:30:00','F'),(208,'2024-11-16',9,'09:30:00','L'),(208,'2024-11-17',9,'10:00:00','L'),(209,'2024-11-11',9,'09:30:00','L'),(209,'2024-11-12',9,'09:30:00','F'),(209,'2024-11-13',9,'09:15:00','L'),(209,'2024-11-14',9,'09:30:00','L'),(209,'2024-11-15',8,'10:00:00','L'),(209,'2024-11-16',9,'09:45:00','L'),(209,'2024-11-17',9,'10:15:00','L'),(210,'2024-11-11',9,'09:45:00','L'),(210,'2024-11-12',9,'10:00:00','F'),(210,'2024-11-13',9,'09:30:00','F'),(210,'2024-11-14',9,'09:45:00','L'),(210,'2024-11-15',8,'10:15:00','L'),(210,'2024-11-16',9,'10:00:00','L'),(210,'2024-11-17',9,'10:30:00','L'),(211,'2024-11-11',9,'10:00:00','F'),(211,'2024-11-12',9,'10:30:00','L'),(211,'2024-11-13',9,'10:00:00','L'),(211,'2024-11-14',9,'10:00:00','F'),(211,'2024-11-15',8,'10:30:00','L'),(211,'2024-11-16',9,'10:15:00','L'),(211,'2024-11-17',9,'10:45:00','L'),(212,'2024-11-11',9,'10:30:00','L'),(212,'2024-11-12',9,'10:45:00','L'),(212,'2024-11-13',9,'10:15:00','L'),(212,'2024-11-14',9,'10:30:00','L'),(212,'2024-11-15',8,'10:45:00','L'),(212,'2024-11-16',9,'10:30:00','F'),(212,'2024-11-17',9,'11:00:00','L'),(213,'2024-11-11',9,'10:45:00','F'),(213,'2024-11-12',9,'11:00:00','L'),(213,'2024-11-13',9,'10:30:00','L'),(213,'2024-11-14',9,'10:45:00','F'),(213,'2024-11-15',8,'11:00:00','L'),(213,'2024-11-16',9,'11:00:00','L'),(213,'2024-11-17',9,'11:15:00','L');
/*!40000 ALTER TABLE `room_clean` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `room_cleaning_view`
--

DROP TABLE IF EXISTS `room_cleaning_view`;
/*!50001 DROP VIEW IF EXISTS `room_cleaning_view`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `room_cleaning_view` AS SELECT 
 1 AS `room_number`,
 1 AS `date_of_clean`,
 1 AS `time_of_clean`,
 1 AS `staff_id`,
 1 AS `title`,
 1 AS `first_name`,
 1 AS `last_name`,
 1 AS `type_of_clean`,
 1 AS `allocated_master_key`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `room_details_view`
--

DROP TABLE IF EXISTS `room_details_view`;
/*!50001 DROP VIEW IF EXISTS `room_details_view`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `room_details_view` AS SELECT 
 1 AS `room_number`,
 1 AS `room_type_code`,
 1 AS `room_type_name`,
 1 AS `modern_style`,
 1 AS `deluxe`,
 1 AS `maximum_guests`,
 1 AS `bathroom_type_code`,
 1 AS `bathroom_type_name`,
 1 AS `seperate_shower`,
 1 AS `bath`,
 1 AS `status`,
 1 AS `key_serial_number`,
 1 AS `price`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `room_price`
--

DROP TABLE IF EXISTS `room_price`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `room_price` (
  `room_type_code` char(3) NOT NULL,
  `bathroom_type_code` char(2) NOT NULL,
  `price` decimal(6,2) NOT NULL,
  PRIMARY KEY (`room_type_code`,`bathroom_type_code`),
  KEY `bathroom_type_code` (`bathroom_type_code`),
  CONSTRAINT `room_price_ibfk_1` FOREIGN KEY (`room_type_code`) REFERENCES `room_type` (`room_type_code`),
  CONSTRAINT `room_price_ibfk_2` FOREIGN KEY (`bathroom_type_code`) REFERENCES `bathroom_type` (`bathroom_type_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `room_price`
--

LOCK TABLES `room_price` WRITE;
/*!40000 ALTER TABLE `room_price` DISABLE KEYS */;
INSERT INTO `room_price` VALUES ('DO','B1',80.00),('DO','B2',85.00),('DOE','B4',120.00),('DOM','B1',90.00),('DOM','B2',95.00),('DOP','B3',105.00),('DOP','B4',110.00),('FA','B1',100.00),('FA','B3',110.00),('FAM','B2',110.00),('FAP','B2',115.00),('FAP','B3',120.00),('SI','B1',60.00),('SI','B2',65.00),('SIM','B2',70.00),('SIM','B3',75.00),('SIP','B2',75.00),('SIP','B3',85.00),('SUE','B4',180.00),('SUP','B3',140.00),('SUP','B4',150.00),('TW','B1',75.00),('TW','B2',80.00),('TWE','B4',115.00);
/*!40000 ALTER TABLE `room_price` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `room_type`
--

DROP TABLE IF EXISTS `room_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `room_type` (
  `room_type_code` char(3) NOT NULL,
  `room_type_name` varchar(25) NOT NULL,
  `modern_style` tinyint NOT NULL COMMENT '0 or 1 to represent boolean',
  `deluxe` tinyint NOT NULL COMMENT '0 or 1 to represent boolean',
  `maximum_guests` tinyint NOT NULL,
  PRIMARY KEY (`room_type_code`),
  KEY `IDX_room_type_name` (`room_type_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `room_type`
--

LOCK TABLES `room_type` WRITE;
/*!40000 ALTER TABLE `room_type` DISABLE KEYS */;
INSERT INTO `room_type` VALUES ('DO','Double',0,0,2),('DOE','Double Executive',1,1,2),('DOM','Double Plus',1,0,2),('DOP','Double Premium',0,1,2),('FA','Family',0,0,4),('FAM','Family Plus',1,0,4),('FAP','Family Premium',0,1,4),('SI','Single',0,0,1),('SIM','Single Plus',1,0,1),('SIP','Single Premium',0,1,1),('SUE','Suite Executive',1,1,6),('SUP','Suite Premium',0,1,4),('TW','Twin',0,0,2),('TWE','Twin Executive',1,1,2);
/*!40000 ALTER TABLE `room_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `staff`
--

DROP TABLE IF EXISTS `staff`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `staff` (
  `staff_id` smallint NOT NULL AUTO_INCREMENT,
  `manager_id` smallint DEFAULT NULL,
  `title` varchar(10) NOT NULL,
  `first_name` varchar(80) NOT NULL,
  `last_name` varchar(80) NOT NULL,
  `role` varchar(15) NOT NULL,
  PRIMARY KEY (`staff_id`),
  KEY `manager_id` (`manager_id`),
  CONSTRAINT `staff_ibfk_1` FOREIGN KEY (`manager_id`) REFERENCES `staff` (`staff_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `staff`
--

LOCK TABLES `staff` WRITE;
/*!40000 ALTER TABLE `staff` DISABLE KEYS */;
INSERT INTO `staff` VALUES (1,NULL,'Mr','Simon','Rumsey','OWNER'),(2,1,'Mrs','Jill','Smithers','RECEP_LEAD'),(3,2,'Mr','James','Dilly','RECEP'),(4,2,'Miss','Heather','Lewis','RECEP'),(5,2,'Ms','Vicki','Green','RECEP'),(6,1,'Mr','Stuart','Sanders','CLEAN_LEAD'),(7,6,'Miss','Paula','Jones','CLEAN'),(8,6,'Miss','Holly','Adams','CLEAN'),(9,6,'Mr','Jack','York','CLEAN');
/*!40000 ALTER TABLE `staff` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'hotel_db'
--

--
-- Dumping routines for database 'hotel_db'
--
/*!50003 DROP PROCEDURE IF EXISTS `findAvailableRooms` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `findAvailableRooms`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `findReservedRooms` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `findReservedRooms`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `validate_phone_number` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `validate_phone_number`(phone_number VARCHAR(30))
BEGIN
    IF NOT phone_number REGEXP '^[0-9]{10,11}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: The phone number must be 10 or 11 digits in length.';
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Final view structure for view `reservation_with_end_date_view`
--

/*!50001 DROP VIEW IF EXISTS `reservation_with_end_date_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `reservation_with_end_date_view` AS select `reservation`.`reservation_id` AS `reservation_id`,`reservation`.`guest_id` AS `guest_id`,`reservation`.`room_number` AS `room_number`,`reservation`.`invoice_number` AS `invoice_number`,`reservation`.`promotion_code` AS `promotion_code`,`reservation`.`reservation_staff_id` AS `reservation_staff_id`,`reservation`.`reservation_date_time` AS `reservation_date_time`,`reservation`.`number_of_guests` AS `number_of_guests`,`reservation`.`start_of_stay` AS `start_of_stay`,`reservation`.`length_of_stay` AS `length_of_stay`,(`reservation`.`start_of_stay` + interval `reservation`.`length_of_stay` day) AS `end_of_stay`,(`reservation`.`start_of_stay` + interval (`reservation`.`length_of_stay` - 1) day) AS `last_night`,`reservation`.`status_code` AS `status_code` from `reservation` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `room_cleaning_view`
--

/*!50001 DROP VIEW IF EXISTS `room_cleaning_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `room_cleaning_view` AS select `r`.`room_number` AS `room_number`,`r`.`date_of_clean` AS `date_of_clean`,`r`.`time_of_clean` AS `time_of_clean`,`s`.`staff_id` AS `staff_id`,`s`.`title` AS `title`,`s`.`first_name` AS `first_name`,`s`.`last_name` AS `last_name`,`r`.`type_of_clean` AS `type_of_clean`,`c`.`allocated_master_key` AS `allocated_master_key` from ((`room_clean` `r` join `staff` `s` on((`r`.`staff_id` = `s`.`staff_id`))) join `cleaning_session` `c` on(((`r`.`date_of_clean` = `c`.`date_of_clean`) and (`r`.`staff_id` = `c`.`staff_id`)))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `room_details_view`
--

/*!50001 DROP VIEW IF EXISTS `room_details_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `room_details_view` AS select `r`.`room_number` AS `room_number`,`r`.`room_type_code` AS `room_type_code`,`rt`.`room_type_name` AS `room_type_name`,`rt`.`modern_style` AS `modern_style`,`rt`.`deluxe` AS `deluxe`,`rt`.`maximum_guests` AS `maximum_guests`,`r`.`bathroom_type_code` AS `bathroom_type_code`,`bt`.`bathroom_type_name` AS `bathroom_type_name`,`bt`.`seperate_shower` AS `seperate_shower`,`bt`.`bath` AS `bath`,`r`.`status` AS `status`,`r`.`key_serial_number` AS `key_serial_number`,`rp`.`price` AS `price` from (((`room` `r` join `room_price` `rp` on(((`r`.`room_type_code` = `rp`.`room_type_code`) and (`r`.`bathroom_type_code` = `rp`.`bathroom_type_code`)))) join `room_type` `rt` on((`rp`.`room_type_code` = `rt`.`room_type_code`))) join `bathroom_type` `bt` on((`rp`.`bathroom_type_code` = `bt`.`bathroom_type_code`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2024-12-08 16:51:47
