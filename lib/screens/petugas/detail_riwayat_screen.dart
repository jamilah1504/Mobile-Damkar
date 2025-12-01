import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:flutter_map/flutter_map.dart'; // [BARU] Import Flutter Map
import 'package:latlong2/latlong.dart'; // [BARU] Import LatLong
import '../../models/petugas/riwayat_model.dart';

class DetailRiwayatScreen extends StatelessWidget {
  final RiwayatTugas data;

  const DetailRiwayatScreen({Key? key, required this.data}) : super(key: key);

  // Fungsi untuk Navigasi (Buka Google Maps App)
  Future<void> _openMap(BuildContext context) async {
    final Uri googleUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${data.latitude},${data.longitude}');

    try {
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal membuka aplikasi peta: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('HH:mm WIB, dd MMMM yyyy').format(data.waktuKejadian);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        title: const Text("Detail Riwayat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Merah Lengkung
            Container(
              width: double.infinity,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFD32F2F),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    "Laporan #${data.tugasId}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  // CARD 1: Info Utama & Peta (UPDATED)
                  _buildMainCard(context, formattedDate),
                  const SizedBox(height: 16),

                  // CARD 2: Deskripsi
                  _buildDescriptionCard(),
                  const SizedBox(height: 16),

                  // CARD 3: Pelapor
                  _buildReporterCard(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, String dateString) {
    // Konversi koordinat dari Model ke LatLng
    final LatLng location = LatLng(data.latitude, data.longitude);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Jenis Kejadian", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(data.jenisKejadian, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          
          const SizedBox(height: 16),
          const Text("Lokasi Kejadian", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${data.latitude}, ${data.longitude}", 
                  style: const TextStyle(fontSize: 14, height: 1.3),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(dateString, style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ],
          ),

          const SizedBox(height: 16),
          
          // --- BAGIAN PETA FLUTTER MAP (DIGANTI DARI GAMBAR) ---
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200, // Tinggi Peta
              width: double.infinity,
              child: Stack(
                children: [
                  // 1. Layer Peta
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: location, // Pusat peta sesuai data laporan
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: location,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // 2. Tombol Navigasi (Floating di atas peta)
                  Positioned(
                    bottom: 10,
                    right: 10, // Saya pindahkan ke kanan agar lebih ergonomis
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue[700],
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                      ),
                      onPressed: () => _openMap(context), 
                      icon: const Icon(Icons.directions, size: 20),
                      label: const Text("Buka Rute", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Deskripsi Kejadian", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            data.deskripsi,
            style: const TextStyle(color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildReporterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Detail Pelapor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.email, size: 18, color: Colors.grey),
              const SizedBox(width: 12),
              Text(data.kontakPelapor, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: Text(
              "Pelapor : ${data.namaPelapor}",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}