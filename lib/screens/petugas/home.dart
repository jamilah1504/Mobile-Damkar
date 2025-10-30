import 'package:flutter/material.dart';
import 'dart:async'; // Untuk Timer

class PetugasHomeScreen extends StatefulWidget {
  const PetugasHomeScreen({super.key});

  @override
  State<PetugasHomeScreen> createState() => _PetugasHomeScreenState();
}

class _PetugasHomeScreenState extends State<PetugasHomeScreen> {
  int _selectedFilterIndex = 0; // 0: Aktif, 1: Riwayat, 2: Selesai
  Timer? _responTimer;
  int _sisaWaktuDetik = 85; // Contoh sisa waktu 1 menit 25 detik

  @override
  void initState() {
    super.initState();
    _startResponTimer(); // Mulai timer saat halaman dimuat (jika ada tugas aktif)
  }

  @override
  void dispose() {
    _responTimer?.cancel(); // Hentikan timer saat halaman ditutup
    super.dispose();
  }

  void _startResponTimer() {
    _responTimer?.cancel(); // Hentikan timer sebelumnya jika ada
    _responTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sisaWaktuDetik > 0) {
        setState(() {
          _sisaWaktuDetik--;
        });
      } else {
        timer.cancel();
        // Tambahkan logika jika waktu habis
      }
    });
  }

  String _formatSisaWaktu(int totalDetik) {
    int menit = totalDetik ~/ 60;
    int detik = totalDetik % 60;
    return '${menit.toString().padLeft(2, '0')}:${detik.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.red.shade800;
    final Color secondaryColor = Colors.red.shade600;
    final Color accentColor = Colors.blue.shade800; // Warna tombol "Terima"
    final Color backgroundColor = Colors.grey.shade100;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'Images/logo2.png',
            width: 40, // Adjust size as needed
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.shield, color: Colors.white, size: 24),
          ),
        ),
        title: const Text(
          'Selamat Datang, Petugas!',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              // Aksi saat ikon notifikasi ditekan
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Banner Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.asset(
                  'Images/image.png', // Ganti URL gambar banner
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey.shade300,
                    child: const Center(child: Text('Gagal Memuat Banner')),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Judul Dashboard & Filter
              const Text(
                'Dashboard',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildFilterButtons(secondaryColor),
              const SizedBox(height: 20),

              // 3. Kartu Panggilan Darurat (Contoh)
              // Tampilkan kartu ini jika _selectedFilterIndex == 0 (Aktif)
              if (_selectedFilterIndex == 0)
                _buildPanggilanDaruratCard(
                  primaryColor,
                  secondaryColor,
                  accentColor,
                ),

              // Tampilkan daftar riwayat jika _selectedFilterIndex == 1
              if (_selectedFilterIndex == 1)
                _buildRiwayatList(), // Buat widget ini
              // Tampilkan daftar selesai jika _selectedFilterIndex == 2
              if (_selectedFilterIndex == 2)
                _buildSelesaiList(), // Buat widget ini

              const SizedBox(height: 20),

              // 4. Kartu Sisa Waktu Respon (Contoh)
              // Tampilkan jika ada tugas aktif
              if (_selectedFilterIndex == 0) _buildSisaWaktuCard(accentColor),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'Info',
          ),
        ],
        currentIndex: 0,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          // Aksi navigasi bawah
        },
      ),
    );
  }

  // Widget untuk tombol filter
  Widget _buildFilterButtons(Color activeColor) {
    final List<String> filters = ['Aktif', 'Riwayat', 'Selesai'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(filters.length, (index) {
        bool isActive = _selectedFilterIndex == index;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedFilterIndex = index;
                  // Tambahkan logika untuk memuat data sesuai filter
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? activeColor : Colors.white,
                foregroundColor: isActive ? Colors.white : Colors.black54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(filters[index]),
            ),
          ),
        );
      }),
    );
  }

  // Widget untuk kartu panggilan darurat
  Widget _buildPanggilanDaruratCard(
    Color primaryColor,
    Color secondaryColor,
    Color accentColor,
  ) {
    return Card(
      color: primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'PANGGILAN DARURAT!!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    // Aksi tombol detail
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Detail'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'KEBAKARAN - Gedung Pertokoan PT. ABCD',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '#Cibogo',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
            Text(
              'Jl. Airlangga N0 17, Kawasan ES Krim',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '22 Sep 2025, 09.15',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Aksi tombol Terima & Mulai Jalan
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor, // Warna biru
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'TERIMA & MULAI JALAN',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Placeholder untuk Riwayat
  Widget _buildRiwayatList() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Text(
          "Tampilan Riwayat Tugas Akan Muncul Di Sini",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  // Widget Placeholder untuk Selesai
  Widget _buildSelesaiList() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Text(
          "Tampilan Tugas Selesai Akan Muncul Di Sini",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  // Widget untuk kartu sisa waktu respon
  Widget _buildSisaWaktuCard(Color accentColor) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Row(
          children: [
            Icon(Icons.timer_outlined, color: accentColor, size: 30),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sisa Waktu Respon',
                  style: TextStyle(color: Colors.black54),
                ),
                Text(
                  _formatSisaWaktu(_sisaWaktuDetik),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
