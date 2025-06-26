USE medical_ecommerce;

DELIMITER //

CREATE PROCEDURE generate_cart_data()
BEGIN
    -- Clear existing cart data
    TRUNCATE TABLE cart;
    
    -- Add random items to carts for about 20% of active customers
    INSERT INTO cart (customer_id, product_id, quantity)
    SELECT 
        u.user_id as customer_id,
        p.product_id,
        1 + FLOOR(RAND() * 3) as quantity  -- 1-3 items
    FROM users u
    JOIN user_roles ur ON u.user_id = ur.user_id
    CROSS JOIN (
        SELECT product_id 
        FROM products 
        WHERE is_active = TRUE
        ORDER BY RAND()
        LIMIT 1
    ) p
    WHERE ur.role_id = 1  -- customers only
    AND RAND() < 0.2      -- 20% of customers
    LIMIT 200;            -- reasonable number of cart items

    -- Add verification
    SELECT 
        'Cart Generation Summary' as message,
        COUNT(*) as total_cart_items,
        COUNT(DISTINCT customer_id) as customers_with_cart,
        AVG(quantity) as avg_quantity_per_item
    FROM cart;
END //

DELIMITER ;

-- Execute the procedure
CALL generate_cart_data();

-- Clean up
DROP PROCEDURE IF EXISTS generate_cart_data;