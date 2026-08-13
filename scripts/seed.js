require('dotenv').config();
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const store = require('../src/store/dataStore');

async function seedDatabase() {
  const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '3307'),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: (process.env.DB_NAME || 'herdoor').trim(),
    multipleStatements: true
  };

  console.log('🌱 Starting HerDoor Database JS Seeder...');
  console.log(`Connecting to MySQL database '${dbConfig.database}' at ${dbConfig.host}:${dbConfig.port}...`);

  try {
    const connection = await mysql.createConnection(dbConfig);
    console.log('✔ MySQL Server connected.');

    // 1. Password Hashing
    const defaultPassword = await bcrypt.hash('Password123!', 8);

    // 2. Disable Foreign Key Checks
    await connection.query('SET FOREIGN_KEY_CHECKS = 0;');

    // 3. Truncate Tables
    const tables = [
      'devices', 'notifications', 'reviews', 'inventory', 'deliveries',
      'payments', 'order_timeline', 'orders', 'grain_types', 'grain_sources',
      'mill_services', 'mills', 'addresses', 'users'
    ];

    for (const table of tables) {
      await connection.query(`TRUNCATE TABLE \`${table}\`;`);
    }
    console.log('✔ Cleared existing database tables.');

    // 4. Seed Users
    const users = [
      [1, 'Ramesh Patel', 'ramesh@example.com', '+919876543210', defaultPassword, 'CUSTOMER', null, null, 'https://images.unsplash.com/photo-1534528741775-53994a69daeb'],
      [2, 'Suresh Mill Owner', 'shop@shreeganesh.com', '+919876543211', defaultPassword, 'SHOPKEEPER', 101, null, null],
      [3, 'Vikram Delivery Agent', 'delivery@herdoor.com', '+919876543212', defaultPassword, 'DELIVERY', null, 'GJ-01-AB-1234', null]
    ];
    for (const user of users) {
      await connection.query(
        'INSERT INTO `users` (`id`, `name`, `email`, `phone`, `password`, `role`, `mill_id`, `vehicle_number`, `profile_image`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        user
      );
    }
    console.log('✔ Users seeded.');

    // 5. Seed Addresses
    await connection.query(
      'INSERT INTO `addresses` (`id`, `user_id`, `address_line1`, `address_line2`, `city`, `state`, `pincode`, `latitude`, `longitude`, `is_default`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [25, 1, 'Flat 402, Shivalik Towers', 'Satellite Road', 'Ahmedabad', 'Gujarat', '380015', 23.02500000, 72.57000000, 1]
    );
    console.log('✔ Addresses seeded.');

    // 6. Seed Mills
    const mills = [
      [101, 2, 'Shree Ganesh Flour Mill', '+919876543211', '12 Market Yard, Ellisbridge, Ahmedabad', 23.02250000, 72.57140000, 4.60, 128, 1, '30-45 min', '08:00 AM - 08:00 PM'],
      [102, 99, 'Navrang Quality Atta Mill', '+919876543299', '45 Swastik Cross Road, Navrangpura, Ahmedabad', 23.03800000, 72.56200000, 4.80, 94, 1, '20-30 min', '09:00 AM - 07:30 PM']
    ];
    for (const mill of mills) {
      await connection.query(
        'INSERT INTO `mills` (`id`, `owner_user_id`, `name`, `phone`, `address`, `latitude`, `longitude`, `rating`, `total_ratings`, `is_open`, `estimated_time`, `working_hours`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        mill
      );
    }
    console.log('✔ Mills seeded.');

    // 7. Seed Mill Services
    const millServices = [
      [101, 'Flour Grinding'],
      [101, 'Packing'],
      [101, 'Home Delivery'],
      [101, 'Cleaning'],
      [102, 'Flour Grinding'],
      [102, 'Home Delivery']
    ];
    for (const ms of millServices) {
      await connection.query('INSERT INTO `mill_services` (`mill_id`, `service_name`) VALUES (?, ?)', ms);
    }
    console.log('✔ Mill Services seeded.');

    // 8. Seed Grain Sources
    const grainSources = [
      [1, 'CUSTOMER', "Customer's own grain", "Bring/pickup customer's own raw grain for milling"],
      [2, 'MILL', 'Mill-provided grain', 'Fresh grain supplied directly by the mill'],
      [3, 'VENDOR', 'Vendor grain', 'Premium vendor sourced grain']
    ];
    for (const gs of grainSources) {
      await connection.query('INSERT INTO `grain_sources` (`id`, `code`, `name`, `description`) VALUES (?, ?, ?, ?)', gs);
    }
    console.log('✔ Grain Sources seeded.');

    // 9. Seed Grain Types Catalog
    const grainTypes = [
      [1, 'Wheat (Gehun)', 'GRAIN', 35.00, 5.00],
      [2, 'Rice (Chawal)', 'GRAIN', 40.00, 6.00],
      [3, 'Bajra (Pearl Millet)', 'GRAIN', 30.00, 5.00],
      [4, 'Jowar (Sorghum)', 'GRAIN', 38.00, 5.00],
      [5, 'Maize (Makai)', 'GRAIN', 28.00, 4.00],
      [6, 'Multigrain Mix', 'GRAIN', 60.00, 8.00],
      [7, 'Ragi (Finger Millet)', 'GRAIN', 55.00, 7.00]
    ];
    for (const gt of grainTypes) {
      await connection.query('INSERT INTO `grain_types` (`id`, `name`, `category`, `price_per_kg`, `grinding_fee_per_kg`) VALUES (?, ?, ?, ?, ?)', gt);
    }
    console.log('✔ Grain Types catalog seeded.');

    // 10. Seed Initial Orders
    await connection.query(
      'INSERT INTO `orders` (`id`, `order_number`, `user_id`, `mill_id`, `grain_source`, `grain_type_id`, `grain_type_name`, `quantity_kg`, `service_type`, `fulfillment_type`, `address_id`, `payment_method`, `payment_status`, `status`, `estimated_minutes`, `estimated_completion_time`, `total_amount`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [501, 'ORD-2026-1001', 1, 101, 'CUSTOMER', 1, 'Wheat (Gehun)', 10.00, 'GRINDING', 'DELIVERY', 25, 'UPI', 'PAID', 'PROCESSING', 45, '18:30', 90.00]
    );

    // 11. Seed Order Timeline
    const timelineEntries = [
      [501, 'PLACED', 'Order placed by customer'],
      [501, 'ACCEPTED', 'Accepted by shopkeeper'],
      [501, 'PROCESSING', 'Grinding started']
    ];
    for (const entry of timelineEntries) {
      await connection.query('INSERT INTO `order_timeline` (`order_id`, `status`, `note`) VALUES (?, ?, ?)', entry);
    }

    // 12. Seed Payments
    await connection.query(
      'INSERT INTO `payments` (`id`, `order_id`, `amount`, `payment_method`, `status`, `transaction_id`) VALUES (?, ?, ?, ?, ?, ?)',
      ['PAY-1001', 501, 90.00, 'UPI', 'SUCCESS', 'TXN_9988776655']
    );

    // 13. Seed Deliveries
    await connection.query(
      'INSERT INTO `deliveries` (`id`, `order_id`, `delivery_person_id`, `delivery_person_name`, `delivery_person_phone`, `status`, `pickup_address`, `delivery_address`) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [801, 501, 3, 'Vikram Delivery Agent', '+919876543212', 'ASSIGNED', 'Shree Ganesh Flour Mill, Market Yard', 'Flat 402, Shivalik Towers, Satellite Road']
    );

    // 14. Seed Inventory
    const inventoryItems = [
      [1, 101, 'FLOUR', 'Wheat Flour (Fresh Atta)', 150.00, 30.00, 45.00],
      [2, 101, 'GRAIN', 'Raw Premium Sharbati Wheat', 400.00, 100.00, 36.00]
    ];
    for (const item of inventoryItems) {
      await connection.query('INSERT INTO `inventory` (`id`, `mill_id`, `product_type`, `name`, `stock_kg`, `minimum_stock_kg`, `price_per_kg`) VALUES (?, ?, ?, ?, ?, ?, ?)', item);
    }

    // 15. Seed Reviews & Notifications & Devices
    await connection.query(
      'INSERT INTO `reviews` (`id`, `order_id`, `user_id`, `user_name`, `mill_id`, `rating`, `review`) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [1, 501, 1, 'Ramesh Patel', 101, 5, 'Excellent grinding quality and fast home delivery service.']
    );

    await connection.query(
      'INSERT INTO `notifications` (`id`, `user_id`, `title`, `message`, `is_read`) VALUES (?, ?, ?, ?, ?)',
      [1, 1, 'Order Accepted', 'Shree Ganesh Flour Mill accepted your order #ORD-2026-1001.', 0]
    );

    await connection.query(
      'INSERT INTO `devices` (`id`, `user_id`, `fcm_token`, `device_type`) VALUES (?, ?, ?, ?)',
      [1, 1, 'token_sample_abc123', 'ANDROID']
    );

    // Enable Foreign Key Checks
    await connection.query('SET FOREIGN_KEY_CHECKS = 1;');
    await connection.end();

    console.log('🎉 HerDoor MySQL Database seeded successfully via JavaScript Seeder!');
  } catch (err) {
    console.warn('⚠️  MySQL Database Seeding Warning:', err.message);
    console.log('ℹ️  Note: If MySQL server is offline or unreachable, the in-memory data store serves as fallback.');
  }
}

if (require.main === module) {
  seedDatabase().then(() => process.exit(0));
}

module.exports = seedDatabase;
