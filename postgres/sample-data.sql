-- Sample data for CDC streaming pipeline demonstration
-- This script populates the database with realistic e-commerce data

-- Insert sample customers
INSERT INTO public.customers (first_name, last_name, email, phone, address, city, state, zip_code, country) VALUES
('John', 'Smith', 'john.smith@email.com', '555-0101', '123 Main St', 'New York', 'NY', '10001', 'USA'),
('Sarah', 'Johnson', 'sarah.johnson@email.com', '555-0102', '456 Oak Ave', 'Los Angeles', 'CA', '90210', 'USA'),
('Michael', 'Brown', 'michael.brown@email.com', '555-0103', '789 Pine Rd', 'Chicago', 'IL', '60601', 'USA'),
('Emily', 'Davis', 'emily.davis@email.com', '555-0104', '321 Elm St', 'Houston', 'TX', '77001', 'USA'),
('David', 'Wilson', 'david.wilson@email.com', '555-0105', '654 Maple Dr', 'Phoenix', 'AZ', '85001', 'USA'),
('Jessica', 'Miller', 'jessica.miller@email.com', '555-0106', '987 Cedar Ln', 'Philadelphia', 'PA', '19101', 'USA'),
('Christopher', 'Moore', 'chris.moore@email.com', '555-0107', '147 Birch Way', 'San Antonio', 'TX', '78201', 'USA'),
('Amanda', 'Taylor', 'amanda.taylor@email.com', '555-0108', '258 Spruce St', 'San Diego', 'CA', '92101', 'USA'),
('Matthew', 'Anderson', 'matt.anderson@email.com', '555-0109', '369 Willow Ave', 'Dallas', 'TX', '75201', 'USA'),
('Ashley', 'Thomas', 'ashley.thomas@email.com', '555-0110', '741 Poplar Rd', 'San Jose', 'CA', '95101', 'USA'),
('James', 'Jackson', 'james.jackson@email.com', '555-0111', '852 Hickory Dr', 'Austin', 'TX', '73301', 'USA'),
('Stephanie', 'White', 'stephanie.white@email.com', '555-0112', '963 Ash Ln', 'Jacksonville', 'FL', '32099', 'USA'),
('Ryan', 'Harris', 'ryan.harris@email.com', '555-0113', '159 Walnut St', 'Fort Worth', 'TX', '76101', 'USA'),
('Nicole', 'Martin', 'nicole.martin@email.com', '555-0114', '357 Chestnut Ave', 'Columbus', 'OH', '43085', 'USA'),
('Kevin', 'Thompson', 'kevin.thompson@email.com', '555-0115', '468 Sycamore Way', 'Charlotte', 'NC', '28201', 'USA');

