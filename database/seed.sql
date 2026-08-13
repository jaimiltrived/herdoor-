-- HerDoor Seed Data DML Script
USE `herdoor`;

-- Truncate existing tables safely
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE `devices`;
TRUNCATE TABLE `notifications`;
TRUNCATE TABLE `reviews`;
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
INSERT INTO `users` (`id`, `name`, `email`, `phone`, `password`, `role`, `mill_id`, `vehicle_number`, `profile_image`) VALUES
(1, 'Ramesh Patel', 'ramesh@example.com', '+919876543210', '$2a$08$U4V2nNqTlnW9xU5qE0rOquk3V6/J65F/Z6uS3aU2eNqTlnW9xU5qE', 'CUSTOMER', NULL, NULL, 'https://images.unsplash.com/photo-1534528741775-53994a69daeb'),
(2, 'Suresh Mill Owner', 'shop@shreeganesh.com', '+919876543211', '$2a$08$U4V2nNqTlnW9xU5qE0rOquk3V6/J65F/Z6uS3aU2eNqTlnW9xU5qE', 'SHOPKEEPER', 101, NULL, NULL),
(3, 'Vikram Delivery Agent', 'delivery@herdoor.com', '+919876543212', '$2a$08$U4V2nNqTlnW9xU5qE0rOquk3V6/J65F/Z6uS3aU2eNqTlnW9xU5qE', 'DELIVERY', NULL, 'GJ-01-AB-1234', NULL);

-- 2. Insert Saved Addresses
INSERT INTO `addresses` (`id`, `user_id`, `address_line1`, `address_line2`, `city`, `state`, `pincode`, `latitude`, `longitude`, `is_default`) VALUES
(25, 1, 'Flat 402, Shivalik Towers', 'Satellite Road', 'Ahmedabad', 'Gujarat', '380015', 23.02500000, 72.57000000, 1);

-- 3. Insert Mills
INSERT INTO `mills` (`id`, `owner_user_id`, `name`, `phone`, `address`, `latitude`, `longitude`, `rating`, `total_ratings`, `is_open`, `estimated_time`, `working_hours`) VALUES
(101, 2, 'Shree Ganesh Flour Mill', '+919876543211', '12 Market Yard, Ellisbridge, Ahmedabad', 23.02250000, 72.57140000, 4.60, 128, 1, '30-45 min', '08:00 AM - 08:00 PM'),
(102, 99, 'Navrang Quality Atta Mill', '+919876543299', '45 Swastik Cross Road, Navrangpura, Ahmedabad', 23.03800000, 72.56200000, 4.80, 94, 1, '20-30 min', '09:00 AM - 07:30 PM');

-- 4. Insert Mill Services
INSERT INTO `mill_services` (`mill_id`, `service_name`) VALUES
(101, 'Flour Grinding'),
(101, 'Packing'),
(101, 'Home Delivery'),
(101, 'Cleaning'),
(102, 'Flour Grinding'),
(102, 'Home Delivery');

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
INSERT INTO `orders` (`id`, `order_number`, `user_id`, `mill_id`, `grain_source`, `grain_type_id`, `grain_type_name`, `quantity_kg`, `service_type`, `fulfillment_type`, `address_id`, `payment_method`, `payment_status`, `status`, `estimated_minutes`, `estimated_completion_time`, `total_amount`) VALUES
(501, 'ORD-2026-1001', 1, 101, 'CUSTOMER', 1, 'Wheat (Gehun)', 10.00, 'GRINDING', 'DELIVERY', 25, 'UPI', 'PAID', 'PROCESSING', 45, '18:30', 90.00);

-- 8. Insert Order Timeline
INSERT INTO `order_timeline` (`order_id`, `status`, `note`) VALUES
(501, 'PLACED', 'Order placed by customer'),
(501, 'ACCEPTED', 'Accepted by shopkeeper'),
(501, 'PROCESSING', 'Grinding started');

-- 9. Insert Payments
INSERT INTO `payments` (`id`, `order_id`, `amount`, `payment_method`, `status`, `transaction_id`) VALUES
('PAY-1001', 501, 90.00, 'UPI', 'SUCCESS', 'TXN_9988776655');

-- 10. Insert Deliveries
INSERT INTO `deliveries` (`id`, `order_id`, `delivery_person_id`, `delivery_person_name`, `delivery_person_phone`, `status`, `pickup_address`, `delivery_address`) VALUES
(801, 501, 3, 'Vikram Delivery Agent', '+919876543212', 'ASSIGNED', 'Shree Ganesh Flour Mill, Market Yard', 'Flat 402, Shivalik Towers, Satellite Road');

-- 11. Insert Inventory
INSERT INTO `inventory` (`id`, `mill_id`, `product_type`, `name`, `stock_kg`, `minimum_stock_kg`, `price_per_kg`) VALUES
(1, 101, 'FLOUR', 'Wheat Flour (Fresh Atta)', 150.00, 30.00, 45.00),
(2, 101, 'GRAIN', 'Raw Premium Sharbati Wheat', 400.00, 100.00, 36.00);

-- 12. Insert Reviews
INSERT INTO `reviews` (`id`, `order_id`, `user_id`, `user_name`, `mill_id`, `rating`, `review`) VALUES
(1, 501, 1, 'Ramesh Patel', 101, 5, 'Excellent grinding quality and fast home delivery service.');

-- 13. Insert Notifications
INSERT INTO `notifications` (`id`, `user_id`, `title`, `message`, `is_read`) VALUES
(1, 1, 'Order Accepted', 'Shree Ganesh Flour Mill accepted your order #ORD-2026-1001.', 0);

-- 14. Insert Devices
INSERT INTO `devices` (`id`, `user_id`, `fcm_token`, `device_type`) VALUES
(1, 1, 'token_sample_abc123', 'ANDROID');
