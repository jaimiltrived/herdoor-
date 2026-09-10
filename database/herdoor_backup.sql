-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3307
-- Generation Time: Sep 09, 2026 at 12:58 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `herdoor`
--

-- --------------------------------------------------------

--
-- Table structure for table `addresses`
--

CREATE TABLE `addresses` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `address_line1` varchar(255) NOT NULL,
  `address_line2` varchar(255) DEFAULT '',
  `city` varchar(100) NOT NULL,
  `state` varchar(100) DEFAULT 'Gujarat',
  `pincode` varchar(20) NOT NULL,
  `latitude` decimal(10,8) DEFAULT 23.02250000,
  `longitude` decimal(11,8) DEFAULT 72.57140000,
  `is_default` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `addresses`
--

INSERT INTO `addresses` (`id`, `user_id`, `address_line1`, `address_line2`, `city`, `state`, `pincode`, `latitude`, `longitude`, `is_default`, `created_at`, `updated_at`) VALUES
(25, 1, 'Flat 402, Shivalik Towers', 'Satellite Road', 'Ahmedabad', 'Gujarat', '380015', 23.02500000, 72.57000000, 1, '2026-09-09 10:57:01', '2026-09-09 10:57:01'),
(26, 1, 'Office 301, Pinnacle Business Park', 'Prahlad Nagar', 'Ahmedabad', 'Gujarat', '380015', 23.01200000, 72.50800000, 0, '2026-09-09 10:57:01', '2026-09-09 10:57:01');

-- --------------------------------------------------------

--
-- Table structure for table `deliveries`
--

