const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/authMiddleware');
const { pool } = require('../config/db');
const { getHistory, addHistory } = require('../controllers/historyController');
const { updateWeight, getWeightHistory } = require('../controllers/profileController');

// GET /users/profile
router.get('/profile', verifyToken, async (req, res) => {
  try {
    console.log('Getting profile for user ID:', req.user.id);
    
    const [rows] = await pool.execute(
      'SELECT id, full_name, email, weight, role, gender, fitness_goal, target_weight, onboarding_completed, date_created FROM users WHERE id = ?',
      [req.user.id]
    );
    
    console.log('Raw user data from DB:', rows[0]);
    
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User tidak ditemukan' });
    }
    const user = rows[0];
    
    // Convert fitness_goal enum to array
    if (user.fitness_goal) {
      // Convert enum value to readable format
      user.goals = [user.fitness_goal.replace('_', ' ')];
    } else {
      user.goals = [];
    }
    
    console.log('Processed user data:', user);
    console.log('onboarding_completed value:', user.onboarding_completed);
    console.log('onboarding_completed type:', typeof user.onboarding_completed);
    
    return res.status(200).json({ success: true, data: user });
  } catch (err) {
    console.error('Get profile error:', err);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server: ' + err.message });
  }
});

// PUT /users/profile
router.put('/profile', verifyToken, async (req, res) => {
  try {
    const { gender, goals, currentWeight, targetWeight } = req.body;
    const userId = req.user.id;

    // Convert goals array to enum value
    let fitnessGoalsValue = null;
    if (goals && goals.length > 0) {
      // Convert readable format back to enum
      fitnessGoalsValue = goals[0].replace(' ', '_');
    }

    const [result] = await pool.execute(
      `UPDATE users 
       SET gender = ?, fitness_goal = ?, weight = ?, target_weight = ?, onboarding_completed = 1
       WHERE id = ?`,
      [
        gender || null,
        fitnessGoalsValue,
        currentWeight || null,
        targetWeight || null,
        userId
      ]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'User tidak ditemukan' });
    }

    // Get updated user data
    const [rows] = await pool.execute(
      'SELECT id, full_name, email, weight, role, gender, fitness_goal, target_weight, onboarding_completed, date_created FROM users WHERE id = ?',
      [userId]
    );

    const updatedUser = rows[0];
    if (updatedUser.fitness_goal) {
      updatedUser.goals = [updatedUser.fitness_goal.replace('_', ' ')];
    } else {
      updatedUser.goals = [];
    }

    return res.status(200).json({ 
      success: true, 
      data: updatedUser,
      message: 'Profil berhasil diperbarui'
    });
  } catch (err) {
    console.error('Update profile error:', err);
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
});

// POST /users/weight
router.post('/weight', verifyToken, updateWeight);

// GET /users/weight/history
router.get('/weight/history', verifyToken, getWeightHistory);

// GET /users/history
router.get('/history', verifyToken, getHistory);

// POST /users/history
router.post('/history', verifyToken, addHistory);

module.exports = router;