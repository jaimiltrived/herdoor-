-- ==========================================================
-- HerDoor Multi-Role Seed Data DML Script
-- ==========================================================
USE `herdoor`;

-- Truncate existing tables safely
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE `devices`;
TRUNCATE TABLE `notifications`;
TRUNCATE TABLE `reviews`;
TRUNCATE TABLE `wholesalers`;
TRUNCATE TABLE `inventory`;
TRUNCATE TABLE `deliveries`;
TRUNCATE TABLE `payments`;
TRUNCATE TABLE `order_timeline`;
TRUNCATE TABLE `orders`;
TRUNCATE TABLE `grain_types`;
TRUNCATE TABLE `grain_sources`;
TRUNCATE TABLE `mill_services`;
TRUNCATE TABLE `mills`;
TRUNCATE TABLE `addresses`;
TRUNCATE TABLE `users`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Insert Initial Users (Hashed password: Password123!)
-- Hash: $2a$08$U4V2nNqTlnW9xU5qE0rOquk3V6/J65F/Z6uS3aU2eNqTlnW9xU5qE
INSERT INTO `users` (`id`, `name`, `email`, `phone`, `password`, `role`, `mill_id`, `vehicle_number`, `vehicle_type`, `is_online`, `rating`, `total_trips`, `profile_image`) VALUES
(1, 'Ramesh Patel', 'ramesh@example.com', '+919876543210', '$2a$08$U4V2nNqTlnW9xU5qE0rOquk3V6/J65F/Z6uS3aU2eNqTlnW9xU5qE', 'CUSTOMER', NULL, NULL, NULL, 1, 5.00, 0, 'https://images.unsplash.com/photo-1534528741775-53994a69daeb'),
(2, 'Suresh Mill Owner', 'shop@shreeganesh.com', '+919876543211', '$2a$08$U4V2nNqTlnW9xU5qE0rOquk3V6/J65F/Z6uS3aU2eNqTlnW9xU5qE', 'SHOPKEEPER', 101, NULL, NULL, 1, 4.80, 0, NULL),
(3, 'Vikram Delivery Agent', 'delivery@herdoor.com', '+919876543212', '$2a$08$U4V2nNqTlnW9xU5qE0rOquk3V6/J65F/Z6uS3aU2eNqTlnW9xU5qE', 'DELIVERY', NULL, 'GJ-01-AB-1234', 'Electric Scooter', 1, 4.90, 184, 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d'),
(4, 'Super Admin', 'admin@herdoor.com', '+919876543200', '$2a$08$U4V2nNqTlnW9xU5qE0rOquk3V6/J65F/Z6uS3aU2eNqTlnW9xU5qE', 'ADMIN', NULL, NULL, NULL, 1, 5.00, 0, NULL),
(5, 'Rajesh Kumar', 'rajesh.rider@herdoor.com', '+919876543215', '$2a$08$U4V2nNqTlnW9xU5qE0rOquk3V6/J65F/Z6uS3aU2eNqTlnW9xU5qE', 'DELIVERY', NULL, 'GJ-01-EB-4821', 'Electric Bike', 1, 4.85, 96, NULL);

-- 2. Insert Saved Addresses
INSERT INTO `addresses` (`id`, `user_id`, `address_line1`, `address_line2`, `city`, `state`, `pincode`, `latitude`, `longitude`, `is_default`) VALUES
(25, 1, 'Flat 402, Shivalik Towers', 'Satellite Road', 'Ahmedabad', 'Gujarat', '380015', 23.02500000, 72.57000000, 1),
(26, 1, 'Office 301, Pinnacle Business Park', 'Prahlad Nagar', 'Ahmedabad', 'Gujarat', '380015', 23.01200000, 72.50800000, 0);

-- 3. Insert Flour Mills
INSERT INTO `mills` (`id`, `owner_user_id`, `name`, `phone`, `address`, `latitude`, `longitude`, `rating`, `total_ratings`, `is_open`, `estimated_time`, `capacity_kg_per_day`, `current_load_kg`, `specialty`, `working_hours`) VALUES
(101, 2, 'Shree Ganesh Flour Mill', '+919876543211', '12 Market Yard, Ellisbridge, Ahmedabad', 23.02250000, 72.57140000, 4.80, 128, 1, '30-45 min', 600.00, 420.00, 'Fresh Stone Ground Flour', '08:00 AM - 08:00 PM'),
(102, 99, 'Navrang Quality Atta Mill', '+919876543299', '45 Swastik Cross Road, Navrangpura, Ahmedabad', 23.03800000, 72.56200000, 4.80, 94, 1, '20-30 min', 500.00, 310.00, 'Organic Whole Wheat & Multigrain', '09:00 AM - 07:30 PM'),
(103, 100, 'Mahadev Traditional Chakki', '+919876543288', 'Shop 8, Vastrapur Lake Complex, Ahmedabad', 23.03500000, 72.52800000, 4.70, 76, 1, '25-40 min', 450.00, 290.00, 'Bajra & Jowar Specialized Grinding', '08:30 AM - 08:30 PM');

-- 4. Insert Mill Services
INSERT INTO `mill_services` (`mill_id`, `service_name`) VALUES
(101, 'Flour Grinding'),
(101, 'Packing'),
(101, 'Home Delivery'),
(101, 'Cleaning'),
(102, 'Flour Grinding'),
(102, 'Home Delivery'),
(103, 'Flour Grinding'),
(103, 'Packing'),
(103, 'Home Delivery');

-- 5. Insert Grain Sources
INSERT INTO `grain_sources` (`id`, `code`, `name`, `description`) VALUES
(1, 'CUSTOMER', 'Customer\'s own grain', 'Bring/pickup customer\'s own raw grain for milling'),
(2, 'MILL', 'Mill-provided grain', 'Fresh grain supplied directly by the mill'),
(3, 'VENDOR', 'Vendor grain', 'Premium vendor sourced grain');

-- 6. Insert Grain Types Catalog
INSERT INTO `grain_types` (`id`, `name`, `category`, `price_per_kg`, `grinding_fee_per_kg`) VALUES
(1, 'Wheat (Gehun)', 'GRAIN', 35.00, 5.00),
(2, 'Rice (Chawal)', 'GRAIN', 40.00, 6.00),
(3, 'Bajra (Pearl Millet)', 'GRAIN', 30.00, 5.00),
(4, 'Jowar (Sorghum)', 'GRAIN', 38.00, 5.00),
(5, 'Maize (Makai)', 'GRAIN', 28.00, 4.00),
(6, 'Multigrain Mix', 'GRAIN', 60.00, 8.00),
(7, 'Ragi (Finger Millet)', 'GRAIN', 55.00, 7.00);

-- 7. Insert Initial Orders
INSERT INTO `orders` (`id`, `order_number`, `user_id`, `customer_name`, `customer_phone`, `mill_id`, `grain_source`, `grain_type_id`, `grain_type_name`, `quantity_kg`, `service_type`, `fulfillment_type`, `address_id`, `pickup_pin`, `delivery_otp`, `payment_method`, `payment_status`, `status`, `estimated_minutes`, `estimated_completion_time`, `total_amount`) VALUES
(501, 'ORD-2026-1001', 1, 'Ramesh Patel', '+919876543210', 101, 'CUSTOMER', 1, 'Wheat (Gehun)', 10.00, 'GRINDING', 'DELIVERY', 25, '4821', '7391', 'UPI', 'PAID', 'PROCESSING', 45, '18:30', 90.00),
(502, 'ORD-2026-1002', 1, 'Elena Rodriguez', '+919876543219', 101, 'CUSTOMER', 6, 'Multigrain Mix', 5.00, 'GRINDING', 'DELIVERY', 25, '1942', '6543', 'UPI', 'PAID', 'PLACED', 30, NULL, 175.00),
(503, 'ORD-2026-1003', 1, 'Marcus Chen', '+919876543220', 101, 'MILL', 4, 'Jowar (Sorghum)', 10.00, 'GRINDING', 'DELIVERY', 25, '8210', '9120', 'UPI', 'PAID', 'DELIVERED', 40, '12:40', 380.00),
(504, 'ORD-2026-1004', 1, 'Priya Sharma', '+919876543222', 101, 'MILL', 1, 'Wheat (Gehun)', 5.00, 'GRINDING', 'PICKUP', NULL, '3321', NULL, 'CASH', 'PENDING', 'READY_FOR_PICKUP', 25, '15:00', 200.00);

-- 8. Insert Order Timeline
INSERT INTO `order_timeline` (`order_id`, `status`, `note`) VALUES
(501, 'PLACED', 'Order placed by customer'),
(501, 'ACCEPTED', 'Accepted by shopkeeper'),
(501, 'PROCESSING', 'Grinding started'),
(502, 'PLACED', 'Order placed by customer'),
(503, 'PLACED', 'Order placed by customer'),
(503, 'DELIVERED', 'Order delivered to customer'),
(504, 'PLACED', 'Pickup order placed'),
(504, 'READY_FOR_PICKUP', 'Ready at counter');

-- 9. Insert Payments
INSERT INTO `payments` (`id`, `order_id`, `amount`, `payment_method`, `status`, `transaction_id`) VALUES
('PAY-1001', 501, 90.00, 'UPI', 'SUCCESS', 'TXN_9988776655');

-- 10. Insert Deliveries
INSERT INTO `deliveries` (`id`, `order_id`, `delivery_person_id`, `delivery_person_name`, `delivery_person_phone`, `status`, `pickup_address`, `delivery_address`, `current_latitude`, `current_longitude`, `pickup_pin`, `delivery_otp`, `delivery_fee`, `estimated_minutes`) VALUES
(801, 501, 3, 'Vikram Delivery Agent', '+919876543212', 'ASSIGNED', 'Shree Ganesh Flour Mill, 12 Market Yard, Ellisbridge', 'Flat 402, Shivalik Towers, Satellite Road, Ahmedabad', 23.02300000, 72.57050000, '4821', '7391', 40.00, 18);

-- 11. Insert Inventory
INSERT INTO `inventory` (`id`, `mill_id`, `product_type`, `name`, `stock_kg`, `minimum_stock_kg`, `price_per_kg`) VALUES
(1, 101, 'FLOUR', 'Wheat Flour (Fresh Atta)', 150.00, 30.00, 45.00),
(2, 101, 'GRAIN', 'Raw Premium Sharbati Wheat', 400.00, 100.00, 36.00),
(3, 101, 'FLOUR', 'Multigrain Dietary Flour', 65.00, 20.00, 68.00),
(4, 101, 'GRAIN', 'Dark Rye Grain', 12.00, 25.00, 48.00);

-- 12. Insert Wholesalers
INSERT INTO `wholesalers` (`id`, `name`, `contact_person`, `phone`, `city`, `grains_supplied`, `rating`, `stock_available_tons`, `status`) VALUES
(1, 'Gujarat Agro Grain Depot', 'Harish Mehta', '+919876543301', 'Ahmedabad', 'Wheat, Bajra, Jowar', 4.80, 145.50, 'ACTIVE'),
(2, 'Saurashtra Organic Pulses & Grains', 'Bhavesh Dave', '+919876543302', 'Rajkot', 'Ragi, Makai, Organic Wheat', 4.90, 88.00, 'ACTIVE');

-- 13. Insert Reviews
INSERT INTO `reviews` (`id`, `order_id`, `user_id`, `user_name`, `mill_id`, `rating`, `review`) VALUES
(1, 503, 1, 'Ramesh Patel', 101, 5, 'Excellent grinding quality, perfect fineness, and super fast home delivery service.');

-- 14. Insert Notifications
INSERT INTO `notifications` (`id`, `user_id`, `title`, `message`, `is_read`) VALUES
(1, 2, '🚨 New Order Received #ORD-2026-1002', 'Elena Rodriguez placed a new order for 5kg Multigrain Mix (₹175.00).', 0),
(2, 2, '🛵 Driver Arrived for Pickup', 'Rajesh Kumar (Electric Bike #EB-4821) arrived at store for order #ORD-2026-1001.', 0),
(3, 2, '⚠️ Low Stock Alert: Dark Rye Blend', 'Stock has fallen below threshold (12kg remaining). Restock soon.', 0),
(4, 2, '🛡️ Food Safety Audit Status', 'Daily chakki stone sanitization and grain moisture test verified (Score 99%).', 1);

-- 15. Insert Devices
INSERT INTO `devices` (`id`, `user_id`, `fcm_token`, `device_type`) VALUES
(1, 1, 'token_sample_customer_123', 'ANDROID'),
(2, 2, 'token_sample_merchant_456', 'ANDROID');
