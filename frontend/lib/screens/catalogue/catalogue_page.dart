import 'package:flutter/material.dart';
import '../../models/workout_model.dart';
import '../../services/workout_service.dart';
import '../../utils/palette.dart';
import 'exercise_selection_page.dart';

class CataloguePage extends StatefulWidget {
  const CataloguePage({super.key});

  @override
  State<CataloguePage> createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage> {
  final WorkoutService _workoutService = WorkoutService();

  List<Workout> _workouts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _selectedLocation = 'all';
  String _selectedCategory = 'all';
  String _selectedDifficulty = 'all';

  static const _locations = [
    _FilterOption(label: 'All', value: 'all'),
    _FilterOption(label: 'Home', value: 'home'),
    _FilterOption(label: 'Gym', value: 'gym'),
    _FilterOption(label: 'Anywhere', value: 'anywhere'),
  ];

  static const _categories = [
    _FilterOption(label: 'All', value: 'all'),
    _FilterOption(label: 'Workout', value: 'workout'),
    _FilterOption(label: 'Warmup', value: 'warmup'),
  ];

  static const _difficulties = [
    _FilterOption(label: 'All', value: 'all'),
    _FilterOption(label: 'Beginner', value: 'beginner'),
    _FilterOption(label: 'Intermediate', value: 'intermediate'),
    _FilterOption(label: 'Advanced', value: 'advanced'),
  ];

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final workouts = await _workoutService.getWorkouts(
        location: _selectedLocation,
        category: _selectedCategory,
      );

      // Filter by difficulty if not 'all'
      final filteredWorkouts = _selectedDifficulty == 'all'
          ? workouts
          : workouts.where((workout) => workout.difficulty.toLowerCase() == _selectedDifficulty).toList();

      if (!mounted) return;
      setState(() {
        _workouts = filteredWorkouts;
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

  void _setLocation(String value) {
    if (_selectedLocation == value) return;
    setState(() => _selectedLocation = value);
    _loadWorkouts();
  }

  void _setCategory(String value) {
    if (_selectedCategory == value) return;
    setState(() => _selectedCategory = value);
    _loadWorkouts();
  }

  void _setDifficulty(String value) {
    if (_selectedDifficulty == value) return;
    setState(() => _selectedDifficulty = value);
    _loadWorkouts();
  }

  void _openWorkout(Workout workout) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseSelectionPage(
          workoutId: workout.id,
          location: workout.locationType,
          workoutType: workout.title,
          workout: workout, 
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: kAccent,
        backgroundColor: kCard,
        onRefresh: _loadWorkouts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Train',
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Choose a workout from your database',
                      style: TextStyle(color: kTextMuted, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    _FilterSection(
                      label: 'Location',
                      icon: Icons.location_on_outlined,
                      options: _locations,
                      selected: _selectedLocation,
                      onSelect: _setLocation,
                    ),
                    const SizedBox(height: 18),
                    _FilterSection(
                      label: 'Category',
                      icon: Icons.category_outlined,
                      options: _categories,
                      selected: _selectedCategory,
                      onSelect: _setCategory,
                    ),
                    const SizedBox(height: 18),
                    _FilterSection(
                      label: 'Difficulty',
                      icon: Icons.trending_up_outlined,
                      options: _difficulties,
                      selected: _selectedDifficulty,
                      onSelect: _setDifficulty,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Workouts',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_isLoading)
                          Text(
                            '${_workouts.length} found',
                            style: const TextStyle(
                              color: kTextMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
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
                  title: 'Failed to load workouts',
                  message: 'Check the server connection and try again.',
                  actionLabel: 'Retry',
                  onAction: _loadWorkouts,
                ),
              )
            else if (_workouts.isEmpty)
              const SliverFillRemaining(
                child: _MessageState(
                  icon: Icons.fitness_center,
                  title: 'No workouts found',
                  message: 'No database workouts match this filter.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final workout = _workouts[index];
                      return _WorkoutCard(
                        workout: workout,
                        imageUrl: _imageForWorkout(workout),
                        onTap: () => _openWorkout(workout),
                      );
                    },
                    childCount: _workouts.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _imageForWorkout(Workout workout) {
    final title = workout.title.toLowerCase();
    if (workout.category == 'warmup' || title.contains('mobility')) {
      return 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=900&q=80';
    }
    if (title.contains('abs')) {
      return 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=900&q=80';
    }
    if (workout.locationType == 'gym') {
      return 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=900&q=80';
    }
    return 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=900&q=80';
  }
}

class _FilterOption {
  const _FilterOption({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.label,
    required this.icon,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final String label;
  final IconData icon;
  final List<_FilterOption> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: kAccent, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: kTextMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final option = options[index];
              return _OptionChip(
                label: option.label,
                isSelected: option.value == selected,
                onTap: () => onSelect(option.value),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemCount: options.length,
          ),
        ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? kAccent : kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kAccent : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? kBg : kTextPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
    required this.workout,
    required this.imageUrl,
    required this.onTap,
  });

  final Workout workout;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 244,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withAlpha(138),
              BlendMode.darken,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _MetaPill(
                    icon: Icons.location_on_outlined,
                    label: _capitalize(workout.locationType),
                    color: kAccent,
                  ),
                  const SizedBox(width: 8),
                  _MetaPill(
                    icon: Icons.category_outlined,
                    label: _capitalize(workout.category),
                    color: const Color(0xFF6BE5FF),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                workout.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                workout.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    '${_capitalize(workout.difficulty)} - ${workout.durationMinutes ?? 0} min - ${workout.exerciseCount} exercises - ${workout.caloriesBurned?.toStringAsFixed(0) ?? '0'} kcal',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kAccent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: kBg,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    color: Color(0xFF6BE5FF),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Equipment: ${workout.equipmentSummary.isEmpty ? 'none' : workout.equipmentSummary}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return '-';
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 12,
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
              style: const TextStyle(color: kTextMuted, height: 1.45),
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