CREATE TABLE `deliveries` (
  `id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `delivery_person_id` int(11) DEFAULT NULL,
  `delivery_person_name` varchar(100) DEFAULT NULL,
  `delivery_person_phone` varchar(20) DEFAULT NULL,
  `status` varchar(50) NOT NULL DEFAULT 'ASSIGNED',
  `pickup_address` text DEFAULT NULL,
  `delivery_address` text DEFAULT NULL,
  `current_latitude` decimal(10,8) DEFAULT 23.02250000,
  `current_longitude` decimal(11,8) DEFAULT 72.57140000,
  `pickup_pin` varchar(10) DEFAULT '4821',
  `delivery_otp` varchar(10) DEFAULT '7391',
  `delivery_fee` decimal(10,2) DEFAULT 40.00,
  `estimated_minutes` int(11) DEFAULT 20,
  `is_batch` tinyint(1) DEFAULT 0,
  `batch_order_count` int(11) DEFAULT 1,
  `group_code` varchar(50) DEFAULT NULL,
  `stops_data` longtext DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `deliveries`
--

INSERT INTO `deliveries` (`id`, `order_id`, `delivery_person_id`, `delivery_person_name`, `delivery_person_phone`, `status`, `pickup_address`, `delivery_address`, `current_latitude`, `current_longitude`, `pickup_pin`, `delivery_otp`, `delivery_fee`, `estimated_minutes`, `is_batch`, `batch_order_count`, `group_code`, `stops_data`, `created_at`, `updated_at`) VALUES
(801, 501, 3, 'Vikram Delivery Agent', '+919876543212', 'ASSIGNED', 'Shree Ganesh Flour Mill, 12 Market Yard, Ellisbridge', 'Flat 402, Shivalik Towers, Satellite Road, Ahmedabad', 23.02300000, 72.57050000, '4821', '7391', 40.00, 18, 0, 1, NULL, NULL, '2026-09-09 10:57:01', '2026-09-09 10:57:01'),
(802, 505, 3, 'Vikram Delivery Agent', '+919876543212', 'DELIVERED', '12 Market Yard, Ellisbridge, Ahmedabad', 'Flat 402, Shivalik Towers, Ahmedabad', 23.02450000, 72.57080000, '4821', '7391', 45.00, 20, 0, 1, NULL, NULL, '2026-09-09 10:57:17', '2026-09-09 10:57:17');

-- --------------------------------------------------------

--
-- Table structure for table `devices`
--

CREATE TABLE `devices` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `fcm_token` varchar(255) NOT NULL,
  `device_type` varchar(50) DEFAULT 'ANDROID',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `devices`
--

INSERT INTO `devices` (`id`, `user_id`, `fcm_token`, `device_type`, `created_at`) VALUES
(1, 1, 'token_sample_customer_123', 'ANDROID', '2026-09-09 10:57:01'),
(2, 2, 'token_sample_merchant_456', 'ANDROID', '2026-09-09 10:57:01');

-- --------------------------------------------------------

--
-- Table structure for table `grain_sources`
--

CREATE TABLE `grain_sources` (
  `id` int(11) NOT NULL,
  `code` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `grain_sources`
--

INSERT INTO `grain_sources` (`id`, `code`, `name`, `description`) VALUES
(1, 'CUSTOMER', 'Customer\'s own grain', 'Bring/pickup customer\'s own raw grain for milling'),
(2, 'MILL', 'Mill-provided grain', 'Fresh grain supplied directly by the mill'),
(3, 'VENDOR', 'Vendor grain', 'Premium vendor sourced grain');

-- --------------------------------------------------------

--
-- Table structure for table `grain_types`
--

CREATE TABLE `grain_types` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `category` varchar(50) DEFAULT 'GRAIN',
  `price_per_kg` decimal(10,2) NOT NULL DEFAULT 0.00,
  `grinding_fee_per_kg` decimal(10,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `grain_types`
--

INSERT INTO `grain_types` (`id`, `name`, `category`, `price_per_kg`, `grinding_fee_per_kg`, `created_at`) VALUES
(1, 'Wheat (Gehun)', 'GRAIN', 35.00, 5.00, '2026-09-09 10:57:01'),
(2, 'Rice (Chawal)', 'GRAIN', 40.00, 6.00, '2026-09-09 10:57:01'),
(3, 'Bajra (Pearl Millet)', 'GRAIN', 30.00, 5.00, '2026-09-09 10:57:01'),
(4, 'Jowar (Sorghum)', 'GRAIN', 38.00, 5.00, '2026-09-09 10:57:01'),
(5, 'Maize (Makai)', 'GRAIN', 28.00, 4.00, '2026-09-09 10:57:01'),
(6, 'Multigrain Mix', 'GRAIN', 60.00, 8.00, '2026-09-09 10:57:01'),
(7, 'Ragi (Finger Millet)', 'GRAIN', 55.00, 7.00, '2026-09-09 10:57:01');

-- --------------------------------------------------------

--
-- Table structure for table `inventory`
--

CREATE TABLE `inventory` (
  `id` int(11) NOT NULL,
  `mill_id` int(11) NOT NULL,
  `product_type` enum('FLOUR','GRAIN','PACKAGING','OTHER') NOT NULL DEFAULT 'FLOUR',
  `name` varchar(150) NOT NULL,
  `stock_kg` decimal(10,2) NOT NULL DEFAULT 0.00,
  `minimum_stock_kg` decimal(10,2) NOT NULL DEFAULT 20.00,
  `price_per_kg` decimal(10,2) NOT NULL DEFAULT 0.00,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `inventory`
--

INSERT INTO `inventory` (`id`, `mill_id`, `product_type`, `name`, `stock_kg`, `minimum_stock_kg`, `price_per_kg`, `updated_at`) VALUES
(1, 101, 'FLOUR', 'Wheat Flour (Fresh Atta)', 150.00, 30.00, 45.00, '2026-09-09 10:57:01'),
(2, 101, 'GRAIN', 'Raw Premium Sharbati Wheat', 400.00, 100.00, 36.00, '2026-09-09 10:57:01'),
(3, 101, 'FLOUR', 'Multigrain Dietary Flour', 65.00, 20.00, 68.00, '2026-09-09 10:57:01'),
(4, 101, 'GRAIN', 'Dark Rye Grain', 12.00, 25.00, 48.00, '2026-09-09 10:57:01');

-- --------------------------------------------------------

--
-- Table structure for table `mills`
--

CREATE TABLE `mills` (
  `id` int(11) NOT NULL,
  `owner_user_id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `phone` varchar(20) NOT NULL,
  `address` text NOT NULL,
  `latitude` decimal(10,8) NOT NULL,
  `longitude` decimal(11,8) NOT NULL,
  `rating` decimal(3,2) DEFAULT 4.80,
  `total_ratings` int(11) DEFAULT 0,
  `is_open` tinyint(1) DEFAULT 1,
  `estimated_time` varchar(50) DEFAULT '30-45 min',
  `capacity_kg_per_day` decimal(10,2) DEFAULT 500.00,
  `current_load_kg` decimal(10,2) DEFAULT 0.00,
  `specialty` varchar(150) DEFAULT 'Fresh Stone Ground Flour',
  `working_hours` varchar(100) DEFAULT '08:00 AM - 08:00 PM',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `mills`
--

INSERT INTO `mills` (`id`, `owner_user_id`, `name`, `phone`, `address`, `latitude`, `longitude`, `rating`, `total_ratings`, `is_open`, `estimated_time`, `capacity_kg_per_day`, `current_load_kg`, `specialty`, `working_hours`, `created_at`, `updated_at`) VALUES
(101, 2, 'Shree Ganesh Flour Mill', '+919876543211', '12 Market Yard, Ellisbridge, Ahmedabad', 23.02250000, 72.57140000, 4.80, 128, 1, '30-45 min', 600.00, 420.00, 'Fresh Stone Ground Flour', '08:00 AM - 08:00 PM', '2026-09-09 10:57:01', '2026-09-09 10:57:01'),
(102, 99, 'Navrang Quality Atta Mill', '+919876543299', '45 Swastik Cross Road, Navrangpura, Ahmedabad', 23.03800000, 72.56200000, 4.80, 94, 1, '20-30 min', 500.00, 310.00, 'Organic Whole Wheat & Multigrain', '09:00 AM - 07:30 PM', '2026-09-09 10:57:01', '2026-09-09 10:57:01'),
(103, 100, 'Mahadev Traditional Chakki', '+919876543288', 'Shop 8, Vastrapur Lake Complex, Ahmedabad', 23.03500000, 72.52800000, 4.70, 76, 1, '25-40 min', 450.00, 290.00, 'Bajra & Jowar Specialized Grinding', '08:30 AM - 08:30 PM', '2026-09-09 10:57:01', '2026-09-09 10:57:01');

-- --------------------------------------------------------

--
-- Table structure for table `mill_services`
--

CREATE TABLE `mill_services` (
  `id` int(11) NOT NULL,
  `mill_id` int(11) NOT NULL,
  `service_name` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `mill_services`
--

INSERT INTO `mill_services` (`id`, `mill_id`, `service_name`) VALUES
(1, 101, 'Flour Grinding'),
(2, 101, 'Packing'),
(3, 101, 'Home Delivery'),
(4, 101, 'Cleaning'),
(5, 102, 'Flour Grinding'),
(6, 102, 'Home Delivery'),
(7, 103, 'Flour Grinding'),
(8, 103, 'Packing'),
(9, 103, 'Home Delivery');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `title` varchar(150) NOT NULL,
  `message` text NOT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `user_id`, `title`, `message`, `is_read`, `created_at`) VALUES
(1, 2, '🚨 New Order Received #ORD-2026-1002', 'Elena Rodriguez placed a new order for 5kg Multigrain Mix (₹175.00).', 0, '2026-09-09 10:57:01'),
(2, 2, '🛵 Driver Arrived for Pickup', 'Rajesh Kumar (Electric Bike #EB-4821) arrived at store for order #ORD-2026-1001.', 0, '2026-09-09 10:57:01'),
(3, 2, '⚠️ Low Stock Alert: Dark Rye Blend', 'Stock has fallen below threshold (12kg remaining). Restock soon.', 0, '2026-09-09 10:57:01'),
(4, 2, '🛡️ Food Safety Audit Status', 'Daily chakki stone sanitization and grain moisture test verified (Score 99%).', 1, '2026-09-09 10:57:01');

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `id` int(11) NOT NULL,
  `order_number` varchar(50) NOT NULL,
  `user_id` int(11) NOT NULL,
  `customer_name` varchar(100) DEFAULT NULL,
  `customer_phone` varchar(20) DEFAULT NULL,
  `mill_id` int(11) NOT NULL,
  `grain_source` varchar(50) NOT NULL DEFAULT 'CUSTOMER',
  `grain_type_id` int(11) NOT NULL,
  `grain_type_name` text NOT NULL,
  `quantity_kg` decimal(10,2) NOT NULL,
  `service_type` varchar(50) NOT NULL DEFAULT 'GRINDING',
  `fulfillment_type` enum('DELIVERY','PICKUP') NOT NULL DEFAULT 'DELIVERY',
  `address_id` int(11) DEFAULT NULL,
  `pickup_pin` varchar(10) DEFAULT '4821',
  `delivery_otp` varchar(10) DEFAULT '7391',
  `payment_method` varchar(50) DEFAULT 'UPI',
  `payment_status` enum('PENDING','PAID','FAILED','REFUNDED') DEFAULT 'PENDING',
  `status` varchar(50) NOT NULL DEFAULT 'PLACED',
  `estimated_minutes` int(11) DEFAULT 30,
  `estimated_completion_time` varchar(50) DEFAULT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `group_id` int(11) DEFAULT NULL,
  `group_code` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`id`, `order_number`, `user_id`, `customer_name`, `customer_phone`, `mill_id`, `grain_source`, `grain_type_id`, `grain_type_name`, `quantity_kg`, `service_type`, `fulfillment_type`, `address_id`, `pickup_pin`, `delivery_otp`, `payment_method`, `payment_status`, `status`, `estimated_minutes`, `estimated_completion_time`, `total_amount`, `group_id`, `group_code`, `created_at`, `updated_at`) VALUES
