class RiwayatTugas {
  final int tugasId;
  final String jenisKejadian;
  final String status;
  final double latitude;
  final double longitude;
  final String deskripsi;
  final String namaPelapor;
  final String kontakPelapor;
  final DateTime waktuKejadian;
  final DateTime? waktuSelesai;

  RiwayatTugas({
    required this.tugasId,
    required this.jenisKejadian,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.deskripsi,
    required this.namaPelapor,
    required this.kontakPelapor,
    required this.waktuKejadian,
    this.waktuSelesai,
  });

  factory RiwayatTugas.fromJson(Map<String, dynamic> json) {
    return RiwayatTugas(
      tugasId: json['tugas_id'] ?? 0,
      jenisKejadian: json['jenisKejadian'] ?? 'Tidak Diketahui',
      status: json['statusInsiden'] ?? '-',
      latitude: (json['latitude'] != null) ? json['latitude'].toDouble() : 0.0,
      longitude: (json['longitude'] != null) ? json['longitude'].toDouble() : 0.0,
      deskripsi: json['deskripsi'] ?? '-',
      namaPelapor: json['nama_pelapor'] ?? 'Anonim',
      kontakPelapor: json['kontak_pelapor'] ?? '-',
      waktuKejadian: json['waktu_laporan'] != null 
          ? DateTime.parse(json['waktu_laporan']) 
          : DateTime.now(),
      waktuSelesai: json['waktuSelesai'] != null 
          ? DateTime.parse(json['waktuSelesai']) 
          : null,
    );
  }
}