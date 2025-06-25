USE medical_ecommerce;

DELIMITER //

CREATE PROCEDURE generate_orders(IN num_orders INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE batch_size INT DEFAULT 100;
    DECLARE orders_created INT DEFAULT 0;
    DECLARE order_date TIMESTAMP;
    DECLARE items_for_order INT;
    
    -- Clear existing order data
    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE order_items;
    TRUNCATE TABLE orders;
    SET FOREIGN_KEY_CHECKS = 1;
    
    START TRANSACTION;
    
    WHILE i <= num_orders DO
        -- Modified: Generate order date within last two years
        SET order_date = DATE_SUB(CURRENT_DATE, 
            INTERVAL (FLOOR(RAND() * 24) * 30 + FLOOR(RAND() * 30)) DAY);
        
        -- Rest of the code remains same as before
        SET items_for_order = 1 + FLOOR(RAND() * 3);
        
        -- Select random customer
        SET @customer_id = (
            SELECT user_id 
            FROM user_roles 
            WHERE role_id = (SELECT role_id FROM roles WHERE role_name = 'customer')
            ORDER BY RAND() 
            LIMIT 1
        );
        
        -- Select random vendor who has products
        SET @vendor_id = (
            SELECT DISTINCT vendor_id 
            FROM products p
            WHERE is_active = TRUE
            AND EXISTS (
                SELECT 1 
                FROM product_inventory pi 
                WHERE pi.product_id = p.product_id 
                AND pi.current_stock > 0
            )
            ORDER BY RAND() 
            LIMIT 1
        );
        
        -- Create order
        INSERT INTO orders (
            customer_id,
            vendor_id,
            status_id,
            total_amount,
            created_at
        ) VALUES (
            @customer_id,
            @vendor_id,
            FLOOR(1 + RAND() * 4), -- Random status (1-4)
            0, -- Will update after adding items
            order_date
        );
        
        SET @order_id = LAST_INSERT_ID();
        
        -- Add items from this vendor's available products
        INSERT INTO order_items (
            order_id,
            product_id,
            quantity,
            unit_price
        )
        SELECT 
            @order_id,
            p.product_id,
            1 + FLOOR(RAND() * 3), -- Quantity 1-3
            pph.price
        FROM products p
        JOIN product_inventory pi ON p.product_id = pi.product_id
        JOIN product_pricing_history pph ON p.product_id = pph.product_id
        WHERE p.vendor_id = @vendor_id
        AND p.is_active = TRUE
        AND pi.current_stock > 0
        AND pph.effective_to IS NULL
        ORDER BY RAND()
        LIMIT items_for_order;
        
        -- Update order total
        UPDATE orders 
        SET total_amount = (
            SELECT SUM(quantity * unit_price)
            FROM order_items
            WHERE order_id = @order_id
        )
        WHERE order_id = @order_id;
        
        -- Update inventory
        UPDATE product_inventory pi
        JOIN order_items oi ON pi.product_id = oi.product_id
        SET pi.current_stock = pi.current_stock - oi.quantity,
            pi.last_updated = NOW()
        WHERE oi.order_id = @order_id;
        
        SET orders_created = orders_created + 1;
        
        IF orders_created >= batch_size THEN
            COMMIT;
            START TRANSACTION;
            SET orders_created = 0;
        END IF;
        
        SET i = i + 1;
    END WHILE;
    
    COMMIT;

    -- Verify generation
    SELECT 
        'Order Generation Summary' as message,
        (SELECT COUNT(*) FROM orders) as total_orders,
        (SELECT COUNT(DISTINCT customer_id) FROM orders) as unique_customers,
        (SELECT COUNT(DISTINCT vendor_id) FROM orders) as unique_vendors,
        (SELECT COUNT(*) FROM order_items) as total_order_items,
        (SELECT ROUND(AVG(total_amount), 2) FROM orders) as avg_order_amount;

    -- Show orders distribution across vendors
    SELECT 
        'Orders per Vendor' as message,
        vendor_id,
        COUNT(*) as order_count,
        COUNT(DISTINCT customer_id) as unique_customers,
        ROUND(AVG(total_amount), 2) as avg_order_amount
    FROM orders
    GROUP BY vendor_id
    ORDER BY order_count DESC
    LIMIT 5;
END //

DELIMITER ;

-- Execute the procedure
CALL generate_orders(5000);

-- Clean up
DROP PROCEDURE IF EXISTS generate_orders;