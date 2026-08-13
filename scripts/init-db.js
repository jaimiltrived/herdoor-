require('dotenv').config();
const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');

async function initializeDatabase() {
  const config = {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '3307'),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    multipleStatements: true
  };

  console.log(`Connecting to MySQL server at ${config.host}:${config.port}...`);

  try {
    const connection = await mysql.createConnection(config);
    console.log('✔ MySQL Server connection established.');

    const schemaSql = fs.readFileSync(path.join(__dirname, '../database/schema.sql'), 'utf-8');
    console.log('Running schema.sql...');
    await connection.query(schemaSql);
    console.log('✔ Database schema initialized successfully.');

    const seedSql = fs.readFileSync(path.join(__dirname, '../database/seed.sql'), 'utf-8');
    console.log('Running seed.sql...');
    await connection.query(seedSql);
    console.log('✔ Initial seed data populated successfully.');

    await connection.end();
    console.log('✔ Database setup finished cleanly.');
    process.exit(0);
  } catch (err) {
    console.error('❌ Database Initialization Warning/Error:', err.message);
    console.log('Note: If MySQL local server on port 3307 is not currently running, the app will continue using the standard in-memory repository layer.');
    process.exit(0);
  }
}

initializeDatabase();
