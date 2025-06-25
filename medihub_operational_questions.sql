-- Operations Questions

-- 17. Database size
SELECT 
    TABLE_SCHEMA as 'Database',
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) as 'Size (MB)'
FROM information_schema.tables
WHERE table_schema = 'medical_ecommerce'
GROUP BY TABLE_SCHEMA;

-- 18. Database size by table (helps in query optimization)
SELECT 
    TABLE_NAME as 'Table',
    ROUND((data_length + index_length) / 1024 / 1024, 2) as 'Size (MB)'
FROM information_schema.tables
WHERE table_schema = 'medical_ecommerce'
ORDER BY (data_length + index_length) DESC;

-- 18. Query optimization examples for previous queries
-- Example: Optimizing customer orders query with EXPLAIN
EXPLAIN SELECT 
    customer_id,
    COUNT(DISTINCT order_id) as order_count
FROM orders 
WHERE created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH)
GROUP BY customer_id
HAVING order_count > 1;

-- Alternative optimized version using index
-- Note: This assumes we have proper indexes on created_at and customer_id
EXPLAIN SELECT 
    o.customer_id,
    COUNT(DISTINCT o.order_id) as order_count
FROM orders o
FORCE INDEX (idx_order_date)  -- Forces use of date index if available
WHERE o.created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH)
GROUP BY o.customer_id
HAVING order_count > 1;