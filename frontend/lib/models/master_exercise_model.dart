class MasterExercise {
  final int id;
  final String namaLatihan;
  final String tipe;
  final String targetOtot;
  final String? deskripsiTeknis;
  final String? mediaUrl;

  MasterExercise({
    required this.id,
    required this.namaLatihan,
    required this.tipe,
    required this.targetOtot,
    this.deskripsiTeknis,
    this.mediaUrl,
  });

  factory MasterExercise.fromJson(Map<String, dynamic> json) {
    return MasterExercise(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      namaLatihan: json['nama_latihan'] ?? '',
      tipe: json['tipe'] ?? 'Gym',
      targetOtot: json['target_otot'] ?? '',
      deskripsiTeknis: json['deskripsi_teknis'],
      mediaUrl: json['media_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_latihan': namaLatihan,
      'tipe': tipe,
      'target_otot': targetOtot,
      'deskripsi_teknis': deskripsiTeknis,
      'media_url': mediaUrl,
    };
  }
}
