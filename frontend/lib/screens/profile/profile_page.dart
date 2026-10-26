import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/palette.dart';
import 'weight_tracking_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  bool _isSubmitting = false;

  void _showWeightDialog(BuildContext context) {
    final TextEditingController weightController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String? weightError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catat Berat Badan',
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Input Berat Badan
                  TextField(
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: kTextPrimary),
                    onChanged: (value) {
                      if (weightError != null) {
                        setModalState(() => weightError = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Berat Badan (kg)',
                      labelStyle: const TextStyle(color: kTextMuted),
                      errorText: weightError,
                      filled: true,
                      fillColor: kBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.monitor_weight_outlined, color: kTextMuted),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input Tanggal
                  GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: kAccent,
                                onPrimary: kBg,
                                surface: kCard,
                                onSurface: kTextPrimary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null && picked != selectedDate) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: kTextMuted),
                          const SizedBox(width: 16),
                          Text(
                            DateFormat('d MMMM yyyy', 'id_ID').format(selectedDate),
                            style: const TextStyle(color: kTextPrimary, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              final weightText = weightController.text.trim();
                              
                              if (weightText.isEmpty) {
                                setModalState(() => weightError = 'Berat badan tidak boleh kosong');
                                return;
                              }
                              
                              final weight = double.tryParse(weightText.replaceAll(',', '.'));
                              if (weight == null) {
                                setModalState(() => weightError = 'Masukkan angka yang valid');
                                return;
                              }
                              
                              if (weight < 20 || weight > 300) {
                                setModalState(() => weightError = 'Berat badan harus antara 20 - 300 kg');
                                return;
                              }

                              setModalState(() => _isSubmitting = true);
                              
                              final result = await _authService.updateWeight(weight, selectedDate);
                              
                              setModalState(() => _isSubmitting = false);

                              if (context.mounted) {
                                Navigator.pop(context); // Tutup dialog
                                
                                if (result['success'] == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result['message']),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  // Refresh profil agar UI terupdate dengan berat terbaru
                                  context.read<AuthProvider>().checkAuthStatus();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result['message'] ?? 'Gagal menyimpan data'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccent,
                        foregroundColor: kBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: kBg, strokeWidth: 2),
                            )
                          : const Text(
                              'Simpan',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator(color: kAccent));
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header Profile
            const CircleAvatar(
              radius: 50,
              backgroundColor: kCard,
              child: Icon(Icons.person, size: 50, color: kTextMuted),
            ),
            const SizedBox(height: 16),
            Text(
              user.fullName,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: const TextStyle(color: kTextMuted, fontSize: 16),
            ),
            const SizedBox(height: 32),

            // Card Berat Badan
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Berat Badan Saat Ini',
                        style: TextStyle(color: kTextMuted, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            user.weight != null ? user.weight!.toStringAsFixed(1) : '--',
                            style: const TextStyle(
                              color: kTextPrimary,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'kg',
                            style: TextStyle(color: kTextMuted, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: kBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit_rounded, color: kAccent),
                      onPressed: () => _showWeightDialog(context),
                      tooltip: 'Update Berat Badan',
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Tombol Update
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => _showWeightDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Catat Berat Badan Baru'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kAccent,
                  side: const BorderSide(color: kAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tombol Lihat Riwayat
            SizedBox(
              width: double.infinity,
              height: 56,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const WeightTrackingPage()),
                  );
                },
                icon: const Icon(Icons.history_rounded, color: kTextMuted),
                label: const Text(
                  'Lihat Riwayat Berat Badan',
                  style: TextStyle(color: kTextMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
