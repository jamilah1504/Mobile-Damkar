class Edukasi {
  final int id;
  final String judul;
  final String isiKonten;
  final String kategori;
  final String? fileUrl; // Bisa null
  final DateTime timestampDibuat;

  Edukasi({
    required this.id,
    required this.judul,
    required this.isiKonten,
    required this.kategori,
    this.fileUrl,
    required this.timestampDibuat,
  });

  // Factory constructor untuk membuat instance dari JSON
  factory Edukasi.fromJson(Map<String, dynamic> json) {
    return Edukasi(
      id: json['id'] as int,
      judul: json['judul'] as String,
      isiKonten: json['isiKonten'] as String,
      kategori: json['kategori'] as String,
      fileUrl: json['fileUrl'] as String?, // BISA NULL
      timestampDibuat: DateTime.parse(json['timestampDibuat'] as String),
    );
  }
}
