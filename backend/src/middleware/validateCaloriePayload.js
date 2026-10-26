// ─────────────────────────────────────────────────────────────────────────────
// Middleware: validateCaloriePayload.js
// PBI-1 Subtask 3 – Validasi payload API perhitungan kalori
//
// Memastikan semua field wajib tersedia dan valid sebelum logika
// bisnis di controller dieksekusi.
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Validasi payload untuk endpoint POST /api/calories/calculate.
 *
 * Field yang divalidasi:
 *  - workout_id       (wajib) : string non-kosong
 *  - duration_minutes (wajib) : angka positif, maks 600 menit (10 jam)
 *  - user_id          (opsional) : jika dikirim, harus berupa string non-kosong
 *                                  Jika tidak dikirim, akan di-fallback ke req.user.id (JWT)
 */
const validateCaloriePayload = (req, res, next) => {
  const { workout_id, duration_minutes, user_id } = req.body;
  const errors = [];

  // ── workout_id ─────────────────────────────────────────────────────────────
  if (!workout_id || typeof workout_id !== 'string' || workout_id.trim() === '') {
    errors.push('workout_id wajib diisi dan harus berupa string yang valid.');
  }

  // ── duration_minutes ───────────────────────────────────────────────────────
  const parsedDuration = parseFloat(duration_minutes);
  if (duration_minutes === undefined || duration_minutes === null || duration_minutes === '') {
    errors.push('duration_minutes wajib diisi.');
  } else if (isNaN(parsedDuration)) {
    errors.push('duration_minutes harus berupa angka.');
  } else if (parsedDuration <= 0) {
    errors.push('duration_minutes harus lebih dari 0 menit.');
  } else if (parsedDuration > 600) {
    errors.push('duration_minutes tidak boleh melebihi 600 menit (10 jam).');
  }

  // ── user_id (opsional) ─────────────────────────────────────────────────────
  // Jika dikirim secara eksplisit di body, validasi formatnya.
  // Jika tidak dikirim, controller akan menggunakan req.user.id dari JWT.
  if (user_id !== undefined) {
    if (typeof user_id !== 'string' || user_id.trim() === '') {
      errors.push('user_id jika dikirim harus berupa string yang valid.');
    }
  }

  // ── Kembalikan semua error sekaligus ───────────────────────────────────────
  if (errors.length > 0) {
    return res.status(400).json({
      success: false,
      message: 'Payload tidak valid.',
      errors,
    });
  }

  // Normalisasi: simpan durasi yang sudah di-parse agar controller tidak perlu parse ulang
  req.parsedDuration = parsedDuration;

  next();
};

module.exports = { validateCaloriePayload };
