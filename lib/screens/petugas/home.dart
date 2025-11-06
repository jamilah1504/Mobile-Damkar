import 'package:flutter/material.dart';
import 'dart:async'; // Untuk Timer
import 'dart:convert'; // Untuk JSON
import 'package:http/http.dart' as http; // Untuk API
import 'package:intl/intl.dart'; // Untuk format tanggal
import 'daftarTugas.dart';

// ---------------------------------------------------
// MODEL DATA (Berdasarkan reportController.js)
// ---------------------------------------------------
class PanggilanLaporan {
  final int id;
  final String judulInsiden;
  final String jenisKejadian;
  final String alamatKejadian;
  final String deskripsi;
  final String status;
  final DateTime timestampDibuat;

  PanggilanLaporan({
    required this.id,
    required this.judulInsiden,
    required this.jenisKejadian,
    required this.alamatKejadian,
    required this.deskripsi,
    required this.status,
    required this.timestampDibuat,
  });

  factory PanggilanLaporan.fromJson(Map<String, dynamic> json) {
    // 'Insiden' bisa jadi null jika ada data yg tidak konsisten
    final insiden = json['Insiden'] as Map<String, dynamic>?;

    return PanggilanLaporan(
      id: json['id'] ?? 0,
      judulInsiden: insiden?['judulInsiden'] ?? 'Judul Tidak Ada',
      jenisKejadian: json['jenisKejadian'] ?? 'Tidak Diketahui',
      alamatKejadian: json['alamatKejadian'] ?? 'Alamat Tidak Ada',
      deskripsi: json['deskripsi'] ?? 'Deskripsi Tidak Ada',
      status: json['status'] ?? 'Tidak Diketahui',
      timestampDibuat: json['timestampDibuat'] != null
          ? DateTime.parse(json['timestampDibuat'])
          : DateTime.now(),
    );
  }
}

// ---------------------------------------------------
// SCREEN UTAMA (Stateful)
// ---------------------------------------------------
class PetugasHomeScreen extends StatefulWidget {
  const PetugasHomeScreen({super.key});

  @override
  State<PetugasHomeScreen> createState() => _PetugasHomeScreenState();
}

class _PetugasHomeScreenState extends State<PetugasHomeScreen> {
  int _selectedFilterIndex = 0; // 0: Aktif, 1: Riwayat, 2: Selesai
  Timer? _responTimer;
  int _sisaWaktuDetik = 0; // Timer dimulai saat tugas diterima
  bool _timerBerjalan = false;

  // Variabel untuk menampung data dari API
  late Future<void> _initData;
  PanggilanLaporan? _panggilanDarurat; // Status 'Menunggu Verifikasi'
  PanggilanLaporan? _tugasBerjalan; // Status 'Diproses'
  List<PanggilanLaporan> _laporanRiwayat = []; // Status 'Ditolak'
  List<PanggilanLaporan> _laporanSelesai = []; // Status 'Selesai'

  // Ganti 'localhost' dengan IP Anda jika testing di HP
  final String _baseUrl =
      'http://localhost:5000'; // 10.0.2.2 untuk Emulator Android

  @override
  void initState() {
    super.initState();
    // Memanggil API saat halaman pertama kali dimuat
    _initData = _fetchPanggilan();
  }

  @override
  void dispose() {
    _responTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------
  // SERVICE API (Memanggil data & menyaring)
  // ---------------------------------------------------
  Future<void> _fetchPanggilan() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/reports'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<PanggilanLaporan> semuaLaporan = data
            .map((json) => PanggilanLaporan.fromJson(json))
            .toList();

        // Menyaring data berdasarkan status
        setState(() {
          // --- PERBAIKAN DIMULAI DI SINI ---

          // Panggilan darurat baru (hanya ambil 1 yang paling baru)
          try {
            _panggilanDarurat = semuaLaporan.firstWhere(
              (p) => p.status == 'Menunggu Verifikasi',
            );
          } catch (e) {
            _panggilanDarurat = null; // Set ke null jika tidak ada
          }

          // Tugas yang sedang berjalan (hanya ambil 1)
          try {
            _tugasBerjalan = semuaLaporan.firstWhere(
              (p) => p.status == 'Diproses',
            );
          } catch (e) {
            _tugasBerjalan = null; // Set ke null jika tidak ada
          }

          // --- PERBAIKAN SELESAI DI SINI ---

          // Daftar untuk filter "Riwayat" (contoh: Ditolak)
          _laporanRiwayat = semuaLaporan
              .where((p) => p.status == 'Ditolak')
              .toList();

          // Daftar untuk filter "Selesai"
          _laporanSelesai = semuaLaporan
              .where((p) => p.status == 'Selesai')
              .toList();

          // Logika untuk timer
          if (_tugasBerjalan != null && !_timerBerjalan) {
            // Jika ada tugas 'Diproses' dan timer belum jalan, mulai timer
            _startResponTimer();
          } else if (_tugasBerjalan == null) {
            // Jika tidak ada tugas 'Diproses', matikan timer
            _responTimer?.cancel();
            _timerBerjalan = false;
          }
        });
      } else {
        throw Exception(
          'Gagal memuat laporan (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      // Tampilkan error di UI
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  // ---------------------------------------------------
  // SERVICE API (Update Status Laporan)
  // ---------------------------------------------------
  Future<void> _terimaTugas(int laporanId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/reports/$laporanId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': 'Diproses'}),
      );

      if (response.statusCode == 200) {
        // Jika berhasil update, panggil ulang data untuk refresh halaman
        setState(() {
          _initData = _fetchPanggilan();
        });
      } else {
        // Tampilkan pesan error jika gagal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menerima tugas: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ---------------------------------------------------
  // LOGIKA TIMER
  // ---------------------------------------------------
  void _startResponTimer() {
    _responTimer?.cancel(); // Hentikan timer sebelumnya
    setState(() {
      _sisaWaktuDetik = 85; // Set sisa waktu
      _timerBerjalan = true; // Set flag
    });

    _responTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sisaWaktuDetik > 0) {
        setState(() {
          _sisaWaktuDetik--;
        });
      } else {
        timer.cancel();
        setState(() {
          _timerBerjalan = false;
          // TODO: Tambahkan logika jika waktu habis
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
  // METHOD BUILD (UI)
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
        // ... (AppBar Anda tidak berubah)
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
      // Gunakan FutureBuilder untuk menunggu API
      body: FutureBuilder<void>(
        future: _initData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }

          // Jika data berhasil dimuat, tampilkan body
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Banner Image (Tidak berubah)
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

                  // 2. Judul Dashboard & Filter (Tidak berubah)
                  const Text(
                    'Dashboard',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildFilterButtons(secondaryColor),
                  const SizedBox(height: 20),

                  // 3. KONTEN DINAMIS BERDASARKAN FILTER
                  _buildFilteredContent(
                    primaryColor,
                    secondaryColor,
                    accentColor,
                  ),

                  const SizedBox(height: 20),

                  // 4. Kartu Sisa Waktu Respon
                  // Tampil HANYA jika timer berjalan (setelah tugas diterima)
                  if (_timerBerjalan) _buildSisaWaktuCard(accentColor),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        // ... (BottomNavBar Anda tidak berubah)
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
                builder: (context) => const DaftarTugasScreen(),
              ),
            );
          }
        },
      ),
    );
  }

