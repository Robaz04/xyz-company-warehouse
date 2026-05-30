-- ═══════════════════════════════════════════════════════
-- AZKO DATA WAREHOUSE — Star Schema
-- Target: Neon.tech (PostgreSQL)
-- ═══════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════
-- DIMENSI
-- ═══════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS dim_time (
    time_key        SERIAL PRIMARY KEY,
    full_date       DATE NOT NULL,
    day             INT,
    month           INT,
    month_name      VARCHAR(20),
    quarter         INT,
    year            INT,
    week_of_year    INT,
    day_of_week     INT,
    day_name        VARCHAR(15),
    is_weekend      BOOLEAN
);

CREATE TABLE IF NOT EXISTS dim_product (
    product_key     SERIAL PRIMARY KEY,
    product_id      VARCHAR(10),        -- Natural Key dari OLTP
    product_name    VARCHAR(150),
    category        VARCHAR(100),
    brand           VARCHAR(100),
    unit_price      DECIMAL(15,2),
    cost_price      DECIMAL(15,2),
    product_status  VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS dim_customer (
    customer_key    SERIAL PRIMARY KEY,
    customer_id     VARCHAR(10),
    customer_name   VARCHAR(100),
    gender          VARCHAR(10),
    age             INT,
    age_group       VARCHAR(25),        -- Derived: Youth / Adult / Middle / Senior
    city            VARCHAR(100),
    membership_level VARCHAR(20),
    registration_date DATE
);

CREATE TABLE IF NOT EXISTS dim_store (
    store_key       SERIAL PRIMARY KEY,
    store_id        VARCHAR(10),
    store_name      VARCHAR(100),
    store_type      VARCHAR(30),
    city            VARCHAR(100),
    province        VARCHAR(100),
    region          VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS dim_supplier (
    supplier_key    SERIAL PRIMARY KEY,
    supplier_id     VARCHAR(10),
    supplier_name   VARCHAR(100),
    supplier_city   VARCHAR(100),
    supplier_category VARCHAR(100),
    supplier_status VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS dim_promotion (
    promotion_key   SERIAL PRIMARY KEY,
    campaign_id     VARCHAR(10),
    campaign_name   VARCHAR(150),
    campaign_type   VARCHAR(30),
    channel         VARCHAR(50),
    target_segment  VARCHAR(100),
    -- SCD Type 2
    effective_date  DATE,
    expiry_date     DATE,
    is_current      BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS dim_payment_method (
    payment_key     SERIAL PRIMARY KEY,
    payment_method  VARCHAR(30),
    payment_type    VARCHAR(20)         -- cash / digital / card
);

-- ═══════════════════════════════════════════════════════
-- FACT TABLE
-- ═══════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS fact_sales (
    sales_key       BIGSERIAL PRIMARY KEY,
    -- Foreign Keys ke Dimensi
    time_key        INT REFERENCES dim_time(time_key),
    product_key     INT REFERENCES dim_product(product_key),
    customer_key    INT REFERENCES dim_customer(customer_key),
    store_key       INT REFERENCES dim_store(store_key),
    promotion_key   INT REFERENCES dim_promotion(promotion_key),
    supplier_key    INT REFERENCES dim_supplier(supplier_key),
    payment_key     INT REFERENCES dim_payment_method(payment_key),
    -- Degenerate Dimension
    transaction_id  VARCHAR(15),
    detail_id       VARCHAR(15),
    -- Measures / Ukuran
    quantity_sold   INT,
    unit_price      DECIMAL(15,2),
    discount_amount DECIMAL(15,2),
    total_sales     DECIMAL(15,2),      -- sebelum diskon
    final_sales     DECIMAL(15,2),      -- setelah diskon
    cost_amount     DECIMAL(15,2),      -- modal
    gross_profit    DECIMAL(15,2)       -- final_sales - cost_amount
);

-- Index untuk performa query analitik
CREATE INDEX IF NOT EXISTS idx_fact_time     ON fact_sales(time_key);
CREATE INDEX IF NOT EXISTS idx_fact_product  ON fact_sales(product_key);
CREATE INDEX IF NOT EXISTS idx_fact_customer ON fact_sales(customer_key);
CREATE INDEX IF NOT EXISTS idx_fact_store    ON fact_sales(store_key);
