-- ============================================================
-- Migration: 001_add_met_value_to_exercises.sql
-- PBI    : Estimasi Kalori Terbakar
-- Subtask: [Database] Tambahkan nilai MET pada tabel exercises
-- Author : Kelompok C
-- Date   : 2026-06-01
--
-- MET (Metabolic Equivalent of Task) adalah satuan standar
-- yang merepresentasikan intensitas suatu aktivitas fisik.
-- Nilai MET digunakan dalam rumus perhitungan kalori:
--   Kalori = Durasi (menit) × (MET × 3.5 × Berat Badan kg) / 200
--
-- Referensi nilai MET:
--   Ainsworth BE, et al. "2011 Compendium of Physical Activities"
--   Medicine & Science in Sports & Exercise.
-- ============================================================

-- ─── STEP 1: Tambahkan kolom met_value ke tabel exercises ───────────────────
-- DEFAULT 1.0 → nilai netral (istirahat duduk = 1.0 MET)
-- Kolom NOT NULL karena setiap latihan HARUS punya nilai MET
-- untuk bisa menghitung kalori secara akurat.
ALTER TABLE exercises
  ADD COLUMN met_value DECIMAL(4, 2) NOT NULL DEFAULT 1.0
    COMMENT 'Metabolic Equivalent of Task – intensitas latihan relatif terhadap istirahat';

-- ─── STEP 2: Seed nilai MET berdasarkan nama latihan yang umum ──────────────
-- Nilai MET diambil dari Compendium of Physical Activities 2011.
-- Latihan yang tidak cocok dengan pola di bawah akan tetap bernilai 1.0
-- dan dapat diperbarui oleh admin melalui panel admin.

UPDATE exercises SET met_value = 8.0  WHERE LOWER(name) LIKE '%running%'      OR LOWER(name) LIKE '%lari%';
UPDATE exercises SET met_value = 7.0  WHERE LOWER(name) LIKE '%cycling%'      OR LOWER(name) LIKE '%bersepeda%';
UPDATE exercises SET met_value = 8.0  WHERE LOWER(name) LIKE '%jump rope%'    OR LOWER(name) LIKE '%skipping%';
UPDATE exercises SET met_value = 3.5  WHERE LOWER(name) LIKE '%walking%'      OR LOWER(name) LIKE '%jalan%';
UPDATE exercises SET met_value = 6.0  WHERE LOWER(name) LIKE '%burpee%';
UPDATE exercises SET met_value = 5.0  WHERE LOWER(name) LIKE '%push up%'      OR LOWER(name) LIKE '%pushup%';
UPDATE exercises SET met_value = 5.0  WHERE LOWER(name) LIKE '%pull up%'      OR LOWER(name) LIKE '%pullup%';
UPDATE exercises SET met_value = 5.0  WHERE LOWER(name) LIKE '%squat%';
UPDATE exercises SET met_value = 5.0  WHERE LOWER(name) LIKE '%lunge%';
UPDATE exercises SET met_value = 4.0  WHERE LOWER(name) LIKE '%plank%';
UPDATE exercises SET met_value = 6.0  WHERE LOWER(name) LIKE '%mountain climber%';
UPDATE exercises SET met_value = 6.0  WHERE LOWER(name) LIKE '%jumping jack%';
UPDATE exercises SET met_value = 3.5  WHERE LOWER(name) LIKE '%sit up%'       OR LOWER(name) LIKE '%situp%';
UPDATE exercises SET met_value = 3.5  WHERE LOWER(name) LIKE '%crunch%';
UPDATE exercises SET met_value = 5.5  WHERE LOWER(name) LIKE '%deadlift%';
UPDATE exercises SET met_value = 5.0  WHERE LOWER(name) LIKE '%bench press%';
UPDATE exercises SET met_value = 4.5  WHERE LOWER(name) LIKE '%shoulder press%' OR LOWER(name) LIKE '%overhead press%';
UPDATE exercises SET met_value = 4.0  WHERE LOWER(name) LIKE '%bicep curl%'   OR LOWER(name) LIKE '%curl%';
UPDATE exercises SET met_value = 5.0  WHERE LOWER(name) LIKE '%row%';
UPDATE exercises SET met_value = 6.0  WHERE LOWER(name) LIKE '%hiit%'         OR LOWER(name) LIKE '%interval%';
UPDATE exercises SET met_value = 2.5  WHERE LOWER(name) LIKE '%yoga%'         OR LOWER(name) LIKE '%stretch%';
UPDATE exercises SET met_value = 4.0  WHERE LOWER(name) LIKE '%pilates%';
UPDATE exercises SET met_value = 7.0  WHERE LOWER(name) LIKE '%swimming%'     OR LOWER(name) LIKE '%renang%';
UPDATE exercises SET met_value = 3.8  WHERE LOWER(name) LIKE '%dumbbell%';
UPDATE exercises SET met_value = 4.0  WHERE LOWER(name) LIKE '%kettlebell%';
UPDATE exercises SET met_value = 5.0  WHERE LOWER(name) LIKE '%box jump%';
UPDATE exercises SET met_value = 5.5  WHERE LOWER(name) LIKE '%step up%';
UPDATE exercises SET met_value = 6.0  WHERE LOWER(name) LIKE '%battle rope%';
UPDATE exercises SET met_value = 7.5  WHERE LOWER(name) LIKE '%sprint%';
UPDATE exercises SET met_value = 4.5  WHERE LOWER(name) LIKE '%leg press%';
UPDATE exercises SET met_value = 4.0  WHERE LOWER(name) LIKE '%tricep%';
UPDATE exercises SET met_value = 3.5  WHERE LOWER(name) LIKE '%lat pulldown%';
UPDATE exercises SET met_value = 4.0  WHERE LOWER(name) LIKE '%hip thrust%'   OR LOWER(name) LIKE '%glute bridge%';

-- ─── STEP 3: Verifikasi hasil migration ─────────────────────────────────────
-- Jalankan query ini untuk memastikan kolom berhasil ditambahkan dan
-- data sudah terisi dengan benar sebelum melanjutkan.
SELECT
  id,
  name,
  met_value,
  base_calories_burn
FROM exercises
ORDER BY met_value DESC, name ASC;

-- ─── ROLLBACK (jika diperlukan) ─────────────────────────────────────────────
-- Jalankan perintah di bawah ini HANYA jika ingin membatalkan migration ini:
--
-- ALTER TABLE exercises DROP COLUMN met_value;
