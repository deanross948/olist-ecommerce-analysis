-- ================================================================
-- ANALYSIS: Customer Retention & Cohort Analysis
-- Dataset: Olist Brazilian E-Commerce
-- Author: Dean
-- Description: Cohort-based retention tracking and customer
--              lifetime value analysis to identify retention risk
-- ================================================================

USE olist_db;

-- Customer cohort retention analysis
-- Groups customers by first purchase month and tracks
-- how many return in subsequent months
WITH 
first_purchase AS (
    SELECT 
        c.customer_unique_id,
        MIN(DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')) AS cohort_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
all_orders AS (
    SELECT 
        c.customer_unique_id,
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')      AS order_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
cohort_index AS (
    SELECT 
        fp.cohort_month,
        ao.order_month,
        COUNT(DISTINCT ao.customer_unique_id)                 AS active_customers,
        PERIOD_DIFF(
            REPLACE(ao.order_month, '-', ''),
            REPLACE(fp.cohort_month, '-', '')
        )                                                     AS month_number
    FROM first_purchase fp
    JOIN all_orders ao ON fp.customer_unique_id = ao.customer_unique_id
    GROUP BY fp.cohort_month, ao.order_month
)
SELECT 
    cohort_month,
    month_number,
    active_customers
FROM cohort_index
WHERE month_number >= 0
ORDER BY cohort_month, month_number;

-- Cohort size per month (denominator for retention rate)
-- Use this alongside the above to calculate retention %
WITH first_purchase AS (
    SELECT 
        c.customer_unique_id,
        MIN(DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')) AS cohort_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    cohort_month,
    COUNT(DISTINCT customer_unique_id)                        AS cohort_size
FROM first_purchase
GROUP BY cohort_month
ORDER BY cohort_month;

-- Customer lifetime value estimation
-- Estimates CLV using avg order value x frequency x lifespan
WITH customer_stats AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id)                            AS total_orders,
        ROUND(SUM(op.payment_value), 2)                       AS total_spent,
        ROUND(AVG(op.payment_value), 2)                       AS avg_order_value,
        MIN(o.order_purchase_timestamp)                       AS first_order,
        MAX(o.order_purchase_timestamp)                       AS last_order,
        DATEDIFF(
            MAX(o.order_purchase_timestamp),
            MIN(o.order_purchase_timestamp)
        ) / 30                                                AS lifespan_months
    FROM customers c
    JOIN orders o          ON c.customer_id = o.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
clv_calc AS (
    SELECT 
        customer_unique_id,
        total_orders,
        total_spent,
        avg_order_value,
        ROUND(lifespan_months, 1)                             AS lifespan_months,
        ROUND(
            avg_order_value * total_orders *
            GREATEST(lifespan_months, 1), 2
        )                                                     AS estimated_clv
    FROM customer_stats
)
SELECT 
    customer_unique_id,
    total_orders,
    total_spent,
    avg_order_value,
    lifespan_months,
    estimated_clv,
    CASE
        WHEN estimated_clv >= 10000 THEN 'Platinum'
        WHEN estimated_clv >= 5000  THEN 'Gold'
        WHEN estimated_clv >= 1000  THEN 'Silver'
        ELSE 'Bronze'
    END                                                       AS clv_tier
FROM clv_calc
ORDER BY estimated_clv DESC
LIMIT 50;
