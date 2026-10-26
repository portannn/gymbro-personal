require('dotenv').config();
const express = require('express');
const cors = require('cors');
const fs = require('fs');

// 1. Hubungkan ke Database
const { pool: db, testConnection } = require('./config/db');

// Routes
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const exerciseRoutes = require('./routes/exerciseRoutes');
const workoutRoutes = require('./routes/workoutRoutes');
const calorieRoutes = require('./routes/calorieRoutes'); // PBI-1 [Subtask 2]

// 2. Media Tools
const cloudinary = require('cloudinary').v2;
const multer = require('multer');

// Pastikan folder 'uploads' ada
const uploadDir = './uploads';
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir);
}

// Config Cloudinary
cloudinary.config(true);
const upload = multer({ dest: 'uploads/' });

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

const adminRoutes = require('./routes/adminRoutes');

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/exercises', exerciseRoutes);
app.use('/api/workouts', require('./routes/workoutRoutes'));
app.use('/api/admin', adminRoutes);
app.use('/api/calories', calorieRoutes); // PBI-1 [Subtask 2] – Estimasi Kalori Terbakar

app.get('/', (req, res) => {
  res.json({ success: true, message: 'Gymbro API is running 🚀' });
});

// End of Admin Routes

app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Endpoint tidak ditemukan' });
});

// Start server
const start = async () => {
  try {
    await testConnection();
    
    // Jalankan migrasi tabel
    const { runMigration } = require('./config/migrate_history');
    await runMigration();
    
    const { runWeightMigration } = require('./config/migrate_weight');
    await runWeightMigration();

    const { runWorkoutsMigration } = require('./config/migrate_workouts');
    await runWorkoutsMigration();

    const { runExercisesMigration } = require('./config/migrate_exercises');
    await runExercisesMigration();

    // PBI-1 [Subtask 1] – Tambahkan kolom met_value ke tabel exercises
    const { runMetMigration } = require('./config/migrate_met');
    await runMetMigration();

    app.listen(PORT, () => {
      console.log(`✅ Server running on http://localhost:${PORT}`);
    });
  } catch (err) {
    console.error('Gagal start server:', err.message);
  }
};

start();
