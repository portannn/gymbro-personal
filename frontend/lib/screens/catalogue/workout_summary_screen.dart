import 'package:flutter/material.dart';
import '../../utils/palette.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  final String workoutName;
  final int durationMinutes;
  final double caloriesBurned;

  const WorkoutSummaryScreen({
    super.key,
    required this.workoutName,
    required this.durationMinutes,
    required this.caloriesBurned,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ikon sukses
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.green,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 32),

                // Teks Ucapan
                const Text(
                  'Latihan Selesai!',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kerja bagus! Anda telah menyelesaikan $workoutName.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: kTextMuted,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),

                // Ringkasan Stats Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Durasi
                      _buildStatColumn(
                        icon: Icons.timer_outlined,
                        iconColor: Colors.blueAccent,
                        value: '$durationMinutes',
                        unit: 'Menit',
                      ),
                      
                      // Divider
                      Container(
                        height: 50,
                        width: 1,
                        color: Colors.white10,
                      ),

                      // Kalori Terbakar
                      _buildStatColumn(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: Colors.orangeAccent,
                        value: caloriesBurned.toStringAsFixed(1),
                        unit: 'Kcal',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Tombol Kembali ke Beranda
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccent,
                      foregroundColor: kBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Kembali ke Beranda',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String unit,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 32),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: const TextStyle(
            color: kTextMuted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
