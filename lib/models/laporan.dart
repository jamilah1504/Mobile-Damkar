class Laporan {
  final int id;
  final String jenisKejadian;
  final String deskripsi;
  final String? alamatKejadian;
  final double? latitude;
  final double? longitude;
  final String status;
  final String timestampDibuat;
  final int pelaporId;
  final List<Dokumentasi> dokumentasi;
  
  // --- FIELD TAMBAHAN UNTUK DETAIL ---
  final Map<String, dynamic>? pelapor; // Menyimpan data: name, email
  final Map<String, dynamic>? insiden; // Menyimpan data: tugas -> laporanLapangan
  final Map<String, dynamic>? insidenTerkait; // Menyimpan status insiden

  Laporan({
    required this.id,
    required this.jenisKejadian,
    required this.deskripsi,
    this.alamatKejadian,
    this.latitude,
    this.longitude,
    required this.status,
    required this.timestampDibuat,
    required this.pelaporId,
    required this.dokumentasi,
    this.pelapor,
    this.insiden,
    this.insidenTerkait,
  });

  factory Laporan.fromJson(Map<String, dynamic> json) {
    return Laporan(
      id: json['id'] ?? 0,
      jenisKejadian: json['jenisKejadian'] ?? 'Tidak Diketahui',
      deskripsi: json['deskripsi'] ?? '-',
      alamatKejadian: json['alamatKejadian'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      status: json['status'] ?? 'Menunggu',
      timestampDibuat: json['timestampDibuat'] ?? DateTime.now().toIso8601String(),
      pelaporId: json['pelaporId'] ?? 0,
      dokumentasi: (json['Dokumentasis'] as List?)
              ?.map((i) => Dokumentasi.fromJson(i))
              .toList() ?? [],
      
      // Mapping Data Tambahan
      pelapor: json['Pelapor'],
      insiden: json['insiden'],
      insidenTerkait: json['InsidenTerkait'],
    );
  }
}

class Dokumentasi {
  final String fileUrl;
  final String tipeFile;

  Dokumentasi({required this.fileUrl, required this.tipeFile});

  factory Dokumentasi.fromJson(Map<String, dynamic> json) {
    return Dokumentasi(
      fileUrl: json['fileUrl'] ?? '',
      tipeFile: json['tipeFile'] ?? 'Gambar',
    );
  }
}