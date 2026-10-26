const { pool } = require('../config/db');

// ─────────────────────────────────────────────────────────────────────────────
// Helper: Fungsi murni kalkulasi kalori (pure function, mudah di-unit-test)
//
// Rumus standar:  Kalori = Durasi (menit) × (MET × 3.5 × Berat Badan kg) / 200
// Referensi     : McArdle, Katch & Katch – "Exercise Physiology" (8th ed.)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Menghitung estimasi kalori yang terbakar berdasarkan nilai MET.
 *
 * @param {number} durationMinutes - Durasi latihan dalam menit (> 0)
 * @param {number} metValue        - Nilai MET dari jenis latihan (> 0)
 * @param {number} weightKg        - Berat badan pengguna dalam kilogram (> 0)
 * @returns {number}               - Estimasi kalori terbakar (dibulatkan 2 desimal)
 * @throws {Error}                 - Jika salah satu argumen tidak valid
 */
const computeCalories = (durationMinutes, metValue, weightKg) => {
  if (durationMinutes <= 0) throw new Error('Durasi latihan harus lebih dari 0 menit.');
  if (metValue <= 0)        throw new Error('Nilai MET harus lebih dari 0.');
  if (weightKg <= 0)        throw new Error('Berat badan harus lebih dari 0 kg.');

  const calories = durationMinutes * (metValue * 3.5 * weightKg) / 200;
  return Math.round(calories * 100) / 100; // bulatkan ke 2 desimal
};

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/calories/calculate
//
// Menghitung estimasi kalori terbakar untuk satu sesi latihan.
//
// Body   : { workout_id: string, duration_minutes: number }
// Auth   : Bearer JWT (user_id & weight diambil otomatis dari token + DB)
// Returns: { calories_burned, met_value, weight_kg, duration_minutes, ... }
// ─────────────────────────────────────────────────────────────────────────────
const calculateCalories = async (req, res) => {
  try {
    // ── 1. Ekstrak input (sudah divalidasi oleh middleware) ────────────────
    const { workout_id, user_id } = req.body;
    const parsedDuration = req.parsedDuration;

    // Mendukung user_id dari payload jika ada, fallback ke JWT token
    const targetUserId = user_id || req.user.id;

    // ── 2. Ambil berat badan user dari database ───────────────────────────
    const [[user]] = await pool.execute(
      'SELECT id, full_name, weight FROM users WHERE id = ?',
      [targetUserId]
    );

    if (!user) {
      return res.status(404).json({ success: false, message: 'User tidak ditemukan.' });
    }

    if (!user.weight || user.weight <= 0) {
      return res.status(422).json({
        success: false,
        message: 'Berat badan belum diatur. Silakan perbarui profil Anda terlebih dahulu.',
      });
    }

    // ── 3. Ambil nilai MET dari semua exercise dalam workout ──────────────
    // Menggunakan rata-rata MET seluruh exercise dalam satu workout.
    // Pendekatan ini merepresentasikan intensitas rata-rata sesi latihan.
    const [exercises] = await pool.execute(
      `SELECT e.name, e.met_value
       FROM workout_exercises we
       INNER JOIN exercises e ON e.id = we.exercise_id
       WHERE we.workout_id = ? AND e.met_value IS NOT NULL`,
      [workout_id]
    );

    if (exercises.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Workout tidak ditemukan atau belum memiliki exercise dengan nilai MET.',
      });
    }

    const totalMet    = exercises.reduce((sum, ex) => sum + parseFloat(ex.met_value), 0);
    const averageMet  = totalMet / exercises.length;

    // ── 4. Hitung kalori menggunakan pure function ────────────────────────
    const caloriesBurned = computeCalories(parsedDuration, averageMet, user.weight);

    // ── 5. Ambil nama workout untuk respons yang informatif ───────────────
    const [[workout]] = await pool.execute(
      'SELECT title FROM workouts WHERE id = ?',
      [workout_id]
    );

    return res.status(200).json({
      success: true,
      message: 'Estimasi kalori berhasil dihitung.',
      data: {
        calories_burned:   caloriesBurned,
        duration_minutes:  parsedDuration,
        met_value:         Math.round(averageMet * 100) / 100,
        weight_kg:         user.weight,
        workout_id:        workout_id,
        workout_title:     workout?.title ?? null,
        exercise_count:    exercises.length,
        formula_used:      `${parsedDuration} × (${Math.round(averageMet * 100) / 100} × 3.5 × ${user.weight}) / 200`,
      },
    });

  } catch (error) {
    console.error('Calculate calories error:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan saat menghitung kalori.',
    });
  }
};

module.exports = { calculateCalories, computeCalories };
