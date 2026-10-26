import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/admin_service.dart';
import '../models/master_exercise_model.dart';

class ExerciseUploadProvider with ChangeNotifier {
  final AdminService _adminService = AdminService();
  final ImagePicker _picker = ImagePicker();

  String _namaLatihan = '';
  String _tipe = 'Gym';
  String _targetOtot = 'Upper body';
  String _deskripsiTeknis = '';
  File? _selectedMedia;
  bool _isLoading = false;

  // Getters
  String get namaLatihan => _namaLatihan;
  String get tipe => _tipe;
  String get targetOtot => _targetOtot;
  String get deskripsiTeknis => _deskripsiTeknis;
  File? get selectedMedia => _selectedMedia;
  bool get isLoading => _isLoading;

  // Setters
  void setNamaLatihan(String val) => _namaLatihan = val;
  void setTipe(String val) {
    _tipe = val;
    notifyListeners();
  }
  void setTargetOtot(String val) {
    _targetOtot = val;
    notifyListeners();
  }
  void setDeskripsi(String val) => _deskripsiTeknis = val;

  Future<void> pickMedia(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source); // or pickVideo
    if (file != null) {
      _selectedMedia = File(file.path);
      notifyListeners();
    }
  }

  void clearMedia() {
    _selectedMedia = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> uploadExercise() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Create Exercise Record
      final exerciseData = {
        'nama_latihan': _namaLatihan,
        'tipe': _tipe,
        'target_otot': _targetOtot,
        'deskripsi_teknis': _deskripsiTeknis,
      };

      final createResult = await _adminService.createExercise(exerciseData);
      if (!createResult['success']) {
        _isLoading = false;
        notifyListeners();
        return createResult;
      }

      final MasterExercise newExercise = MasterExercise.fromJson(createResult['data']);

      // 2. If media is selected, upload it
      if (_selectedMedia != null) {
        final uploadResult = await _adminService.uploadExerciseMedia(newExercise.id, _selectedMedia!.path);
        if (!uploadResult['success']) {
          _isLoading = false;
          notifyListeners();
          return {'success': true, 'message': 'Latihan dibuat, tapi media gagal diupload: ${uploadResult['message']}'};
        }
      }

      _isLoading = false;
      resetForm();
      notifyListeners();
      return {'success': true, 'message': 'Latihan dan media berhasil diupload!'};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  void resetForm() {
    _namaLatihan = '';
    _tipe = 'Gym';
    _targetOtot = 'Upper body';
    _deskripsiTeknis = '';
    _selectedMedia = null;
    _isLoading = false;
  }
}
