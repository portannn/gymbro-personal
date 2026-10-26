require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });
const { pool } = require('./db');

// ─────────────────────────────────────────────────────────────────────────────
// Migration: migrate_met.js
// PBI     : Estimasi Kalori Terbakar
// Subtask : [Database] Tambahkan nilai MET pada tabel exercises
//
// MET (Metabolic Equivalent of Task) adalah satuan standar yang merepresentasikan
// intensitas suatu aktivitas fisik relatif terhadap kondisi istirahat.
// Digunakan dalam rumus:
//   Kalori = Durasi (menit) × (MET × 3.5 × Berat Badan kg) / 200
//
// Referensi: Ainsworth BE, et al. "2011 Compendium of Physical Activities"
// ─────────────────────────────────────────────────────────────────────────────

async function runMetMigration() {
  try {
    // ─── STEP 1: Tambahkan kolom met_value (idempotent, aman dijalankan ulang) ──
    // Cek dulu apakah kolom sudah ada agar migration tidak error jika dijalankan ulang
    const [columns] = await pool.query(`
      SELECT COLUMN_NAME
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME   = 'exercises'
        AND COLUMN_NAME  = 'met_value'
    `);

    if (columns.length === 0) {
      // Kolom belum ada → tambahkan
      await pool.query(`
        ALTER TABLE exercises
          ADD COLUMN met_value DECIMAL(4, 2) NOT NULL DEFAULT 1.0
            COMMENT 'Metabolic Equivalent of Task – intensitas latihan relatif terhadap istirahat'
      `);
      console.log('✅ Migration: kolom met_value berhasil ditambahkan ke tabel exercises.');
    } else {
      console.log('ℹ️  Migration: kolom met_value sudah ada, lewati ALTER TABLE.');
    }

    // ─── STEP 2: Seed nilai MET berdasarkan nama latihan ───────────────────────
    // Nilai MET diambil dari Compendium of Physical Activities 2011.
    // Setiap UPDATE hanya memengaruhi baris yang namanya cocok dengan pola,
    // sehingga aman dijalankan berulang kali.
    const metSeeds = [
      { met: 8.0,  patterns: ['%running%', '%lari%'] },
      { met: 7.0,  patterns: ['%cycling%', '%bersepeda%'] },
      { met: 8.0,  patterns: ['%jump rope%', '%skipping%'] },
      { met: 3.5,  patterns: ['%walking%', '%jalan%'] },
      { met: 6.0,  patterns: ['%burpee%'] },
      { met: 5.0,  patterns: ['%push up%', '%pushup%', '%push-up%'] },
      { met: 5.0,  patterns: ['%pull up%', '%pullup%', '%pull-up%'] },
      { met: 5.0,  patterns: ['%squat%'] },
      { met: 5.0,  patterns: ['%lunge%'] },
      { met: 4.0,  patterns: ['%plank%'] },
      { met: 6.0,  patterns: ['%mountain climber%'] },
      { met: 6.0,  patterns: ['%jumping jack%'] },
      { met: 3.5,  patterns: ['%sit up%', '%situp%', '%sit-up%'] },
      { met: 3.5,  patterns: ['%crunch%'] },
      { met: 5.5,  patterns: ['%deadlift%'] },
      { met: 5.0,  patterns: ['%bench press%'] },
      { met: 4.5,  patterns: ['%shoulder press%', '%overhead press%'] },
      { met: 4.0,  patterns: ['%bicep curl%', '%biceps curl%'] },
      { met: 5.0,  patterns: ['%row%'] },
      { met: 6.0,  patterns: ['%hiit%', '%interval%'] },
      { met: 2.5,  patterns: ['%yoga%', '%stretch%'] },
      { met: 4.0,  patterns: ['%pilates%'] },
      { met: 7.0,  patterns: ['%swimming%', '%renang%'] },
      { met: 3.8,  patterns: ['%dumbbell%'] },
      { met: 4.0,  patterns: ['%kettlebell%'] },
      { met: 5.0,  patterns: ['%box jump%'] },
      { met: 5.5,  patterns: ['%step up%'] },
      { met: 6.0,  patterns: ['%battle rope%'] },
      { met: 7.5,  patterns: ['%sprint%'] },
      { met: 4.5,  patterns: ['%leg press%'] },
      { met: 4.0,  patterns: ['%tricep%'] },
      { met: 3.5,  patterns: ['%lat pulldown%'] },
      { met: 4.0,  patterns: ['%hip thrust%', '%glute bridge%'] },
    ];

    let totalUpdated = 0;
    for (const seed of metSeeds) {
      for (const pattern of seed.patterns) {
        const [result] = await pool.query(
          'UPDATE exercises SET met_value = ? WHERE LOWER(name) LIKE ?',
          [seed.met, pattern]
        );
        totalUpdated += result.affectedRows;
      }
    }

    console.log(`✅ Migration: seed MET selesai. Total baris diperbarui: ${totalUpdated}.`);

    // ─── STEP 3: Verifikasi ─────────────────────────────────────────────────────
    const [rows] = await pool.query(
      'SELECT id, name, met_value FROM exercises ORDER BY met_value DESC, name ASC'
    );
    console.log(`ℹ️  Verifikasi: ${rows.length} exercise ditemukan di database.`);
    if (rows.length > 0) {
      console.table(rows.map(r => ({ name: r.name, met_value: r.met_value })));
    }

  } catch (error) {
    console.error('❌ Migration error (met_value):', error.message);
    throw error;
  }
}

module.exports = { runMetMigration };