-- Insert sample products
INSERT INTO public.products (name, description, category, price, stock_quantity, sku, weight, dimensions) VALUES
('Wireless Bluetooth Headphones', 'Premium noise-canceling wireless headphones with 30-hour battery life', 'Electronics', 199.99, 150, 'WBH-001', 0.75, '7.5 x 6.5 x 3.0 inches'),
('Smartphone Case', 'Durable protective case for latest smartphone models', 'Accessories', 24.99, 500, 'SPC-002', 0.15, '6.0 x 3.0 x 0.5 inches'),
('Laptop Stand', 'Adjustable aluminum laptop stand for ergonomic workspace', 'Office', 79.99, 75, 'LPS-003', 2.5, '10.0 x 8.0 x 2.0 inches'),
('Coffee Maker', 'Programmable 12-cup coffee maker with thermal carafe', 'Kitchen', 129.99, 45, 'CFM-004', 8.5, '14.0 x 10.0 x 12.0 inches'),
('Running Shoes', 'Lightweight athletic shoes with advanced cushioning technology', 'Sports', 149.99, 200, 'RNS-005', 1.2, '12.0 x 8.0 x 5.0 inches'),
('Desk Lamp', 'LED desk lamp with adjustable brightness and USB charging port', 'Office', 59.99, 120, 'DSL-006', 1.8, '18.0 x 8.0 x 6.0 inches'),
('Wireless Mouse', 'Ergonomic wireless mouse with precision tracking', 'Electronics', 39.99, 300, 'WMS-007', 0.25, '4.5 x 2.5 x 1.5 inches'),
('Water Bottle', 'Insulated stainless steel water bottle, 32oz capacity', 'Sports', 34.99, 180, 'WTB-008', 0.8, '10.5 x 3.5 x 3.5 inches'),
('Bluetooth Speaker', 'Portable waterproof speaker with 360-degree sound', 'Electronics', 89.99, 95, 'BTS-009', 1.5, '6.0 x 6.0 x 4.0 inches'),
('Yoga Mat', 'Non-slip exercise mat with carrying strap', 'Sports', 49.99, 85, 'YGM-010', 2.2, '72.0 x 24.0 x 0.25 inches'),
('Tablet Stand', 'Adjustable stand for tablets and e-readers', 'Accessories', 29.99, 160, 'TBS-011', 0.6, '8.0 x 6.0 x 1.0 inches'),
('Kitchen Scale', 'Digital kitchen scale with precision measurements', 'Kitchen', 44.99, 70, 'KTS-012', 3.2, '9.0 x 6.5 x 1.5 inches'),
('Phone Charger', 'Fast-charging USB-C cable with braided design', 'Electronics', 19.99, 400, 'PHC-013', 0.3, '6.0 x 4.0 x 1.0 inches'),
('Backpack', 'Waterproof laptop backpack with multiple compartments', 'Accessories', 79.99, 110, 'BKP-014', 2.1, '18.0 x 12.0 x 8.0 inches'),
('Air Purifier', 'HEPA air purifier for rooms up to 300 sq ft', 'Home', 199.99, 35, 'APF-015', 12.5, '14.0 x 8.0 x 20.0 inches');

-- Insert sample orders
INSERT INTO public.orders (customer_id, status, total_amount, shipping_address, billing_address, payment_method) VALUES
(1, 'completed', 249.98, '123 Main St, New York, NY 10001', '123 Main St, New York, NY 10001', 'credit_card'),
(2, 'processing', 129.99, '456 Oak Ave, Los Angeles, CA 90210', '456 Oak Ave, Los Angeles, CA 90210', 'paypal'),
(3, 'shipped', 89.99, '789 Pine Rd, Chicago, IL 60601', '789 Pine Rd, Chicago, IL 60601', 'credit_card'),
(4, 'pending', 174.98, '321 Elm St, Houston, TX 77001', '321 Elm St, Houston, TX 77001', 'debit_card'),
(5, 'completed', 59.99, '654 Maple Dr, Phoenix, AZ 85001', '654 Maple Dr, Phoenix, AZ 85001', 'credit_card'),
(6, 'processing', 199.99, '987 Cedar Ln, Philadelphia, PA 19101', '987 Cedar Ln, Philadelphia, PA 19101', 'paypal'),
(7, 'shipped', 109.98, '147 Birch Way, San Antonio, TX 78201', '147 Birch Way, San Antonio, TX 78201', 'credit_card'),
(8, 'completed', 84.98, '258 Spruce St, San Diego, CA 92101', '258 Spruce St, San Diego, CA 92101', 'credit_card'),
(9, 'pending', 229.98, '369 Willow Ave, Dallas, TX 75201', '369 Willow Ave, Dallas, TX 75201', 'debit_card'),
(10, 'processing', 149.99, '741 Poplar Rd, San Jose, CA 95101', '741 Poplar Rd, San Jose, CA 95101', 'paypal');

