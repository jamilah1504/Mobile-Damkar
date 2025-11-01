import 'laporan_lapangan.dart'; // Pastikan path benar: lib/models/laporan_lapangan.dart

class Laporan {
  final int id;
  final String jenisKejadian;
  final String deskripsi;
  final String? alamatKejadian;
  final double? latitude;
  final double? longitude;
  final String status;
  final DateTime timestampDibuat;
  final List<String> dokumentasi;
  final LaporanLapangan? laporanLapangan;

  Laporan({
    required this.id,
    required this.jenisKejadian,
    required this.deskripsi,
    this.alamatKejadian,
    this.latitude,
    this.longitude,
    required this.status,
    required this.timestampDibuat,
    this.dokumentasi = const [],
    this.laporanLapangan,
  });

  factory Laporan.fromJson(Map<String, dynamic> json) {
    return Laporan(
      id: json['id'] as int,
      jenisKejadian: json['jenisKejadian'] as String,
      deskripsi: json['deskripsi'] as String,
      alamatKejadian: json['alamatKejadian'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      status: json['status'] as String,
      timestampDibuat: DateTime.parse(json['timestampDibuat'] as String),
      dokumentasi:
          (json['dokumentasi'] as List<dynamic>?)
              ?.map((e) => e['fileUrl'] as String)
              .toList() ??
          [],
      laporanLapangan: json['insiden']?['tugas']?[0]?['laporanLapangan'] != null
          ? LaporanLapangan.fromJson(
              json['insiden']['tugas'][0]['laporanLapangan']
                  as Map<String, dynamic>,
            )
          : null,
    );
  }
}
