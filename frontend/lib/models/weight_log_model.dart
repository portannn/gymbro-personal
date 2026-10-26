class WeightLog {
  final int id;
  final double weight;
  final DateTime recordedDate;

  const WeightLog({
    required this.id,
    required this.weight,
    required this.recordedDate,
  });

  factory WeightLog.fromJson(Map<String, dynamic> json) {
    return WeightLog(
      id: json['id'] as int,
      weight: (json['weight'] as num).toDouble(),
      recordedDate: DateTime.parse(json['recorded_date']),
    );
  }
}

class WeightHistoryResult {
  final List<WeightLog> data;
  final int totalData;
  final int totalPages;
  final int currentPage;
  final bool hasMore;

  const WeightHistoryResult({
    required this.data,
    required this.totalData,
    required this.totalPages,
    required this.currentPage,
    required this.hasMore,
  });
}
