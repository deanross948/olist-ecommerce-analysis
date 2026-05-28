-- ================================================================
-- ANALYSIS: Revenue Overview
-- Dataset: Olist Brazilian E-Commerce
-- Author: Dean
-- Description: High level revenue breakdown by order status,
--              monthly revenue trends and cumulative growth
-- ================================================================

USE olist_db;

-- Revenue and order count by status
SELECT 
    order_status,
    COUNT(*)                        AS total_orders,
    ROUND(SUM(op.payment_value), 2) AS total_revenue
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
GROUP BY order_status
HAVING COUNT(*) > 1000
ORDER BY total_orders DESC;

-- Monthly revenue trend with cumulative running total
WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        ROUND(SUM(oi.price), 2)                          AS monthly_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY order_month
)
SELECT 
    order_month,
    monthly_revenue,
    ROUND(SUM(monthly_revenue) OVER (
        ORDER BY order_month
    ), 2)                                                AS cumulative_revenue
FROM monthly_revenue
ORDER BY order_month;

-- Revenue leakage by order status
WITH delivered_revenue AS (
    SELECT 
        o.order_status,
        COUNT(DISTINCT o.order_id)        AS total_orders,
        ROUND(SUM(op.payment_value), 2)   AS total_revenue
    FROM orders o
    JOIN order_payments op ON o.order_id = op.order_id
    GROUP BY o.order_status
),
total AS (
    SELECT ROUND(SUM(total_revenue), 2) AS platform_total
    FROM delivered_revenue
)
SELECT 
    dr.order_status,
    dr.total_orders,
    dr.total_revenue,
    ROUND(dr.total_revenue / t.platform_total * 100, 2) AS revenue_share_pct
FROM delivered_revenue dr
CROSS JOIN total t
ORDER BY dr.total_revenue DESC;

-- Orders with no payment record (payment gap detection)
SELECT 
    COUNT(*)                                                        AS orders_without_payment,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2)     AS pct_of_total
FROM orders o
LEFT JOIN order_payments op ON o.order_id = op.order_id
WHERE op.order_id IS NULL;
