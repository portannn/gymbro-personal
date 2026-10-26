const express = require('express');
const router = express.Router();
const workoutController = require('../controllers/workoutController');

// GET request to fetch all workouts
router.get('/', workoutController.getWorkouts);

// GET request to fetch exercises for a specific workout
router.get('/:id/exercises', workoutController.getWorkoutExercises);

module.exports = router;
