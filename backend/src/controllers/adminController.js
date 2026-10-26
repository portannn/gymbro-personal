const { pool } = require('../config/db');
const { randomUUID } = require('crypto');

// ─── Helper: admin guard ─────────────────────────────────────────────────────
const requireAdmin = (req, res) => {
  if (req.user.role !== 'admin') {
    res.status(403).json({ success: false, message: 'Akses ditolak: Hanya admin yang diizinkan' });
    return false;
  }
  return true;
};

// ─── Users ───────────────────────────────────────────────────────────────────

// GET /api/admin/users
const getAllUsers = async (req, res) => {
  if (!requireAdmin(req, res)) return;
  try {
    const [rows] = await pool.query(
      'SELECT id, full_name, email, weight, role, gender, fitness_goal, target_weight, onboarding_completed, date_created FROM users ORDER BY date_created DESC'
    );
    return res.status(200).json({ success: true, data: rows });
  } catch (err) {
    console.error('Get all users error:', err);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

// ─── Workouts ─────────────────────────────────────────────────────────────────

// GET /api/admin/workouts  (same data as public, but token-protected)
const getAllWorkouts = async (req, res) => {
  if (!requireAdmin(req, res)) return;
  try {
    const [rows] = await pool.query(
      `SELECT w.*,
              (SELECT COUNT(*) FROM workout_exercises we WHERE we.workout_id = w.id) AS exercise_count
       FROM workouts w
       ORDER BY w.created_at DESC`
    );
    return res.status(200).json({ success: true, data: rows });
  } catch (err) {
    console.error('Get all workouts error:', err);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

// POST /api/admin/workouts
const createWorkout = async (req, res) => {
  if (!requireAdmin(req, res)) return;
  try {
    const { title, description, duration_minutes, calories_burned } = req.body;
    // Katalog memfilter dengan nilai lowercase, jadi normalisasi di sini
    const lower = (v) => (v ? v.toString().trim().toLowerCase() : v);
    const difficulty = lower(req.body.difficulty);
    const location_type = lower(req.body.location_type);
    const category = lower(req.body.category);
    const fitness_goal = lower(req.body.fitness_goal);

    if (!title || !difficulty || !location_type || !category) {
      return res.status(400).json({ success: false, message: 'title, difficulty, location_type, dan category wajib diisi' });
    }

    const id = randomUUID();
    await pool.execute(
      `INSERT INTO workouts (id, title, difficulty, location_type, category, description, duration_minutes, calories_burned, fitness_goal)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [id, title, difficulty, location_type, category, description || null, duration_minutes || null, calories_burned || null, fitness_goal || null]
    );

    const [[workout]] = await pool.execute('SELECT * FROM workouts WHERE id = ?', [id]);
    return res.status(201).json({ success: true, message: 'Workout berhasil dibuat', data: workout });
  } catch (err) {
    console.error('Create workout error:', err);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

// PUT /api/admin/workouts/:id
const updateWorkout = async (req, res) => {
  if (!requireAdmin(req, res)) return;
  try {
    const { id } = req.params;
    const { title, description, duration_minutes, calories_burned } = req.body;
    // Katalog memfilter dengan nilai lowercase, jadi normalisasi di sini
    const lower = (v) => (v ? v.toString().trim().toLowerCase() : v);
    const difficulty = lower(req.body.difficulty);
    const location_type = lower(req.body.location_type);
    const category = lower(req.body.category);
    const fitness_goal = lower(req.body.fitness_goal);

    if (!title || !difficulty || !location_type || !category) {
      return res.status(400).json({ success: false, message: 'title, difficulty, location_type, dan category wajib diisi' });
    }

    const [result] = await pool.execute(
      `UPDATE workouts SET title=?, difficulty=?, location_type=?, category=?, description=?, duration_minutes=?, calories_burned=?, fitness_goal=?
       WHERE id=?`,
      [title, difficulty, location_type, category, description || null, duration_minutes || null, calories_burned || null, fitness_goal || null, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Workout tidak ditemukan' });
    }

    const [[workout]] = await pool.execute('SELECT * FROM workouts WHERE id = ?', [id]);
    return res.status(200).json({ success: true, message: 'Workout berhasil diperbarui', data: workout });
  } catch (err) {
    console.error('Update workout error:', err);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

// DELETE /api/admin/workouts/:id
const deleteWorkout = async (req, res) => {
  if (!requireAdmin(req, res)) return;
  try {
    const { id } = req.params;
    const [result] = await pool.execute('DELETE FROM workouts WHERE id = ?', [id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Workout tidak ditemukan' });
    }

    return res.status(200).json({ success: true, message: 'Workout berhasil dihapus' });
  } catch (err) {
    console.error('Delete workout error:', err);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

// ─── Supplements (Products) ──────────────────────────────────────────────────

// GET /api/admin/supplements
const getAllSupplements = async (req, res) => {
  if (!requireAdmin(req, res)) return;
  try {
    const [rows] = await pool.query('SELECT * FROM products ORDER BY id DESC');
    return res.status(200).json({ success: true, data: rows });
  } catch (err) {
    console.error('Get all supplements error:', err);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

// POST /api/admin/supplements
const createSupplement = async (req, res) => {
  if (!requireAdmin(req, res)) return;
  try {
    const { name, description, price, stock, category, image_url } = req.body;

    if (!name || !price || stock === undefined) {
      return res.status(400).json({ success: false, message: 'name, price, dan stock wajib diisi' });
    }

    const [result] = await pool.execute(
      `INSERT INTO products (name, description, price, stock, category, image_url)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [name, description || null, price, stock, category || null, image_url || null]
    );

    const [[supplement]] = await pool.execute('SELECT * FROM products WHERE id = ?', [result.insertId]);
    return res.status(201).json({ success: true, message: 'Produk berhasil dibuat', data: supplement });
  } catch (err) {
    console.error('Create supplement error:', err);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

// PUT /api/admin/supplements/:id
const updateSupplement = async (req, res) => {
  if (!requireAdmin(req, res)) return;
  try {
    const { id } = req.params;
    const { name, description, price, stock, category, image_url } = req.body;

    if (!name || !price || stock === undefined) {
      return res.status(400).json({ success: false, message: 'name, price, dan stock wajib diisi' });
    }

    const [result] = await pool.execute(
      `UPDATE products SET name=?, description=?, price=?, stock=?, category=?, image_url=?
       WHERE id=?`,
      [name, description || null, price, stock, category || null, image_url || null, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Produk tidak ditemukan' });
    }

    const [[supplement]] = await pool.execute('SELECT * FROM products WHERE id = ?', [id]);
    return res.status(200).json({ success: true, message: 'Produk berhasil diperbarui', data: supplement });
  } catch (err) {
    console.error('Update supplement error:', err);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

// DELETE /api/admin/supplements/:id
const deleteSupplement = async (req, res) => {
  if (!requireAdmin(req, res)) return;
  try {
    const { id } = req.params;
    const [result] = await pool.execute('DELETE FROM products WHERE id = ?', [id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Produk tidak ditemukan' });
    }

    return res.status(200).json({ success: true, message: 'Produk berhasil dihapus' });
  } catch (err) {
    console.error('Delete supplement error:', err);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

// ─── Exercises ───────────────────────────────────────────────────────────────

// GET /api/admin/exercises
const getAllExercises = async (req, res) => {
  if (!requireAdmin(req, res)) return;
  try {
    const [rows] = await pool.query('SELECT * FROM exercises ORDER BY created_at DESC');
    return res.status(200).json({ success: true, data: rows });
  } catch (err) {
    console.error('Get all exercises error:', err);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

// Validasi angka opsional untuk form latihan; mengembalikan null jika tidak valid
const parseNumber = (value, fallback) => {
  if (value === undefined || value === null || value === '') return fallback;
  const n = Number(value);
  return Number.isFinite(n) && n >= 0 ? n : null;
};

// POST /api/admin/exercises
const createExercise = async (req, res) => {
  if (!requireAdmin(req, res)) return;
  try {
    const { name, instructions, equipment_required } = req.body;
    const baseCalories = parseNumber(req.body.base_calories_burn, 0);
    const met = parseNumber(req.body.met_value, 1.0);

    if (!name || !name.toString().trim()) {
      return res.status(400).json({ success: false, message: 'name wajib diisi' });
    }
    if (baseCalories === null || met === null || met <= 0) {
      return res.status(400).json({ success: false, message: 'base_calories_burn dan met_value harus angka valid (MET > 0)' });
    }

    const id = randomUUID();
    await pool.execute(
      `INSERT INTO exercises (id, name, instructions, equipment_required, base_calories_burn, met_value)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [id, name.toString().trim(), instructions || null, equipment_required || null, baseCalories, met]
    );

    const [[exercise]] = await pool.execute('SELECT * FROM exercises WHERE id = ?', [id]);
    return res.status(201).json({ success: true, message: 'Latihan berhasil dibuat', data: exercise });
  } catch (err) {
    console.error('Create exercise error:', err);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

// PUT /api/admin/exercises/:id
const updateExercise = async (req, res) => {
  if (!requireAdmin(req, res)) return;
  try {
    const { id } = req.params;
    const { name, instructions, equipment_required } = req.body;
    const baseCalories = parseNumber(req.body.base_calories_burn, 0);
    const met = parseNumber(req.body.met_value, 1.0);

    if (!name || !name.toString().trim()) {
      return res.status(400).json({ success: false, message: 'name wajib diisi' });
    }
    if (baseCalories === null || met === null || met <= 0) {
      return res.status(400).json({ success: false, message: 'base_calories_burn dan met_value harus angka valid (MET > 0)' });
    }

    const [result] = await pool.execute(
      `UPDATE exercises SET name=?, instructions=?, equipment_required=?, base_calories_burn=?, met_value=? WHERE id=?`,
      [name.toString().trim(), instructions || null, equipment_required || null, baseCalories, met, id]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Latihan tidak ditemukan' });
    }

    const [[exercise]] = await pool.execute('SELECT * FROM exercises WHERE id = ?', [id]);
    return res.status(200).json({ success: true, message: 'Latihan berhasil diperbarui', data: exercise });
  } catch (err) {
    console.error('Update exercise error:', err);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

// DELETE /api/admin/exercises/:id  (baris workout_exercises ikut terhapus via ON DELETE CASCADE)
const deleteExercise = async (req, res) => {
  if (!requireAdmin(req, res)) return;
  try {
    const [result] = await pool.execute('DELETE FROM exercises WHERE id = ?', [req.params.id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Latihan tidak ditemukan' });
    }
    return res.status(200).json({ success: true, message: 'Latihan berhasil dihapus' });
  } catch (err) {
    console.error('Delete exercise error:', err);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

// ─── Workout <-> Exercise links ──────────────────────────────────────────────

// GET /api/admin/workouts/:id/exercises
const getWorkoutExercises = async (req, res) => {
  if (!requireAdmin(req, res)) return;
  try {
    const [rows] = await pool.execute(
      `SELECT e.id AS exercise_id, e.name, e.equipment_required, we.reps_or_duration, we.sequence_order
       FROM workout_exercises we
       INNER JOIN exercises e ON e.id = we.exercise_id
       WHERE we.workout_id = ?
       ORDER BY we.sequence_order ASC, we.id ASC`,
      [req.params.id]
    );
    return res.status(200).json({ success: true, data: rows });
  } catch (err) {
    console.error('Get workout exercises error:', err);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

// PUT /api/admin/workouts/:id/exercises
// Body: { exercises: [{ exercise_id, reps_or_duration }] }  (urutan array = sequence_order)
// Mengganti seluruh daftar latihan workout dalam satu transaksi.
const setWorkoutExercises = async (req, res) => {
  if (!requireAdmin(req, res)) return;
  const items = req.body.exercises;
  if (!Array.isArray(items)) {
    return res.status(400).json({ success: false, message: 'exercises harus berupa array' });
  }

  const conn = await pool.getConnection();
  try {
    const [[workout]] = await conn.execute('SELECT id FROM workouts WHERE id = ?', [req.params.id]);
    if (!workout) {
      return res.status(404).json({ success: false, message: 'Workout tidak ditemukan' });
    }

    await conn.beginTransaction();
    await conn.execute('DELETE FROM workout_exercises WHERE workout_id = ?', [req.params.id]);
    for (let i = 0; i < items.length; i++) {
      const { exercise_id, reps_or_duration } = items[i] || {};
      if (!exercise_id) throw Object.assign(new Error('exercise_id wajib diisi'), { status: 400 });
      await conn.execute(
        'INSERT INTO workout_exercises (workout_id, exercise_id, sequence_order, reps_or_duration) VALUES (?, ?, ?, ?)',
        [req.params.id, exercise_id, i + 1, reps_or_duration || null]
      );
    }
    await conn.commit();
    return res.status(200).json({ success: true, message: 'Daftar latihan workout diperbarui' });
  } catch (err) {
    await conn.rollback();
    if (err.status === 400 || err.code === 'ER_NO_REFERENCED_ROW_2') {
      return res.status(400).json({ success: false, message: err.status ? err.message : 'Ada exercise_id yang tidak ditemukan' });
    }
    console.error('Set workout exercises error:', err);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  } finally {
    conn.release();
  }
};

// POST /api/admin/exercises/:id/media (Multipart)
// Media upload handling will be in the route with Multer + Cloudinary
const updateExerciseMedia = async (req, res) => {
  if (!requireAdmin(req, res)) return;
  try {
    const { id } = req.params;
    const media_url = req.cloudinaryUrl; // Passed from middleware

    if (!media_url) {
      return res.status(400).json({ success: false, message: 'File media tidak ditemukan' });
    }

    const [result] = await pool.execute(
      'UPDATE exercises SET media_url = ? WHERE id = ?',
      [media_url, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Latihan tidak ditemukan' });
    }

    return res.status(200).json({ success: true, message: 'Media berhasil diupload', data: { media_url } });
  } catch (err) {
    console.error('Update exercise media error:', err);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

module.exports = {
  getAllUsers,
  getAllWorkouts,
  createWorkout,
  updateWorkout,
  deleteWorkout,
  getAllSupplements,
  createSupplement,
  updateSupplement,
  deleteSupplement,
  getAllExercises,
  createExercise,
  updateExercise,
  deleteExercise,
  getWorkoutExercises,
  setWorkoutExercises,
  updateExerciseMedia,
};

