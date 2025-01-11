
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
