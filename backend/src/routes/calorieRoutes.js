const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/authMiddleware');
const { validateCaloriePayload } = require('../middleware/validateCaloriePayload');
const { calculateCalories } = require('../controllers/calorieController');

// POST /api/calories/calculate
// Hitung estimasi kalori terbakar untuk satu sesi latihan.
// Membutuhkan autentikasi JWT – user_id & weight diambil otomatis dari token.
router.post('/calculate', verifyToken, validateCaloriePayload, calculateCalories);

module.exports = router;
