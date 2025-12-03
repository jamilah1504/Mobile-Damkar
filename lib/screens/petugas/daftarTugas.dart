import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Pastikan path import ini sesuai dengan struktur folder Anda
import '../../methods/api.dart'; 
import '../../models/petugas/riwayat_model.dart'; // Sesuaikan jika lokasi model berbeda
import 'detail_riwayat_screen.dart'; 

class DaftarTugas extends StatefulWidget {
  const DaftarTugas({Key? key}) : super(key: key);

  @override
  State<DaftarTugas> createState() => _DaftarTugasState();
}

class _DaftarTugasState extends State<DaftarTugas> {
  late Future<List<RiwayatTugas>> _futureRiwayat;
  final ApiService _apiService = ApiService();

  // 1. Variabel untuk Filter
  String _selectedFilter = 'Semua'; 
  final List<String> _filterOptions = ['Hari ini', 'Minggu ini', 'Bulan ini', 'Semua'];

  @override
  void initState() {
    super.initState();
    _futureRiwayat = _apiService.getRiwayatTugas();
  }

  Future<void> _refreshData() async {
    setState(() {
      _futureRiwayat = _apiService.getRiwayatTugas();
    });
  }

  // 2. Logika Filtering Data
  List<RiwayatTugas> _applyFilter(List<RiwayatTugas> data) {
    DateTime now = DateTime.now();
    
    if (_selectedFilter == 'Hari ini') {
      return data.where((tugas) {
        return tugas.waktuKejadian.year == now.year &&
               tugas.waktuKejadian.month == now.month &&
               tugas.waktuKejadian.day == now.day;
      }).toList();
    } 
    else if (_selectedFilter == 'Minggu ini') {
      DateTime oneWeekAgo = now.subtract(const Duration(days: 7));
      return data.where((tugas) {
        return tugas.waktuKejadian.isAfter(oneWeekAgo) && 
               tugas.waktuKejadian.isBefore(now.add(const Duration(days: 1)));
      }).toList();
    } 
    else if (_selectedFilter == 'Bulan ini') {
      return data.where((tugas) {
        return tugas.waktuKejadian.year == now.year &&
               tugas.waktuKejadian.month == now.month;
      }).toList();
    }
    // Jika 'Semua', kembalikan data asli
    return data;
  }

  // 3. Fungsi Menentukan Warna Status Secara Dinamis
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Colors.green;
      case 'penanganan':
      case 'diproses':
        return Colors.orange;
      case 'investigasi':
      case 'menunggu verifikasi':
        return Colors.blue;
      case 'ditolak':
      case 'batal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Riwayat Tugas", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none))
        ],
      ),
      body: Column(
        children: [
          // Bagian Tombol Filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((filter) {
                  bool isActive = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.black87,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isActive,
                      selectedColor: const Color(0xFFD32F2F),
                      backgroundColor: Colors.grey[200],
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Bagian List Data
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: FutureBuilder<List<RiwayatTugas>>(
                future: _futureRiwayat,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("Belum ada riwayat tugas."));
                  }

                  // Terapkan Filter
                  final originalList = snapshot.data!;
                  final filteredList = _applyFilter(originalList);

                  if (filteredList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history, size: 50, color: Colors.grey),
                          const SizedBox(height: 10),
                          Text("Tidak ada data untuk filter '$_selectedFilter'", style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final tugas = filteredList[index];
                      return _buildTaskCard(tugas);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(RiwayatTugas tugas) {
    // Format tanggal
    final String formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(tugas.waktuKejadian);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailRiwayatScreen(data: tugas),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Laporan #${tugas.tugasId}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  // Badge Status Dinamis
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(tugas.status), // Warna sesuai status
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tugas.status, // Teks sesuai status database
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 10, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Jenis Kejadian : ${tugas.jenisKejadian}",
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                "Lokasi : ${tugas.latitude}, ${tugas.longitude}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                "Waktu: $formattedDate WIB",
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}