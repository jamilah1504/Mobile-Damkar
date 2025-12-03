import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../petugas/daftarTugas.dart';
import 'detailTugas.dart';

// ---------------------------------------------------
// MODEL DATA
// ---------------------------------------------------
class PanggilanLaporan {
  final int id;
  final int insidenId;
  final String judulInsiden;
  final String jenisKejadian;
  final String alamatKejadian;
  final String deskripsi;
  final String status;
  final DateTime timestampDibuat;
  final String namaPelapor;
  final double? latitude;
  final double? longitude;

  PanggilanLaporan({
    required this.id,
    required this.insidenId,
    required this.judulInsiden,
    required this.jenisKejadian,
    required this.alamatKejadian,
    required this.deskripsi,
    required this.status,
    required this.timestampDibuat,
    required this.namaPelapor,
    this.latitude,
    this.longitude,
  });

  factory PanggilanLaporan.fromJson(Map<String, dynamic> json) {
    final insiden = json['Insiden'] as Map<String, dynamic>?;
    String? alamat = json['alamatKejadian'];
    double? lat = json['latitude'] != null ? (json['latitude'] as num).toDouble() : null;
    double? long = json['longitude'] != null ? (json['longitude'] as num).toDouble() : null;

    if ((alamat == null || alamat.isEmpty) && lat != null && long != null) {
      alamat = 'Titik GPS: $lat, $long';
    }

    return PanggilanLaporan(
      id: json['id'] ?? 0,
      insidenId: json['insidenId'] ?? 0,
      judulInsiden: insiden?['judulInsiden'] ?? 'Laporan Masuk',
      jenisKejadian: json['jenisKejadian'] ?? 'Kejadian Tidak Diketahui',
      alamatKejadian: alamat ?? 'Lokasi Tidak Diketahui',
      deskripsi: json['deskripsi'] ?? '-',
      status: json['status'] ?? 'Tidak Diketahui',
      timestampDibuat: json['timestampDibuat'] != null
          ? DateTime.parse(json['timestampDibuat'])
          : DateTime.now(),
      namaPelapor: json['namaPelapor'] ?? (json['Pelapor']?['name']) ?? 'Warga',
      latitude: lat,
      longitude: long,
    );
  }
}

// ---------------------------------------------------
// SCREEN UTAMA
// ---------------------------------------------------
class PetugasHomeScreen extends StatefulWidget {
  const PetugasHomeScreen({super.key});

  @override
  State<PetugasHomeScreen> createState() => _PetugasHomeScreenState();
}

class _PetugasHomeScreenState extends State<PetugasHomeScreen> {
  late Future<void> _initData;
  
  // List data untuk dashboard
  List<PanggilanLaporan> _listPanggilanDarurat = [];
  List<PanggilanLaporan> _listTugasBerjalan = [];

