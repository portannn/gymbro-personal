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
      'SELECT * FROM workouts ORDER BY created_at DESC'
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
    const { title, difficulty, location_type, category, description, duration_minutes, calories_burned, fitness_goal } = req.body;

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
    const { title, difficulty, location_type, category, description, duration_minutes, calories_burned, fitness_goal } = req.body;

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

// POST /api/admin/exercises
const createExercise = async (req, res) => {
  if (!requireAdmin(req, res)) return;
  try {
    const { name, instructions, equipment_required, base_calories_burn } = req.body;

    if (!name) {
      return res.status(400).json({ success: false, message: 'name wajib diisi' });
    }

    const id = randomUUID();
    await pool.execute(
      `INSERT INTO exercises (id, name, instructions, equipment_required, base_calories_burn)
       VALUES (?, ?, ?, ?, ?)`,
      [id, name, instructions || null, equipment_required || null, base_calories_burn || 0]
    );

    const [[exercise]] = await pool.execute('SELECT * FROM exercises WHERE id = ?', [id]);
    return res.status(201).json({ success: true, message: 'Latihan berhasil dibuat', data: exercise });
  } catch (err) {
    console.error('Create exercise error:', err);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
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
  updateExerciseMedia,
};

