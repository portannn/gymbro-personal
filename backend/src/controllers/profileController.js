const { pool } = require('../config/db');

// POST /users/weight
const updateWeight = async (req, res) => {
    try {
        const userId = req.user.id;
        const { weight, recorded_date } = req.body;

        // [PKCTB-307] Validasi ketat di sisi backend
        if (weight === undefined || weight === null) {
            return res.status(400).json({ success: false, message: 'Berat badan wajib diisi' });
        }

        const parsedWeight = parseFloat(weight);
        if (isNaN(parsedWeight) || parsedWeight < 20 || parsedWeight > 300) {
            return res.status(400).json({ 
                success: false, 
                message: 'Data tidak valid. Berat badan harus berupa angka antara 20 - 300 kg' 
            });
        }

        // Tanggal default adalah waktu sekarang jika tidak dikirim dari klien
        const dateToLog = recorded_date ? new Date(recorded_date) : new Date();

        // 1. Catat ke tabel user_weight_logs
        await pool.execute(
            'INSERT INTO user_weight_logs (user_id, weight, recorded_date) VALUES (?, ?, ?)',
            [userId, weight, dateToLog]
        );

        // 2. Update kolom weight di profil utama (tabel USERS)
        await pool.execute(
            'UPDATE users SET weight = ? WHERE id = ?',
            [weight, userId]
        );

        return res.status(200).json({ 
            success: true, 
            message: 'Berat badan berhasil diperbarui',
            data: {
                weight: weight,
                recorded_date: dateToLog.toISOString()
            }
        });
    } catch (err) {
        console.error('Update weight error:', err);
        return res.status(500).json({ success: false, message: 'Terjadi kesalahan saat memperbarui berat badan' });
    }
};

// GET /users/weight/history?page=1&limit=10
const getWeightHistory = async (req, res) => {
    try {
        const userId = req.user.id;

        // [PKCTB-316] Pagination: Ambil parameter page & limit dari query, dengan nilai default
        const limit = Math.min(parseInt(req.query.limit) || 10, 50); // maks 50 per halaman
        const page  = Math.max(parseInt(req.query.page)  || 1,  1);
        const offset = (page - 1) * limit;

        // Hitung total data milik user ini
        const [[{ total }]] = await pool.query(
            'SELECT COUNT(*) AS total FROM user_weight_logs WHERE user_id = ?',
            [userId]
        );

        // [PKCTB-314] Filter Keamanan Privasi: Mengambil riwayat HANYA untuk user_id ini
        // [PKCTB-315] Sorting: Diurutkan dari yang terbaru ke terlama (DESC)
        const [rows] = await pool.query(
            'SELECT * FROM user_weight_logs WHERE user_id = ? ORDER BY recorded_date DESC LIMIT ? OFFSET ?',
            [userId, limit, offset]
        );

        const totalPages = Math.ceil(total / limit);

        return res.status(200).json({
            success: true,
            data: rows,
            pagination: {
                totalData:   total,
                totalPages:  totalPages,
                currentPage: page,
                limit:       limit
            }
        });
    } catch (err) {
        console.error('Get weight history error:', err);
        return res.status(500).json({ success: false, message: 'Terjadi kesalahan saat mengambil riwayat berat badan' });
    }
};

module.exports = { updateWeight, getWeightHistory };
