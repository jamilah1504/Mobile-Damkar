import 'package:flutter/material.dart';
import '../masyarakat/laporan/RiwayatLaporanScreen.dart'; // Impor halaman riwayat

class MasyarakatHomeScreen extends StatelessWidget {
  const MasyarakatHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Definisikan warna tema
    final Color primaryColor = Colors.red.shade800;
    final Color secondaryColor = Colors.red.shade600;
    final Color backgroundColor = Colors.grey.shade100;
    final Color cardColor = Colors.white;
    final Color textColor = Colors.black87;
    final Color subtleTextColor = Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            // Ganti dengan path logo Anda
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
              // 1. Banner Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.asset(
                  // Ganti dengan path banner Anda
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

              // 2. Tombol Lapor Utama
              _buildLaporSection(
                context,
                primaryColor,
                secondaryColor,
              ), // Berikan context
              const SizedBox(height: 24),

              // 3. Section Layanan
              _buildLayananSection(
                context,
                secondaryColor,
                textColor,
              ), // Berikan context
              const SizedBox(height: 24),

              // 4. Section Materi Edukasi
              _buildEdukasiSection(
                context,
                cardColor,
                textColor,
                subtleTextColor,
              ), // Berikan context
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
          ), // Pastikan ikon dan label sesuai
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifikasi',
          ),
        ],
        currentIndex: 0, // Indeks item yang aktif (Beranda)
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        // --- PERBAIKI LOGIKA onTap ---
        onTap: (index) {
          // Aksi saat item navigasi ditekan
          if (index == 1) {
            // Jika tombol Riwayat (indeks 1) ditekan
            Navigator.push(
              // Gunakan push agar bisa kembali ke Beranda
              context,
              MaterialPageRoute(
                builder: (context) => const RiwayatLaporanScreen(),
              ),
            );
          }
          // Tambahkan logika untuk indeks lain jika perlu
          // else if (index == 0) { /* Sudah di Beranda */ }
          // else if (index == 2) { /* Navigasi ke Halaman Notifikasi */ }
        },
        // --- AKHIR PERBAIKAN onTap ---
      ),
    );
  }

  // Widget _buildLaporSection perlu context
  Widget _buildLaporSection(
    BuildContext context,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return Column(
      children: [
        // ... (Container Lingkaran LAPOR tidak berubah)
        Container(/* ... */),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                // Navigasi ke halaman Lapor Via Teks
                // avigator.push(context, MaterialPageRoute(builder: (context) => const LaporTeksScreen()));
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
                // Logika untuk melakukan panggilan telepon
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

  // Widget _buildLayananSection perlu context
  Widget _buildLayananSection(
    BuildContext context,
    Color buttonColor,
    Color textColor,
  ) {
    // Daftar layanan dengan aksi navigasi
    final List<Map<String, dynamic>> services = [
      {
        'icon': Icons.local_fire_department,
        'label': 'Lapor\nKebakaran',
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
              service['action'], // Tambahkan aksi
            );
          },
        ),
      ],
    );
  }

  // Widget _buildServiceButton perlu VoidCallback onPressed
  Widget _buildServiceButton(
    IconData icon,
    String label,
    Color buttonColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed, // Gunakan callback yang diberikan
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

  // Widget _buildEdukasiSection perlu context
  Widget _buildEdukasiSection(
    BuildContext context,
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
              // Aksi saat card edukasi ditekan
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
}
