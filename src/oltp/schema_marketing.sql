-- =====================================================
-- 3. MARKETING DATABASE (azko_marketing_db)
-- Dijalankan di MySQL (Railway / PlanetScale)
-- =====================================================

CREATE TABLE IF NOT EXISTS marketing_campaigns (
    campaign_id VARCHAR(10) PRIMARY KEY,
    campaign_name VARCHAR(150),
    campaign_type ENUM('Discount', 'Bundle', 'Cashback', 'Loyalty'),
    start_date DATE,
    end_date DATE,
    channel ENUM('Store', 'Instagram', 'Website', 'Email'),
    campaign_budget DECIMAL(15,2),
    target_segment VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS promotion_usage (
    promo_usage_id VARCHAR(15) PRIMARY KEY,
    campaign_id VARCHAR(10),
    transaction_id VARCHAR(15),
    customer_id VARCHAR(10),
    promo_code VARCHAR(50),
    discount_value DECIMAL(15,2),
    usage_date DATE,

    FOREIGN KEY (campaign_id) REFERENCES marketing_campaigns(campaign_id)
);

CREATE TABLE IF NOT EXISTS customer_feedback (
    feedback_id VARCHAR(15) PRIMARY KEY,
    customer_id VARCHAR(10),
    transaction_id VARCHAR(15),
    product_id VARCHAR(10),
    feedback_date DATE,
    rating INT,
    review_text TEXT,
    sentiment ENUM('Positive', 'Neutral', 'Negative'),
    feedback_channel ENUM('Website', 'App', 'Google Review', 'Social Media')
);
