const express = require('express');
const router = express.Router();
const multer = require('multer');
const cloudinary = require('cloudinary').v2;
const fs = require('fs');
const { verifyToken } = require('../middleware/authMiddleware');
const {
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
} = require('../controllers/adminController');

// Multer Config
const upload = multer({ dest: 'uploads/' });

// ─── Users ───────────────────────────────────────────────────────────────────
router.get('/users', verifyToken, getAllUsers);

// ─── Workouts ─────────────────────────────────────────────────────────────────
router.get('/workouts', verifyToken, getAllWorkouts);
router.post('/workouts', verifyToken, createWorkout);
router.put('/workouts/:id', verifyToken, updateWorkout);
router.delete('/workouts/:id', verifyToken, deleteWorkout);

// ─── Supplements (Products) ──────────────────────────────────────────────────
router.get('/supplements', verifyToken, getAllSupplements);
router.post('/supplements', verifyToken, createSupplement);
router.put('/supplements/:id', verifyToken, updateSupplement);
router.delete('/supplements/:id', verifyToken, deleteSupplement);

// ─── Exercises ───────────────────────────────────────────────────────────────
router.get('/exercises', verifyToken, getAllExercises);
router.post('/exercises', verifyToken, createExercise);

// Exercise Media Upload (Multipart)
router.post('/exercises/:id/media', verifyToken, upload.single('media_file'), async (req, res, next) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'File tidak ditemukan' });
  }

  try {
    const result = await cloudinary.uploader.upload(req.file.path, {
      folder: 'gymbro_exercises',
      resource_type: 'auto',
    });

    // Pass the URL to the controller
    req.cloudinaryUrl = result.secure_url;
    
    // Clean up local file
    if (fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);
    
    next();
  } catch (error) {
    if (req.file && fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);
    console.error('Cloudinary upload error:', error);
    res.status(500).json({ success: false, message: 'Gagal upload ke Cloudinary' });
  }
}, updateExerciseMedia);

module.exports = router;
