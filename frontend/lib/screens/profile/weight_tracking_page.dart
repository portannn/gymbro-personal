import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/weight_log_model.dart';
import '../../services/weight_service.dart';
import '../../utils/palette.dart';

class WeightTrackingPage extends StatefulWidget {
  const WeightTrackingPage({super.key});

  @override
  State<WeightTrackingPage> createState() => _WeightTrackingPageState();
}

class _WeightTrackingPageState extends State<WeightTrackingPage> {
  final WeightService _weightService = WeightService();
  final ScrollController _scrollController = ScrollController();

  final List<WeightLog> _logs = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _fetchMoreLogs();
    }
  }

  Future<void> _fetchLogs({bool reset = false}) async {
    if (reset) {
      setState(() {
        _logs.clear();
        _currentPage = 1;
        _hasMore = true;
        _hasError = false;
      });
    }

    setState(() => _isLoading = true);

    final result = await _weightService.getWeightHistory(page: _currentPage);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.data.isEmpty && _logs.isEmpty) {
        _hasMore = false;
      } else {
        _logs.addAll(result.data);
        _hasMore = result.hasMore;
        _currentPage++;
      }
    });
  }

  Future<void> _fetchMoreLogs() async {
    setState(() => _isLoadingMore = true);
    final result = await _weightService.getWeightHistory(page: _currentPage);
    if (!mounted) return;
    setState(() {
      _isLoadingMore = false;
      _logs.addAll(result.data);
      _hasMore = result.hasMore;
      _currentPage++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Riwayat Berat Badan',
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pantau perubahan berat badan Anda',
                    style: TextStyle(color: kTextMuted, fontSize: 14),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    // Loading state awal
    if (_isLoading && _logs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: kAccent),
      );
    }

    // Error state
    if (_hasError && _logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: kTextMuted, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat data',
              style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Silakan coba lagi',
              style: TextStyle(color: kTextMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _fetchLogs(reset: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent,
                foregroundColor: kBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (_logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monitor_weight_outlined, color: kTextMuted.withAlpha(128), size: 80),
            const SizedBox(height: 20),
            const Text(
              'Belum ada data berat badan',
              style: TextStyle(
                  color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Catat berat badanmu di halaman Profile',
              style: TextStyle(color: kTextMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Data list dengan infinite scroll
    return RefreshIndicator(
      color: kAccent,
      backgroundColor: kCard,
      onRefresh: () => _fetchLogs(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        itemCount: _logs.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _logs.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: kAccent)),
            );
          }
          return _WeightLogCard(log: _logs[index], isFirst: index == 0);
        },
      ),
    );
  }
}

class _WeightLogCard extends StatelessWidget {
  const _WeightLogCard({required this.log, required this.isFirst});

  final WeightLog log;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('d MMMM yyyy', 'id_ID').format(log.recordedDate);
    final formattedWeight = log.weight.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: isFirst
            ? Border.all(color: kAccent.withAlpha(128), width: 1.5)
            : Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Icon kiri
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isFirst ? kAccent.withAlpha(38) : kBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.monitor_weight_outlined,
              color: isFirst ? kAccent : kTextMuted,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Teks tanggal & label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isFirst)
                  const SizedBox(height: 2),
                if (isFirst)
                  const Text(
                    'Terbaru',
                    style: TextStyle(color: kAccent, fontSize: 12),
                  ),
              ],
            ),
          ),

          // Berat badan kanan
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formattedWeight,
                style: TextStyle(
                  color: isFirst ? kAccent : kTextPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              const Text(
                ' kg',
                style: TextStyle(color: kTextMuted, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
