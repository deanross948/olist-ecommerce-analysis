-- ================================================================
-- ANALYSIS: Revenue Leakage Detection
-- Dataset: Olist Brazilian E-Commerce
-- Author: Dean
-- Description: Identifies revenue lost through cancellations,
--              failed deliveries and missing payment records
-- ================================================================

USE olist_db;

-- Revenue breakdown by order status
-- Quantifies how much revenue each status represents
WITH delivered_revenue AS (
    SELECT 
        o.order_status,
        COUNT(DISTINCT o.order_id)          AS total_orders,
        ROUND(SUM(op.payment_value), 2)     AS total_revenue
    FROM orders o
    JOIN order_payments op ON o.order_id = op.order_id
    GROUP BY o.order_status
),
total AS (
    SELECT ROUND(SUM(total_revenue), 2)     AS platform_total
    FROM delivered_revenue
)
SELECT 
    dr.order_status,
    dr.total_orders,
    dr.total_revenue,
    ROUND(dr.total_revenue / t.platform_total * 100, 2) AS revenue_share_pct,
    CASE
        WHEN dr.order_status = 'delivered'  THEN 'Completed Revenue'
        WHEN dr.order_status = 'canceled'   THEN 'Lost Revenue'
        WHEN dr.order_status = 'shipped'    THEN 'Revenue In Transit'
        ELSE 'Revenue At Risk'
    END                                                 AS revenue_classification
FROM delivered_revenue dr
CROSS JOIN total t
ORDER BY dr.total_revenue DESC;

-- Payment gap detection
-- Orders that exist but have no payment record
SELECT 
    COUNT(*)                                                    AS orders_without_payment,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2
    )                                                           AS pct_of_total_orders
FROM orders o
LEFT JOIN order_payments op ON o.order_id = op.order_id
WHERE op.order_id IS NULL;

-- Canceled order analysis by month
-- Shows when cancellation spikes occurred
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')            AS order_month,
    COUNT(*)                                                    AS canceled_orders,
    ROUND(SUM(op.payment_value), 2)                             AS canceled_revenue
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
WHERE o.order_status = 'canceled'
GROUP BY order_month
ORDER BY canceled_revenue DESC;

-- High value orders that were canceled or undelivered
-- These represent the biggest individual revenue losses
WITH lost_orders AS (
    SELECT 
        o.order_id,
        o.order_status,
        o.order_purchase_timestamp,
        ROUND(SUM(op.payment_value), 2)                         AS order_value
    FROM orders o
    JOIN order_payments op ON o.order_id = op.order_id
    WHERE o.order_status IN ('canceled', 'unavailable')
    GROUP BY o.order_id, o.order_status, o.order_purchase_timestamp
)
SELECT 
    order_id,
    order_status,
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m')              AS order_month,
    order_value,
    RANK() OVER (ORDER BY order_value DESC)                     AS loss_rank
FROM lost_orders
ORDER BY order_value DESC
LIMIT 20;

-- Total quantified leakage summary
SELECT 
    ROUND(SUM(CASE 
        WHEN o.order_status = 'canceled' 
        THEN op.payment_value END), 2)                          AS canceled_revenue,
    ROUND(SUM(CASE 
        WHEN o.order_status = 'unavailable' 
        THEN op.payment_value END), 2)                          AS unavailable_revenue,
    ROUND(SUM(CASE 
        WHEN o.order_status NOT IN ('delivered', 'shipped') 
        THEN op.payment_value END), 2)                          AS total_leakage,
    ROUND(SUM(op.payment_value), 2)                             AS total_platform_revenue,
    ROUND(SUM(CASE 
        WHEN o.order_status NOT IN ('delivered', 'shipped') 
        THEN op.payment_value END) * 100.0 / 
        SUM(op.payment_value), 2)                               AS leakage_pct
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id;
