import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk fitur copy paste token
import '../service/notfikasi.dart';
import '../screens/auth/login.dart'; // UNCOMMENT JIKA FILE LOGIN SUDAH ADA

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variabel untuk menyimpan token (untuk keperluan debug)
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    // Panggil logika pengambilan token saat aplikasi dibuka
    _getAndPrintToken();
  }

  // Fungsi dari kode sebelumnya untuk mengambil & print token
  void _getAndPrintToken() async {
    String? token = await NotificationService().getFcmToken();
    
    if (mounted) {
      setState(() {
        _fcmToken = token;
      });
    }

    // Print ke console agar Anda bisa copy untuk testing di Postman/Backend
    print("========================================");
    print("FCM TOKEN DEVICE INI:");
    print(token);
    print("========================================");
  }

  @override
  Widget build(BuildContext context) {
    // Definisikan warna tema
    final Color primaryColor = Colors.red.shade800;
    final Color secondaryColor = Colors.red.shade600;
    final Color backgroundColor = Colors.grey.shade100;
    // final Color cardColor = Colors.white; // Unused variable removed
    final Color textColor = Colors.black87;
    // final Color subtleTextColor = Colors.black54; // Unused variable removed

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          // Pastikan file gambar ada di assets dan pubspec.yaml
          child: Image.asset(
            'Images/logo2.png',
            width: 40,
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.shield, color: Colors.white, size: 24),
          ),
        ),
        // FITUR RAHASIA: GestureDetector untuk copy token tanpa merusak UI
        title: GestureDetector(
          onLongPress: () {
            if (_fcmToken != null) {
              Clipboard.setData(ClipboardData(text: _fcmToken!));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Token Dev: $_fcmToken Disalin!")),
              );
            }
          },
          child: const Text(
            'Pemadam Kebakaran\nKabupaten Subang',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: ElevatedButton(
              onPressed: () {
                // Navigasi ke Login
                // Pastikan route atau file LoginScreen sudah ada
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
              ),
              child: const Text('Login'),
            ),
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
                  'Images/image.png', // Pastikan asset ini ada
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

              // 4. Section Materi Edukasi (Placeholder)
              const SizedBox(height: 24),
            ],
          ),
        ),
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                   print("Tombol LAPOR ditekan");
                   // Tambahkan logika navigasi ke halaman lapor darurat disini
                },
                customBorder: const CircleBorder(),
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
          physics: const NeverScrollableScrollPhysics(), // Nonaktifkan scroll internal
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
            _buildServiceButton(
              Icons.school,
              'Edukasi\nPublik',
              buttonColor,
              textColor,
            ),
            _buildServiceButton(
              Icons.contacts,
              'Kontak\nPetugas',
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
        backgroundColor: Colors.white, // Ganti background jadi putih agar icon menonjol
        foregroundColor: buttonColor, // Warna icon mengikuti tema
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 8), // Padding disesuaikan
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: textColor),
          ),
        ],
      ),
    );
  }
}