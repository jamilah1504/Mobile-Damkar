import 'package:flutter/material.dart';
// Impor model RiwayatLaporan agar bisa digunakan di sini
import 'RiwayatLaporanScreen.dart';

class DetailLaporanScreen extends StatelessWidget {
  final RiwayatLaporan laporan; // Menerima data laporan yang dipilih

  const DetailLaporanScreen({Key? key, required this.laporan})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.red.shade800;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Laporan #${laporan.id}'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        // Agar bisa scroll jika konten panjang
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem(context, 'ID Laporan', '#${laporan.id}'),
            _buildDetailItem(context, 'Jenis Insiden', laporan.jenis),
            _buildDetailItem(
              context,
              'Lokasi',
              laporan.lokasiSingkat,
            ), // Ganti dengan detail lokasi jika ada
            _buildDetailItem(context, 'Tanggal Laporan', laporan.tanggal),
            _buildStatusItem(context, 'Status', laporan.status),

            // Tambahkan bagian untuk deskripsi jika ada di model
            // const SizedBox(height: 16),
            // Text('Deskripsi:', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            // Text(laporan.deskripsi ?? 'Tidak ada deskripsi.', style: Theme.of(context).textTheme.bodyLarge),

            // Tambahkan bagian untuk menampilkan foto/dokumentasi jika ada
            const SizedBox(height: 24),
            Text(
              'Dokumentasi:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // Ganti dengan widget Image.network atau sejenisnya jika ada URL gambar
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Tidak ada dokumentasi',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk menampilkan item detail
  Widget _buildDetailItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }

  // Helper widget khusus untuk menampilkan status dengan warna
  Widget _buildStatusItem(BuildContext context, String label, String value) {
    Color statusColor;
    Color backgroundColor;

    switch (value.toLowerCase()) {
      case 'selesai':
        statusColor = Colors.green.shade800;
        backgroundColor = Colors.green.shade100;
        break;
      case 'ditangani':
        statusColor = Colors.orange.shade800;
        backgroundColor = Colors.orange.shade100;
        break;
      default: // Menunggu Verifikasi, Ditolak, dll.
        statusColor = Colors.grey.shade700;
        backgroundColor = Colors.grey.shade300;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 14, // Ukuran font status
              ),
            ),
          ),
        ],
      ),
    );
  }
}
