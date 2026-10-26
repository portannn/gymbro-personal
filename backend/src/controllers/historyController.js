const { pool } = require('../config/db');

const PAGE_LIMIT = 10; // jumlah item per halaman

// GET /users/history?limit=10&offset=0
const getHistory = async (req, res) => {
    try {
        // [PKCTB-241] Autentikasi: Mendapatkan identitas user yang sedang login dari JWT token
        const userId = req.user.id;

        // Ambil limit & page dari query params, dengan nilai default
        const limit = Math.min(parseInt(req.query.limit) || PAGE_LIMIT, 50); // maks 50
        const page  = Math.max(parseInt(req.query.page) || 1, 1);
        const offset = (page - 1) * limit;

        // Hitung total data milik user ini
        const [[{ total }]] = await pool.execute(
            'SELECT COUNT(*) AS total FROM workout_history WHERE user_id = ?',
            [userId]
        );

        // [PKCTB-241 & PKCTB-242] Filter & Sorting: 
        // 1. Mengembalikan data HANYA milik user_id tersebut (Filter)
        // 2. Diurutkan dari yang terbaru menggunakan ORDER BY date DESC (Sorting)
        const [rows] = await pool.query(
            'SELECT * FROM workout_history WHERE user_id = ? ORDER BY date DESC LIMIT ? OFFSET ?',
            [userId, limit, offset]
        );

        const totalPages = Math.ceil(total / limit);

        return res.status(200).json({
            success: true,
            data: rows,
            pagination: {
                totalData: total,
                totalPages: totalPages,
                currentPage: page,
                limit: limit,
                hasMore: page < totalPages
            },
        });
    } catch (err) {
        console.error('Get history error:', err);
        return res.status(500).json({ success: false, message: 'Terjadi kesalahan saat mengambil riwayat' });
    }
};

// POST /users/history
const addHistory = async (req, res) => {
    try {
        const userId = req.user.id;
        const { workout_name, duration_minutes, calories_burned } = req.body;

        if (!workout_name || !duration_minutes || !calories_burned) {
            return res.status(400).json({ success: false, message: 'Nama latihan, durasi, dan kalori wajib diisi' });
        }

        const [result] = await pool.execute(
            'INSERT INTO workout_history (user_id, workout_name, duration_minutes, calories_burned) VALUES (?, ?, ?, ?)',
            [userId, workout_name, duration_minutes, calories_burned]
        );

        return res.status(201).json({ 
            success: true, 
            message: 'Riwayat latihan berhasil ditambahkan',
            data: {
                id: result.insertId,
                user_id: userId,
                workout_name,
                duration_minutes,
                calories_burned,
                date: new Date().toISOString()
            }
        });
    } catch (err) {
        console.error('Add history error:', err);
        return res.status(500).json({ success: false, message: 'Terjadi kesalahan saat menyimpan riwayat' });
    }
};

module.exports = { getHistory, addHistory };
