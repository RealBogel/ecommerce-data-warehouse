DROP TABLE IF EXISTS dim_customer;

CREATE TABLE dim_customer (
    customer_key SERIAL PRIMARY KEY,
    customer_unique_id VARCHAR(32) UNIQUE NOT NULL,
    customer_city VARCHAR(100),
    customer_state VARCHAR(2)
);