-- Customer Questions
USE medical_ecommerce;
-- 11. Most expensive order among my orders
SELECT 
    order_id,
    FORMAT(total_amount, 2) as amount
FROM orders 
WHERE customer_id = 56
ORDER BY total_amount DESC
LIMIT 2;

-- 12. How many orders did I place?
SELECT COUNT(*) as total_orders
FROM orders 
WHERE customer_id = 56;

-- 13. Total historical spend YTD
SELECT FORMAT(SUM(total_amount), 2) as total_spent
FROM orders
WHERE customer_id = 56
AND YEAR(created_at) = YEAR(CURRENT_DATE());

-- 14. Customer expenditure trend
SELECT 
    DATE_FORMAT(created_at, '%Y-%m') as month,
    FORMAT(SUM(total_amount), 2) as monthly_spent
FROM orders
WHERE customer_id = 56
GROUP BY DATE_FORMAT(created_at, '%Y-%m')
ORDER BY month;

-- 15. Top 3 customers by orders last month
SELECT 
    u.first_name,
    u.last_name,
    COUNT(*) as order_count
FROM orders o
JOIN users u ON o.customer_id = u.user_id
WHERE MONTH(o.created_at) = MONTH(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH))
AND YEAR(o.created_at) = YEAR(CURRENT_DATE())
GROUP BY u.user_id, u.first_name, u.last_name
ORDER BY order_count DESC
LIMIT 3;

-- 16. Customers with repeated orders in last 3 months
SELECT 
    u.first_name,
    u.last_name,
    COUNT(*) as order_count
FROM orders o
JOIN users u ON o.customer_id = u.user_id
WHERE o.created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH)
GROUP BY o.customer_id, u.first_name, u.last_name
HAVING COUNT(*) > 1
ORDER BY order_count DESC;

-- Count (Q16)
SELECT COUNT(DISTINCT customer_id) as repeat_customers
FROM (
    SELECT customer_id
    FROM orders
    WHERE created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH)
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) as repeats;