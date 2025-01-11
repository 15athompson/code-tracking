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