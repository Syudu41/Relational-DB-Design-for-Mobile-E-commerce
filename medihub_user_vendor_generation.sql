USE medical_ecommerce;

DELIMITER //

-- Previous name: generate_users_and_vendors()
-- Same name kept, but functionality enhanced
CREATE PROCEDURE generate_users_and_vendors()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE total_users INT DEFAULT 1000;
    DECLARE total_vendors INT DEFAULT 40;
    DECLARE curr_month DATE;
    DECLARE month_counter INT;
    
    -- Clear existing data
    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE monthly_metrics;
    TRUNCATE TABLE reviews;
    TRUNCATE TABLE order_items;
    TRUNCATE TABLE orders;
    TRUNCATE TABLE prescriptions;
    TRUNCATE TABLE product_pricing_history;
    TRUNCATE TABLE products;
    TRUNCATE TABLE vendor_profiles;
    TRUNCATE TABLE user_roles;
    TRUNCATE TABLE user_contacts;
    TRUNCATE TABLE user_status_history;  -- NEW: Clear status history
    TRUNCATE TABLE addresses;            -- NEW: Clear addresses
    TRUNCATE TABLE users;
    SET FOREIGN_KEY_CHECKS = 1;

    START TRANSACTION;
    
    WHILE i <= total_users DO
        -- NEW: Create address first
        INSERT INTO addresses (
            street_number,
            street_name,
            postal_code,
            city_id
        ) 
        SELECT 
            CONCAT(FLOOR(100 + RAND() * 9900)),
            CONCAT('Street ', FLOOR(RAND() * 100)),
            CONCAT(LPAD(FLOOR(RAND() * 99999), 5, '0')),
            city_id
        FROM cities
        ORDER BY RAND()
        LIMIT 1;
        
        SET @current_address_id = LAST_INSERT_ID();
        
        -- Insert user
        INSERT INTO users (
            email,
            password_hash,
            first_name,
            last_name,
            created_at,
            is_active
        ) VALUES (
            CONCAT('user', i, '@example.com'),
            SHA2(CONCAT('hash', i), 256),
            ELT(1 + FLOOR(RAND() * 10), 'John', 'Jane', 'Mike', 'Sarah', 'David', 'Lisa', 'James', 'Emily', 'Robert', 'Mary'),
            ELT(1 + FLOOR(RAND() * 10), 'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez'),
            DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 365) DAY),
            TRUE
        );
        
        -- Insert contact info with new address reference
        INSERT INTO user_contacts (
            user_id,
            phone,
            primary_address_id
        ) VALUES (
            i,
            CONCAT('555-', LPAD(i, 4, '0')),
            @current_address_id
        );
        
        -- First 40 users are vendors
        IF i <= total_vendors THEN
            INSERT INTO user_roles (user_id, role_id) 
            VALUES (i, (SELECT role_id FROM roles WHERE role_name = 'vendor'));
            
            INSERT INTO vendor_profiles (
                vendor_id,
                business_name,
                license_number,
                is_active
            ) VALUES (
                i,
                CONCAT('Pharmacy ', i),
                CONCAT('LIC', LPAD(i, 6, '0')),
                TRUE
            );
        END IF;
        
        -- All users are customers
        INSERT INTO user_roles (user_id, role_id) 
        VALUES (i, (SELECT role_id FROM roles WHERE role_name = 'customer'));
        
        SET i = i + 1;
    END WHILE;
    
    -- NEW: Generate monthly status changes for the past 12 months
    SET month_counter = 11;
    
    WHILE month_counter >= 0 DO
        SET curr_month = DATE_SUB(DATE_FORMAT(NOW(), '%Y-%m-01'), INTERVAL month_counter MONTH);
        
        -- Customers: 0-5% inactive
        INSERT INTO user_status_history (user_id, status_month, is_active)
        SELECT 
            user_id,
            curr_month,
            CASE 
                WHEN RAND() < 0.95 THEN TRUE -- 95% active
                ELSE FALSE                   -- 5% inactive
            END
        FROM users
        WHERE user_id > total_vendors;
        
        -- Vendors: 0-10 inactive
        INSERT INTO user_status_history (user_id, status_month, is_active)
        SELECT 
            user_id,
            curr_month,
            CASE 
                WHEN RAND() < (1 - (FLOOR(RAND() * 11) / total_vendors)) THEN TRUE
                ELSE FALSE
            END
        FROM users
        WHERE user_id <= total_vendors;
        
        SET month_counter = month_counter - 1;
    END WHILE;
    
    COMMIT;

    -- Verify generation
    SELECT 
        'User Generation Summary' as message,
        (SELECT COUNT(*) FROM users) as total_users,
        (SELECT COUNT(*) FROM vendor_profiles) as total_vendors,
        (SELECT COUNT(*) FROM user_roles WHERE role_id = 1) as total_customers,
        (SELECT COUNT(*) FROM user_roles WHERE role_id = 2) as vendor_roles,
        (SELECT COUNT(*) FROM addresses) as total_addresses,
        (SELECT COUNT(DISTINCT user_id) FROM user_status_history WHERE is_active = FALSE) as users_with_inactive_periods;
END //

DELIMITER ;

-- Execute the procedure
CALL generate_users_and_vendors();

-- Clean up
DROP PROCEDURE IF EXISTS generate_users_and_vendors;