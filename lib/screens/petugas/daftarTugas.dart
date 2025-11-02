import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// ENUM untuk Status (sesuai permintaan Anda)
enum TugasStatus { Ready, SedangBerjalan, Selesai }

// ---------------------------------------------------
// MODEL DATA (sesuai API Tugas.js)
// ---------------------------------------------------
class Tugas {
  final int id;
  final DateTime? waktuDisposisi;
  final DateTime? waktuTiba;
  final DateTime? waktuSelesai;

  // TODO: Data ini tidak ada di API /api/tugas Anda.
  // Anda perlu memodifikasi API Anda untuk menyertakan data ini,
  // misalnya dengan JOIN ke tabel Laporan.
  final String laporanId;
  final String jenisKejadian;
  final String alamat;

  Tugas({
    required this.id,
    this.waktuDisposisi,
    this.waktuTiba,
    this.waktuSelesai,
    // Data dummy untuk UI, ganti dengan data API
    this.laporanId = "11111-1111",
    this.jenisKejadian = "Kebakaran Lahan",
    this.alamat = "Jl. Sudirman No.12",
  });

  factory Tugas.fromJson(Map<String, dynamic> json) {
    return Tugas(
      id: json['id'],
      waktuDisposisi: json['waktuDisposisi'] != null
          ? DateTime.parse(json['waktuDisposisi'])
          : null,
      waktuTiba: json['waktuTiba'] != null
          ? DateTime.parse(json['waktuTiba'])
          : null,
      waktuSelesai: json['waktuSelesai'] != null
          ? DateTime.parse(json['waktuSelesai'])
          : null,

      // TODO: Ganti 'laporanId_dari_api' dll, dengan key JSON yang benar dari API Anda
      // laporanId: json['laporanId_dari_api'],
      // jenisKejadian: json['jenisKejadian_dari_api'],
      // alamat: json['alamat_dari_api'],
    );
  }

  // Logika untuk menentukan status berdasarkan waktu
  TugasStatus get status {
    if (waktuSelesai != null) {
      return TugasStatus.Selesai;
    } else if (waktuTiba != null) {
      return TugasStatus.SedangBerjalan;
    } else {
      return TugasStatus.Ready;
    }
  }

  // Helper untuk mendapatkan String status
  String get statusString {
    switch (status) {
      case TugasStatus.Selesai:
        return 'Selesai';
      case TugasStatus.SedangBerjalan:
        return 'Sedang Berjalan';
      case TugasStatus.Ready:
        return 'Ready';
    }
  }

  // Helper untuk mendapatkan warna status
  Color get statusColor {
    switch (status) {
      case TugasStatus.Selesai:
        return Colors.green; // Selesai (Hijau)
      case TugasStatus.SedangBerjalan:
        return Colors.orange; // Sedang Berjalan (Oranye)
      case TugasStatus.Ready:
        return Colors.blue; // Ready (Biru)
    }
  }

  // Helper untuk format tanggal di card
  String get waktuDisplayString {
    final DateFormat formatter = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    if (status == TugasStatus.Selesai && waktuSelesai != null) {
      return 'Selesai ${formatter.format(waktuSelesai!)} WIB';
    } else if (status == TugasStatus.SedangBerjalan && waktuTiba != null) {
      return 'Tiba ${formatter.format(waktuTiba!)} WIB';
    } else if (waktuDisposisi != null) {
      return 'Disposisi ${formatter.format(waktuDisposisi!)} WIB';
    }
    return 'Menunggu data waktu';
  }
}

// ---------------------------------------------------
// SCREEN UTAMA
// ---------------------------------------------------
class DaftarTugasScreen extends StatelessWidget {
  // Ini adalah key/route yang bisa dipanggil dari home.dart
  static const String routeName = '/daftar-tugas';

  const DaftarTugasScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Tugas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFC00A0A), // Warna merah header
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Logika notifikasi
            },
          ),
        ],
      ),
      body: const DaftarTugasPage(),
      // TODO: Anda bisa tambahkan BottomNavigationBar di sini jika perlu
    );
  }
}

// ---------------------------------------------------
// ISI HALAMAN (STATEFUL)
// ---------------------------------------------------
class DaftarTugasPage extends StatefulWidget {
  const DaftarTugasPage({Key? key}) : super(key: key);

