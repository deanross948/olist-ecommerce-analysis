-- ================================================================
-- ANALYSIS: Seller Performance
-- Dataset: Olist Brazilian E-Commerce
-- Author: Dean
-- Description: Seller revenue rankings globally and by state,
--              top sellers per product category, platform share
-- ================================================================

USE olist_db;

-- Global seller revenue ranking with platform share
SELECT 
    seller_id,
    ROUND(SUM(price), 2)                                            AS total_revenue,
    CONCAT(ROUND(SUM(price) / SUM(SUM(price)) OVER () * 100, 2), '%') AS platform_share,
    ROW_NUMBER() OVER (ORDER BY SUM(price) DESC)                    AS row_num,
    RANK()       OVER (ORDER BY SUM(price) DESC)                    AS rank_num,
    DENSE_RANK() OVER (ORDER BY SUM(price) DESC)                    AS dense_rank_num
FROM order_items
GROUP BY seller_id
HAVING SUM(price) > 1000
ORDER BY total_revenue DESC;

-- Top 3 sellers by revenue per state
SELECT *
FROM (
    SELECT 
        RANK() OVER (
            PARTITION BY s.seller_state
            ORDER BY SUM(oi.price) DESC)    AS state_rank,
        s.seller_state,
        oi.seller_id,
        ROUND(SUM(oi.price), 2)             AS total_revenue
    FROM order_items oi
    JOIN sellers s ON oi.seller_id = s.seller_id
    GROUP BY oi.seller_id, s.seller_state
) ranked
WHERE state_rank <= 3
ORDER BY seller_state ASC, state_rank ASC;

-- Top seller per product category
SELECT *
FROM (
    SELECT 
        p.product_category_name,
        oi.seller_id,
        ROUND(SUM(oi.price), 2)             AS category_revenue,
        RANK() OVER (
            PARTITION BY p.product_category_name
            ORDER BY SUM(oi.price) DESC
        )                                   AS category_rank
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    WHERE p.product_category_name IS NOT NULL
    GROUP BY p.product_category_name, oi.seller_id
) ranked
WHERE category_rank = 1
ORDER BY category_revenue DESC
LIMIT 15;

-- Top 10 revenue generating product categories
SELECT 
    p.product_category_name,
    COUNT(DISTINCT oi.order_id)             AS total_orders,
    ROUND(SUM(oi.price), 2)                 AS total_revenue,
    ROUND(AVG(oi.price), 2)                 AS avg_order_value
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
WHERE p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
ORDER BY total_revenue DESC
LIMIT 10;
