const { pool } = require('./db');

async function runMigration() {
    try {
        await pool.query(`
            CREATE TABLE IF NOT EXISTS workout_history (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id VARCHAR(255) NOT NULL,
                workout_name VARCHAR(255) NOT NULL,
                duration_minutes INT NOT NULL,
                calories_burned INT NOT NULL,
                date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                
                -- [PKCTB-245] Relasi & Integritas Data: 
                -- Memastikan riwayat_latihan terikat kuat dengan tabel USERS.
                -- Jika user dihapus, riwayat ikut terhapus (ON DELETE CASCADE)
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                
                -- [PKCTB-244 & PKCTB-246] Optimasi Index: 
                -- 1. Index spesifik pada user_id otomatis terbuat oleh Foreign Key di atas (mempercepat WHERE user_id).
                -- 2. Menambahkan INDEX gabungan (user_id, date) tambahan untuk menyempurnakan performa pagination & sorting.
                INDEX idx_user_date (user_id, date)
            )
        `);
        console.log("✅ Migration: workout_history table created successfully (Optimized for PKCTB-244).");
    } catch (error) {
        console.error("❌ Migration error:", error.message);
    }
}

module.exports = { runMigration };
