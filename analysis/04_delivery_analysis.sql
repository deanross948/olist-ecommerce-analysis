-- ================================================================
-- ANALYSIS: Delivery Performance
-- Dataset: Olist Brazilian E-Commerce
-- Author: Dean
-- Description: Delivery tiering by delay severity, revenue at
--              risk from late orders, and on-time performance
-- ================================================================

USE olist_db;

-- Delivery performance tiered by delay severity
WITH delivery_status AS (
    SELECT 
        o.order_id,
        p.payment_value,
        DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        )                                           AS days_difference,
        CASE
            WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) < 0
                THEN 'Early Delivery'
            WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) = 0
                THEN 'On Time'
            WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) <= 3
                THEN 'Small Delay'
            WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) <= 7
                THEN 'Medium Delay'
            ELSE 'Large Delay'
        END AS delay_status
    FROM orders o
    JOIN order_payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
)
SELECT
    ds.delay_status,
    COUNT(*)                                                        AS total_orders,
    ROUND(SUM(ds.payment_value), 2)                                 AS total_revenue,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)             AS percentage
FROM delivery_status ds
GROUP BY ds.delay_status
ORDER BY total_orders DESC;

-- Late orders summary: count, revenue and pct of all delivered
WITH late_orders AS (
    SELECT 
        o.order_id,
        op.payment_value,
        DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        )                                           AS days_late
    FROM orders o
    JOIN order_payments op ON o.order_id = op.order_id
    WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date > o.order_estimated_delivery_date
)
SELECT 
    COUNT(*)                                                        AS late_orders,
    ROUND(SUM(payment_value), 2)                                    AS late_order_revenue,
    ROUND(COUNT(*) * 100.0 / (
        SELECT COUNT(*) FROM orders
        WHERE order_status = 'delivered'
    ), 2)                                                           AS pct_of_delivered
FROM late_orders;
