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
  int _selectedFilterIndex = 0;
  Timer? _responTimer;
  int _sisaWaktuDetik = 0;
  bool _timerBerjalan = false;

  late Future<void> _initData;
  PanggilanLaporan? _panggilanDarurat;
  PanggilanLaporan? _tugasBerjalan;
  List<PanggilanLaporan> _laporanRiwayat = [];
  List<PanggilanLaporan> _laporanSelesai = [];

  // Ganti dengan IP Anda (localhost untuk Web/Windows, 10.0.2.2 untuk Emulator)
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

  @override
  void dispose() {
    _responTimer?.cancel();
    super.dispose();
  }

  // --- HELPER: AMBIL TOKEN ---
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Prioritaskan authToken, fallback ke token
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

        setState(() {
          try {
            _panggilanDarurat = semuaLaporan.firstWhere(
              (p) => p.status == 'Menunggu Verifikasi',
            );
          } catch (e) {
            _panggilanDarurat = null;
          }

          try {
            _tugasBerjalan = semuaLaporan.firstWhere(
              (p) => p.status == 'Diproses' || p.status == 'Penanganan', // Tambahkan Penanganan
            );
          } catch (e) {
            _tugasBerjalan = null;
          }

          _laporanRiwayat = semuaLaporan
              .where((p) => p.status == 'Ditolak')
              .toList();
          _laporanSelesai = semuaLaporan
              .where((p) => p.status == 'Selesai')
              .toList();

          if (_tugasBerjalan != null && !_timerBerjalan) {
            _startResponTimer();
          } else if (_tugasBerjalan == null) {
            _responTimer?.cancel();
            _timerBerjalan = false;
          }
        });
      }
    } catch (e) {
      print('Error fetch: $e');
    }
  }

  // ---------------------------------------------------
  // LOGIKA TIMER
  // ---------------------------------------------------
  void _startResponTimer() {
    _responTimer?.cancel();
    setState(() {
      _sisaWaktuDetik = 0; 
      _timerBerjalan = true;
    });

    _responTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _sisaWaktuDetik++;
        });
      }
    });
  }

  String _formatSisaWaktu(int totalDetik) {
    int menit = totalDetik ~/ 60;
    int detik = totalDetik % 60;
    return '${menit.toString().padLeft(2, '0')}:${detik.toString().padLeft(2, '0')}';
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
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
                  // 1. Banner
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

                  // 2. Dashboard & Filter
                  const Text(
                    'Dashboard',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildFilterButtons(secondaryColor),
                  const SizedBox(height: 20),

                  // 3. Konten Dinamis
                  _buildFilteredContent(
                    primaryColor,
                    secondaryColor,
                    accentColor,
                  ),

                  const SizedBox(height: 20),

                  // 4. Timer Card
                  if (_timerBerjalan) _buildSisaWaktuCard(accentColor),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'Info',
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

  Widget _buildFilteredContent(Color primary, Color secondary, Color accent) {
    switch (_selectedFilterIndex) {
      case 0: // AKTIF
        if (_panggilanDarurat != null) {
          return _buildPanggilanDaruratCard(
            _panggilanDarurat!,
            primary,
            secondary,
            accent,
          );
        }
        if (_tugasBerjalan != null) {
          return _buildTugasBerjalanCard(_tugasBerjalan!, accent);
        }
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Text(
              "Tidak ada panggilan darurat saat ini.",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        );
      case 1: // RIWAYAT (Ditolak)
        return _buildListFromData(
          _laporanRiwayat,
          "Tidak ada riwayat laporan (Ditolak).",
        );
      case 2: // SELESAI
        return _buildListFromData(
          _laporanSelesai,
          "Belum ada tugas yang selesai.",
        );
      default:
        return const SizedBox.shrink();
    }
  }

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
                ElevatedButton(
                  onPressed: () {
                    // [IMPLEMENTASI AUTO REFRESH DI SINI]
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailTugasScreen(
                          laporan: panggilan,
                          onTerimaTugas: () {
                            setState(() {
                              _initData = _fetchPanggilan();
                              _startResponTimer();
                            });
                          },
                        ),
                      ),
                    ).then((_) {
                      // REFRESH SAAT KEMBALI DARI DETAIL
                      setState(() {
                        _initData = _fetchPanggilan();
                      });
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: primaryColor),
                  child: const Text('Detail'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('${panggilan.jenisKejadian.toUpperCase()} - ${panggilan.namaPelapor}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Row(children: [const Icon(Icons.location_on, color: Colors.white, size: 16), const SizedBox(width: 4), Expanded(child: Text(panggilan.alamatKejadian, style: const TextStyle(color: Colors.white, fontSize: 15), maxLines: 2))]),
            const SizedBox(height: 8),
            Text(tgl, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
            const SizedBox(height: 16),
            
            // TOMBOL TERIMA & MULAI JALAN (LANGSUNG KE DETAIL + REFRESH)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailTugasScreen(
                      laporan: panggilan,
                      onTerimaTugas: () {
                        setState(() {
                          _initData = _fetchPanggilan();
                          _startResponTimer();
                        });
                      },
                    ),
                  ),
                ).then((_) {
                   // [IMPLEMENTASI AUTO REFRESH]
                   setState(() {
                     _initData = _fetchPanggilan();
                   });
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
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
            
            // TOMBOL LIHAT DETAIL (AUTO REFRESH)
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
                   // [IMPLEMENTASI AUTO REFRESH]
                   setState(() {
                     _initData = _fetchPanggilan();
                   });
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('LIHAT DETAIL / UPDATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSisaWaktuCard(Color accentColor) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(children: [Icon(Icons.timer_outlined, color: accentColor, size: 30), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Waktu Respon Berjalan', style: TextStyle(color: Colors.black54)), Text(_formatSisaWaktu(_sisaWaktuDetik), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accentColor))])]),
      ),
    );
  }

  Widget _buildListFromData(List<PanggilanLaporan> list, String pesanKosong) {
    if (list.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40.0), child: Text(pesanKosong, style: const TextStyle(color: Colors.grey))));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final laporan = list[index];
        final String tgl = DateFormat('dd MMM yyyy', 'id_ID').format(laporan.timestampDibuat);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(title: Text(laporan.jenisKejadian), subtitle: Text(laporan.alamatKejadian), trailing: Text(tgl)),
        );
      },
    );
  }
}