const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

async function runMigration() {
  const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '3307', 10),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'herdoor',
    multipleStatements: true
  });

  try {
    console.log('Connecting to database...');
    const sqlPath = path.join(__dirname, '../database/migrations/002_package_and_2leg_delivery.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    console.log('Running migration script...');
    await pool.query(sql);
    console.log('✅ Migration 002 executed successfully!');
  } catch (err) {
    console.error('❌ Migration failed:', err);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

runMigration();
