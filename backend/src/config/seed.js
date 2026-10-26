require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });
const { randomUUID } = require('crypto');
const { pool } = require('./db');

// Data awal katalog. Idempotent: baris yang sudah ada (berdasarkan nama/judul) dilewati,
// jadi aman dijalankan ulang dan tidak menimpa hasil edit dari admin.
// Nilai lowercase sengaja: filter katalog membandingkan nilai lowercase.

const exercises = [
  // name, equipment, met, base_calories_burn (per sesi singkat), instructions
  ['Arm Circles', 'None', 2.5, 15, 'Berdiri tegak, rentangkan lengan ke samping lalu putar membentuk lingkaran kecil, ganti arah setelah separuh waktu.'],
  ['Hip Circles', 'None', 2.5, 15, 'Tangan di pinggang, putar pinggul membentuk lingkaran lebar secara perlahan, ganti arah di tengah.'],
  ['Cat-Cow Stretch', 'None', 2.5, 15, 'Posisi merangkak. Lengkungkan punggung ke atas (cat), lalu turunkan perut dan angkat dada (cow). Atur napas.'],
  ['Jumping Jack', 'None', 6.0, 40, 'Lompat sambil membuka kaki dan mengangkat tangan di atas kepala, lalu kembali ke posisi awal.'],
  ['Push-Up', 'None', 5.0, 35, 'Posisi plank tangan selebar bahu. Turunkan dada hingga hampir menyentuh lantai, dorong kembali ke atas dengan badan lurus.'],
  ['Squat', 'None', 5.0, 35, 'Kaki selebar bahu, turunkan pinggul ke belakang seperti duduk hingga paha sejajar lantai, dorong kembali lewat tumit.'],
  ['Lunge', 'None', 5.0, 35, 'Langkahkan satu kaki ke depan, turunkan lutut belakang mendekati lantai, dorong kembali ke posisi berdiri. Ganti kaki.'],
  ['Plank', 'None', 4.0, 25, 'Tumpu pada lengan bawah dan ujung kaki, jaga tubuh lurus dari kepala hingga tumit, kencangkan perut.'],
  ['Sit-Up', 'None', 3.5, 25, 'Berbaring dengan lutut ditekuk, angkat badan bagian atas hingga duduk menggunakan otot perut, turun perlahan.'],
  ['Glute Bridge', 'None', 4.0, 25, 'Berbaring dengan lutut ditekuk, angkat pinggul hingga badan lurus dari bahu ke lutut, tahan sejenak lalu turun.'],
  ['Burpee', 'None', 6.0, 55, 'Dari berdiri, jongkok dan tempatkan tangan di lantai, lempar kaki ke belakang (push-up), lompat kembali dan melompat ke atas.'],
  ['Mountain Climber', 'None', 6.0, 45, 'Posisi plank tinggi, tarik lutut ke dada secara bergantian dengan cepat sambil menjaga pinggul tetap rendah.'],
  ['Pull-Up', 'Pull-up bar', 5.0, 40, 'Gantung pada palang dengan genggaman lebih lebar dari bahu, tarik dada ke arah palang, turun terkontrol.'],
  ['Bench Press', 'Barbell, bench', 5.0, 45, 'Berbaring di bench, turunkan barbel ke dada dengan terkontrol lalu dorong ke atas hingga lengan lurus.'],
  ['Shoulder Press', 'Dumbbell', 4.5, 40, 'Duduk atau berdiri, dorong dumbbell dari sisi bahu ke atas kepala hingga lengan lurus, turunkan perlahan.'],
  ['Tricep Pushdown', 'Cable machine', 4.0, 30, 'Siku dirapatkan di sisi badan, dorong tali kabel ke bawah hingga lengan lurus, kembali perlahan.'],
  ['Deadlift', 'Barbell', 5.5, 55, 'Berdiri dengan barbel di depan kaki, punggung lurus, angkat dengan mendorong lantai menjauh hingga berdiri tegak.'],
  ['Barbell Row', 'Barbell', 5.0, 45, 'Condongkan badan ke depan dengan punggung lurus, tarik barbel ke perut bagian bawah, turunkan terkontrol.'],
  ['Lat Pulldown', 'Cable machine', 3.5, 35, 'Duduk, tarik bar lebar ke arah dada bagian atas dengan menjepit tulang belikat, kembali perlahan.'],
  ['Bicep Curl', 'Dumbbell', 4.0, 30, 'Siku dirapatkan, angkat dumbbell ke arah bahu dengan memutar lengan, turunkan perlahan tanpa mengayun.'],
  ['Leg Press', 'Leg press machine', 4.5, 40, 'Duduk di mesin, dorong platform dengan kedua kaki hingga hampir lurus, tekuk kembali tanpa mengangkat pinggul.'],
  ['Treadmill Running', 'Treadmill', 8.0, 80, 'Berlari dengan kecepatan stabil. Mulai dari tempo ringan lalu naikkan sesuai kemampuan.'],
  ['Jump Rope', 'Jump rope', 8.0, 80, 'Putar tali dengan pergelangan tangan dan lompat kecil dengan ujung kaki, jaga ritme stabil.'],
];

