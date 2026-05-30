-- =====================================================
-- 2. WAREHOUSE AND LOGISTICS DATABASE
-- =====================================================
USE azko_warehouse_db;

CREATE TABLE suppliers (
    supplier_id VARCHAR(10) PRIMARY KEY,
    supplier_name VARCHAR(100),
    supplier_city VARCHAR(100),
    supplier_category VARCHAR(100),
    contact_person VARCHAR(100),
    supplier_status ENUM('Active', 'Inactive')
);

CREATE TABLE products (
    product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(150),
    category VARCHAR(100),
    brand VARCHAR(100),
    supplier_id VARCHAR(10),
    unit_price DECIMAL(15,2),
    cost_price DECIMAL(15,2),
    product_status ENUM('Active', 'Discontinued'),

    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
);

CREATE TABLE inventory_stock (
    stock_id VARCHAR(15) PRIMARY KEY,
    product_id VARCHAR(10),
    store_id VARCHAR(10),
    stock_date DATE,
    beginning_stock INT,
    stock_in INT,
    stock_out INT,
    ending_stock INT,
    stock_status ENUM('Safe', 'Low', 'Out of Stock'),

    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE shipments (
    shipment_id VARCHAR(15) PRIMARY KEY,
    shipment_date DATE,
    source_location VARCHAR(100),
    destination_store_id VARCHAR(10),
    product_id VARCHAR(10),
    quantity_shipped INT,
    shipping_cost DECIMAL(15,2),
    shipment_status ENUM('Delivered', 'Delayed', 'Cancelled'),

    FOREIGN KEY (product_id) REFERENCES products(product_id)
);