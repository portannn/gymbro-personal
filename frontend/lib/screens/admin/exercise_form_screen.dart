import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;
import '../../models/admin_exercise_model.dart';
import '../../services/admin_service.dart';
import '../../utils/admin_colors.dart';

class ExerciseFormScreen extends StatefulWidget {
  const ExerciseFormScreen({super.key, this.exercise});

  /// null = tambah baru, non-null = edit
  final AdminExercise? exercise;

  @override
  State<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends State<ExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _equipmentCtrl;
  late final TextEditingController _instructionsCtrl;
  late final TextEditingController _metCtrl;
  late final TextEditingController _caloriesCtrl;

  XFile? _pickedMedia;
  bool _isSaving = false;

  bool get _isEditing => widget.exercise != null;

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _equipmentCtrl = TextEditingController(text: e?.equipmentRequired ?? '');
    _instructionsCtrl = TextEditingController(text: e?.instructions ?? '');
    _metCtrl = TextEditingController(text: (e?.metValue ?? 3.5).toString());
    _caloriesCtrl = TextEditingController(text: (e?.baseCaloriesBurn ?? 0).toStringAsFixed(0));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _equipmentCtrl.dispose();
    _instructionsCtrl.dispose();
    _metCtrl.dispose();
    _caloriesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source) async {
    final file = await _picker.pickImage(source: source);
    if (file != null) setState(() => _pickedMedia = file);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final body = {
      'name': _nameCtrl.text.trim(),
      'equipment_required': _equipmentCtrl.text.trim(),
      'instructions': _instructionsCtrl.text.trim(),
      'met_value': double.parse(_metCtrl.text.trim()),
      'base_calories_burn': double.tryParse(_caloriesCtrl.text.trim()) ?? 0,
    };

    final result = _isEditing
        ? await _adminService.updateExercise(widget.exercise!.id, body)
        : await _adminService.createExercise(body);

    if (result['success'] != true) {
      _finish(result['message']?.toString() ?? 'Gagal menyimpan latihan', ok: false);
      return;
    }

    // Upload media (jika dipilih) setelah record tersimpan
    if (_pickedMedia != null) {
      final id = (result['data'] as Map<String, dynamic>)['id'].toString();
      final upload = await _adminService.uploadExerciseMedia(id, _pickedMedia!);
      if (upload['success'] != true) {
        _finish('Latihan tersimpan, tapi media gagal diupload: ${upload['message']}', ok: true, warn: true);
        return;
      }
    }

    _finish(_isEditing ? 'Latihan berhasil diperbarui!' : 'Latihan berhasil ditambahkan!', ok: true);
  }

  void _finish(String message, {required bool ok, bool warn = false}) {
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: !ok ? Colors.redAccent : (warn ? Colors.orange : Colors.green),
      ),
    );
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bgColor,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Latihan' : 'Tambah Latihan',
          style: const TextStyle(color: AdminColors.textPrimary),
        ),
        backgroundColor: AdminColors.cardColor,
        iconTheme: const IconThemeData(color: AdminColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMediaSection(),
              const SizedBox(height: 24),
              _field(_nameCtrl, 'Nama Latihan', required: true),
              const SizedBox(height: 16),
              _field(_equipmentCtrl, 'Alat yang dibutuhkan (mis. Dumbbell, None)'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _metCtrl,
                      'Nilai MET',
                      required: true,
                      number: true,
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());
                        if (n == null || n <= 0) return 'MET harus angka > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _field(_caloriesCtrl, 'Kalori dasar', number: true)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'MET dipakai untuk estimasi kalori: durasi x MET x 3.5 x berat badan / 200. '
                'Jalan santai ~3.5, lari ~8.',
                style: TextStyle(color: AdminColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _field(_instructionsCtrl, 'Instruksi / deskripsi teknis', maxLines: 5),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.accentColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : Text(
                        _isEditing ? 'Perbarui Latihan' : 'Simpan Latihan',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    final existingUrl = widget.exercise?.mediaUrl;
    Widget? preview;
    if (_pickedMedia != null) {
      preview = kIsWeb
          ? Image.network(_pickedMedia!.path, fit: BoxFit.cover)
          : Image.file(File(_pickedMedia!.path), fit: BoxFit.cover);
    } else if (existingUrl != null && existingUrl.isNotEmpty) {
      preview = Image.network(
        existingUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Center(
          child: Text('Media tidak dapat ditampilkan', style: TextStyle(color: AdminColors.textSecondary)),
        ),
      );
    }

    return Container(
      height: 200,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AdminColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.textSecondary.withValues(alpha: 0.3)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ?preview,
          Align(
            alignment: preview == null ? Alignment.center : Alignment.bottomCenter,
            child: Container(
              color: preview == null ? null : Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (preview == null)
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Text('Media (opsional)', style: TextStyle(color: AdminColors.textSecondary)),
                    ),
                  TextButton.icon(
                    onPressed: () => _pickMedia(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, color: AdminColors.accentColor),
                    label: const Text('Galeri', style: TextStyle(color: Colors.white)),
                  ),
                  if (!kIsWeb)
                    TextButton.icon(
                      onPressed: () => _pickMedia(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, color: AdminColors.accentColor),
                      label: const Text('Kamera', style: TextStyle(color: Colors.white)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool number = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: number ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : null,
      style: const TextStyle(color: AdminColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AdminColors.textSecondary),
        filled: true,
        fillColor: AdminColors.cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.accentColor)),
      ),
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null
              : null),
    );
  }
}