// title, difficulty, location_type, category, description, minutes, kcal, fitness_goal, [[exercise, reps_or_duration], ...]
const workouts = [
  ['Full Body Warm-Up', 'beginner', 'anywhere', 'warmup', 'Pemanasan ringan seluruh tubuh sebelum latihan apa pun.', 8, 40, 'maintenance', [
    ['Arm Circles', '30 sec'], ['Hip Circles', '30 sec'], ['Cat-Cow Stretch', '45 sec'], ['Jumping Jack', '45 sec'],
  ]],
  ['Beginner Home Full Body', 'beginner', 'home', 'workout', 'Latihan tubuh penuh tanpa alat untuk pemula.', 20, 150, 'weight loss', [
    ['Squat', '3 x 12'], ['Push-Up', '3 x 8'], ['Lunge', '3 x 10 per kaki'], ['Plank', '3 x 30 sec'], ['Sit-Up', '3 x 12'],
  ]],
  ['Home HIIT Burner', 'intermediate', 'home', 'workout', 'Interval intensitas tinggi tanpa alat untuk membakar kalori.', 25, 280, 'weight loss', [
    ['Burpee', '40 sec'], ['Mountain Climber', '40 sec'], ['Jumping Jack', '40 sec'], ['Squat', '40 sec'], ['Push-Up', '40 sec'],
  ]],
  ['Bodyweight Strength', 'advanced', 'home', 'workout', 'Latihan kekuatan dengan berat badan sendiri dan pull-up bar.', 35, 300, 'muscle gain', [
    ['Pull-Up', '4 x 8'], ['Push-Up', '4 x 15'], ['Lunge', '4 x 12 per kaki'], ['Glute Bridge', '4 x 15'], ['Plank', '3 x 60 sec'],
  ]],
  ['Gym Push Day', 'intermediate', 'gym', 'workout', 'Fokus dada, bahu, dan trisep.', 45, 320, 'muscle gain', [
    ['Bench Press', '4 x 8'], ['Shoulder Press', '3 x 10'], ['Tricep Pushdown', '3 x 12'],
  ]],
  ['Gym Pull Day', 'intermediate', 'gym', 'workout', 'Fokus punggung dan bisep.', 45, 330, 'muscle gain', [
    ['Deadlift', '4 x 5'], ['Barbell Row', '4 x 8'], ['Lat Pulldown', '3 x 10'], ['Bicep Curl', '3 x 12'],
  ]],
  ['Gym Leg Day', 'beginner', 'gym', 'workout', 'Latihan kaki dasar dengan mesin dan beban ringan.', 40, 300, 'muscle gain', [
    ['Leg Press', '4 x 10'], ['Squat', '3 x 12'], ['Lunge', '3 x 10 per kaki'], ['Glute Bridge', '3 x 15'],
  ]],
  ['Cardio Starter', 'beginner', 'gym', 'workout', 'Kardio dasar untuk membangun daya tahan.', 30, 300, 'endurance', [
    ['Treadmill Running', '15 min'], ['Jump Rope', '5 x 1 min'],
  ]],
];

async function runSeed() {
  const exerciseIds = {};
  let newExercises = 0;
  let newWorkouts = 0;

  for (const [name, equipment, met, kcal, instructions] of exercises) {
    const [[existing]] = await pool.execute('SELECT id FROM exercises WHERE name = ?', [name]);
    if (existing) {
      exerciseIds[name] = existing.id;
      continue;
    }
    const id = randomUUID();
    await pool.execute(
      `INSERT INTO exercises (id, name, instructions, equipment_required, base_calories_burn, met_value)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [id, name, instructions, equipment, kcal, met]
    );
    exerciseIds[name] = id;
    newExercises++;
  }

  for (const [title, difficulty, location, category, description, minutes, kcal, goal, items] of workouts) {
    const [[existing]] = await pool.execute('SELECT id FROM workouts WHERE title = ?', [title]);
    if (existing) continue;

    const id = randomUUID();
    await pool.execute(
      `INSERT INTO workouts (id, title, difficulty, location_type, category, description, duration_minutes, calories_burned, fitness_goal)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [id, title, difficulty, location, category, description, minutes, kcal, goal]
    );
    for (let i = 0; i < items.length; i++) {
      const [exName, reps] = items[i];
      await pool.execute(
        'INSERT INTO workout_exercises (workout_id, exercise_id, sequence_order, reps_or_duration) VALUES (?, ?, ?, ?)',
        [id, exerciseIds[exName], i + 1, reps]
      );
    }
    newWorkouts++;
  }

  console.log(`✅ Seed: ${newExercises} exercise baru, ${newWorkouts} workout baru.`);
}

module.exports = { runSeed };

if (require.main === module) {
  runSeed()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('❌ Seed error:', err.message);
      process.exit(1);
    });
}
