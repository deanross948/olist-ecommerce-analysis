-- ================================================================
-- ANALYSIS: Customer Segmentation
-- Dataset: Olist Brazilian E-Commerce
-- Author: Dean
-- Description: Customer value tiering, repeat purchaser analysis,
--              and customer lifetime value estimation
-- ================================================================

USE olist_db;

-- Repeat customers: customers with more than one order
WITH order_spend AS (
    SELECT 
        order_id,
        SUM(payment_value) AS total_spent
    FROM order_payments
    GROUP BY order_id
)
SELECT 
    c.customer_unique_id,
    COUNT(o.order_id)               AS total_orders,
    ROUND(SUM(os.total_spent), 2)   AS total_spent
FROM customers c
JOIN orders o       ON c.customer_id = o.customer_id
JOIN order_spend os ON o.order_id = os.order_id
GROUP BY c.customer_unique_id
HAVING COUNT(o.order_id) > 1
ORDER BY total_spent DESC;

-- Customer value tier segmentation
WITH customer_amount AS (
    SELECT
        c.customer_unique_id,
        SUM(p.payment_value) AS total_spend,
        CASE
            WHEN SUM(p.payment_value) < 0   THEN 'Early Delivery'
            WHEN SUM(p.payment_value) <= 100 THEN 'Low Value'
            WHEN SUM(p.payment_value) <= 500 THEN 'Mid Value'
            ELSE 'High Value'
        END AS value_tier
    FROM order_payments p
    JOIN orders o     ON p.order_id = o.order_id
    JOIN customers c  ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT 
    value_tier,
    COUNT(*)                                                        AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)             AS percentage
FROM customer_amount
GROUP BY value_tier
ORDER BY total_customers DESC;

-- Customer lifetime value estimation
WITH customer_stats AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id)                  AS total_orders,
        ROUND(SUM(op.payment_value), 2)             AS total_spent,
        ROUND(AVG(op.payment_value), 2)             AS avg_order_value,
        MIN(o.order_purchase_timestamp)             AS first_order,
        MAX(o.order_purchase_timestamp)             AS last_order,
        DATEDIFF(
            MAX(o.order_purchase_timestamp),
            MIN(o.order_purchase_timestamp)
        ) / 30                                      AS lifespan_months
    FROM customers c
    JOIN orders o           ON c.customer_id = o.customer_id
    JOIN order_payments op  ON o.order_id = op.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    customer_unique_id,
    total_orders,
    total_spent,
    avg_order_value,
    ROUND(lifespan_months, 1)                       AS lifespan_months,
    ROUND(
        avg_order_value * total_orders *
        GREATEST(lifespan_months, 1), 2
    )                                               AS estimated_clv
FROM customer_stats
ORDER BY estimated_clv DESC
LIMIT 20;
