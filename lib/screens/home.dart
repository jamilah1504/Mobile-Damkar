import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
          // Ganti dengan logo Anda
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
          'Pemadam Kebakaran\nKabupaten Subang',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.symmetric(horizontal: 12.0),
        //     child: ElevatedButton(
        //       onPressed: () {
        //         // Navigasi ke halaman Login
        //       },
        //       style: ElevatedButton.styleFrom(
        //         backgroundColor: Colors.white,
        //         foregroundColor: primaryColor,
        //       ),
        //       child: const Text('Login'),
        //     ),
        //   ),
        // ],
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
                child: Image.network(
                  'https://placehold.co/600x200/FF0000/FFFFFF?text=Banner+Damkar', // Ganti URL gambar banner
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
              _buildLaporSection(primaryColor, secondaryColor),
              const SizedBox(height: 24),

              // 3. Section Layanan
              _buildLayananSection(secondaryColor, textColor),
              const SizedBox(height: 24),

              // 4. Section Materi Edukasi
              _buildEdukasiSection(cardColor, textColor, subtleTextColor),
              const SizedBox(height: 24), // Tambahan space di bawah
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifikasi',
          ),
        ],
        currentIndex: 0, // Indeks item yang aktif (Beranda)
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          // Aksi saat item navigasi ditekan
        },
      ),
    );
  }

  // Widget untuk section tombol lapor
  Widget _buildLaporSection(Color primaryColor, Color secondaryColor) {
    return Column(
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: secondaryColor, // Warna lingkaran luar
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor, // Warna lingkaran dalam
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic, color: Colors.white, size: 40),
                    SizedBox(height: 5),
                    Text(
                      'LAPOR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {},
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
              onPressed: () {},
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

  // Widget untuk section layanan
  Widget _buildLayananSection(Color buttonColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Layanan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3, // 3 kolom
          shrinkWrap: true, // Agar GridView menyesuaikan tingginya
          physics:
              const NeverScrollableScrollPhysics(), // Nonaktifkan scroll internal
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _buildServiceButton(
              Icons.local_fire_department,
              'Lapor\nKebakaran',
              buttonColor,
              textColor,
            ),
            _buildServiceButton(
              Icons.support,
              'Lapor Non\nKebakaran',
              buttonColor,
              textColor,
            ),
            _buildServiceButton(
              Icons.bar_chart,
              'Grafik\nKejadian',
              buttonColor,
              textColor,
            ),
            _buildServiceButton(
              Icons.book,
              'Daftar\nKunjungan',
              buttonColor,
              textColor,
            ),
          ],
        ),
      ],
    );
  }

  // Widget untuk tombol layanan individual
  Widget _buildServiceButton(
    IconData icon,
    String label,
    Color buttonColor,
    Color textColor,
  ) {
    return ElevatedButton(
      onPressed: () {},
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

  // Widget untuk section materi edukasi
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
            // Membuat Card bisa ditekan
            onTap: () {
              // Aksi saat card edukasi ditekan
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ganti dengan logo partner jika ada
                        Image.network(
                          'https://placehold.co/100x20/cccccc/000000?text=Partner',
                          height: 20,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox(height: 20),
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
                          'Pelajari lebih lanjut tentang tugas...', // Tambahkan deskripsi singkat
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
                      'https://placehold.co/100x80/FFA07A/FFFFFF?text=Edukasi', // Ganti URL gambar edukasi
                      width: 100,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
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

// Jangan lupa untuk membuat file main.dart jika belum ada
// Contoh main.dart:
/*
import 'package:flutter/material.dart';
import 'home_screen.dart'; // Sesuaikan path jika perlu

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FireResponse App',
      theme: ThemeData(
        primarySwatch: Colors.red, // Atau gunakan colorScheme
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red.shade800),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
*/
