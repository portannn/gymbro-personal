import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/exercise_upload_provider.dart';

class ManageExercisesScreen extends StatefulWidget {
  const ManageExercisesScreen({super.key});

  @override
  State<ManageExercisesScreen> createState() => _ManageExercisesScreenState();
}

class _ManageExercisesScreenState extends State<ManageExercisesScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExerciseUploadProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Master Data Latihan', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF292929),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Media Preview/Picker Area
              _buildMediaSection(provider),
              const SizedBox(height: 24),

              // Form Fields
              _buildTextField(
                label: 'Nama Latihan',
                hint: 'Contoh: Bench Press',
                onSaved: (val) => provider.setNamaLatihan(val ?? ''),
                validator: (val) => val == null || val.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              _buildDropdownField(
                label: 'Target Otot',
                value: provider.targetOtot,
                items: ['Upper body', 'Lower body', 'Full body'],
                onChanged: (val) => provider.setTargetOtot(val!),
              ),
              const SizedBox(height: 16),

              _buildDropdownField(
                label: 'Lokasi Latihan',
                value: provider.tipe,
                items: ['Gym', 'Rumah'],
                onChanged: (val) => provider.setTipe(val!),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Deskripsi Teknis',
                hint: 'Jelaskan cara melakukan latihan ini...',
                maxLines: 4,
                onSaved: (val) => provider.setDeskripsi(val ?? ''),
              ),
              const SizedBox(height: 32),

              // Upload Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCCFF00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: provider.isLoading ? null : () => _handleUpload(provider),
                child: provider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : const Text('UPLOAD MASTER DATA', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaSection(ExerciseUploadProvider provider) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF292929),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9E9E9E).withValues(alpha: 0.3)),
      ),
      child: provider.selectedMedia != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(provider.selectedMedia!, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: provider.clearMedia,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_upload_outlined, size: 48, color: Color(0xFF9E9E9E)),
                const SizedBox(height: 8),
                const Text('Pilih Media (Foto/Video)', style: TextStyle(color: Color(0xFF9E9E9E))),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPickerButton(Icons.camera_alt, 'Kamera', () => provider.pickMedia(ImageSource.camera)),
                    const SizedBox(width: 16),
                    _buildPickerButton(Icons.photo_library, 'Galeri', () => provider.pickMedia(ImageSource.gallery)),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildPickerButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFCCFF00)),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    int maxLines = 1,
    required FormFieldSetter<String> onSaved,
    FormFieldValidator<String>? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          style: const TextStyle(color: Colors.white),
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
            filled: true,
            fillColor: const Color(0xFF292929),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          onSaved: onSaved,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: const Color(0xFF292929), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF292929),
              style: const TextStyle(color: Colors.white),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleUpload(ExerciseUploadProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final result = await provider.uploadExercise();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
      ),
    );

    if (result['success']) {
      _formKey.currentState!.reset();
    }
  }
}
