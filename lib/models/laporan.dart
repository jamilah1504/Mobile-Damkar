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
  
  // --- FIELD TAMBAHAN ---
  final Map<String, dynamic>? pelapor; 
  final Map<String, dynamic>? insiden; // Data Laporan Lapangan ada di sini
  final Map<String, dynamic>? insidenTerkait; // Data Status Insiden ada di sini

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
    // LOGIKA PENYELAMAT:
    // Kita ambil data insiden dari berbagai kemungkinan kunci (key)
    // Backend kadang kirim 'insiden', 'Insiden', atau 'InsidenTerkait'
    final rawInsiden = json['insiden'] ?? json['InsidenTerkait'] ?? json['Insiden'];

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
      
      // Mapping Dokumentasi (Foto/Video)
      dokumentasi: (json['Dokumentasis'] as List?)
              ?.map((i) => Dokumentasi.fromJson(i))
              .toList() ?? [],
      
      // Mapping Data Tambahan (LEBIH AMAN)
      pelapor: json['Pelapor'] ?? json['pelapor'], // Cek huruf besar/kecil
      
      // 🔥 PERBAIKAN UTAMA DI SINI 🔥
      // Kita isi 'insiden' dengan data apapun yang kita temukan tadi
      insiden: rawInsiden, 
      
      // Kita isi 'insidenTerkait' juga dengan data yang sama (biar UI tidak error)
      insidenTerkait: rawInsiden, 
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