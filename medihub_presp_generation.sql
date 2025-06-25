USE medical_ecommerce;

DELIMITER //

CREATE PROCEDURE generate_prescriptions()
BEGIN
    -- All declarations must come first
    DECLARE done INT DEFAULT FALSE;
    DECLARE curr_order_id INT;
    DECLARE curr_customer_id INT;
    DECLARE curr_order_date TIMESTAMP;
    
    -- Declare cursor
    DECLARE prescription_cursor CURSOR FOR 
    SELECT DISTINCT 
        o.order_id,
        o.customer_id,
        o.created_at
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE p.requires_prescription = TRUE
    AND oi.prescription_id IS NULL
    ORDER BY o.created_at;
    
    -- Declare handler
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Clear existing prescription data
    SET FOREIGN_KEY_CHECKS = 0;
    UPDATE order_items SET prescription_id = NULL;
    TRUNCATE TABLE prescriptions;
    TRUNCATE TABLE doctors;
    SET FOREIGN_KEY_CHECKS = 1;
    
    -- Generate sample doctors
    INSERT INTO doctors (first_name, last_name, license_number) VALUES
    ('John', 'Smith', 'MD123456'),
    ('Sarah', 'Johnson', 'MD234567'),
    ('Michael', 'Williams', 'MD345678'),
    ('Emily', 'Brown', 'MD456789'),
    ('David', 'Jones', 'MD567890');
    
    START TRANSACTION;
    
    OPEN prescription_cursor;
    
    prescription_loop: LOOP
        FETCH prescription_cursor INTO curr_order_id, curr_customer_id, curr_order_date;
        IF done THEN
            LEAVE prescription_loop;
        END IF;
        
        -- Generate prescription
        INSERT INTO prescriptions (
            user_id,
            doctor_id,
            issued_date,
            valid_until,
            is_verified
        ) VALUES (
            curr_customer_id,
            (SELECT doctor_id FROM doctors ORDER BY RAND() LIMIT 1),
            DATE(DATE_SUB(curr_order_date, INTERVAL FLOOR(RAND() * 7) DAY)),
            DATE(DATE_ADD(curr_order_date, INTERVAL 6 MONTH)),
            TRUE  -- All prescriptions verified for sample data
        );
        
        SET @prescription_id = LAST_INSERT_ID();
        
        -- Link prescription to order items that need it
        UPDATE order_items oi
        JOIN products p ON oi.product_id = p.product_id
        SET oi.prescription_id = @prescription_id
        WHERE oi.order_id = curr_order_id
        AND p.requires_prescription = TRUE;
        
        IF (curr_order_id % 100) = 0 THEN
            COMMIT;
            START TRANSACTION;
        END IF;
    END LOOP;
    
    CLOSE prescription_cursor;
    COMMIT;

    -- Verify generation
    SELECT 
        'Prescription Generation Summary' as message,
        (SELECT COUNT(*) FROM doctors) as total_doctors,
        (SELECT COUNT(*) FROM prescriptions) as total_prescriptions,
        (SELECT COUNT(DISTINCT user_id) FROM prescriptions) as unique_customers,
        (SELECT COUNT(DISTINCT prescription_id) FROM order_items WHERE prescription_id IS NOT NULL) as prescriptions_used;

    -- Show prescription distribution
    SELECT 
        'Prescriptions per Customer (Top 5)' as message,
        p.user_id,
        COUNT(*) as prescription_count,
        MIN(p.issued_date) as first_prescription,
        MAX(p.issued_date) as last_prescription
    FROM prescriptions p
    GROUP BY p.user_id
    ORDER BY prescription_count DESC
    LIMIT 5;
END //

DELIMITER ;

-- Execute the procedure
CALL generate_prescriptions();

-- Clean up
DROP PROCEDURE IF EXISTS generate_prescriptions;