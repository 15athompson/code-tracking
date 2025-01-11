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