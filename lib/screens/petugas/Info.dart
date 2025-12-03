import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Ganti dengan import halaman login Anda
import '../auth/Login.dart'; 

class HalamanInfo extends StatelessWidget {
  const HalamanInfo({super.key});

  // Fungsi Logout
  Future<void> _handleLogout(BuildContext context) async {
    // Tampilkan Dialog Konfirmasi
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 1. Hapus Data Sesi (Token, dll)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 2. Arahkan ke Halaman Login & Hapus semua rute sebelumnya
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()), // Pastikan LoginScreen diimport
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan warna tema yang sama dengan Home
    final Color primaryColor = Colors.red.shade800;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Info & Pengaturan",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- BAGIAN 1: HEADER APLIKASI ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                children: [
                  // Logo Aplikasi
                  Container(
                    width: 100,
                    height: 100,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    // Ganti dengan Logo Anda
                    child: Image.asset('Images/logo2.png', fit: BoxFit.contain), 
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Emergency Response App",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Versi 1.0.0 (Beta)",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- BAGIAN 2: TENTANG APLIKASI ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: primaryColor),
                          const SizedBox(width: 10),
                          const Text("Tentang Aplikasi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 20),
                      const Text(
                        "Aplikasi ini digunakan oleh petugas lapangan untuk menerima, memverifikasi, dan melaporkan penanganan insiden darurat secara real-time. Pastikan GPS selalu aktif saat bertugas.",
                        textAlign: TextAlign.justify,
                        style: TextStyle(height: 1.5, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- BAGIAN 3: SOP PETUGAS (ACCORDION) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.menu_book, color: primaryColor),
                          const SizedBox(width: 10),
                          const Text("SOP Petugas Lapangan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Divider(height: 0),
                    
                    // List SOP
                    _buildSopItem(
                      "1. Menerima Panggilan", 
                      "Segera tekan tombol 'Terima' saat notifikasi masuk. Cek lokasi dan jenis kejadian sebelum berangkat."
                    ),
                    _buildSopItem(
                      "2. Persiapan & Keberangkatan", 
                      "Pastikan alat pelindung diri (APD) lengkap. Nyalakan sirine jika kondisi darurat (Red Code)."
                    ),
                    _buildSopItem(
                      "3. Tiba di Lokasi", 
                      "Lakukan update status 'Tiba di Lokasi' pada aplikasi. Amankan area sekitar dan lakukan assessment awal."
                    ),
                    _buildSopItem(
                      "4. Pelaporan Pasca Insiden", 
                      "Wajib mengunggah foto bukti penanganan dan deskripsi singkat hasil operasi sebelum menutup tiket tugas."
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- BAGIAN 4: TOMBOL LOGOUT ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _handleLogout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text("KELUAR APLIKASI", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Footer Copyright
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "© 2025 Emergency Response App. All rights reserved.",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Helper untuk Item SOP (Accordion)
  Widget _buildSopItem(String title, String content) {
    return ExpansionTile(
      title: Text(
        title, 
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      children: [
        Text(
          content,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }
}