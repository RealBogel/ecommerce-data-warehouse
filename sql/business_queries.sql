-- 1. Monthly Revenue and Order Volume
-- Shows how sales performance changes over time.

SELECT
    d.year,
    d.month,
    ROUND(SUM(f.price)::numeric, 2) AS revenue,
    COUNT(DISTINCT f.order_id) AS orders
FROM fact_sales f
JOIN dim_date d
    ON f.date_key = d.date_key
WHERE f.order_status = 'delivered'
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

-- 2. Top Product Categories by Revenue

SELECT
    p.product_category,
    ROUND(SUM(f.price)::numeric, 2) AS revenue,
    COUNT(DISTINCT f.order_id) AS orders
FROM fact_sales f
JOIN dim_product p
    ON f.product_key = p.product_key
WHERE f.order_status = 'delivered'
GROUP BY p.product_category
ORDER BY revenue DESC
LIMIT 10;

-- 3. Revenue by Customer State

SELECT
    c.customer_state,
    ROUND(SUM(f.price)::numeric, 2) AS revenue,
    COUNT(DISTINCT f.order_id) AS orders
FROM fact_sales f
JOIN dim_customer c
    ON f.customer_key = c.customer_key
WHERE f.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY revenue DESC;

-- 4. Top Sellers by Revenue

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    ROUND(SUM(f.price)::numeric, 2) AS revenue,
    COUNT(DISTINCT f.order_id) AS orders
FROM fact_sales f
JOIN dim_seller s
    ON f.seller_key = s.seller_key
WHERE f.order_status = 'delivered'
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
ORDER BY revenue DESC
LIMIT 10;

-- 5. Repeat Customer Analysis
-- Identifies customers who placed more than one delivered order.

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT f.order_id) AS order_count,
        ROUND(SUM(f.price)::numeric, 2) AS total_revenue
    FROM fact_sales f
    JOIN dim_customer c
        ON f.customer_key = c.customer_key
    WHERE f.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT
    customer_unique_id,
    order_count,
    total_revenue
FROM customer_orders
WHERE order_count > 1
ORDER BY order_count DESC, total_revenue DESC
LIMIT 20;