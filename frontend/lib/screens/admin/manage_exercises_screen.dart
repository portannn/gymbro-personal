import 'package:flutter/material.dart';
import '../../models/admin_exercise_model.dart';
import '../../services/admin_service.dart';
import '../../utils/admin_colors.dart';
import 'exercise_form_screen.dart';

class ManageExercisesScreen extends StatefulWidget {
  const ManageExercisesScreen({super.key});

  @override
  State<ManageExercisesScreen> createState() => _ManageExercisesScreenState();
}

class _ManageExercisesScreenState extends State<ManageExercisesScreen> {
  final AdminService _adminService = AdminService();
  List<AdminExercise> _exercises = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  Future<void> _fetchExercises() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _adminService.getExercises();
    if (!mounted) return;

    if (result['success'] == true) {
      final raw = (result['data'] as List<dynamic>? ?? []);
      final list = raw.whereType<Map<String, dynamic>>().map(AdminExercise.fromJson).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      setState(() {
        _exercises = list;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message']?.toString() ?? 'Gagal memuat latihan';
        _isLoading = false;
      });
    }
  }

  Future<void> _openForm({AdminExercise? exercise}) async {
    final refreshed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ExerciseFormScreen(exercise: exercise)),
    );
    if (refreshed == true) _fetchExercises();
  }

  Future<void> _confirmDelete(AdminExercise exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.cardColor,
        title: const Text('Hapus Latihan', style: TextStyle(color: AdminColors.textPrimary)),
        content: Text(
          'Yakin ingin menghapus "${exercise.name}"? Latihan ini juga akan dihapus dari semua workout.',
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

    final result = await _adminService.deleteExercise(exercise.id);
    if (!mounted) return;

    final ok = result['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Latihan berhasil dihapus' : (result['message']?.toString() ?? 'Gagal menghapus latihan')),
        backgroundColor: ok ? Colors.green : Colors.redAccent,
      ),
    );
    if (ok) _fetchExercises();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bgColor,
      appBar: AppBar(
        title: const Text('Master Data Latihan', style: TextStyle(color: AdminColors.textPrimary)),
        backgroundColor: AdminColors.cardColor,
        iconTheme: const IconThemeData(color: AdminColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AdminColors.accentColor),
            onPressed: _fetchExercises,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AdminColors.accentColor,
        foregroundColor: Colors.black,
        onPressed: () => _openForm(),
        tooltip: 'Tambah Latihan',
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AdminColors.accentColor),
                onPressed: _fetchExercises,
                icon: const Icon(Icons.refresh, color: Colors.black),
                label: const Text('Coba Lagi', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      );
    }

    final visible = _exercises.where((e) => e.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            style: const TextStyle(color: AdminColors.textPrimary),
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Cari latihan...',
              hintStyle: const TextStyle(color: AdminColors.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AdminColors.textSecondary),
              filled: true,
              fillColor: AdminColors.cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? const Center(
                  child: Text('Tidak ada latihan.', style: TextStyle(color: AdminColors.textSecondary, fontSize: 16)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: visible.length,
                  itemBuilder: (context, i) {
                    final e = visible[i];
                    return _ExerciseCard(
                      exercise: e,
                      onEdit: () => _openForm(exercise: e),
                      onDelete: () => _confirmDelete(e),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.onEdit, required this.onDelete});

  final AdminExercise exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AdminColors.cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white10),
      ),
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          exercise.name,
          style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Tag('MET ${exercise.metValue.toStringAsFixed(1)}'),
              if (exercise.equipmentRequired.isNotEmpty) _Tag(exercise.equipmentRequired),
              if (exercise.mediaUrl != null && exercise.mediaUrl!.isNotEmpty) const _Tag('media'),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AdminColors.accentColor, size: 20),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: onDelete,
              tooltip: 'Hapus',
            ),
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
        style: const TextStyle(color: AdminColors.accentColor, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
