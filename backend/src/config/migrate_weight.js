const { pool } = require('./db');

async function runWeightMigration() {
    try {
        await pool.query(`
            CREATE TABLE IF NOT EXISTS user_weight_logs (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id VARCHAR(255) NOT NULL,
                weight FLOAT NOT NULL,
                recorded_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                INDEX idx_user_date (user_id, recorded_date DESC)
            )
        `);
        console.log("✅ Migration: user_weight_logs table created successfully (Optimized for PKCTB-305).");
    } catch (error) {
        console.error("❌ Migration error:", error.message);
    }
}

module.exports = { runWeightMigration };
