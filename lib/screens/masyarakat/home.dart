import 'package:flutter/material.dart';
import './laporan/RiwayatLaporanScreen.dart'; // Impor halaman riwayat

// --- 1. TAMBAHKAN IMPORT ---
import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert'; // Diperlukan untuk jsonDecode dan base64Url

// --- 2. UBAH MENJADI STATEFULWIDGET ---
class MasyarakatHomeScreen extends StatefulWidget {
  const MasyarakatHomeScreen({super.key});

  @override
  State<MasyarakatHomeScreen> createState() => _MasyarakatHomeScreenState();
}

class _MasyarakatHomeScreenState extends State<MasyarakatHomeScreen> {
  // --- 3. TAMBAHKAN STATE UNTUK NAMA PENGGUNA ---
  String _userName = "Memuat..."; // Nilai default saat sedang loadin
  int _userId = 0; // Simpan userId jika diperlukan

  // Definisikan warna tema di sini agar bisa diakses di seluruh class
  final Color primaryColor = Colors.red.shade800;
  final Color secondaryColor = Colors.red.shade600;
  final Color backgroundColor = Colors.grey.shade100;
  final Color cardColor = Colors.white;
  final Color textColor = Colors.black87;
  final Color subtleTextColor = Colors.black54;

  // --- 4. TAMBAHKAN initState UNTUK MEMUAT DATA ---
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // --- 5. FUNGSI UNTUK MEMUAT DATA DARI TOKEN ---
  Future<void> _loadUserData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Langsung ambil 'userName' dan 'userId'
      final String? userName = prefs.getString('userName'); 
      final int? userId = prefs.getInt('userId'); 

      // --- PERBAIKAN UTAMA ADA DI SINI ---
      // Pastikan KEDUA data ada sebelum melanjutkan
      if (userName == null || userName.isEmpty || userId == null) {
        // Jika salah satu data tidak ada, lempar error
        // agar ditangkap oleh blok 'catch'
        throw Exception("Data pengguna (nama atau ID) tidak lengkap di SharedPreferences");
      }
      // --- AKHIR PERBAIKAN ---

      // Update UI (HANYA jika kedua data valid)
      if (mounted) {
        setState(() {
          _userName = userName; 
          _userId = userId; 
        });
      }
    } catch (e) {
      print("Gagal memuat data pengguna: $e");
      // Blok 'catch' ini sekarang akan menangani 
      // jika 'userName' HILANG atau 'userId' HILANG
      if (mounted) {
        setState(() {
          _userName = "Tamu"; // Fallback
          _userId = 0 ; // Fallback
        });
      }
    }
  }


  // --- 7. PINDAHKAN LOGIKA BUILD KE DALAM STATE ---
  @override
  Widget build(BuildContext context) {
    // Variabel warna sudah dipindah ke atas (di dalam State)

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'Images/logo2.png',
            width: 40,
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.shield, color: Colors.white, size: 24),
          ),
        ),
        title: const Text(
          'Pemadam Kebakaran\nKabupaten Subang',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Banner Image (tidak berubah)
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.asset(
                  'Images/image.png',
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

              // --- 8. TAMBAHKAN WIDGET SAMBUTAN ---
              Text(
                "Selamat Datang,",
                style: TextStyle(
                  fontSize: 18,
                  color: subtleTextColor, // Pakai warna subtle
                ),
              ),
              Text(
                "Halo, $_userName - $_userId", // Menampilkan "Halo, Budi Santoso"
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 24), // Beri jarak tambahan
              // --- AKHIR PENAMBAHAN ---

              // 2. Tombol Lapor Utama
              _buildLaporSection(
                // 'context' tidak perlu dikirim,
                // karena method ini ada di class State
                primaryColor,
                secondaryColor,
              ),
              const SizedBox(height: 24),

              // 3. Section Layanan
              _buildLayananSection(
                secondaryColor,
                textColor,
              ),
              const SizedBox(height: 24),

              // 4. Section Materi Edukasi
              _buildEdukasiSection(
                cardColor,
                textColor,
                subtleTextColor,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifikasi',
          ),
        ],
        currentIndex: 0,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RiwayatLaporanScreen(),
              ),
            );
          }
        },
      ),
    );
  }

  // --- 9. PINDAHKAN HELPER METHOD KE DALAM STATE ---
  // (dan hapus parameter 'BuildContext context' yang tidak perlu)

  // Widget _buildLaporSection
  Widget _buildLaporSection(
    Color primaryColor,
    Color secondaryColor,
  ) {
    return Column(
      children: [
        // Container Lingkaran (jika ada, tidak ada di kode Anda)
        // Container(/* ... */),
        // const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                // Gunakan 'context' milik State
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigasi ke Lapor Teks')),
                );
              },
              icon: const Icon(Icons.text_fields),
              label: const Text('Lapor Via Teks'),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Gunakan 'context' milik State
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Membuka Panggilan Telepon')),
                );
              },
              icon: const Icon(Icons.phone),
              label: const Text('Telepon'),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget _buildLayananSection
  Widget _buildLayananSection(
    Color buttonColor,
    Color textColor,
  ) {
    // Daftar layanan dengan aksi navigasi
    final List<Map<String, dynamic>> services = [
      {
        'icon': Icons.local_fire_department,
        'label': 'Lapor\nKebakaran',
        // Gunakan 'context' milik State
        'action': () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigasi ke Lapor Kebakaran')),
        ),
      },
      {
        'icon': Icons.support,
        'label': 'Lapor Non\nKebakaran',
        'action': () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigasi ke Lapor Non Kebakaran')),
        ),
      },
      {
        'icon': Icons.bar_chart,
        'label': 'Grafik\nKejadian',
        'action': () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigasi ke Grafik Kejadian')),
        ),
      },
      {
        'icon': Icons.book,
        'label': 'Daftar\nKunjungan',
        'action': () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigasi ke Daftar Kunjungan')),
        ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Layanan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: services.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final service = services[index];
            return _buildServiceButton(
              service['icon'],
              service['label'],
              buttonColor,
              textColor,
              service['action'],
            );
          },
        ),
      ],
    );
  }

  // Widget _buildServiceButton (tidak berubah)
  Widget _buildServiceButton(
    IconData icon,
    String label,
    Color buttonColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Widget _buildEdukasiSection
  Widget _buildEdukasiSection(
    Color cardColor,
    Color textColor,
    Color subtleTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Materi Edukasi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          color: cardColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              // Gunakan 'context' milik State
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Membuka Detail Edukasi')),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          'https://placehold.co/100x20/cccccc/000000?text=Partner',
                          height: 20,
                          errorBuilder: (c, e, s) => const SizedBox(height: 20),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Masih Bingung dengan Damkar?\nIni Dia Penjelasan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pelajari lebih lanjut tentang tugas...',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtleTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      'https://placehold.co/100x80/FFA07A/FFFFFF?text=Edukasi',
                      width: 100,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 100,
                        height: 80,
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
} // --- AKHIR DARI _MasyarakatHomeScreenState ---