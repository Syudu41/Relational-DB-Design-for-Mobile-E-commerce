USE medical_ecommerce;

DELIMITER //

CREATE PROCEDURE generate_reviews()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE curr_order_id INT;
    DECLARE curr_customer_id INT;
    DECLARE curr_order_date TIMESTAMP;
    
    -- Declare cursor for delivered orders (status_id = 4)
    DECLARE review_cursor CURSOR FOR 
    SELECT 
        order_id,
        customer_id,
        created_at
    FROM orders 
    WHERE status_id = 4  -- Delivered orders
    ORDER BY created_at;
    
    -- Declare handler
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Clear existing reviews
    TRUNCATE TABLE reviews;
    
    START TRANSACTION;
    
    OPEN review_cursor;
    
    review_loop: LOOP
        FETCH review_cursor INTO curr_order_id, curr_customer_id, curr_order_date;
        IF done THEN
            LEAVE review_loop;
        END IF;
        
        -- 70% chance to review each product in order
        INSERT INTO reviews (
            order_id,
            product_id,
            user_id,
            rating,
            comment,
            created_at
        )
        SELECT DISTINCT
            curr_order_id,
            oi.product_id,
            curr_customer_id,
            CASE -- Weighted rating distribution
                WHEN RAND() < 0.4 THEN 5  -- 40% chance of 5 stars
                WHEN RAND() < 0.7 THEN 4  -- 30% chance of 4 stars
                WHEN RAND() < 0.9 THEN 3  -- 20% chance of 3 stars
                ELSE 1 + FLOOR(RAND() * 2) -- 10% chance of 1-2 stars
            END as rating,
            CASE 
                WHEN RAND() < 0.2 THEN NULL  -- 20% chance of no comment
                ELSE
                    CONCAT(
                        ELT(1 + FLOOR(RAND() * 5),
                            'Great product! ',
                            'Very effective. ',
                            'Good quality. ',
                            'Fast delivery. ',
                            'Recommended! '
                        ),
                        ELT(1 + FLOOR(RAND() * 5),
                            'Will order again.',
                            'Meets expectations.',
                            'Good packaging.',
                            'Fair price.',
                            'Satisfied with purchase.'
                        )
                    )
            END as comment,
            DATE_ADD(curr_order_date, 
                    INTERVAL FLOOR(RAND() * 7) DAY)  -- Review within 7 days of delivery
        FROM order_items oi
        WHERE oi.order_id = curr_order_id
        AND RAND() < 0.7;  -- 70% chance to review each item
        
        IF (curr_order_id % 100) = 0 THEN
            COMMIT;
            START TRANSACTION;
        END IF;
    END LOOP;
    
    CLOSE review_cursor;
    COMMIT;

    -- Verify generation
    SELECT 
        'Review Generation Summary' as message,
        (SELECT COUNT(*) FROM reviews) as total_reviews,
        (SELECT COUNT(DISTINCT user_id) FROM reviews) as unique_reviewers,
        (SELECT COUNT(DISTINCT product_id) FROM reviews) as products_reviewed,
        (SELECT ROUND(AVG(rating), 2) FROM reviews) as avg_rating,
        (SELECT COUNT(*) FROM reviews WHERE comment IS NOT NULL) as reviews_with_comments;
        
    -- Show rating distribution
    SELECT 
        'Rating Distribution' as message,
        rating,
        COUNT(*) as count,
        ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM reviews), 2) as percentage
    FROM reviews
    GROUP BY rating
    ORDER BY rating DESC;

    -- Show top reviewed products
    SELECT 
        'Most Reviewed Products (Top 5)' as message,
        r.product_id,
        p.name as product_name,
        COUNT(*) as review_count,
        ROUND(AVG(r.rating), 2) as avg_rating,
        COUNT(r.comment) as comments_count
    FROM reviews r
    JOIN products p ON r.product_id = p.product_id
    GROUP BY r.product_id, p.name
    ORDER BY review_count DESC
    LIMIT 5;
END //

DELIMITER ;

-- Execute the procedure
CALL generate_reviews();

-- Clean up
DROP PROCEDURE IF EXISTS generate_reviews;