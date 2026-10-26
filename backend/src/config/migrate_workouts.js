require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });
const { pool } = require('./db');

async function runWorkoutsMigration() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS workouts (
        id            VARCHAR(36)  PRIMARY KEY,
        title         VARCHAR(255) NOT NULL,
        difficulty    VARCHAR(50)  NOT NULL,
        location_type VARCHAR(50)  NOT NULL,
        category      VARCHAR(100) NOT NULL,
        description   TEXT,
        duration_minutes INT       DEFAULT NULL,
        calories_burned  FLOAT     DEFAULT NULL,
        fitness_goal  VARCHAR(100) DEFAULT NULL,
        created_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
        updated_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Migration: workouts table ready.');
  } catch (error) {
    console.error('❌ Migration error (workouts):', error.message);
  }
}

module.exports = { runWorkoutsMigration };
