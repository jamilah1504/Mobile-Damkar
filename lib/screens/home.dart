import 'package:flutter/material.dart';
import 'package:flutter_application_2/screens/masyarakat/EdukasiScreen.dart';
import 'package:flutter_application_2/screens/masyarakat/DetailEdukasiScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- IMPORT BUTTON LAPOR ---
import 'package:flutter_application_2/screens/masyarakat/laporan/LaporButton.dart';

import './masyarakat/laporan/LaporanDarurat.dart';

// --- PENTING: IMPORT HALAMAN LOGIN ANDA DI SINI ---
import './auth/Login.dart'; 

// --- IMPORT MODEL ---
import '../../models/edukasi.dart';

// --- IMPORT API SERVICE ---
import '../../methods/api.dart' as method_api;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Edukasi>> futureEdukasi;

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
  }

  void _loadEdukasi() {
    setState(() {
      futureEdukasi = method_api.ApiService().getEdukasi();
    });
  }
  // --- FUNGSI LOGIN (PENGGANTI LOGOUT) ---
  Future<void> _handleLogin() async {
    // Kita bersihkan sesi lama agar saat masuk ke halaman Login benar-benar bersih
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear(); 
      
      if (!mounted) return;

      // Langsung navigasi ke Login tanpa Dialog Konfirmasi
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(), 
        ),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint("Error saat ke halaman login: $e");
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
        // --- TOMBOL LOGIN DI APPBAR (DIUBAH) ---
        actions: [
          IconButton(
            onPressed: _handleLogin,
            icon: const Icon(Icons.login, color: Colors.white), // Ikon diganti jadi Login
            tooltip: 'Login / Ganti Akun',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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

              // // 5. Section Materi Edukasi (Slider)
              // _buildEdukasiSliderSection(
              //   context,
              //   cardColor,
              //   textColor,
              //   subtleTextColor,
              // ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
        // Pastikan widget LaporButton Anda memang menerima parameter ini
        LaporButton(),
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

  // Widget _buildEdukasiSliderSection(
  //   BuildContext context,
  //   Color cardColor,
  //   Color textColor,
  //   Color subtleTextColor,
  // ) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       // Judul Header
  //       Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 16.0),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             const Text(
  //               'Materi Edukasi',
  //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //             ),
  //             TextButton(
  //               onPressed: () {
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (context) => const EdukasiListScreen(),
  //                   ),
  //                 );
  //               },
  //               child: const Text("Lihat Semua"),
  //             )
  //           ],
  //         ),
  //       ),
  //       const SizedBox(height: 8),

  //       // FutureBuilder untuk Slider
  //       // FutureBuilder untuk Slider
  //       FutureBuilder<List<Edukasi>>(
  //         future: futureEdukasi,
  //         builder: (context, snapshot) {
            
  //           // --- PERBAIKAN DI SINI ---
  //           // Jangan pakai '!', tapi pakai '?? []'.
  //           // Artinya: Jika data ada, pakai datanya. Jika data null (loading/error), pakai list kosong [].
  //           final allEdukasi = snapshot.data ?? []; 

  //           // Jika data masih kosong (sedang loading atau gagal), tampilkan kotak kosong atau loading kecil
  //           // agar layout tidak berantakan.
  //           if (allEdukasi.isEmpty) {
  //             return const SizedBox(
  //               height: 140, 
  //               child: Center(child: CircularProgressIndicator())
  //             );
  //           }

  //           final limitedEdukasi = allEdukasi.take(4).toList();

  //           return SizedBox(
  //             height: 140,
  //             child: ListView.builder(
  //               scrollDirection: Axis.horizontal,
  //               itemCount: limitedEdukasi.length,
  //               padding: const EdgeInsets.symmetric(horizontal: 16.0),
  //               itemBuilder: (context, index) {
  //                 final edukasi = limitedEdukasi[index];
  //                 return Container(
  //                   width: 300,
  //                   margin: const EdgeInsets.only(right: 12.0),
  //                   child: _buildEdukasiCard(
  //                     edukasi,
  //                     cardColor,
  //                     textColor,
  //                     subtleTextColor,
  //                     context,
  //                   ),
  //                 );
  //               },
  //             ),
  //           );
  //         },
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildEdukasiCard(
  //   Edukasi edukasi,
  //   Color cardColor,
  //   Color textColor,
  //   Color subtleTextColor,
  //   BuildContext context,
  // ) {
  //   final String previewText = edukasi.isiKonten.length > 60
  //       ? '${edukasi.isiKonten.substring(0, 60)}...'
  //       : edukasi.isiKonten;

  //   final String formattedDate =
  //       '${edukasi.timestampDibuat.day}/${edukasi.timestampDibuat.month}/${edukasi.timestampDibuat.year}';

  //   final bool isPdf = edukasi.fileUrl != null &&
  //       edukasi.fileUrl!.toLowerCase().endsWith('.pdf');

  //   return Card(
  //     color: cardColor,
  //     elevation: 2,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     child: InkWell(
  //       borderRadius: BorderRadius.circular(12),
  //       onTap: () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => DetailEdukasiScreen(edukasi: edukasi),
  //           ),
  //         );
  //       },
  //       child: Padding(
  //         padding: const EdgeInsets.all(12.0),
  //         child: Row(
  //           children: [
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   Text(
  //                     edukasi.judul,
  //                     style: TextStyle(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.bold,
  //                       color: textColor,
  //                     ),
  //                     maxLines: 2,
  //                     overflow: TextOverflow.ellipsis,
  //                   ),
  //                   const SizedBox(height: 4),
  //                   Text(
  //                     previewText,
  //                     style: TextStyle(fontSize: 11, color: subtleTextColor),
  //                     maxLines: 2,
  //                     overflow: TextOverflow.ellipsis,
  //                   ),
  //                   const SizedBox(height: 4),
  //                   Text(
  //                     formattedDate,
  //                     style: TextStyle(
  //                       fontSize: 10,
  //                       color: Colors.grey.shade600,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(width: 8),
  //             ClipRRect(
  //               borderRadius: BorderRadius.circular(8.0),
  //               child: isPdf
  //                   ? Container(
  //                       width: 80,
  //                       height: 80,
  //                       color: Colors.red.shade50,
  //                       child: const Icon(
  //                         Icons.picture_as_pdf,
  //                         color: Colors.red,
  //                         size: 30,
  //                       ),
  //                     )
  //                   : Image.network(
  //                       edukasi.fileUrl ??
  //                           'https://placehold.co/100x80/FFA07A/FFFFFF?text=Edukasi',
  //                       width: 80,
  //                       height: 80,
  //                       fit: BoxFit.cover,
  //                       errorBuilder: (c, e, s) => Container(
  //                         width: 80,
  //                         height: 80,
  //                         color: Colors.grey.shade300,
  //                         child: const Icon(Icons.image_not_supported, size: 30),
  //                       ),
  //                     ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}