  @override
  _DaftarTugasPageState createState() => _DaftarTugasPageState();
}

class _DaftarTugasPageState extends State<DaftarTugasPage> {
  String _selectedFilter = 'Minggu ini'; // Filter aktif
  late Future<List<Tugas>> _futureTugas;
  List<Tugas> _semuaTugas = [];
  List<Tugas> _filteredTugas = [];

  @override
  void initState() {
    super.initState();
    // Panggil API saat halaman dimuat
    _futureTugas = _fetchTugas();
  }

  // ---------------------------------------------------
  // SERVICE API (Pemanggilan ke API)
  // ---------------------------------------------------
  Future<List<Tugas>> _fetchTugas() async {
    // GANTI 'localhost:5000' dengan IP Anda jika testing di HP
    const String url =
        'http://localhost:5000/api/tugas'; // 10.0.2.2 untuk emulator Android
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        _semuaTugas = jsonResponse.map((data) => Tugas.fromJson(data)).toList();
        _applyFilter(); // Terapkan filter awal
        return _filteredTugas;
      } else {
        throw Exception(
          'Gagal memuat tugas (Status code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  // ---------------------------------------------------
  // LOGIKA FILTER
  // ---------------------------------------------------
  void _applyFilter() {
    final now = DateTime.now();
    setState(() {
      switch (_selectedFilter) {
        case 'Hari ini':
          _filteredTugas = _semuaTugas.where((t) {
            final tgl = t.waktuSelesai ?? t.waktuTiba ?? t.waktuDisposisi;
            return tgl != null &&
                tgl.day == now.day &&
                tgl.month == now.month &&
                tgl.year == now.year;
          }).toList();
          break;
        case 'Minggu ini':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          _filteredTugas = _semuaTugas.where((t) {
            final tgl = t.waktuSelesai ?? t.waktuTiba ?? t.waktuDisposisi;
            return tgl != null && tgl.isAfter(startOfWeek);
          }).toList();
          break;
        case 'Bulan ini':
          _filteredTugas = _semuaTugas.where((t) {
            final tgl = t.waktuSelesai ?? t.waktuTiba ?? t.waktuDisposisi;
            return tgl != null &&
                tgl.month == now.month &&
                tgl.year == now.year;
          }).toList();
          break;
        case 'Semua':
        default:
          _filteredTugas = List.from(_semuaTugas); // Salin semua
          break;
      }
    });
  }

  // ---------------------------------------------------
  // WIDGET UI
  // ---------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: FutureBuilder<List<Tugas>>(
            future: _futureTugas,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || _filteredTugas.isEmpty) {
                return const Center(child: Text('Tidak ada riwayat tugas.'));
              }

              // Jika data ada, tampilkan list
              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _filteredTugas.length,
                itemBuilder: (context, index) {
                  return _buildTugasCard(_filteredTugas[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget untuk Filter Bar (Hari ini, Minggu ini, dll.)
  Widget _buildFilterBar() {
    final List<String> filters = [
      'Hari ini',
      'Minggu ini',
      'Bulan ini',
      'Semua',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: filters.map((filter) {
          bool isSelected = _selectedFilter == filter;
          return ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedFilter = filter;
                  _applyFilter(); // Panggil filter saat chip dipilih
                });
              }
            },
            selectedColor: const Color(0xFFC00A0A), // Warna merah
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
            ),
            backgroundColor: Colors.grey[200],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Widget untuk satu Card Tugas
  Widget _buildTugasCard(Tugas tugas) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Laporan #${tugas.laporanId}', // Data dummy
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                _buildStatusChip(tugas.statusString, tugas.statusColor),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Jenis Kejadian', tugas.jenisKejadian), // Data dummy
            const SizedBox(height: 4),
            _buildInfoRow('Alamat', tugas.alamat), // Data dummy
            const SizedBox(height: 12),
            Text(
              tugas.waktuDisplayString, // Data dari API
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Helper untuk baris info (Jenis Kejadian, Alamat)
  Widget _buildInfoRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 14),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }

  // Helper untuk chip status (Selesai, Sedang Berjalan, Ready)
  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
