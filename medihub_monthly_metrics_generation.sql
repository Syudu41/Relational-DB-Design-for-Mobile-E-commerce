USE medical_ecommerce;

-- Clear existing monthly metrics
TRUNCATE TABLE monthly_metrics;

-- Insert monthly metrics based on actual order data
INSERT INTO monthly_metrics (
    month_date,
    vendor_id,
    revenue,
    orders_count,
    total_cost
)
SELECT 
    DATE_FORMAT(o.created_at, '%Y-%m-01') as month_date,
    o.vendor_id,
    SUM(o.total_amount) as revenue,
    COUNT(DISTINCT o.order_id) as orders_count,
    SUM(
        oi.quantity * pph.cost_price
    ) as total_cost
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN product_pricing_history pph ON p.product_id = pph.product_id
WHERE pph.effective_to IS NULL  -- Get current price
GROUP BY 
    DATE_FORMAT(o.created_at, '%Y-%m-01'),
    o.vendor_id;

-- Verify the populated data
SELECT 
    'Monthly Metrics Summary' as message,
    COUNT(DISTINCT month_date) as unique_months,
    COUNT(DISTINCT vendor_id) as unique_vendors,
    FORMAT(SUM(revenue), 2) as total_revenue,
    FORMAT(SUM(total_cost), 2) as total_cost,
    SUM(orders_count) as total_orders
FROM monthly_metrics;

-- Show sample monthly data
SELECT 
    month_date,
    COUNT(DISTINCT vendor_id) as active_vendors,
    FORMAT(SUM(revenue), 2) as total_revenue,
    SUM(orders_count) as total_orders,
    FORMAT(SUM(total_cost), 2) as total_cost
FROM monthly_metrics
GROUP BY month_date
ORDER BY month_date DESC
LIMIT 12;