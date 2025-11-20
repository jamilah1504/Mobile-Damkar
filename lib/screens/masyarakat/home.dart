import 'package:flutter/material.dart';
import 'package:flutter_application_2/screens/masyarakat/EdukasiScreen.dart';
import 'package:flutter_application_2/screens/masyarakat/DetailEdukasiScreen.dart';
import 'package:flutter_application_2/screens/masyarakat/GrafikLaporan.dart';
import 'package:flutter_application_2/screens/masyarakat/LokasiRawan.dart';
import 'package:flutter_application_2/screens/masyarakat/Notifikasi.dart';
import 'package:flutter_application_2/screens/masyarakat/laporan/LaporButton.dart';
import '../masyarakat/laporan/RiwayatLaporanScreen.dart'; 
import '../../models/edukasi.dart';
import '../../methods/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './laporan/LaporanDarurat.dart';

class MasyarakatHomeScreen extends StatefulWidget {
  const MasyarakatHomeScreen({super.key});

  @override
  State<MasyarakatHomeScreen> createState() => _MasyarakatHomeScreenState();
}

class _MasyarakatHomeScreenState extends State<MasyarakatHomeScreen> {
  late Future<List<Edukasi>> futureEdukasi;

  String _userName = "Memuat...";
  int _userId = 0;

  final Color primaryColor = Colors.red.shade800;
  final Color secondaryColor = Colors.red.shade600;
  final Color backgroundColor = Colors.grey.shade100;
  final Color cardColor = Colors.white;
  final Color textColor = Colors.black87;
  final Color subtleTextColor = Colors.black54;

  @override
  void initState() {
    super.initState();
    _loadEdukasi();
    _loadUserData();
  }

  void _loadEdukasi() {
    setState(() {
      futureEdukasi = ApiService().getEdukasi(); 
    });
    debugPrint("CATATAN: Memanggil method 'getEdukasi' dari ApiService.");
  }

  Future<void> _loadUserData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userName = prefs.getString('userName'); 
      final int? userId = prefs.getInt('userId'); 

      if (userName == null || userName.isEmpty || userId == null) {
        throw Exception("Data pengguna tidak lengkap");
      }

