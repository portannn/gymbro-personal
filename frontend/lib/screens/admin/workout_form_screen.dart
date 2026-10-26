import 'package:flutter/material.dart';
import '../../models/admin_exercise_model.dart';
import '../../utils/admin_colors.dart';
import '../../models/workout_model.dart';
import '../../services/admin_service.dart';

class WorkoutFormScreen extends StatefulWidget {
  /// Jika null, berarti mode Tambah. Jika diisi, berarti mode Edit.
  final Workout? workout;

  const WorkoutFormScreen({super.key, this.workout});

  @override
  State<WorkoutFormScreen> createState() => _WorkoutFormScreenState();
}

class _WorkoutFormScreenState extends State<WorkoutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  bool _isLoading = false;

  // Controllers
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _caloriesCtrl;

  // Latihan di dalam workout (urutan list = urutan tampil)
  final List<_WorkoutExerciseLink> _links = [];
  List<AdminExercise> _allExercises = [];
  bool _exercisesLoading = true;
  // Hanya kirim daftar latihan jika berhasil dimuat, supaya gagal-muat tidak menghapus data
  bool _linksReady = false;

  // Dropdown selections
  String _difficulty = 'Beginner';
  String _locationType = 'Gym';
  String _category = 'Workout';
  String _fitnessGoal = '';

  static const _difficulties = ['Beginner', 'Intermediate', 'Advanced'];
  static const _locationTypes = ['Gym', 'Home', 'Anywhere'];
  static const _categories = ['Workout', 'Warmup'];
  static const _fitnessGoals = ['', 'Weight Loss', 'Muscle Gain', 'Maintenance', 'Endurance'];

  @override
  void initState() {
    super.initState();
    final w = widget.workout;
    _titleCtrl = TextEditingController(text: w?.title ?? '');
    _descriptionCtrl = TextEditingController(text: w?.description ?? '');
    _durationCtrl = TextEditingController(text: w?.durationMinutes?.toString() ?? '');
    _caloriesCtrl = TextEditingController(text: w?.caloriesBurned?.toStringAsFixed(0) ?? '');

    if (w != null) {
      // Backend menyimpan lowercase; cocokkan tanpa peduli huruf besar/kecil
      String pick(List<String> options, String? value, String fallback) => options.firstWhere(
            (o) => o.toLowerCase() == (value ?? '').toLowerCase(),
            orElse: () => fallback,
          );
      _difficulty = pick(_difficulties, w.difficulty, 'Beginner');
      _locationType = pick(_locationTypes, w.locationType, 'Gym');
      _category = pick(_categories, w.category, 'Workout');
      _fitnessGoal = pick(_fitnessGoals, w.fitnessGoal, '');
    }
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final all = await _adminService.getExercises();
    final linked = widget.workout == null
        ? {'success': true, 'data': <dynamic>[]}
        : await _adminService.getWorkoutExercises(widget.workout!.id);
    if (!mounted) return;

    if (all['success'] == true) {
      _allExercises = (all['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AdminExercise.fromJson)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    if (linked['success'] == true) {
      for (final row in (linked['data'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>()) {
        _links.add(_WorkoutExerciseLink(
          exerciseId: row['exercise_id'].toString(),
          name: (row['name'] ?? '').toString(),
          reps: (row['reps_or_duration'] ?? '').toString(),
        ));
      }
    }
    setState(() {
      _linksReady = all['success'] == true && linked['success'] == true;
      _exercisesLoading = false;
    });
  }

  Future<void> _addExercise() async {
    final usedIds = _links.map((l) => l.exerciseId).toSet();
    final available = _allExercises.where((e) => !usedIds.contains(e.id)).toList();

    final picked = await showModalBottomSheet<AdminExercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdminColors.cardColor,
      builder: (ctx) => _ExercisePickerSheet(exercises: available),
    );
    if (picked != null) {
      setState(() => _links.add(_WorkoutExerciseLink(exerciseId: picked.id, name: picked.name, reps: '')));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _durationCtrl.dispose();
    _caloriesCtrl.dispose();
    for (final l in _links) {
      l.repsCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final body = {
      'title': _titleCtrl.text.trim(),
      'difficulty': _difficulty,
      'location_type': _locationType,
      'category': _category,
      'description': _descriptionCtrl.text.trim(),
      'duration_minutes': int.tryParse(_durationCtrl.text.trim()),
      'calories_burned': double.tryParse(_caloriesCtrl.text.trim()),
      'fitness_goal': _fitnessGoal.isEmpty ? null : _fitnessGoal,
    };

    final isEditing = widget.workout != null;
    final Map<String, dynamic> result;

    if (isEditing) {
      result = await _adminService.updateWorkout(widget.workout!.id, body);
    } else {
      result = await _adminService.createWorkout(body);
    }

    if (!mounted) return;

    String? linkError;
    if (result['success'] == true && _linksReady) {
      final workoutId = (result['data'] as Workout).id;
      final linkResult = await _adminService.setWorkoutExercises(
        workoutId,
        _links.map((l) => {'exercise_id': l.exerciseId, 'reps_or_duration': l.repsCtrl.text.trim()}).toList(),
      );
      if (linkResult['success'] != true) linkError = linkResult['message']?.toString() ?? 'Gagal menyimpan latihan';
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(linkError != null
              ? 'Workout tersimpan, tapi daftar latihan gagal: $linkError'
              : (isEditing ? 'Workout berhasil diperbarui!' : 'Workout berhasil ditambahkan!')),
          backgroundColor: linkError != null ? Colors.orange : Colors.green,
        ),
      );
      // Return true so the caller knows to refresh its list
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal menyimpan workout'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.workout != null;

    return Scaffold(
      backgroundColor: AdminColors.bgColor,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Workout' : 'Tambah Workout',
          style: const TextStyle(color: AdminColors.textPrimary),
        ),
        backgroundColor: AdminColors.cardColor,
        iconTheme: const IconThemeData(color: AdminColors.textPrimary),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: AdminColors.accentColor, strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: AdminColors.accentColor),
              onPressed: _saveForm,
              tooltip: 'Simpan',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              _buildTextField(
                controller: _titleCtrl,
                label: 'Judul Workout',
                isRequired: true,
              ),
              const SizedBox(height: 16),

              // Difficulty & Category (dropdowns)
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Kesulitan',
                      value: _difficulty,
                      items: _difficulties,
                      onChanged: (v) => setState(() => _difficulty = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Kategori',
                      value: _category,
                      items: _categories,
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location Type
              _buildDropdown(
                label: 'Tipe Lokasi',
                value: _locationType,
                items: _locationTypes,
                onChanged: (v) => setState(() => _locationType = v!),
              ),
              const SizedBox(height: 16),

              // Fitness Goal (optional)
              _buildDropdown(
                label: 'Fitness Goal (opsional)',
                value: _fitnessGoal,
                items: _fitnessGoals,
                onChanged: (v) => setState(() => _fitnessGoal = v ?? ''),
              ),
              const SizedBox(height: 16),

              // Description
              _buildTextField(
                controller: _descriptionCtrl,
                label: 'Deskripsi',
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // Duration & Calories
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _durationCtrl,
                      label: 'Durasi (menit)',
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _caloriesCtrl,
                      label: 'Kalori Terbakar',
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildExercisesSection(),
              const SizedBox(height: 32),

              // Save button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.accentColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : _saveForm,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : Text(
                        isEditing ? 'Perbarui Workout' : 'Simpan Workout',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExercisesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Latihan dalam workout',
                style: TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            TextButton.icon(
              onPressed: (_exercisesLoading || _allExercises.isEmpty) ? null : _addExercise,
              icon: const Icon(Icons.add, color: AdminColors.accentColor, size: 18),
              label: const Text('Tambah', style: TextStyle(color: AdminColors.accentColor)),
            ),
          ],
        ),
        if (_exercisesLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(color: AdminColors.accentColor)),
          )
        else if (!_linksReady)
          const Text(
            'Gagal memuat daftar latihan. Daftar latihan tidak akan diubah saat menyimpan.',
            style: TextStyle(color: Colors.orange, fontSize: 13),
          )
        else if (_links.isEmpty)
          const Text(
            'Belum ada latihan. Tekan Tambah untuk memilih dari master data.',
            style: TextStyle(color: AdminColors.textSecondary, fontSize: 13),
          )
        else
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                _links.insert(newIndex, _links.removeAt(oldIndex));
              });
            },
            children: [
              for (var i = 0; i < _links.length; i++)
                Card(
                  key: ValueKey(_links[i].exerciseId),
                  color: AdminColors.cardColor,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.drag_handle, color: AdminColors.textSecondary),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '${i + 1}. ${_links[i].name}',
                            style: const TextStyle(color: AdminColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _links[i].repsCtrl,
                            style: const TextStyle(color: AdminColors.textPrimary, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: '3 x 12 / 30 sec',
                              hintStyle: TextStyle(color: AdminColors.textSecondary, fontSize: 12),
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                          tooltip: 'Hapus dari workout',
                          onPressed: () => setState(() => _links.removeAt(i).repsCtrl.dispose()),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: AdminColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AdminColors.textSecondary),
        filled: true,
        fillColor: AdminColors.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AdminColors.accentColor),
        ),
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label wajib diisi';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: AdminColors.cardColor,
      style: const TextStyle(color: AdminColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AdminColors.textSecondary),
        filled: true,
        fillColor: AdminColors.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AdminColors.accentColor),
        ),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e.isEmpty ? '—' : e, style: const TextStyle(color: AdminColors.textPrimary)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _WorkoutExerciseLink {
  _WorkoutExerciseLink({required this.exerciseId, required this.name, required String reps})
      : repsCtrl = TextEditingController(text: reps);

  final String exerciseId;
  final String name;
  final TextEditingController repsCtrl;
}

class _ExercisePickerSheet extends StatefulWidget {
  const _ExercisePickerSheet({required this.exercises});
  final List<AdminExercise> exercises;

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.exercises.where((e) => e.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  autofocus: true,
                  style: const TextStyle(color: AdminColors.textPrimary),
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Cari latihan...',
                    hintStyle: TextStyle(color: AdminColors.textSecondary),
                    prefixIcon: Icon(Icons.search, color: AdminColors.textSecondary),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('Tidak ada latihan tersedia.', style: TextStyle(color: AdminColors.textSecondary)),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final e = filtered[i];
                          return ListTile(
                            title: Text(e.name, style: const TextStyle(color: AdminColors.textPrimary)),
                            subtitle: Text(
                              e.equipmentRequired.isEmpty ? 'MET ${e.metValue}' : '${e.equipmentRequired} - MET ${e.metValue}',
                              style: const TextStyle(color: AdminColors.textSecondary, fontSize: 12),
                            ),
                            onTap: () => Navigator.pop(context, e),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