  // Ganti dengan IP Anda
  final String _baseUrl = 'http://localhost:5000';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      if (mounted) {
        setState(() {
          _initData = _fetchPanggilan();
        });
      }
    });
  }

  // Helper Token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken') ?? prefs.getString('token'); 
  }

  // ---------------------------------------------------
  // SERVICE API
  // ---------------------------------------------------
  Future<void> _fetchPanggilan() async {
    try {
      final token = await _getToken(); 

      final response = await http.get(
        Uri.parse('$_baseUrl/api/reports'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<PanggilanLaporan> semuaLaporan = data
            .map((json) => PanggilanLaporan.fromJson(json))
            .toList();

        // Urutkan dari terbaru
        semuaLaporan.sort((a, b) => b.timestampDibuat.compareTo(a.timestampDibuat));

        setState(() {
          // 1. Ambil Laporan 'Menunggu Verifikasi' (Group by Insiden)
          var rawDarurat = semuaLaporan
              .where((p) => p.status == 'Menunggu Verifikasi')
              .toList();
          _listPanggilanDarurat = _filterLatestPerIncident(rawDarurat);

          // 2. Ambil Tugas Berjalan (Group by Insiden)
          var rawBerjalan = semuaLaporan
              .where((p) => p.status == 'Diproses' || p.status == 'Penanganan')
              .toList();
          _listTugasBerjalan = _filterLatestPerIncident(rawBerjalan);
        });
      }
    } catch (e) {
      print('Error fetch: $e');
    }
  }

  // Helper: Filter agar 1 insiden hanya muncul 1 kartu (paling baru)
  List<PanggilanLaporan> _filterLatestPerIncident(List<PanggilanLaporan> list) {
    final Map<int, PanggilanLaporan> uniqueMap = {};
    for (var laporan in list) {
      if (!uniqueMap.containsKey(laporan.insidenId)) {
        uniqueMap[laporan.insidenId] = laporan;
      }
    }
    return uniqueMap.values.toList();
  }

  // ---------------------------------------------------
  // UI BUILD
  // ---------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.red.shade800;
    final Color secondaryColor = Colors.red.shade600;
    final Color accentColor = Colors.blue.shade800;
    final Color backgroundColor = Colors.grey.shade100;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('Images/logo2.png'),
        ),
        title: const Text(
          'Selamat Datang, Petugas!',
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner Image
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

                  // Dashboard Title
                  const Text(
                    'Dashboard Aktif',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pantau tugas yang sedang berlangsung di sini.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // KONTEN UTAMA
                  if (_listPanggilanDarurat.isEmpty && _listTugasBerjalan.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                            SizedBox(height: 16),
                            Text("Tidak ada panggilan darurat saat ini.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        // LIST 1: Panggilan Darurat (Merah)
                        ..._listPanggilanDarurat.map((laporan) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildPanggilanDaruratCard(laporan, primaryColor, secondaryColor, accentColor),
                        )),

                        // LIST 2: Tugas Berjalan (Biru/Hijau)
                        ..._listTugasBerjalan.map((laporan) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildTugasBerjalanCard(laporan, accentColor),
                        )),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: 'Info'),
        ],
        currentIndex: 0,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DaftarTugas(),
              ),
            );
          }
        },
      ),
    );
  }

  // ---------------------------------------------------
  // WIDGETS
  // ---------------------------------------------------

  Widget _buildPanggilanDaruratCard(
    PanggilanLaporan panggilan,
    Color primaryColor,
    Color secondaryColor,
    Color accentColor,
  ) {
    final String tgl = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(panggilan.timestampDibuat);

    return Card(
      color: primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 30),
                    SizedBox(width: 8),
                    Text('PANGGILAN DARURAT!!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailTugasScreen(
                          laporan: panggilan,
                          onTerimaTugas: () {
                            setState(() { _initData = _fetchPanggilan(); });
                          },
                        ),
                      ),
                    ).then((_) {
                      setState(() { _initData = _fetchPanggilan(); });
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Text('Detail', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Konten
            Text('${panggilan.jenisKejadian.toUpperCase()} - ${panggilan.namaPelapor}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Row(children: [const Icon(Icons.location_on, color: Colors.white, size: 16), const SizedBox(width: 4), Expanded(child: Text(panggilan.alamatKejadian, style: const TextStyle(color: Colors.white, fontSize: 15), maxLines: 2))]),
            const SizedBox(height: 8),
            Text(tgl, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
            const SizedBox(height: 16),
            
            // Tombol Terima
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailTugasScreen(
                      laporan: panggilan,
                      onTerimaTugas: () {
                        setState(() { _initData = _fetchPanggilan(); });
                      },
                    ),
                  ),
                ).then((_) {
                   setState(() { _initData = _fetchPanggilan(); });
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('TERIMA & MULAI JALAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTugasBerjalanCard(PanggilanLaporan panggilan, Color accentColor) {
    final String tgl = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(panggilan.timestampDibuat);
    return Card(
      color: accentColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(children: [Icon(Icons.directions_run, color: Colors.white, size: 30), SizedBox(width: 8), Text('TUGAS SEDANG BERJALAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]),
            const SizedBox(height: 12),
            Text(panggilan.jenisKejadian.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text(panggilan.alamatKejadian, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
            const SizedBox(height: 8),
            Text("Diterima: $tgl", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
            const SizedBox(height: 16),
            
            // Tombol Update
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailTugasScreen(
                      laporan: panggilan,
                      onTerimaTugas: () {},
                    ),
                  ),
                ).then((_) {
                   setState(() { _initData = _fetchPanggilan(); });
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('LIHAT DETAIL / UPDATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}