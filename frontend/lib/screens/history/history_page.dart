import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/history_model.dart';
import '../../services/history_service.dart';
import '../../utils/palette.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final HistoryService _historyService = HistoryService();
  final ScrollController _scrollController = ScrollController();

  List<WorkoutHistory> _histories = [];
  bool _isInitialLoading = true; // loading pertama kali (seluruh halaman)
  bool _isLoadingMore = false;   // loading tambahan (bottom indicator)
  bool _hasMore = true;
  bool _hasError = false;        // flag error saat load gagal
  int _total = 0;
  int _page = 1;

  // --- Stat Getters (dari semua data yang sudah di-load) ---
  int get _totalCalories =>
      _histories.fold(0, (sum, h) => sum + h.caloriesBurned);
  int get _totalMinutes =>
      _histories.fold(0, (sum, h) => sum + h.durationMinutes);

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Deteksi scroll mencapai 80% ke bawah → muat lebih banyak
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  // Reset & muat dari awal (pull-to-refresh atau init)
  Future<void> _loadInitial() async {
    if (!mounted) return;
    setState(() {
      _isInitialLoading = true;
      _hasError = false;
      _histories = [];
      _page = 1;
      _hasMore = true;
    });
    try {
      final result = await _historyService.getHistory(page: 1);
      if (!mounted) return;
      setState(() {
        _histories = result.data;
        _total = result.total;
        _hasMore = result.hasMore;
        if (result.data.isNotEmpty) _page++;
        _isInitialLoading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitialLoading = false;
        _hasError = true;
      });
    }
  }

  // Muat halaman berikutnya (infinite scroll)
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    if (!mounted) return;
    setState(() => _isLoadingMore = true);

    try {
      final result = await _historyService.getHistory(page: _page);
      if (!mounted) return;
      setState(() {
        _histories.addAll(result.data);
        _total = result.total;
        _hasMore = result.hasMore;
        if (result.data.isNotEmpty) _page++;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  // Groups the LOADED histories by date label
  Map<String, List<WorkoutHistory>> get _grouped {
    final Map<String, List<WorkoutHistory>> map = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final h in _histories) {
      final d = h.date.toLocal();
      final day = DateTime(d.year, d.month, d.day);
      String label;
      if (day == today) {
        label = 'Hari Ini';
      } else if (day == yesterday) {
        label = 'Kemarin';
      } else {
        // Menggunakan format yang lebih user-friendly dengan locale Indonesia
        // Contoh: "12 Mei 2026"
        label = DateFormat('d MMMM yyyy', 'id_ID').format(d);
      }
      map.putIfAbsent(label, () => []).add(h);
    }
    return map;
  }

  void _showAddHistoryDialog() {
    final formKey = GlobalKey<FormState>();
    String workoutName = '';
    String durationStr = '';
    String caloriesStr = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white10),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Text('Catat Latihan Baru',
                    style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _buildInputField(
                  label: 'Nama Latihan',
                  icon: Icons.fitness_center,
                  onSaved: (v) => workoutName = v!,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Nama latihan wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        label: 'Durasi (menit)',
                        icon: Icons.timer_outlined,
                        keyboardType: TextInputType.number,
                        onSaved: (v) => durationStr = v!,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        label: 'Kalori (kkal)',
                        icon: Icons.local_fire_department_outlined,
                        keyboardType: TextInputType.number,
                        onSaved: (v) => caloriesStr = v!,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccent,
                      foregroundColor: kBg,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        Navigator.pop(ctx);
                        final ok = await _historyService.addHistory(
                          workoutName: workoutName,
                          durationMinutes: int.tryParse(durationStr) ?? 0,
                          caloriesBurned: int.tryParse(caloriesStr) ?? 0,
                        );
                        if (ok) {
                          _loadInitial(); // refresh dari awal
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Gagal menyimpan riwayat')),
                          );
                        }
                      }
                    },
                    child: const Text('Simpan Latihan',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      style: const TextStyle(color: kTextPrimary),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kTextMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: kAccent, size: 20),
        filled: true,
        fillColor: kBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kAccent),
        ),
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: kAccent,
          backgroundColor: kCard,
          onRefresh: _loadInitial,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Riwayat',
                              style: TextStyle(
                                  color: kTextMuted, fontSize: 14)),
                          const Text('Latihan',
                              style: TextStyle(
                                  color: kTextPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold)),
                          if (!_isInitialLoading)
                            Text('$_total sesi tersimpan',
                                style: const TextStyle(
                                    color: kTextMuted, fontSize: 12)),
                        ],
                      ),
                      GestureDetector(
                        onTap: _showAddHistoryDialog,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kAccent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.add, color: kBg, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Summary Stats ──────────────────────────────────────
              if (!_isInitialLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Row(
                      children: [
                        _StatCard(
                          icon: Icons.bar_chart_rounded,
                          value: '$_total',
                          label: 'Sesi',
                          color: kAccent,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          icon: Icons.timer_outlined,
                          value: '$_totalMinutes',
                          label: 'Menit',
                          color: const Color(0xFF6BE5FF),
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          icon: Icons.local_fire_department,
                          value: '$_totalCalories',
                          label: 'kkal',
                          color: const Color(0xFFFF7043),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Initial Loading ────────────────────────────────────
              if (_isInitialLoading)
                const SliverFillRemaining(
                  child: Center(
                      child: CircularProgressIndicator(color: kAccent)),
                )

              // ── Error State ────────────────────────────────────────
              else if (_hasError)
                SliverFillRemaining(
                  child: Center(
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
                              border: Border.all(color: Colors.red.withAlpha(128)),
                            ),
                            child: const Icon(Icons.wifi_off_rounded,
                                color: Colors.redAccent, size: 44),
                          ),
                          const SizedBox(height: 20),
                          const Text('Gagal memuat data',
                              style: TextStyle(
                                  color: kTextPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text(
                            'Periksa koneksi internet\natau coba lagi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: kTextMuted, height: 1.5),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadInitial,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Coba Lagi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kAccent,
                              foregroundColor: kBg,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )

              // ── Empty State ────────────────────────────────────────
              else if (_histories.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: kCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white10),
                          ),
                          child: const Icon(Icons.fitness_center,
                              color: kTextMuted, size: 48),
                        ),
                        const SizedBox(height: 20),
                        const Text('Belum Ada Riwayat',
                            style: TextStyle(
                                color: kTextPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                            'Tekan tombol + untuk mencatat\nlatihan pertamamu!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: kTextMuted, height: 1.5)),
                        const SizedBox(height: 28),
                        GestureDetector(
                          onTap: _showAddHistoryDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            decoration: BoxDecoration(
                              color: kAccent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Catat Sekarang',
                                style: TextStyle(
                                    color: kBg,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )

              // ── History list (grouped by date) ─────────────────────
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entries = _grouped.entries.toList();
                        final entry = entries[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date group header
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 12, top: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: kAccent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(entry.key,
                                      style: const TextStyle(
                                          color: kTextPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  const SizedBox(width: 8),
                                  Text('(${entry.value.length} sesi)',
                                      style: const TextStyle(
                                          color: kTextMuted,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            ...entry.value
                                .map((h) => _WorkoutCard(history: h)),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                      childCount: _grouped.length,
                    ),
                  ),
                ),

              // ── Load More indicator ────────────────────────────────
              SliverToBoxAdapter(
                child: _isLoadingMore
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                            child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: kAccent, strokeWidth: 2),
                        )),
                      )
                    : (!_hasMore && _histories.isNotEmpty)
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: kCard,
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: Colors.white12),
                                ),
                                child: Text(
                                  'Semua $_total riwayat sudah ditampilkan',
                                  style: const TextStyle(
                                      color: kTextMuted, fontSize: 12),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(height: 80),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Summary stat box ──────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 22)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(color: kTextMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ─── Individual workout card ───────────────────────────────────────────────────
class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.history});
  final WorkoutHistory history;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: kAccent.withAlpha(38),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.fitness_center, color: kAccent, size: 24),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(history.workoutName,
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Pill(
                      icon: Icons.timer_outlined,
                      label: '${history.durationMinutes} menit',
                      color: const Color(0xFF6BE5FF),
                    ),
                    const SizedBox(width: 8),
                    _Pill(
                      icon: Icons.local_fire_department,
                      label: '${history.caloriesBurned} kkal',
                      color: const Color(0xFFFF7043),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Time
          Text(
            DateFormat('HH:mm').format(history.date.toLocal()),
            style: const TextStyle(
                color: kTextMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Small info pill ───────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  const _Pill(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