      if (mounted) {
        setState(() {
          _userName = userName; 
          _userId = userId; 
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat data pengguna: $e"); 
      if (mounted) {
        setState(() {
          _userName = "Tamu"; 
          _userId = 0 ; 
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(vertical: 16.0), // Padding diubah agar slider bisa full width visualnya
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Padding horizontal manual untuk widget yang bukan slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Banner Image
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

                    // 2. Tombol Lapor Utama
                    _buildLaporSection(
                      context,
                      primaryColor,
                      secondaryColor,
                    ),
                    const SizedBox(height: 24),

                    // 3. Widget Sambutan
                    Text(
                      "Selamat Datang,",
                      style: TextStyle(
                        fontSize: 18,
                        color: subtleTextColor,
                      ),
                    ),
                    Text(
                      "Halo, $_userName ",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. Section Layanan
                    _buildLayananSection(
                      context,
                      secondaryColor,
                      textColor,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // 5. Section Materi Edukasi (MODIFIKASI DISINI: SLIDER)
              // Tidak dibungkus padding horizontal parent agar scroll mentok ke layar
              _buildEdukasiSliderSection(
                  context,
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
                builder: (context) => RiwayatLaporan(),
              ),
            );
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotifikasiPage(),
              ),
            );
          }
        },
      ),
    );
  }

// --- Helper Widgets ---
  Widget _buildLaporSection(
    BuildContext context,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return Column(
      children: [
        LaporButton(
          primaryColor: primaryColor, 
          secondaryColor: secondaryColor
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LaporanDarurat(),
                  ),
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

  Widget _buildLayananSection(
    BuildContext context,
    Color buttonColor,
    Color textColor,
  ) {
    final List<Map<String, dynamic>> services = [
     {
        'icon': Icons.local_fire_department,
        'label': 'Lapor\nKebakaran',
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LaporanDarurat(),
            ),
          );
        },
      },
      {
        'icon': Icons.support,
        'label': 'Lapor Non\nKebakaran',
        'action': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LaporanDarurat(),
              ),
            );
          },
        },
      {
        'icon': Icons.bar_chart,
        'label': 'Grafik\nKejadian',
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GrafikLaporanScreen(),
            ),
          );
        },
      },
      {
        'icon': Icons.book,
        'label': 'Daftar\nKunjungan',
        'action': () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigasi ke Daftar Kunjungan')),
        ),
      },
      {
        'icon': Icons.school,
        'label': 'Edukasi\nPublik',
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EdukasiListScreen(),
            ),
          );
        },
      },
      {
        'icon': Icons.warning_amber,
        'label': 'Lokasi\nRawan',
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MapScreen(),
            ),
          );
        },
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

  // --- MODIFIKASI UTAMA: Edukasi Slider Section ---
  Widget _buildEdukasiSliderSection(
    BuildContext context,
    Color cardColor,
    Color textColor,
    Color subtleTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul Header dengan Padding karena keluar dari SingleScrollView padding utama
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Materi Edukasi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Tombol Lihat Semua opsional
              TextButton(
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EdukasiListScreen(),
                    ),
                  );
                },
                child: const Text("Lihat Semua"),
              )
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // FutureBuilder untuk Slider
        FutureBuilder<List<Edukasi>>(
          future: futureEdukasi,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text("Error: ${snapshot.error}"),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Belum ada materi edukasi tersedia.'),
              );
            }

            // 1. Ambil Data dan LIMIT jadi 4 saja
            final allEdukasi = snapshot.data!;
            final limitedEdukasi = allEdukasi.take(4).toList();

            // 2. Buat Horizontal List (Slider)
            return SizedBox(
              height: 140, // Tentukan tinggi tetap untuk slider
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: limitedEdukasi.length,
                padding: const EdgeInsets.symmetric(horizontal: 16.0), // Padding awal & akhir list
                itemBuilder: (context, index) {
                  final edukasi = limitedEdukasi[index];
                  
                  // Bungkus card agar punya lebar tetap saat di-slide
                  return Container(
                    width: 300, // Lebar per item slider
                    margin: const EdgeInsets.only(right: 12.0), // Jarak antar item
                    child: _buildEdukasiCard(
                      edukasi,
                      cardColor,
                      textColor,
                      subtleTextColor,
                      context,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // Widget Card Edukasi (Sedikit disesuaikan untuk Slider)
  Widget _buildEdukasiCard(
    Edukasi edukasi,
    Color cardColor,
    Color textColor,
    Color subtleTextColor,
    BuildContext context,
  ) {
    final String previewText = edukasi.isiKonten.length > 60
        ? '${edukasi.isiKonten.substring(0, 60)}...'
        : edukasi.isiKonten;

    final String formattedDate =
        '${edukasi.timestampDibuat.day}/${edukasi.timestampDibuat.month}/${edukasi.timestampDibuat.year}';

    final bool isPdf =
        edukasi.fileUrl != null &&
        edukasi.fileUrl!.toLowerCase().endsWith('.pdf');

    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
           // Aktifkan navigasi detail jika diperlukan
           Navigator.push(
             context,
             MaterialPageRoute(
               builder: (context) => DetailEdukasiScreen(edukasi: edukasi),
             ),
           );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      edukasi.judul,
                      style: TextStyle(
                        fontSize: 14, // Font sedikit diperkecil agar muat di slider
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      previewText,
                      style: TextStyle(fontSize: 11, color: subtleTextColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Gambar / Icon PDF
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: isPdf
                    ? Container(
                        width: 80,
                        height: 80,
                        color: Colors.red.shade50,
                        child: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                          size: 30,
                        ),
                      )
                    : Image.network(
                        edukasi.fileUrl ??
                            'https://placehold.co/100x80/FFA07A/FFFFFF?text=Edukasi',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image_not_supported, size: 30),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}