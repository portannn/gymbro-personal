const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');

const generateId = () => require('crypto').randomUUID();

// POST /auth/register
const register = async (req, res) => {
  const { full_name, email, password, confirm_password } = req.body;

  if (!full_name || !email || !password || !confirm_password) {
    return res.status(400).json({ success: false, message: 'Semua field wajib diisi' });
  }
  if (password !== confirm_password) {
    return res.status(400).json({ success: false, message: 'Password dan konfirmasi password tidak cocok' });
  }
  if (password.length < 6) {
    return res.status(400).json({ success: false, message: 'Password minimal 6 karakter' });
  }

  try {
    const [existing] = await pool.execute('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length > 0) {
      return res.status(409).json({ success: false, message: 'Email sudah terdaftar' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const userId = generateId();

    await pool.execute(
      'INSERT INTO users (id, full_name, email, password, role) VALUES (?, ?, ?, ?, ?)',
      [userId, full_name, email, hashedPassword, 'user']
    );

    return res.status(201).json({ success: true, message: 'Registrasi berhasil' });
  } catch (err) {
    console.error('Register error:', err);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

// POST /auth/login
const login = async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ success: false, message: 'Email dan password wajib diisi' });
  }

  try {
    const [rows] = await pool.execute(
      'SELECT id, full_name, email, password, weight, role FROM users WHERE email = ?',
      [email]
    );

    if (rows.length === 0) {
      return res.status(401).json({ success: false, message: 'Email atau password salah' });
    }

    const user = rows[0];
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Email atau password salah' });
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '100d' }
    );

    return res.status(200).json({
      success: true,
      message: 'Login berhasil',
      data: {
        token,
        user: {
          id: user.id,
          full_name: user.full_name,
          email: user.email,
          weight: user.weight,
          role: user.role,
        },
      },
    });
  } catch (err) {
    console.error('Login error:', err);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

module.exports = { register, login };