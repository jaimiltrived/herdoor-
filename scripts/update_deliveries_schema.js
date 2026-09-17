const path = require('path');
const mysql = require('mysql2/promise');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

async function updateDeliveriesSchema() {
  const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: (process.env.DB_NAME || 'herdoor').trim(),
    multipleStatements: true
  });

  try {
    console.log('Checking deliveries columns...');
    const [cols] = await pool.query('DESCRIBE deliveries');
    const colNames = cols.map(c => c.Field);
    console.log('Existing columns in deliveries:', colNames);

    if (!colNames.includes('leg_type')) {
      await pool.query("ALTER TABLE deliveries ADD COLUMN leg_type VARCHAR(50) DEFAULT 'LEG_1_GRAIN_PICKUP'");
      console.log('Added leg_type column');
    }
    if (!colNames.includes('surge_bonus')) {
      await pool.query("ALTER TABLE deliveries ADD COLUMN surge_bonus DECIMAL(10,2) DEFAULT 0.00");
      console.log('Added surge_bonus column');
    }
    if (!colNames.includes('heavy_bag_bonus')) {
      await pool.query("ALTER TABLE deliveries ADD COLUMN heavy_bag_bonus DECIMAL(10,2) DEFAULT 0.00");
      console.log('Added heavy_bag_bonus column');
    }
    if (!colNames.includes('current_stage')) {
      await pool.query("ALTER TABLE deliveries ADD COLUMN current_stage VARCHAR(50) DEFAULT NULL");
      console.log('Added current_stage column');
    }
    if (!colNames.includes('scanned_bags')) {
      await pool.query("ALTER TABLE deliveries ADD COLUMN scanned_bags TEXT DEFAULT NULL");
      console.log('Added scanned_bags column');
    }
    if (!colNames.includes('rejection_reason')) {
      await pool.query("ALTER TABLE deliveries ADD COLUMN rejection_reason TEXT DEFAULT NULL");
      console.log('Added rejection_reason column');
    }

    console.log('✅ Deliveries schema updated successfully!');

    // Check order 626 and sync a delivery row for it if missing
    const [dels626] = await pool.query('SELECT * FROM deliveries WHERE order_id = 626');
    if (dels626.length === 0) {
      console.log('Creating missing delivery row for order 626...');
      await pool.query(`
        INSERT INTO deliveries
          (order_id, delivery_person_id, delivery_person_name, delivery_person_phone, status, pickup_address, delivery_address, current_latitude, current_longitude, pickup_pin, delivery_otp, delivery_fee, leg_type, current_stage, estimated_minutes, created_at, updated_at)
        VALUES
          (626, 3, 'Vikram Delivery Agent', '+919876543212', 'OUT_FOR_DELIVERY', 'Flat 402, Shivalik Towers, Satellite Road, Ahmedabad', '12 Market Yard, Ellisbridge, Ahmedabad', 23.0225, 72.5714, '4821', '7391', 90.0, 'LEG_1_GRAIN_PICKUP', 'headingToMill', 20, NOW(), NOW())
      `);
      console.log('Synced delivery row for order 626!');
    }
  } catch (err) {
    console.error('❌ Error updating deliveries schema:', err);
  } finally {
    await pool.end();
  }
}

updateDeliveriesSchema();