-- Insert order items
INSERT INTO public.order_items (order_id, product_id, quantity, unit_price, total_price) VALUES
-- Order 1: Headphones + Phone Case
(1, 1, 1, 199.99, 199.99),
(1, 2, 2, 24.99, 49.98),
-- Order 2: Coffee Maker
(2, 4, 1, 129.99, 129.99),
-- Order 3: Bluetooth Speaker
(3, 9, 1, 89.99, 89.99),
-- Order 4: Running Shoes + Water Bottle
(4, 5, 1, 149.99, 149.99),
(4, 8, 1, 24.99, 24.99),
-- Order 5: Desk Lamp
(5, 6, 1, 59.99, 59.99),
-- Order 6: Headphones
(6, 1, 1, 199.99, 199.99),
-- Order 7: Wireless Mouse + Tablet Stand
(7, 7, 1, 39.99, 39.99),
(7, 11, 1, 29.99, 29.99),
(7, 13, 2, 19.99, 39.98),
-- Order 8: Yoga Mat + Water Bottle
(8, 10, 1, 49.99, 49.99),
(8, 8, 1, 34.99, 34.99),
-- Order 9: Laptop Stand + Backpack
(9, 3, 1, 79.99, 79.99),
(9, 14, 1, 79.99, 79.99),
(9, 12, 2, 44.99, 89.98),
-- Order 10: Running Shoes
(10, 5, 1, 149.99, 149.99);

-- Insert customer activity data
INSERT INTO public.customer_activity (customer_id, activity_type, activity_data, ip_address) VALUES
(1, 'page_view', '{"page": "/products/wireless-headphones", "duration": 45}', '192.168.1.100'),
(1, 'add_to_cart', '{"product_id": 1, "quantity": 1}', '192.168.1.100'),
(1, 'page_view', '{"page": "/products/phone-case", "duration": 23}', '192.168.1.100'),
(1, 'add_to_cart', '{"product_id": 2, "quantity": 2}', '192.168.1.100'),
(1, 'checkout', '{"order_id": 1, "total": 249.98}', '192.168.1.100'),
(2, 'search', '{"query": "coffee maker", "results": 5}', '10.0.0.50'),
(2, 'page_view', '{"page": "/products/coffee-maker", "duration": 67}', '10.0.0.50'),
(2, 'add_to_cart', '{"product_id": 4, "quantity": 1}', '10.0.0.50'),
(3, 'page_view', '{"page": "/categories/electronics", "duration": 120}', '172.16.0.25'),
(3, 'page_view', '{"page": "/products/bluetooth-speaker", "duration": 89}', '172.16.0.25'),
(4, 'search', '{"query": "running shoes", "results": 8}', '192.168.2.75'),
(4, 'page_view', '{"page": "/products/running-shoes", "duration": 156}', '192.168.2.75'),
(4, 'add_to_cart', '{"product_id": 5, "quantity": 1}', '192.168.2.75'),
(5, 'page_view', '{"page": "/products/desk-lamp", "duration": 34}', '10.1.1.200'),
(5, 'add_to_cart', '{"product_id": 6, "quantity": 1}', '10.1.1.200');

-- Update order tracking numbers for shipped orders
UPDATE public.orders SET tracking_number = 'TRK' || LPAD(id::text, 10, '0') WHERE status IN ('shipped', 'completed');

-- Add some inventory movements for demonstration
INSERT INTO public.inventory_movements (product_id, movement_type, quantity, reference_type, notes) VALUES
(1, 'in', 50, 'restock', 'Weekly inventory replenishment'),
(2, 'in', 100, 'restock', 'Monthly bulk order received'),
(3, 'adjustment', -2, 'damage', 'Damaged units removed from inventory'),
(4, 'in', 25, 'restock', 'Supplier delivery'),
(5, 'adjustment', 5, 'found', 'Found additional units during audit');

-- Create some additional customer records for testing
INSERT INTO public.customers (first_name, last_name, email, phone, address, city, state, zip_code, country) VALUES
('Robert', 'Garcia', 'robert.garcia@email.com', '555-0116', '789 Oak Street', 'Miami', 'FL', '33101', 'USA'),
('Lisa', 'Rodriguez', 'lisa.rodriguez@email.com', '555-0117', '456 Pine Avenue', 'Seattle', 'WA', '98101', 'USA'),
('William', 'Lewis', 'william.lewis@email.com', '555-0118', '123 Cedar Road', 'Denver', 'CO', '80201', 'USA'),
('Michelle', 'Lee', 'michelle.lee@email.com', '555-0119', '321 Maple Lane', 'Boston', 'MA', '02101', 'USA'),
('Daniel', 'Walker', 'daniel.walker@email.com', '555-0120', '654 Elm Drive', 'Las Vegas', 'NV', '89101', 'USA');

