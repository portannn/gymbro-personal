import 'package:flutter/material.dart';
import '../../models/exercise_model.dart';
import '../../models/workout_model.dart';
import '../../services/exercise_service.dart';
import '../../services/history_service.dart';
import '../../services/calorie_service.dart';
import '../../utils/palette.dart';
import 'workout_summary_screen.dart';

class ExerciseSelectionPage extends StatefulWidget {
  const ExerciseSelectionPage({
    super.key,
    this.workoutId,
    required this.location,
    required this.workoutType,
    this.workout,
  });

  final String? workoutId;
  final String location;
  final String workoutType;
  final Workout? workout;

  @override
  State<ExerciseSelectionPage> createState() => _ExerciseSelectionPageState();
}

class _ExerciseSelectionPageState extends State<ExerciseSelectionPage> {
  final ExerciseService _exerciseService = ExerciseService();
  final HistoryService _historyService = HistoryService();
  final CalorieService _calorieService = CalorieService();

  List<Exercise> _exercises = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final exercises = await _exerciseService.getExercises(
        workoutId: widget.workoutId,
        location: widget.location,
        workoutType: widget.workoutType,
      );

      if (!mounted) return;
      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  
  void _startSession() async {
    // Gunakan data workout (durasi) yang ada
    final duration = widget.workout?.durationMinutes ?? 0;
    
    if (duration == 0 || widget.workoutId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data workout tidak lengkap (durasi atau ID tidak ada).'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Hitung estimasi kalori aktual memanggil API Backend (PBI-1 Subtask 5)
      final calculatedCalories = await _calorieService.calculateCalories(
        workoutId: widget.workoutId!,
        durationMinutes: duration,
      );

      if (calculatedCalories == null) {
        throw Exception('Gagal menghitung kalori. Pastikan profil berat badan Anda sudah diisi.');
      }

      // 2. Simpan ke history menggunakan kalori yang sudah dihitung (dibulatkan ke int untuk history)
      final success = await _historyService.addHistory(
        workoutName: widget.workoutType,
        durationMinutes: duration,
        caloriesBurned: calculatedCalories.round(),
      );
      
      if (success) {
        if (mounted) {
          // Navigasi ke Halaman Ringkasan Latihan (PBI-1 Subtask 4)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutSummaryScreen(
                workoutName: widget.workoutType,
                durationMinutes: duration,
                caloriesBurned: calculatedCalories,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save workout completion'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      bottomNavigationBar: _isLoading || _hasError || _exercises.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _startSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccent,
                    foregroundColor: kBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Start Session',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
      body: SafeArea(
        child: RefreshIndicator(
          color: kAccent,
          backgroundColor: kCard,
          onRefresh: _loadExercises,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: kTextPrimary,
                            ),
                            tooltip: 'Back',
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Choosen Workout',
                        style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoPill(
                            icon: Icons.location_on_outlined,
                            label: widget.location,
                          ),
                          _InfoPill(
                            icon: Icons.accessibility_new_rounded,
                            label: widget.workoutType,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: kAccent),
                  ),
                )
              else if (_hasError)
                SliverFillRemaining(
                  child: _MessageState(
                    icon: Icons.wifi_off_rounded,
                    title: 'Failed to load exercises',
                    message: 'Check the server connection and try again.',
                    actionLabel: 'Retry',
                    onAction: _loadExercises,
                  ),
                )
              else if (_exercises.isEmpty)
                const SliverFillRemaining(
                  child: _MessageState(
                    icon: Icons.fitness_center,
                    title: 'No exercises found',
                    message: 'No database exercises match this workout option.',
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    _exercises.isEmpty ? 24 : 96,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final exercise = _exercises[index];
                        return _ExerciseCard(
                          exercise: exercise,
                        );
                      },
                      childCount: _exercises.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kAccent, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
  });

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ExerciseThumb(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          exercise.name.isEmpty
                              ? 'Untitled Exercise'
                              : exercise.name,
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (exercise.workoutTitle.isNotEmpty)
                    Text(
                      exercise.workoutTitle,
                      style: const TextStyle(
                        color: kTextMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (exercise.workoutTitle.isNotEmpty)
                    const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (exercise.repsOrDuration.isNotEmpty)
                        _ExercisePill(
                          icon: Icons.repeat_rounded,
                          label: exercise.repsOrDuration,
                          color: kAccent,
                        ),
                      if (exercise.baseCaloriesBurn != null)
                        _ExercisePill(
                          icon: Icons.local_fire_department,
                          label:
                              '${exercise.baseCaloriesBurn!.toStringAsFixed(1)} kcal',
                          color: const Color(0xFFFF7043),
                        ),
                    ],
                  ),
                  if (exercise.instructions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      exercise.instructions,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kTextMuted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
    );
  }
}

class _ExerciseThumb extends StatelessWidget {
  const _ExerciseThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      clipBehavior: Clip.antiAlias,
      child: const Icon(Icons.fitness_center, color: kAccent, size: 28),
    );
  }
}

class _ExercisePill extends StatelessWidget {
  const _ExercisePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kCard,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: Icon(icon, color: kTextMuted, size: 44),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextMuted,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccent,
                  foregroundColor: kBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
