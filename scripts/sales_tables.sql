-- =====================================================
-- 1. SALES DATABASE
-- =====================================================
USE azko_sales_db;

CREATE TABLE customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    customer_name VARCHAR(100),
    gender ENUM('Male', 'Female'),
    age INT,
    city VARCHAR(100),
    membership_level ENUM('Regular', 'Silver', 'Gold', 'Platinum'),
    registration_date DATE
);

CREATE TABLE stores (
    store_id VARCHAR(10) PRIMARY KEY,
    store_name VARCHAR(100),
    store_type ENUM('Mall Store', 'Standalone Store'),
    city VARCHAR(100),
    province VARCHAR(100),
    region VARCHAR(50)
);

CREATE TABLE sales_transactions (
    transaction_id VARCHAR(15) PRIMARY KEY,
    transaction_date DATE,
    store_id VARCHAR(10),
    customer_id VARCHAR(10),
    employee_id VARCHAR(10),
    payment_method ENUM('Cash', 'Debit Card', 'Credit Card', 'E-Wallet', 'Bank Transfer'),
    total_amount DECIMAL(15,2),
    discount_amount DECIMAL(15,2),
    final_amount DECIMAL(15,2),
    transaction_status ENUM('Success', 'Cancelled', 'Returned'),

    FOREIGN KEY (store_id) REFERENCES stores(store_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE sales_transaction_details (
    detail_id VARCHAR(15) PRIMARY KEY,
    transaction_id VARCHAR(15),
    product_id VARCHAR(10),
    quantity INT,
    unit_price DECIMAL(15,2),
    discount_per_item DECIMAL(15,2),
    subtotal DECIMAL(15,2),

    FOREIGN KEY (transaction_id) REFERENCES sales_transactions(transaction_id)
);