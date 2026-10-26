const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  ssl: {
    ca: fs.readFileSync(path.join(__dirname, 'ca.pem')),
  },
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  // Prevent ECONNRESET on idle SSL connections
  enableKeepAlive: true,
  keepAliveInitialDelay: 10000, // send keepalive ping every 10s
  connectTimeout: 30000,        // 30s timeout saat koneksi baru
  idleTimeout: 60000,           // tutup koneksi idle setelah 60s
});

const testConnection = async () => {
  try {
    const conn = await pool.getConnection();
    console.log('MySQL connected successfully');
    conn.release();
  } catch (err) {
    console.error('MySQL connection failed:', err.message);
    process.exit(1);
  }
};

module.exports = { pool, testConnection };