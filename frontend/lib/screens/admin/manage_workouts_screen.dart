import 'package:flutter/material.dart';
import '../../utils/admin_colors.dart';
import '../../models/workout_model.dart';
import '../../services/admin_service.dart';
import 'workout_form_screen.dart';

class ManageWorkoutsScreen extends StatefulWidget {
  const ManageWorkoutsScreen({super.key});

  @override
  State<ManageWorkoutsScreen> createState() => _ManageWorkoutsScreenState();
}

class _ManageWorkoutsScreenState extends State<ManageWorkoutsScreen> {
  final AdminService _adminService = AdminService();
  List<Workout> _workouts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchWorkouts();
  }

  Future<void> _fetchWorkouts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _adminService.getWorkouts();

    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _workouts = List<Workout>.from(result['data']);
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'];
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToForm({Workout? workout}) async {
    final refreshed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutFormScreen(workout: workout),
      ),
    );
    if (refreshed == true) {
      _fetchWorkouts();
    }
  }

  Future<void> _confirmDelete(Workout workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.cardColor,
        title: const Text('Hapus Workout', style: TextStyle(color: AdminColors.textPrimary)),
        content: Text(
          'Yakin ingin menghapus "${workout.title}"? Tindakan ini tidak dapat dibatalkan.',
          style: const TextStyle(color: AdminColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AdminColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await _adminService.deleteWorkout(workout.id);
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchWorkouts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal menghapus workout'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bgColor,
      appBar: AppBar(
        title: const Text('Manage Workouts', style: TextStyle(color: AdminColors.textPrimary)),
        backgroundColor: AdminColors.cardColor,
        iconTheme: const IconThemeData(color: AdminColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AdminColors.accentColor),
            onPressed: _fetchWorkouts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AdminColors.accentColor,
        foregroundColor: Colors.black,
        onPressed: () => _navigateToForm(),
        tooltip: 'Tambah Workout',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AdminColors.accentColor));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AdminColors.accentColor),
                onPressed: _fetchWorkouts,
                icon: const Icon(Icons.refresh, color: Colors.black),
                label: const Text('Coba Lagi', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      );
    }

    if (_workouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64, color: AdminColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'Belum ada workout.\nTambahkan workout pertama Anda!',
              style: TextStyle(color: AdminColors.textSecondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _workouts.length,
      itemBuilder: (context, index) {
        final workout = _workouts[index];
        return _WorkoutCard(
          workout: workout,
          onEdit: () => _navigateToForm(workout: workout),
          onDelete: () => _confirmDelete(workout),
        );
      },
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
    required this.workout,
    required this.onEdit,
    required this.onDelete,
  });

  final Workout workout;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AdminColors.cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    workout.title,
                    style: const TextStyle(
                      color: AdminColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AdminColors.accentColor, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Hapus',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Tag(workout.category),
                _Tag(workout.difficulty),
                _Tag(workout.locationType),
                if (workout.durationMinutes != null)
                  _Tag('${workout.durationMinutes} menit'),
                if (workout.caloriesBurned != null)
                  _Tag('${workout.caloriesBurned!.toStringAsFixed(0)} kcal'),
              ],
            ),
            if (workout.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                workout.description,
                style: const TextStyle(color: AdminColors.textSecondary, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AdminColors.accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AdminColors.accentColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AdminColors.accentColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