(501, 'ORD-2026-1001', 1, 'Ramesh Patel', '+919876543210', 101, 'CUSTOMER', 1, 'Wheat (Gehun)', 10.00, 'GRINDING', 'DELIVERY', 25, '4821', '7391', 'UPI', 'PAID', 'PROCESSING', 45, '18:30', 90.00, NULL, NULL, '2026-09-09 10:57:01', '2026-09-09 10:57:01'),
(502, 'ORD-2026-1002', 1, 'Elena Rodriguez', '+919876543219', 101, 'CUSTOMER', 6, 'Multigrain Mix', 5.00, 'GRINDING', 'DELIVERY', 25, '1942', '6543', 'UPI', 'PAID', 'PLACED', 30, NULL, 175.00, NULL, NULL, '2026-09-09 10:57:01', '2026-09-09 10:57:01'),
(503, 'ORD-2026-1003', 1, 'Marcus Chen', '+919876543220', 101, 'MILL', 4, 'Jowar (Sorghum)', 10.00, 'GRINDING', 'DELIVERY', 25, '8210', '9120', 'UPI', 'PAID', 'DELIVERED', 40, '12:40', 380.00, NULL, NULL, '2026-09-09 10:57:01', '2026-09-09 10:57:01'),
(504, 'ORD-2026-1004', 1, 'Priya Sharma', '+919876543222', 101, 'MILL', 1, 'Wheat (Gehun)', 5.00, 'GRINDING', 'PICKUP', NULL, '3321', NULL, 'CASH', 'PENDING', 'READY_FOR_PICKUP', 25, '15:00', 200.00, NULL, NULL, '2026-09-09 10:57:01', '2026-09-09 10:57:01'),
(505, '#HD-437154484', 1, 'Ramesh Patel', '+919876543210', 101, 'CUSTOMER', 1, 'Wheat (Gehun)', 15.00, 'GRINDING', 'DELIVERY', 25, '4821', '7391', 'UPI', 'PAID', 'DELIVERED', 30, 'Within 24 Hours', 77.00, NULL, NULL, '2026-09-09 10:57:17', '2026-09-09 10:57:17');

