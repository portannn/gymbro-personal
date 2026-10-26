require('dotenv').config();
const { pool } = require('../src/config/db');

async function checkTable() {
  try {
    const [tables] = await pool.query('SHOW TABLES');
    console.log('Tables in database:', tables);

    const [columns] = await pool.query('DESCRIBE exercises');
    console.log('Exercises Table Structure:');
    console.table(columns);
    
    // ... rest
  } catch (err) {
    console.error('Error during DB check:', err);
    process.exit(1);
  }
}

checkTable();