  // ---------------------------------------------------
  // WIDGET HELPER
  // ---------------------------------------------------

  // Widget untuk menampilkan konten berdasarkan filter
  Widget _buildFilteredContent(Color primary, Color secondary, Color accent) {
    switch (_selectedFilterIndex) {
      case 0: // AKTIF
        // Tampilkan Panggilan Darurat JIKA ADA
        if (_panggilanDarurat != null) {
          return _buildPanggilanDaruratCard(
            _panggilanDarurat!,
            primary,
            secondary,
            accent,
          );
        }
        // Tampilkan Tugas Berjalan JIKA ADA
        if (_tugasBerjalan != null) {
          return _buildTugasBerjalanCard(_tugasBerjalan!, accent);
        }
        // Jika tidak ada keduanya
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Text(
              "Tidak ada panggilan darurat saat ini.",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        );
      case 1: // RIWAYAT
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

  // Widget untuk tombol filter
  Widget _buildFilterButtons(Color activeColor) {
    final List<String> filters = ['Aktif', 'Riwayat', 'Selesai'];
    return Row(
      // ... (Tidak berubah)
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

  // Widget untuk kartu panggilan darurat BARU (Status: Menunggu Verifikasi)
  Widget _buildPanggilanDaruratCard(
    PanggilanLaporan panggilan,
    Color primaryColor,
    Color secondaryColor,
    Color accentColor,
  ) {
    // Format tanggal
    final String tgl = DateFormat(
      'dd MMM yyyy, HH:mm',
      'id_ID',
    ).format(panggilan.timestampDibuat);

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
              // ... (Icon Panggilan Darurat tidak berubah)
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
                    // TODO: Aksi tombol detail (buka halaman detail)
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
            // Data dari API
            Text(
              panggilan.judulInsiden, // 'KEBAKARAN - Gedung JTIK...'
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            // Data dari API
            Text(
              panggilan.alamatKejadian, // 'Jl. Airlangga...'
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            // Data dari API
            Text(
              tgl, // '22 Sep 2025, 09.15'
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            // Tombol "TERIMA"
            ElevatedButton(
              onPressed: () {
                // Panggil API untuk update status
                _terimaTugas(panggilan.id);
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

  // Widget baru untuk TUGAS BERJALAN (Status: Diproses)
  Widget _buildTugasBerjalanCard(
    PanggilanLaporan panggilan,
    Color accentColor,
  ) {
    final String tgl = DateFormat(
      'dd MMM yyyy, HH:mm',
      'id_ID',
    ).format(panggilan.timestampDibuat);

    return Card(
      color: accentColor, // Warna biru
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.directions_run, color: Colors.white, size: 30),
                SizedBox(width: 8),
                Text(
                  'TUGAS SEDANG BERJALAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              panggilan.judulInsiden,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              panggilan.alamatKejadian,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Diterima: $tgl",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Aksi tombol (misal: 'Sudah Tiba' atau 'Selesaikan Tugas')
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Warna hijau
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'UPDATE STATUS (Contoh)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk kartu sisa waktu respon
  Widget _buildSisaWaktuCard(Color accentColor) {
    // Tampilan card ini tidak berubah
    return Card(
      // ... (Styling tidak berubah)
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

  // Widget untuk menampilkan daftar (Riwayat / Selesai)
  Widget _buildListFromData(List<PanggilanLaporan> list, String pesanKosong) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Text(pesanKosong, style: const TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final laporan = list[index];
        final String tgl = DateFormat(
          'dd MMM yyyy',
          'id_ID',
        ).format(laporan.timestampDibuat);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(laporan.judulInsiden),
            subtitle: Text(laporan.alamatKejadian),
            trailing: Text(tgl),
            onTap: () {
              // TODO: Aksi ke halaman detail
            },
          ),
        );
      },
    );
  }
}
