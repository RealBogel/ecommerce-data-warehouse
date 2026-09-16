-- ============================================================
-- OLIST E-COMMERCE ANALYTICS WAREHOUSE
-- ============================================================


-- ------------------------------------------------------------
-- Clean up existing warehouse tables
-- ------------------------------------------------------------

DROP TABLE IF EXISTS fact_payments;
DROP TABLE IF EXISTS fact_sales;
DROP TABLE IF EXISTS dim_date;
DROP TABLE IF EXISTS dim_seller;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_customer;


-- ============================================================
-- DIMENSION: CUSTOMER
-- One row per unique customer
-- ============================================================

CREATE TABLE dim_customer (
    customer_key SERIAL PRIMARY KEY,
    customer_unique_id VARCHAR(32) UNIQUE NOT NULL,
    customer_city VARCHAR(100),
    customer_state VARCHAR(2)
);

INSERT INTO dim_customer (
    customer_unique_id,
    customer_city,
    customer_state
)
SELECT DISTINCT ON (customer_unique_id)
    customer_unique_id,
    customer_city,
    customer_state
FROM stg_customers
ORDER BY customer_unique_id, customer_id;


-- ============================================================
-- DIMENSION: PRODUCT
-- One row per product
-- ============================================================

CREATE TABLE dim_product (
    product_key SERIAL PRIMARY KEY,
    product_id VARCHAR(32) UNIQUE NOT NULL,
    product_category VARCHAR(100),
    product_weight_g NUMERIC,
    product_length_cm NUMERIC,
    product_height_cm NUMERIC,
    product_width_cm NUMERIC
);

INSERT INTO dim_product (
    product_id,
    product_category,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
SELECT
    p.product_id,
    COALESCE(t.product_category_name_english, p.product_category_name),
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM stg_products p
LEFT JOIN stg_category_translation t
    ON p.product_category_name = t.product_category_name;


-- ============================================================
-- DIMENSION: SELLER
-- One row per seller
-- ============================================================

CREATE TABLE dim_seller (
    seller_key SERIAL PRIMARY KEY,
    seller_id VARCHAR(32) UNIQUE NOT NULL,
    seller_city VARCHAR(100),
    seller_state VARCHAR(2)
);

INSERT INTO dim_seller (
    seller_id,
    seller_city,
    seller_state
)
SELECT
    seller_id,
    seller_city,
    seller_state
FROM stg_sellers;


-- ============================================================
-- DIMENSION: DATE
-- One row per purchase date
-- ============================================================

CREATE TABLE dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE UNIQUE NOT NULL,
    year INTEGER,
    quarter INTEGER,
    month INTEGER,
    month_name VARCHAR(20),
    day INTEGER,
    day_of_week VARCHAR(20)
);

INSERT INTO dim_date
SELECT
    TO_CHAR(full_date, 'YYYYMMDD')::INTEGER AS date_key,
    full_date,
    EXTRACT(YEAR FROM full_date)::INTEGER,
    EXTRACT(QUARTER FROM full_date)::INTEGER,
    EXTRACT(MONTH FROM full_date)::INTEGER,
    TO_CHAR(full_date, 'Month'),
    EXTRACT(DAY FROM full_date)::INTEGER,
    TO_CHAR(full_date, 'Day')
FROM (
    SELECT DISTINCT
        order_purchase_timestamp::TIMESTAMP::DATE AS full_date
    FROM stg_orders
) dates;


-- ============================================================
-- FACT: SALES
-- Grain: one row per order item
-- ============================================================

CREATE TABLE fact_sales (
    sales_key SERIAL PRIMARY KEY,

    order_id VARCHAR(32) NOT NULL,
    order_item_id INTEGER NOT NULL,

    customer_key INTEGER REFERENCES dim_customer(customer_key),
    product_key INTEGER REFERENCES dim_product(product_key),
    seller_key INTEGER REFERENCES dim_seller(seller_key),
    date_key INTEGER REFERENCES dim_date(date_key),

    order_status VARCHAR(20),

    price NUMERIC(12,2),
    freight_value NUMERIC(12,2)
);

INSERT INTO fact_sales (
    order_id,
    order_item_id,
    customer_key,
    product_key,
    seller_key,
    date_key,
    order_status,
    price,
    freight_value
)
SELECT
    oi.order_id,
    oi.order_item_id,

    dc.customer_key,
    dp.product_key,
    ds.seller_key,
    dd.date_key,

    o.order_status,
    oi.price,
    oi.freight_value

FROM stg_order_items oi

JOIN stg_orders o
    ON oi.order_id = o.order_id

JOIN stg_customers c
    ON o.customer_id = c.customer_id

LEFT JOIN dim_customer dc
    ON c.customer_unique_id = dc.customer_unique_id

LEFT JOIN dim_product dp
    ON oi.product_id = dp.product_id

LEFT JOIN dim_seller ds
    ON oi.seller_id = ds.seller_id

LEFT JOIN dim_date dd
    ON o.order_purchase_timestamp::TIMESTAMP::DATE = dd.full_date;


-- ============================================================
-- FACT: PAYMENTS
-- Grain: one row per payment record
-- ============================================================

CREATE TABLE fact_payments (
    payment_key SERIAL PRIMARY KEY,

    order_id VARCHAR(32) NOT NULL,
    payment_sequential INTEGER,

    payment_type VARCHAR(50),
    payment_installments INTEGER,
    payment_value NUMERIC(12,2)
);

INSERT INTO fact_payments (
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
)
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM stg_payments;