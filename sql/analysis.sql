-- ============================================================
-- 1. MONTHLY REVENUE AND ORDERS
-- ============================================================

SELECT
    d.year,
    d.month,
    ROUND(SUM(f.price), 2) AS revenue,
    COUNT(DISTINCT f.order_id) AS orders
FROM fact_sales f
JOIN dim_date d
    ON f.date_key = d.date_key
WHERE f.order_status = 'delivered'
GROUP BY d.year, d.month
ORDER BY d.year, d.month;


-- ============================================================
-- 2. TOP 10 PRODUCT CATEGORIES BY REVENUE
-- ============================================================

SELECT
    p.product_category,
    ROUND(SUM(f.price), 2) AS revenue,
    COUNT(*) AS items_sold
FROM fact_sales f
JOIN dim_product p
    ON f.product_key = p.product_key
WHERE f.order_status = 'delivered'
GROUP BY p.product_category
ORDER BY revenue DESC
LIMIT 10;


-- ============================================================
-- 3. SALES BY CUSTOMER STATE
-- ============================================================

SELECT
    c.customer_state,
    ROUND(SUM(f.price), 2) AS revenue,
    COUNT(DISTINCT f.order_id) AS orders,
    COUNT(DISTINCT f.customer_key) AS customers
FROM fact_sales f
JOIN dim_customer c
    ON f.customer_key = c.customer_key
WHERE f.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY revenue DESC;


-- ============================================================
-- 4. REPEAT CUSTOMER BEHAVIOR
-- ============================================================

WITH customer_orders AS (
    SELECT
        customer_key,
        COUNT(DISTINCT order_id) AS order_count
    FROM fact_sales
    WHERE order_status = 'delivered'
    GROUP BY customer_key
)

SELECT
    CASE
        WHEN order_count = 1 THEN 'One-time customer'
        ELSE 'Repeat customer'
    END AS customer_type,
    COUNT(*) AS customers
FROM customer_orders
GROUP BY customer_type
ORDER BY customers DESC;


-- ============================================================
-- 5. AVERAGE ORDER VALUE
-- ============================================================

WITH order_totals AS (
    SELECT
        order_id,
        SUM(price) AS order_value
    FROM fact_sales
    WHERE order_status = 'delivered'
    GROUP BY order_id
)

SELECT
    ROUND(AVG(order_value), 2) AS average_order_value
FROM order_totals;


-- ============================================================
-- 6. TOP 10 SELLERS BY REVENUE
-- ============================================================

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    ROUND(SUM(f.price), 2) AS revenue,
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


-- ============================================================
-- 7. PAYMENT METHOD BREAKDOWN
-- ============================================================

SELECT
    payment_type,
    COUNT(*) AS payment_records,
    ROUND(SUM(payment_value), 2) AS payment_value
FROM fact_payments
GROUP BY payment_type
ORDER BY payment_value DESC;


-- ============================================================
-- 8. AVERAGE FREIGHT COST BY PRODUCT CATEGORY
-- ============================================================

SELECT
    p.product_category,
    ROUND(AVG(f.freight_value), 2) AS avg_freight_cost,
    COUNT(*) AS items_sold
FROM fact_sales f
JOIN dim_product p
    ON f.product_key = p.product_key
WHERE f.order_status = 'delivered'
GROUP BY p.product_category
HAVING COUNT(*) >= 100
ORDER BY avg_freight_cost DESC
LIMIT 10;