USE medical_ecommerce;

-- 1. How many vendors registered?
SELECT COUNT(*) as registered_vendors 
FROM vendor_profiles;

-- 2. Number of active vs inactive vendors this month
SELECT 
    CASE ush.is_active 
        WHEN TRUE THEN 'Active' 
        ELSE 'Inactive' 
    END as status,
    COUNT(*) as count
FROM user_status_history ush
JOIN vendor_profiles vp ON ush.user_id = vp.vendor_id
WHERE status_month = DATE_FORMAT(CURRENT_DATE, '%Y-%m-01')
GROUP BY ush.is_active;

-- 3. How many customers registered from beginning?
SELECT COUNT(*) as total_customers
FROM user_roles
WHERE role_id = 1;  -- 1 = customer

-- 4. Vendor with most number listings
SELECT 
    vp.business_name,
    COUNT(p.product_id) as product_count
FROM vendor_profiles vp
JOIN products p ON vp.vendor_id = p.vendor_id
GROUP BY vp.vendor_id, vp.business_name
ORDER BY product_count DESC
LIMIT 1;

-- 5. Customer with greatest number of orders
SELECT 
    CONCAT(u.first_name, ' ', u.last_name) as customer_name,
    COUNT(*) as order_count
FROM users u
JOIN orders o ON u.user_id = o.customer_id
GROUP BY u.user_id
ORDER BY order_count DESC
LIMIT 1;

-- 6. Top 5 vendors by revenue - Jan, Feb, Mar
SELECT 
    vp.business_name,
    MONTHNAME(mm.month_date) as month,
    FORMAT(mm.revenue, 2) as revenue
FROM monthly_metrics mm
JOIN vendor_profiles vp ON mm.vendor_id = vp.vendor_id
WHERE MONTH(month_date) IN (1, 2, 3)
AND YEAR(month_date) = YEAR(CURRENT_DATE())
ORDER BY MONTH(month_date), mm.revenue DESC
LIMIT 5;

-- 7. Top 5 customers by revenue this year (Fixed - Monthly Comparison)
SELECT 
    MONTH(o.created_at) as month,
    CONCAT(u.first_name, ' ', u.last_name) as customer_name,
    FORMAT(SUM(o.total_amount), 2) as monthly_revenue
FROM users u
JOIN orders o ON u.user_id = o.customer_id
WHERE YEAR(o.created_at) = YEAR(CURRENT_DATE)
GROUP BY MONTH(o.created_at), u.user_id
HAVING SUM(o.total_amount) = (
    -- Get the highest revenue for each month
    SELECT SUM(o2.total_amount)
    FROM orders o2
    WHERE YEAR(o2.created_at) = YEAR(CURRENT_DATE)
    AND MONTH(o2.created_at) = MONTH(o.created_at)
    GROUP BY MONTH(o2.created_at), o2.customer_id
    ORDER BY SUM(o2.total_amount) DESC
    LIMIT 1
)
ORDER BY month
Limit 5;

-- 8. Revenue comparison last month vs last year same month
SELECT 
    DATE_FORMAT(month_date, '%Y-%m') as month,
    FORMAT(SUM(revenue), 2) as revenue
FROM monthly_metrics
WHERE month_date IN (
    DATE_FORMAT(DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH), '%Y-%m-01'),
    DATE_FORMAT(DATE_SUB(CURRENT_DATE, INTERVAL 13 MONTH), '%Y-%m-01')
)
GROUP BY month_date
ORDER BY month_date;

-- 9. Top 5 customers profitability vs revenue
SELECT 
    CONCAT(u.first_name, ' ', u.last_name) as customer_name,
    FORMAT(SUM(o.total_amount), 2) as revenue,
    FORMAT(SUM(o.total_amount - (oi.quantity * pph.cost_price)), 2) as profit
FROM users u
JOIN orders o ON u.user_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN product_pricing_history pph ON p.product_id = pph.product_id
GROUP BY u.user_id
ORDER BY profit DESC
LIMIT 5;

-- 10. Vendor with highest customer satisfaction rating
SELECT 
    vp.business_name,
    ROUND(AVG(r.rating), 2) as avg_rating,
    COUNT(r.review_id) as total_reviews
FROM vendor_profiles vp
JOIN products p ON vp.vendor_id = p.vendor_id
JOIN reviews r ON p.product_id = r.product_id
GROUP BY vp.vendor_id, vp.business_name
HAVING total_reviews >= 10  -- minimum reviews for reliability
ORDER BY avg_rating DESC
LIMIT 1;