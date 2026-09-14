-- ==========================================================
-- HerDoor Multi-Role Relational Database Schema
-- Supports Customer, Merchant, Delivery Partner & Admin
-- Compatible with MySQL 8.0+ / MariaDB
-- ==========================================================

CREATE DATABASE IF NOT EXISTS `herdoor` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `herdoor`;

-- Disable foreign key checks to safely drop and recreate tables
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `devices`;
DROP TABLE IF EXISTS `notifications`;
DROP TABLE IF EXISTS `reviews`;
DROP TABLE IF EXISTS `wholesalers`;
DROP TABLE IF EXISTS `inventory`;
DROP TABLE IF EXISTS `deliveries`;
DROP TABLE IF EXISTS `payments`;
DROP TABLE IF EXISTS `user_favorites`;
DROP TABLE IF EXISTS `order_timeline`;
DROP TABLE IF EXISTS `orders`;
DROP TABLE IF EXISTS `grain_types`;
DROP TABLE IF EXISTS `grain_sources`;
DROP TABLE IF EXISTS `mill_services`;
DROP TABLE IF EXISTS `mills`;
DROP TABLE IF EXISTS `addresses`;
DROP TABLE IF EXISTS `users`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Users Table (Customer, Merchant, Rider, Admin)
CREATE TABLE `users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `email` VARCHAR(150) UNIQUE,
  `phone` VARCHAR(20) UNIQUE,
  `password` VARCHAR(255) NOT NULL,
  `role` ENUM('CUSTOMER', 'SHOPKEEPER', 'DELIVERY', 'ADMIN') NOT NULL DEFAULT 'CUSTOMER',
  `mill_id` INT DEFAULT NULL,
  `vehicle_number` VARCHAR(50) DEFAULT NULL,
  `vehicle_type` VARCHAR(50) DEFAULT 'Electric Scooter',
  `is_online` TINYINT(1) DEFAULT 1,
  `rating` DECIMAL(3, 2) DEFAULT 5.00,
  `total_trips` INT DEFAULT 0,
  `profile_image` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_users_role` (`role`),
  INDEX `idx_users_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Customer Saved Delivery Addresses Table
CREATE TABLE `addresses` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `address_line1` VARCHAR(255) NOT NULL,
  `address_line2` VARCHAR(255) DEFAULT '',
  `city` VARCHAR(100) NOT NULL,
  `state` VARCHAR(100) DEFAULT 'Gujarat',
  `pincode` VARCHAR(20) NOT NULL,
  `latitude` DECIMAL(10, 8) DEFAULT 23.02250000,
  `longitude` DECIMAL(11, 8) DEFAULT 72.57140000,
  `is_default` TINYINT(1) DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_addresses_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Flour Mills Table
CREATE TABLE `mills` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `owner_user_id` INT NOT NULL,
  `name` VARCHAR(150) NOT NULL,
  `phone` VARCHAR(20) NOT NULL,
  `address` TEXT NOT NULL,
  `latitude` DECIMAL(10, 8) NOT NULL,
  `longitude` DECIMAL(11, 8) NOT NULL,
  `rating` DECIMAL(3, 2) DEFAULT 4.80,
  `total_ratings` INT DEFAULT 0,
  `is_open` TINYINT(1) DEFAULT 1,
  `estimated_time` VARCHAR(50) DEFAULT '30-45 min',
  `capacity_kg_per_day` DECIMAL(10, 2) DEFAULT 500.00,
  `current_load_kg` DECIMAL(10, 2) DEFAULT 0.00,
  `specialty` VARCHAR(150) DEFAULT 'Fresh Stone Ground Flour',
  `working_hours` VARCHAR(100) DEFAULT '08:00 AM - 08:00 PM',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_mills_lat_lon` (`latitude`, `longitude`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Mill Offered Services Table
CREATE TABLE `mill_services` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `mill_id` INT NOT NULL,
  `service_name` VARCHAR(100) NOT NULL,
  CONSTRAINT `fk_services_mill` FOREIGN KEY (`mill_id`) REFERENCES `mills` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. Grain Sources Table
CREATE TABLE `grain_sources` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(50) NOT NULL UNIQUE,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. Grain Types Catalog Table
CREATE TABLE `grain_types` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `category` VARCHAR(50) DEFAULT 'GRAIN',
  `price_per_kg` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `grinding_fee_per_kg` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. Orders Table
CREATE TABLE `orders` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `order_number` VARCHAR(50) NOT NULL UNIQUE,
  `user_id` INT NOT NULL,
  `customer_name` VARCHAR(100) DEFAULT NULL,
  `customer_phone` VARCHAR(20) DEFAULT NULL,
  `mill_id` INT NOT NULL,
  `grain_source` VARCHAR(50) NOT NULL DEFAULT 'CUSTOMER',
  `grain_type_id` INT NOT NULL,
  `grain_type_name` TEXT NOT NULL,
  `quantity_kg` DECIMAL(10, 2) NOT NULL,
  `service_type` VARCHAR(50) NOT NULL DEFAULT 'GRINDING',
  `fulfillment_type` ENUM('DELIVERY', 'PICKUP') NOT NULL DEFAULT 'DELIVERY',
  `address_id` INT DEFAULT NULL,
  `pickup_pin` VARCHAR(10) DEFAULT '4821',
  `delivery_otp` VARCHAR(10) DEFAULT '7391',
  `payment_method` VARCHAR(50) DEFAULT 'UPI',
  `payment_status` ENUM('PENDING', 'PAID', 'FAILED', 'REFUNDED') DEFAULT 'PENDING',
  `status` VARCHAR(50) NOT NULL DEFAULT 'PLACED',
  `estimated_minutes` INT DEFAULT 30,
  `estimated_completion_time` VARCHAR(50) DEFAULT NULL,
  `total_amount` DECIMAL(10, 2) NOT NULL,
  `group_id` INT DEFAULT NULL,
  `group_code` VARCHAR(50) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_orders_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_orders_mill` FOREIGN KEY (`mill_id`) REFERENCES `mills` (`id`),
  INDEX `idx_orders_status` (`status`),
  INDEX `idx_orders_group_code` (`group_code`),
  INDEX `idx_orders_group_id` (`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8. Order Status Timeline Table
CREATE TABLE `order_timeline` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `order_id` INT NOT NULL,
  `status` VARCHAR(50) NOT NULL,
  `title` VARCHAR(150) DEFAULT NULL,
  `note` TEXT,
  `description` TEXT,
  `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_timeline_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8b. User Favorite Mills Table
CREATE TABLE `user_favorites` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `mill_id` INT NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_user_mill` (`user_id`, `mill_id`),
  CONSTRAINT `fk_favorites_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_favorites_mill` FOREIGN KEY (`mill_id`) REFERENCES `mills` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 9. Payments Table
CREATE TABLE `payments` (
  `id` VARCHAR(100) PRIMARY KEY,
  `order_id` INT NOT NULL,
  `amount` DECIMAL(10, 2) NOT NULL,
  `payment_method` VARCHAR(50) NOT NULL DEFAULT 'UPI',
  `status` VARCHAR(50) NOT NULL DEFAULT 'CREATED',
  `transaction_id` VARCHAR(100) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_payments_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 10. Deliveries Table
CREATE TABLE `deliveries` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `order_id` INT NOT NULL UNIQUE,
  `delivery_person_id` INT DEFAULT NULL,
  `delivery_person_name` VARCHAR(100) DEFAULT NULL,
  `delivery_person_phone` VARCHAR(20) DEFAULT NULL,
  `status` VARCHAR(50) NOT NULL DEFAULT 'ASSIGNED',
  `pickup_address` TEXT DEFAULT NULL,
  `delivery_address` TEXT DEFAULT NULL,
  `current_latitude` DECIMAL(10, 8) DEFAULT 23.02250000,
  `current_longitude` DECIMAL(11, 8) DEFAULT 72.57140000,
  `pickup_pin` VARCHAR(10) DEFAULT '4821',
  `delivery_otp` VARCHAR(10) DEFAULT '7391',
  `delivery_fee` DECIMAL(10, 2) DEFAULT 40.00,
  `estimated_minutes` INT DEFAULT 20,
  `is_batch` TINYINT(1) DEFAULT 0,
  `batch_order_count` INT DEFAULT 1,
  `group_code` VARCHAR(50) DEFAULT NULL,
  `stops_data` LONGTEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_deliveries_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 11. Mill Inventory Table
CREATE TABLE `inventory` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `mill_id` INT NOT NULL,
  `product_type` ENUM('FLOUR', 'GRAIN', 'PACKAGING', 'OTHER') NOT NULL DEFAULT 'FLOUR',
  `name` VARCHAR(150) NOT NULL,
  `stock_kg` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `minimum_stock_kg` DECIMAL(10, 2) NOT NULL DEFAULT 20.00,
  `price_per_kg` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_inventory_mill` FOREIGN KEY (`mill_id`) REFERENCES `mills` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 12. Wholesalers & Grain Depot Table
CREATE TABLE `wholesalers` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(150) NOT NULL,
  `contact_person` VARCHAR(100) DEFAULT NULL,
  `phone` VARCHAR(20) NOT NULL,
  `city` VARCHAR(100) DEFAULT 'Ahmedabad',
  `grains_supplied` TEXT,
  `rating` DECIMAL(3, 2) DEFAULT 4.80,
  `stock_available_tons` DECIMAL(10, 2) DEFAULT 50.00,
  `status` VARCHAR(50) DEFAULT 'ACTIVE',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 13. Customer Reviews Table
CREATE TABLE `reviews` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `order_id` INT NOT NULL UNIQUE,
  `user_id` INT NOT NULL,
  `user_name` VARCHAR(100) NOT NULL,
  `mill_id` INT NOT NULL,
  `rating` INT NOT NULL CHECK (`rating` BETWEEN 1 AND 5),
  `review` TEXT,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_reviews_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_reviews_mill` FOREIGN KEY (`mill_id`) REFERENCES `mills` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 14. Notifications Table
CREATE TABLE `notifications` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `title` VARCHAR(150) NOT NULL,
  `message` TEXT NOT NULL,
  `is_read` TINYINT(1) DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_notifications_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 15. Mobile Device FCM Tokens Table
CREATE TABLE `devices` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `fcm_token` VARCHAR(255) NOT NULL,
  `device_type` VARCHAR(50) DEFAULT 'ANDROID',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_devices_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 16. Packages Table (Smart Package-Level QR)
CREATE TABLE `packages` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `order_id` INT NOT NULL,
  `order_item_id` INT DEFAULT NULL,
  `package_code` VARCHAR(100) NOT NULL UNIQUE,
  `qr_token` VARCHAR(255) NOT NULL UNIQUE,
  `product_name` VARCHAR(150) NOT NULL,
  `expected_weight` DECIMAL(10, 2) NOT NULL,
  `actual_weight` DECIMAL(10, 2) DEFAULT NULL,
  `unit` VARCHAR(20) DEFAULT 'KG',
  `status` ENUM('CREATED', 'READY_FOR_PICKUP', 'PICKED_UP_FROM_CUSTOMER', 'RECEIVED_AT_MILL', 'PROCESSING', 'READY_FOR_DELIVERY', 'PICKED_UP_FROM_MILL', 'OUT_FOR_DELIVERY', 'DELIVERED') NOT NULL DEFAULT 'CREATED',
  `current_leg` ENUM('LEG_1', 'LEG_2', 'COMPLETED') NOT NULL DEFAULT 'LEG_1',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_packages_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  INDEX `idx_packages_order_id` (`order_id`),
  INDEX `idx_packages_qr_token` (`qr_token`),
  INDEX `idx_packages_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 17. Delivery Tasks Table (Automatic 2-Leg Logistics)
CREATE TABLE `delivery_tasks` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `order_id` INT NOT NULL,
  `leg` ENUM('LEG_1_CUSTOMER_TO_MILL', 'LEG_2_MILL_TO_CUSTOMER') NOT NULL,
  `delivery_person_id` INT DEFAULT NULL,
  `delivery_person_name` VARCHAR(100) DEFAULT NULL,
  `delivery_person_phone` VARCHAR(20) DEFAULT NULL,
  `pickup_location` TEXT DEFAULT NULL,
  `drop_location` TEXT DEFAULT NULL,
  `status` ENUM('AVAILABLE', 'ASSIGNED', 'IN_TRANSIT', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'AVAILABLE',
  `started_at` TIMESTAMP NULL DEFAULT NULL,
  `accepted_at` TIMESTAMP NULL DEFAULT NULL,
  `completed_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_delivery_tasks_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_delivery_tasks_rider` FOREIGN KEY (`delivery_person_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  INDEX `idx_delivery_tasks_order_leg` (`order_id`, `leg`),
  INDEX `idx_delivery_tasks_status` (`status`),
  INDEX `idx_delivery_tasks_rider` (`delivery_person_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 18. Package Scan Events Audit Log Table
CREATE TABLE `package_scan_events` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `package_id` INT NOT NULL,
  `order_id` INT NOT NULL,
  `scanned_by_user_id` INT NOT NULL,
  `location_type` ENUM('CUSTOMER', 'MILL') NOT NULL,
  `scan_type` ENUM('PICKUP', 'MILL_INTAKE', 'MILL_DISPATCH', 'DELIVERY') NOT NULL,
  `result` ENUM('SUCCESS', 'REJECTED', 'DUPLICATE', 'INVALID') NOT NULL,
  `latitude` DECIMAL(10, 8) DEFAULT NULL,
  `longitude` DECIMAL(11, 8) DEFAULT NULL,
  `note` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_scan_events_package` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_scan_events_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_scan_events_user` FOREIGN KEY (`scanned_by_user_id`) REFERENCES `users` (`id`),
  INDEX `idx_scan_events_package` (`package_id`),
  INDEX `idx_scan_events_order` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

