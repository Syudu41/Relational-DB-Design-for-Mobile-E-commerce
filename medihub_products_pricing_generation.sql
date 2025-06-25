USE medical_ecommerce;

DELIMITER //

CREATE PROCEDURE generate_products_and_pricing()
BEGIN
    DECLARE v_vendor_id INT;
    DECLARE done INT DEFAULT FALSE;
    DECLARE product_count INT;
    
    -- Cursor for vendors
    DECLARE vendor_cursor CURSOR FOR 
        SELECT vendor_id, 
               40 - ROW_NUMBER() OVER (ORDER BY RAND()) + 1 as num_products
        FROM vendor_profiles 
        WHERE is_active = TRUE;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Clear existing product data
    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE product_inventory;
    TRUNCATE TABLE product_pricing_history;
    TRUNCATE TABLE products;
    SET FOREIGN_KEY_CHECKS = 1;
    
    START TRANSACTION;
    
    OPEN vendor_cursor;
    
    vendor_loop: LOOP
        -- Get next vendor and their assigned product count
        FETCH vendor_cursor INTO v_vendor_id, product_count;
        IF done THEN
            LEAVE vendor_loop;
        END IF;
        
        -- Generate products for this vendor
        INSERT INTO products (
            vendor_id,
            category_id,
            name,
            description,
            requires_prescription,
            is_active,
            created_at
        )
        SELECT 
            v_vendor_id,
            c.category_id,
            CASE c.category_id
                WHEN 1 THEN CONCAT('Pain', ELT(1 + FLOOR(RAND() * 3), 'Relief', 'Away', 'Cure'), ' ', 100 * ROUND(RAND() * 5 + 1), 'mg')
                WHEN 2 THEN CONCAT('Antibiotic', ELT(1 + FLOOR(RAND() * 3), 'Cin', 'Zith', 'Mox'), ' ', 250 * ROUND(RAND() * 2 + 1), 'mg')
                WHEN 3 THEN CONCAT('Card', ELT(1 + FLOOR(RAND() * 3), 'iox', 'izen', 'ipine'), ' ', 25 * ROUND(RAND() * 4 + 1), 'mg')
                WHEN 4 THEN CONCAT('Diab', ELT(1 + FLOOR(RAND() * 3), 'etrol', 'etin', 'ecare'), ' ', 500 * ROUND(RAND() * 2 + 1), 'mg')
                WHEN 5 THEN CONCAT('Resp', ELT(1 + FLOOR(RAND() * 3), 'ivent', 'iclear', 'ihale'), ' ', 50 * ROUND(RAND() * 4 + 1), 'mcg')
                WHEN 6 THEN CONCAT('Gastro', ELT(1 + FLOOR(RAND() * 3), 'zole', 'prol', 'tide'), ' ', 20 * ROUND(RAND() * 4 + 1), 'mg')
                WHEN 7 THEN CONCAT('Mental', ELT(1 + FLOOR(RAND() * 3), 'calm', 'peace', 'serene'), ' ', 10 * ROUND(RAND() * 4 + 1), 'mg')
                WHEN 8 THEN CONCAT('Allergy', ELT(1 + FLOOR(RAND() * 3), 'clear', 'stop', 'relief'), ' ', 5 * ROUND(RAND() * 4 + 1), 'mg')
                WHEN 9 THEN CONCAT('Vitamin', ELT(1 + FLOOR(RAND() * 3), ' B12', ' D3', ' C'), ' ', 1000 * ROUND(RAND() * 4 + 1), 'IU')
                ELSE CONCAT('FirstAid', ELT(1 + FLOOR(RAND() * 3), 'Kit', 'Pack', 'Set'), ' Type-', ROUND(RAND() * 3 + 1))
            END,
            CONCAT('Professional grade medicine from Vendor ', v_vendor_id),
            CASE WHEN c.category_id IN (2, 3, 4, 7) THEN TRUE ELSE FALSE END,
            TRUE,
            DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 365) DAY)
        FROM (
            SELECT c.*, ROW_NUMBER() OVER () as rn
            FROM categories c
            CROSS JOIN (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t
            WHERE c.is_active = TRUE
        ) c
        WHERE c.rn <= product_count;

        -- Add pricing for newly created products
        INSERT INTO product_pricing_history (
            product_id,
            price,
            cost_price,
            effective_from,
            effective_to
        )
        SELECT 
            p.product_id,
            ROUND(50 + (RAND() * 450), 2),
            ROUND(30 + (RAND() * 300), 2),
            p.created_at,
            NULL
        FROM products p
        WHERE p.vendor_id = v_vendor_id
        AND p.product_id NOT IN (SELECT product_id FROM product_pricing_history);

        -- Add inventory for new products
        INSERT INTO product_inventory (
            product_id,
            current_stock,
            last_updated
        )
        SELECT 
            p.product_id,
            FLOOR(100 + (RAND() * 900)),
            NOW()
        FROM products p
        WHERE p.vendor_id = v_vendor_id
        AND p.product_id NOT IN (SELECT product_id FROM product_inventory);
        
    END LOOP;
    
    CLOSE vendor_cursor;
    COMMIT;

    -- Show distribution
    SELECT 
        'Products per Vendor' as message,
        vendor_id,
        COUNT(*) as product_count
    FROM products
    GROUP BY vendor_id
    ORDER BY product_count DESC;
END //

DELIMITER ;

-- Execute the procedure
CALL generate_products_and_pricing();

-- Clean up
DROP PROCEDURE IF EXISTS generate_products_and_pricing;