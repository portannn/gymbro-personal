
const { pool } = require('./db');

async function runExercisesMigration() {
  try {
    // 1. Table Exercises
    await pool.query(`
      CREATE TABLE IF NOT EXISTS exercises (
        id VARCHAR(36) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        instructions TEXT,
        equipment_required VARCHAR(255),
        base_calories_burn FLOAT DEFAULT 0,
        media_url TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Migration: exercises table ready.');

    // 2. Table Workout Exercises (Join table)
    await pool.query(`
      CREATE TABLE IF NOT EXISTS workout_exercises (
        id INT AUTO_INCREMENT PRIMARY KEY,
        workout_id VARCHAR(36) NOT NULL,
        exercise_id VARCHAR(36) NOT NULL,
        sequence_order INT DEFAULT 0,
        reps_or_duration VARCHAR(255),
        FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
      )
    `);
    console.log('✅ Migration: workout_exercises table ready.');

    // 3. Table Products (Supplements)
    await pool.query(`
      CREATE TABLE IF NOT EXISTS products (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        price DECIMAL(10, 2) NOT NULL,
        stock INT DEFAULT 0,
        category VARCHAR(100),
        image_url TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Migration: products table ready.');

  } catch (error) {
    console.error('❌ Migration error (exercises/products):', error.message);
  }
}

module.exports = { runExercisesMigration };
