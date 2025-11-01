class LaporanLapangan {
  final int jumlahKorban;
  final int? estimasiKerugian;
  final String? dugaanPenyebab;
  final String? catatan;

  LaporanLapangan({
    required this.jumlahKorban,
    this.estimasiKerugian,
    this.dugaanPenyebab,
    this.catatan,
  });

  factory LaporanLapangan.fromJson(Map<String, dynamic> json) {
    return LaporanLapangan(
      jumlahKorban: json['jumlahKorban'] as int,
      estimasiKerugian: json['estimasiKerugian'] as int?,
      dugaanPenyebab: json['dugaanPenyebab'] as String?,
      catatan: json['catatan'] as String?,
    );
  }
}
