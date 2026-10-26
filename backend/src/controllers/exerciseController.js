const { pool } = require('../config/db');

const normalizeLocation = (value = '') => {
  const normalized = value.toString().trim().toLowerCase();
  if (normalized === 'home' || normalized === 'gym') return normalized;
  return normalized;
};

const getWorkoutKeywords = (value = '') => {
  return value
    .toString()
    .toLowerCase()
    .replace(/workout/g, '')
    .split(/\s+/)
    .map((word) => word.trim())
    .filter(Boolean);
};

exports.getExercises = async (req, res) => {
  try {
    const { workout_id, location, workout_type, difficulty, category } =
      req.query;
    const conditions = [];
    const params = [];
    const selectedLocation = normalizeLocation(location);
    const workoutKeywords = getWorkoutKeywords(workout_type);

    if (workout_id) {
      conditions.push('w.id = ?');
      params.push(workout_id);
    }

    if (selectedLocation) {
      conditions.push('(w.location_type = ? OR w.location_type = ?)');
      params.push(selectedLocation, 'anywhere');
    }

    for (const keyword of workoutKeywords) {
      conditions.push('LOWER(w.title) LIKE ?');
      params.push(`%${keyword}%`);
    }

    if (difficulty) {
      conditions.push('w.difficulty = ?');
      params.push(difficulty.toString().toLowerCase());
    }

    if (category) {
      conditions.push('w.category = ?');
      params.push(category.toString().toLowerCase());
    }

    let query = `
      SELECT
        e.id,
        e.name,
        e.instructions,
        e.equipment_required,
        e.base_calories_burn,
        we.sequence_order,
        we.reps_or_duration,
        w.id AS workout_id,
        w.title AS workout_title,
        w.difficulty,
        w.location_type,
        w.category,
        w.duration_minutes,
        w.description AS workout_description
      FROM workouts w
      INNER JOIN workout_exercises we ON we.workout_id = w.id
      INNER JOIN exercises e ON e.id = we.exercise_id
    `;

    if (conditions.length > 0) {
      query += ` WHERE ${conditions.join(' AND ')}`;
    }

    query += ' ORDER BY w.title ASC, we.sequence_order ASC, e.name ASC';
    const [rows] = await pool.execute(query, params);
    return res.status(200).json({ success: true, data: rows });
  } catch (error) {
    console.error('Get exercises error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error fetching exercises',
    });
  }
};
