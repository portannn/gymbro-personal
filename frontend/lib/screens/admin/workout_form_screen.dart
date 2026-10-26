import 'package:flutter/material.dart';
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

  // Dropdown selections
  String _difficulty = 'Beginner';
  String _locationType = 'Gym';
  String _category = 'Strength';
  String _fitnessGoal = '';

  static const _difficulties = ['Beginner', 'Intermediate', 'Advanced'];
  static const _locationTypes = ['Gym', 'Home', 'Anywhere'];
  static const _categories = ['Strength', 'Cardio', 'Flexibility', 'HIIT', 'Yoga', 'Other'];
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
      _difficulty = _difficulties.contains(w.difficulty) ? w.difficulty : 'Beginner';
      _locationType = _locationTypes.contains(w.locationType) ? w.locationType : 'Gym';
      _category = _categories.contains(w.category) ? w.category : 'Strength';
      _fitnessGoal = _fitnessGoals.contains(w.fitnessGoal ?? '') ? (w.fitnessGoal ?? '') : '';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _durationCtrl.dispose();
    _caloriesCtrl.dispose();
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
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Workout berhasil diperbarui!' : 'Workout berhasil ditambahkan!'),
          backgroundColor: Colors.green,
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
