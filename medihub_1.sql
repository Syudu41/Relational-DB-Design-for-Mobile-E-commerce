DROP DATABASE IF EXISTS medical_ecommerce;
CREATE DATABASE medical_ecommerce;
USE medical_ecommerce;

-- =============================================
-- 1. Base Configuration Tables
-- =============================================

-- Roles for user type definition
CREATE TABLE roles (
    role_id INT PRIMARY KEY AUTO_INCREMENT,
    role_name VARCHAR(20) NOT NULL UNIQUE
);

-- Initial roles
INSERT INTO roles (role_name) VALUES ('customer'), ('vendor');

-- Order status definitions
CREATE TABLE order_statuses (
    status_id INT PRIMARY KEY AUTO_INCREMENT,
    status_name VARCHAR(20) NOT NULL UNIQUE
);

-- Initial order statuses
INSERT INTO order_statuses (status_name) 
VALUES ('pending'), ('processing'), ('shipped'), ('delivered'), ('cancelled');

-- =============================================
-- 2. Location Management Tables
-- Hierarchical structure for addresses
-- =============================================

CREATE TABLE countries (
    country_id INT PRIMARY KEY AUTO_INCREMENT,
    country_name VARCHAR(50) NOT NULL
);

CREATE TABLE states (
    state_id INT PRIMARY KEY AUTO_INCREMENT,
    country_id INT NOT NULL,
    state_name VARCHAR(50) NOT NULL,
    FOREIGN KEY (country_id) REFERENCES countries(country_id)
);

CREATE TABLE cities (
    city_id INT PRIMARY KEY AUTO_INCREMENT,
    state_id INT NOT NULL,
    city_name VARCHAR(50) NOT NULL,
    FOREIGN KEY (state_id) REFERENCES states(state_id)
);

CREATE TABLE addresses (
    address_id INT PRIMARY KEY AUTO_INCREMENT,
    street_number VARCHAR(20) NOT NULL,
    street_name VARCHAR(100) NOT NULL,
    postal_code VARCHAR(10) NOT NULL,
    city_id INT NOT NULL,
    FOREIGN KEY (city_id) REFERENCES cities(city_id)
);

-- =============================================
-- 3. Core User Management Tables
-- =============================================

-- Base user information
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(64) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- User status tracking by month
CREATE TABLE user_status_history (
    user_id INT,
    status_month DATE,
    is_active BOOLEAN,
    PRIMARY KEY (user_id, status_month),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- User contact details
CREATE TABLE user_contacts (
    user_id INT PRIMARY KEY,
    phone VARCHAR(15) NOT NULL,
    primary_address_id INT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (primary_address_id) REFERENCES addresses(address_id)
);

-- User role assignments
CREATE TABLE user_roles (
    user_id INT,
    role_id INT,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (role_id) REFERENCES roles(role_id)
);

-- =============================================
-- 4. Vendor Management Tables
-- =============================================

CREATE TABLE vendor_profiles (
    vendor_id INT PRIMARY KEY,
    business_name VARCHAR(100) NOT NULL,
    license_number VARCHAR(50) NOT NULL UNIQUE,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (vendor_id) REFERENCES users(user_id)
);

-- =============================================
-- 5. Product Management Tables
-- =============================================

-- Product categories
CREATE TABLE categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE
);

-- Core product information
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    vendor_id INT NOT NULL,
    category_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    requires_prescription BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vendor_id) REFERENCES vendor_profiles(vendor_id),
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

-- Product pricing history
CREATE TABLE product_pricing_history (
    pricing_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    cost_price DECIMAL(10,2) NOT NULL,
    effective_from TIMESTAMP NOT NULL,
    effective_to TIMESTAMP NULL,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Product inventory tracking
CREATE TABLE product_inventory (
    product_id INT PRIMARY KEY,
    current_stock INT NOT NULL DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- =============================================
-- 6. Prescription Management Tables
-- =============================================

-- Doctor information
CREATE TABLE doctors (
    doctor_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    license_number VARCHAR(50) NOT NULL UNIQUE
);

-- Prescription records
CREATE TABLE prescriptions (
    prescription_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    doctor_id INT NOT NULL,
    issued_date DATE NOT NULL,
    valid_until DATE NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
);

-- =============================================
-- 7. Order Management Tables
-- =============================================

-- Order header information
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    vendor_id INT NOT NULL,
    status_id INT NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES users(user_id),
    FOREIGN KEY (vendor_id) REFERENCES vendor_profiles(vendor_id),
    FOREIGN KEY (status_id) REFERENCES order_statuses(status_id)
);

-- Order line items
CREATE TABLE order_items (
    order_id INT,
    product_id INT,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    prescription_id INT NULL,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescription_id)
);

-- =============================================
-- 8. Review System
-- =============================================

CREATE TABLE reviews (
    review_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    user_id INT NOT NULL,
    rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    UNIQUE INDEX idx_order_product_user (order_id, product_id, user_id)
);

-- =============================================
-- 9. Analytics and Reporting
-- =============================================

-- Monthly vendor metrics
CREATE TABLE monthly_metrics (
    month_date DATE,
    vendor_id INT,
    revenue DECIMAL(12,2) DEFAULT 0,
    orders_count INT DEFAULT 0,
    total_cost DECIMAL(12,2) DEFAULT 0,
    PRIMARY KEY (month_date, vendor_id),
    FOREIGN KEY (vendor_id) REFERENCES vendor_profiles(vendor_id)
);

-- =============================================
-- 10. Views for Common Data Access
-- =============================================

-- Current product prices view
CREATE VIEW current_product_prices AS
SELECT 
    p.product_id, 
    p.name, 
    pph.price, 
    pph.cost_price,
    pi.current_stock
FROM products p
JOIN product_pricing_history pph ON p.product_id = pph.product_id
LEFT JOIN product_inventory pi ON p.product_id = pi.product_id
WHERE pph.effective_to IS NULL;

-- Vendor ratings view
CREATE VIEW vendor_ratings AS
SELECT 
    v.vendor_id,
    v.business_name,
    COALESCE(AVG(r.rating), 0) as average_rating,
    COUNT(r.review_id) as total_reviews
FROM vendor_profiles v
LEFT JOIN products p ON v.vendor_id = p.vendor_id
LEFT JOIN reviews r ON p.product_id = r.product_id
GROUP BY v.vendor_id, v.business_name;

-- =============================================
-- 11. Indexes for Performance Optimization
-- =============================================

CREATE INDEX idx_product_vendor ON products(vendor_id);
CREATE INDEX idx_product_category ON products(category_id);
CREATE INDEX idx_order_customer ON orders(customer_id);
CREATE INDEX idx_order_vendor ON orders(vendor_id);
CREATE INDEX idx_order_status ON orders(status_id);
CREATE INDEX idx_order_date ON orders(created_at);
CREATE INDEX idx_review_product ON reviews(product_id);
CREATE INDEX idx_review_user ON reviews(user_id);