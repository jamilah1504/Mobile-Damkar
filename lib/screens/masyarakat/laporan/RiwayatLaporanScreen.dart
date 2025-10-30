import 'package:flutter/material.dart';
// --- TAMBAHKAN IMPOR INI ---
import 'DetailLaporanScreen.dart'; // Impor halaman detail yang baru dibuat

// Model data sederhana untuk riwayat laporan
class RiwayatLaporan {
  final int id;
  final String jenis;
  final String lokasiSingkat;
  final String tanggal;
  final String status;
  // Tambahkan detail lain jika perlu
  // final String detailLokasi;
  // final String deskripsi;

  RiwayatLaporan({
    required this.id,
    required this.jenis,
    required this.lokasiSingkat,
    required this.tanggal,
    required this.status,
    // this.detailLokasi = '',
    // this.deskripsi = '',
  });
}

// Data dummy untuk riwayat (gantilah dengan data dari API nanti)
final List<RiwayatLaporan> dummyRiwayat = [
  RiwayatLaporan(
    id: 1021,
    jenis: 'Kebakaran Rumah',
    lokasiSingkat: 'Jl. Pahlawan',
    tanggal: '19 Sep 2025',
    status: 'Selesai',
  ),
  RiwayatLaporan(
    id: 1015,
    jenis: 'Penyelamatan Kucing',
    lokasiSingkat: 'Perum Gria Asri',
    tanggal: '15 Sep 2025',
    status: 'Selesai',
  ),
  RiwayatLaporan(
    id: 1010,
    jenis: 'Kebakaran Lahan',
    lokasiSingkat: 'Area Sawah Belakang',
    tanggal: '10 Sep 2025',
    status: 'Selesai',
  ),
  RiwayatLaporan(
    id: 1005,
    jenis: 'Pohon Tumbang',
    lokasiSingkat: 'Depan Kantor Pos',
    tanggal: '05 Sep 2025',
    status: 'Selesai',
  ),
];

class RiwayatLaporanScreen extends StatelessWidget {
  const RiwayatLaporanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.red.shade800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Laporan Saya'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.grey.shade100,
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        itemCount: dummyRiwayat.length,
        itemBuilder: (context, index) {
          final laporan = dummyRiwayat[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 16.0,
              ),
              leading: Icon(
                laporan.jenis.toLowerCase().contains('kebakaran')
                    ? Icons.local_fire_department_outlined
                    : Icons.help_outline_rounded,
                color: primaryColor,
                size: 40,
              ),
              title: Text(
                laporan.jenis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                '${laporan.lokasiSingkat}\n${laporan.tanggal}',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: laporan.status == 'Selesai'
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  laporan.status,
                  style: TextStyle(
                    color: laporan.status == 'Selesai'
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              // --- PERBAIKAN onTap UNTUK NAVIGASI KE DETAIL ---
              onTap: () {
                // Aksi saat item riwayat ditekan: Buka Halaman Detail
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Kirim data 'laporan' ke halaman detail
                    builder: (context) => DetailLaporanScreen(laporan: laporan),
                  ),
                );
              },
              // --- AKHIR PERBAIKAN onTap ---
            ),
          );
        },
      ),
    );
  }
}