-- --------------------------------------------------------

--
-- Table structure for table `order_timeline`
--

CREATE TABLE `order_timeline` (
  `id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `status` varchar(50) NOT NULL,
  `title` varchar(150) DEFAULT NULL,
  `note` text DEFAULT NULL,
  `description` text DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `order_timeline`
--

INSERT INTO `order_timeline` (`id`, `order_id`, `status`, `title`, `note`, `description`, `timestamp`) VALUES
(1, 501, 'PLACED', NULL, 'Order placed by customer', NULL, '2026-09-09 10:57:01'),
(2, 501, 'ACCEPTED', NULL, 'Accepted by shopkeeper', NULL, '2026-09-09 10:57:01'),
(3, 501, 'PROCESSING', NULL, 'Grinding started', NULL, '2026-09-09 10:57:01'),
(4, 502, 'PLACED', NULL, 'Order placed by customer', NULL, '2026-09-09 10:57:01'),
(5, 503, 'PLACED', NULL, 'Order placed by customer', NULL, '2026-09-09 10:57:01'),
(6, 503, 'DELIVERED', NULL, 'Order delivered to customer', NULL, '2026-09-09 10:57:01'),
(7, 504, 'PLACED', NULL, 'Pickup order placed', NULL, '2026-09-09 10:57:01'),
(8, 504, 'READY_FOR_PICKUP', NULL, 'Ready at counter', NULL, '2026-09-09 10:57:01'),
(9, 505, 'PLACED', 'Order Placed', NULL, 'Order placed by customer', '2026-09-09 10:57:17'),
(10, 505, 'ACCEPTED', 'Order Accepted', NULL, 'Accepted by mill owner (ETA: 30 mins)', '2026-09-09 10:57:17'),
(11, 505, 'PROCESSING', 'Milling Started', NULL, 'Chakki grinding started', '2026-09-09 10:57:17'),
(12, 505, 'PACKING', 'Packing Started', NULL, 'Flour packing & bagging started', '2026-09-09 10:57:17'),
(13, 505, 'READY', 'Order Ready', NULL, 'Order packed and ready for fulfillment', '2026-09-09 10:57:17'),
(14, 505, 'DELIVERED', 'Order Delivered', NULL, 'Package safely handed over at doorstep. Verified.', '2026-09-09 10:57:17');

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `id` varchar(100) NOT NULL,
  `order_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `payment_method` varchar(50) NOT NULL DEFAULT 'UPI',
  `status` varchar(50) NOT NULL DEFAULT 'CREATED',
  `transaction_id` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `payments`
--

INSERT INTO `payments` (`id`, `order_id`, `amount`, `payment_method`, `status`, `transaction_id`, `created_at`) VALUES
('PAY-1001', 501, 90.00, 'UPI', 'SUCCESS', 'TXN_9988776655', '2026-09-09 10:57:01');

-- --------------------------------------------------------

--
-- Table structure for table `reviews`
--

CREATE TABLE `reviews` (
  `id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `user_name` varchar(100) NOT NULL,
  `mill_id` int(11) NOT NULL,
  `rating` int(11) NOT NULL CHECK (`rating` between 1 and 5),
  `review` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `reviews`
--

INSERT INTO `reviews` (`id`, `order_id`, `user_id`, `user_name`, `mill_id`, `rating`, `review`, `created_at`) VALUES
(1, 503, 1, 'Ramesh Patel', 101, 5, 'Excellent grinding quality, perfect fineness, and super fast home delivery service.', '2026-09-09 10:57:01');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(150) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('CUSTOMER','SHOPKEEPER','DELIVERY','ADMIN') NOT NULL DEFAULT 'CUSTOMER',
  `mill_id` int(11) DEFAULT NULL,
  `vehicle_number` varchar(50) DEFAULT NULL,
  `vehicle_type` varchar(50) DEFAULT 'Electric Scooter',
  `is_online` tinyint(1) DEFAULT 1,
  `rating` decimal(3,2) DEFAULT 5.00,
  `total_trips` int(11) DEFAULT 0,
  `profile_image` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `phone`, `password`, `role`, `mill_id`, `vehicle_number`, `vehicle_type`, `is_online`, `rating`, `total_trips`, `profile_image`, `created_at`, `updated_at`) VALUES
(1, 'Ramesh Patel', 'ramesh@example.com', '+919876543210', '$2a$10$.Iwo0Ld9nmRHRsW1LY.4.uZL1PYggfQpniVjj/tm5a8mzxxi6wR.e', 'CUSTOMER', NULL, NULL, NULL, 1, 5.00, 0, 'https://images.unsplash.com/photo-1534528741775-53994a69daeb', '2026-09-09 10:57:01', '2026-09-09 10:57:17'),
(2, 'Suresh Mill Owner', 'shop@shreeganesh.com', '+919876543211', '$2a$10$IB8Wa17N4.zImQI4zOgQKOxxo/JuH2PoYNRHgepQK9TB01Xbp5OOe', 'SHOPKEEPER', 101, NULL, NULL, 1, 4.80, 0, NULL, '2026-09-09 10:57:01', '2026-09-09 10:57:01'),
(3, 'Vikram Delivery Agent', 'delivery@herdoor.com', '+919876543212', '$2a$10$IB8Wa17N4.zImQI4zOgQKOxxo/JuH2PoYNRHgepQK9TB01Xbp5OOe', 'DELIVERY', NULL, 'GJ-01-AB-1234', 'Electric Scooter', 1, 4.90, 184, 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d', '2026-09-09 10:57:01', '2026-09-09 10:57:01'),
(4, 'Super Admin', 'admin@herdoor.com', '+919876543200', '$2a$10$IB8Wa17N4.zImQI4zOgQKOxxo/JuH2PoYNRHgepQK9TB01Xbp5OOe', 'ADMIN', NULL, NULL, NULL, 1, 5.00, 0, NULL, '2026-09-09 10:57:01', '2026-09-09 10:57:01'),
(5, 'Rajesh Kumar', 'rajesh.rider@herdoor.com', '+919876543215', '$2a$10$IB8Wa17N4.zImQI4zOgQKOxxo/JuH2PoYNRHgepQK9TB01Xbp5OOe', 'DELIVERY', NULL, 'GJ-01-EB-4821', 'Electric Bike', 1, 4.85, 96, NULL, '2026-09-09 10:57:01', '2026-09-09 10:57:01'),
(6, 'Aarav Mehta', NULL, '+919876543299', '$2a$10$oaTYkzudBeqSlTvKkgM3XegWi.oUR4ZM70wBrWq7TEKItTaRdrVIi', 'CUSTOMER', NULL, NULL, 'Electric Scooter', 1, 5.00, 0, NULL, '2026-09-09 10:57:17', '2026-09-09 10:57:17');

-- --------------------------------------------------------

--
-- Table structure for table `user_favorites`
--

CREATE TABLE `user_favorites` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `mill_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `wholesalers`
--

CREATE TABLE `wholesalers` (
  `id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `contact_person` varchar(100) DEFAULT NULL,
  `phone` varchar(20) NOT NULL,
  `city` varchar(100) DEFAULT 'Ahmedabad',
  `grains_supplied` text DEFAULT NULL,
  `rating` decimal(3,2) DEFAULT 4.80,
  `stock_available_tons` decimal(10,2) DEFAULT 50.00,
  `status` varchar(50) DEFAULT 'ACTIVE',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `wholesalers`
--

INSERT INTO `wholesalers` (`id`, `name`, `contact_person`, `phone`, `city`, `grains_supplied`, `rating`, `stock_available_tons`, `status`, `created_at`) VALUES
(1, 'Gujarat Agro Grain Depot', 'Harish Mehta', '+919876543301', 'Ahmedabad', 'Wheat, Bajra, Jowar', 4.80, 145.50, 'ACTIVE', '2026-09-09 10:57:01'),
(2, 'Saurashtra Organic Pulses & Grains', 'Bhavesh Dave', '+919876543302', 'Rajkot', 'Ragi, Makai, Organic Wheat', 4.90, 88.00, 'ACTIVE', '2026-09-09 10:57:01');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `addresses`
--
ALTER TABLE `addresses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_addresses_user` (`user_id`);

--
-- Indexes for table `deliveries`
--
ALTER TABLE `deliveries`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `order_id` (`order_id`);

--
-- Indexes for table `devices`
--
ALTER TABLE `devices`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_devices_user` (`user_id`);

--
-- Indexes for table `grain_sources`
--
ALTER TABLE `grain_sources`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`);

--
-- Indexes for table `grain_types`
--
ALTER TABLE `grain_types`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `inventory`
--
ALTER TABLE `inventory`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_inventory_mill` (`mill_id`);

--
-- Indexes for table `mills`
--
ALTER TABLE `mills`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_mills_lat_lon` (`latitude`,`longitude`);

--
-- Indexes for table `mill_services`
--
ALTER TABLE `mill_services`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_services_mill` (`mill_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_notifications_user` (`user_id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `order_number` (`order_number`),
  ADD KEY `fk_orders_user` (`user_id`),
  ADD KEY `fk_orders_mill` (`mill_id`),
  ADD KEY `idx_orders_status` (`status`),
  ADD KEY `idx_orders_group_code` (`group_code`),
  ADD KEY `idx_orders_group_id` (`group_id`);

--
-- Indexes for table `order_timeline`
--
ALTER TABLE `order_timeline`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_timeline_order` (`order_id`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_payments_order` (`order_id`);

--
-- Indexes for table `reviews`
--
ALTER TABLE `reviews`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `order_id` (`order_id`),
  ADD KEY `fk_reviews_mill` (`mill_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `phone` (`phone`),
  ADD KEY `idx_users_role` (`role`),
  ADD KEY `idx_users_phone` (`phone`);

--
-- Indexes for table `user_favorites`
--
ALTER TABLE `user_favorites`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_user_mill` (`user_id`,`mill_id`),
  ADD KEY `fk_favorites_mill` (`mill_id`);

--
-- Indexes for table `wholesalers`
--
ALTER TABLE `wholesalers`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `addresses`
--
ALTER TABLE `addresses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT for table `deliveries`
--
ALTER TABLE `deliveries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=803;

--
-- AUTO_INCREMENT for table `devices`
--
ALTER TABLE `devices`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `grain_sources`
--
ALTER TABLE `grain_sources`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `grain_types`
--
ALTER TABLE `grain_types`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `inventory`
--
ALTER TABLE `inventory`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `mills`
--
ALTER TABLE `mills`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=104;

--
-- AUTO_INCREMENT for table `mill_services`
--
ALTER TABLE `mill_services`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=506;

--
-- AUTO_INCREMENT for table `order_timeline`
--
ALTER TABLE `order_timeline`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `reviews`
--
ALTER TABLE `reviews`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `user_favorites`
--
ALTER TABLE `user_favorites`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `wholesalers`
--
ALTER TABLE `wholesalers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `addresses`
--
ALTER TABLE `addresses`
  ADD CONSTRAINT `fk_addresses_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `deliveries`
--
ALTER TABLE `deliveries`
  ADD CONSTRAINT `fk_deliveries_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `devices`
--
ALTER TABLE `devices`
  ADD CONSTRAINT `fk_devices_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `inventory`
--
ALTER TABLE `inventory`
  ADD CONSTRAINT `fk_inventory_mill` FOREIGN KEY (`mill_id`) REFERENCES `mills` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `mill_services`
--
ALTER TABLE `mill_services`
  ADD CONSTRAINT `fk_services_mill` FOREIGN KEY (`mill_id`) REFERENCES `mills` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `fk_notifications_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `fk_orders_mill` FOREIGN KEY (`mill_id`) REFERENCES `mills` (`id`),
  ADD CONSTRAINT `fk_orders_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `order_timeline`
--
ALTER TABLE `order_timeline`
  ADD CONSTRAINT `fk_timeline_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `fk_payments_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `reviews`
--
ALTER TABLE `reviews`
  ADD CONSTRAINT `fk_reviews_mill` FOREIGN KEY (`mill_id`) REFERENCES `mills` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_reviews_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_favorites`
--
ALTER TABLE `user_favorites`
  ADD CONSTRAINT `fk_favorites_mill` FOREIGN KEY (`mill_id`) REFERENCES `mills` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_favorites_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
