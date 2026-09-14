-- Migration 002: Package-Level QR & Automatic 2-Leg Delivery Workflow

USE `herdoor`;

-- 1. Packages Table
CREATE TABLE IF NOT EXISTS `packages` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `order_id` INT NOT NULL,
  `order_item_id` INT DEFAULT NULL,
  `package_code` VARCHAR(100) NOT NULL UNIQUE,
  `qr_token` VARCHAR(255) NOT NULL UNIQUE,
  `product_name` VARCHAR(150) NOT NULL,
  `expected_weight` DECIMAL(10, 2) NOT NULL,
  `actual_weight` DECIMAL(10, 2) DEFAULT NULL,
  `unit` VARCHAR(20) DEFAULT 'KG',
  `status` ENUM(
    'CREATED',
    'READY_FOR_PICKUP',
    'PICKED_UP_FROM_CUSTOMER',
    'RECEIVED_AT_MILL',
    'PROCESSING',
    'READY_FOR_DELIVERY',
    'PICKED_UP_FROM_MILL',
    'OUT_FOR_DELIVERY',
    'DELIVERED'
  ) NOT NULL DEFAULT 'CREATED',
  `current_leg` ENUM('LEG_1', 'LEG_2', 'COMPLETED') NOT NULL DEFAULT 'LEG_1',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_packages_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  INDEX `idx_packages_order_id` (`order_id`),
  INDEX `idx_packages_qr_token` (`qr_token`),
  INDEX `idx_packages_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Delivery Tasks Table (2-Leg Logistics Task Management)
CREATE TABLE IF NOT EXISTS `delivery_tasks` (
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

-- 3. Package Scan Event Audit Log Table
CREATE TABLE IF NOT EXISTS `package_scan_events` (
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

-- 4. Backfill existing orders with a default package & leg 1 task if none exist
INSERT INTO `packages` (`order_id`, `package_code`, `qr_token`, `product_name`, `expected_weight`, `unit`, `status`, `current_leg`)
SELECT 
  o.id,
  CONCAT('PKG-', o.order_number, '-01'),
  CONCAT('QR-', o.order_number, '-01-TOK-', UUID_SHORT()),
  o.grain_type_name,
  o.quantity_kg,
  'KG',
  CASE 
    WHEN o.status = 'DELIVERED' THEN 'DELIVERED'
    WHEN o.status = 'OUT_FOR_DELIVERY' THEN 'OUT_FOR_DELIVERY'
    WHEN o.status = 'READY_FOR_DELIVERY' THEN 'READY_FOR_DELIVERY'
    WHEN o.status = 'PROCESSING' THEN 'PROCESSING'
    WHEN o.status = 'PICKUP' THEN 'PICKED_UP_FROM_CUSTOMER'
    ELSE 'CREATED'
  END,
  CASE
    WHEN o.status IN ('DELIVERED', 'OUT_FOR_DELIVERY', 'READY_FOR_DELIVERY') THEN 'LEG_2'
    ELSE 'LEG_1'
  END
FROM `orders` o
WHERE NOT EXISTS (SELECT 1 FROM `packages` p WHERE p.order_id = o.id);

-- Backfill Leg 1 task for existing non-delivered orders
INSERT INTO `delivery_tasks` (`order_id`, `leg`, `delivery_person_id`, `status`, `created_at`)
SELECT 
  o.id,
  'LEG_1_CUSTOMER_TO_MILL',
  d.delivery_person_id,
  CASE WHEN o.status IN ('PICKUP', 'PROCESSING', 'READY_FOR_DELIVERY', 'OUT_FOR_DELIVERY', 'DELIVERED') THEN 'COMPLETED' ELSE 'AVAILABLE' END,
  o.created_at
FROM `orders` o
LEFT JOIN `deliveries` d ON d.order_id = o.id
WHERE NOT EXISTS (SELECT 1 FROM `delivery_tasks` dt WHERE dt.order_id = o.id AND dt.leg = 'LEG_1_CUSTOMER_TO_MILL');
