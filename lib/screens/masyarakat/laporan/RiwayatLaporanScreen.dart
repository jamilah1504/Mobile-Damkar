// Lokasi: screens/riwayat_laporan_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Import yang diperlukan
import '../../../methods/api.dart';
import '../../../models/laporan.dart';
import 'DetailLaporanScreen.dart'; // Asumsikan halaman detail ada

class RiwayatLaporanScreen extends StatefulWidget {
  const RiwayatLaporanScreen({super.key});

  @override
  _RiwayatLaporanScreenState createState() => _RiwayatLaporanScreenState();
}

class _RiwayatLaporanScreenState extends State<RiwayatLaporanScreen> {
  final ApiService _apiService = ApiService();
  List<Laporan> allReports = [];
  List<Laporan> filtered = [];
  bool loading = true;
  String? error;

  // Filter
  String filterJenis = '';
  String filterTanggal = '';
  String filterStatus = '';

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
  }

  // Fungsi yang mengambil userId dan memanggil API
  Future<void> _loadUserAndData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final userId = prefs.getInt('userId');

      if (token == null || userId == null) {
        setState(() {
          error = 'Silakan login terlebih dahulu.';
          loading = false;
        });
        return;
      }

      // Pemanggilan API dengan userId
      final reports = await _apiService.getRiwayatLaporan(userId);

      setState(() {
        allReports = reports;
        filtered = reports;
        loading = false;
      });
    } catch (e) {
      // 🎯 PERBAIKAN: Menangkap error dari ApiService
      setState(() {
        // Menghilangkan awalan 'Exception:' untuk pesan yang lebih bersih di UI
        error = e.toString().contains('Exception:')
            ? e.toString().substring(e.toString().indexOf(':') + 1).trim()
            : 'Terjadi kesalahan saat memuat data riwayat.';
        loading = false;
      });
    }
  }

  void _applyFilter() {
    var temp = allReports;

    if (filterJenis.isNotEmpty) {
      temp = temp
          .where(
            (l) => l.jenisKejadian.toLowerCase().contains(
              filterJenis.toLowerCase(),
            ),
          )
          .toList();
    }

    if (filterTanggal.isNotEmpty) {
      temp = temp
          .where(
            (l) =>
                DateFormat('yyyy-MM-dd').format(l.timestampDibuat) ==
                filterTanggal,
          )
          .toList();
    }

    if (filterStatus.isNotEmpty) {
      temp = temp.where((l) => l.status == filterStatus).toList();
    }

    setState(() => filtered = temp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Riwayat Laporan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: loading
          ? Center(
              child: CircularProgressIndicator(color: const Color(0xFFF7941D)),
            )
          : error != null
          ? _buildError()
          : _buildMainContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUserAndData,
            child: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF7941D),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    // Menghilangkan Row/Expanded jika Anda tidak menggunakan layout desktop
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter section (disimpan di kolom atas)
          _buildFilterCard(),
          const SizedBox(height: 16),
          // List Section (di-expand agar mengisi sisa ruang)
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  // Catatan: _buildFilterCard diubah menjadi widget mandiri (bukan di Row)
  Widget _buildFilterCard() {
    // ... (Implementasi _buildFilterCard, _buildTextField, _buildDateField, _buildStatusDropdown) ...
    // Saya asumsikan Anda ingin filter tetap ada dan berfungsi.
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Laporan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              'Jenis Kejadian',
              (v) => setState(() => filterJenis = v),
              filterJenis,
            ),
            const SizedBox(height: 16),
            _buildDateField(),
            const SizedBox(height: 16),
            _buildStatusDropdown(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {
                filterJenis = filterTanggal = filterStatus = '';
                filtered = allReports;
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF7941D),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Reset Filter',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    Function(String) onChanged,
    String value,
  ) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onChanged: (v) {
        onChanged(v);
        _applyFilter();
      },
    );
  }

  Widget _buildDateField() {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Tanggal',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
        suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFFF7941D)),
      ),
      controller: TextEditingController(
        text: filterTanggal.isEmpty ? '' : filterTanggal,
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() {
            filterTanggal = DateFormat('yyyy-MM-dd').format(date);
            _applyFilter();
          });
        }
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: filterStatus.isEmpty ? null : filterStatus,
      decoration: InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items:
          [
                'Semua Status',
                'Menunggu Verifikasi',
                'Diproses',
                'Selesai',
                'Ditolak',
              ]
              .map(
                (s) => DropdownMenuItem(
                  value: s == 'Semua Status' ? '' : s,
                  child: Text(s),
                ),
              )
              .toList(),
      onChanged: (v) {
        setState(() {
          filterStatus = v ?? '';
          _applyFilter();
        });
      },
    );
  }

  Widget _buildList() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hasil Riwayat',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Chip(
              label: Text(
                '${filtered.length} Laporan',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFFF7941D),
              labelStyle: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Menggunakan Expanded di sini untuk List
        Expanded(
          child: filtered.isEmpty ? _buildEmptyState() : _buildLaporanList(),
        ),
      ],
    );
  }

  Widget _buildLaporanList() {
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, i) => _buildLaporanCard(filtered[i]),
    );
  }

  Widget _buildLaporanCard(Laporan l) {
    final statusConfig = _getStatusConfig(l.status);
    final imageUrls = l.dokumentasi.take(2).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    l.jenisKejadian,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: const Color(0xFFF7941D),
                ),
                Chip(
                  label: Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(l.timestampDibuat),
                  ),
                  backgroundColor: Colors.grey.shade700,
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: imageUrls.isNotEmpty
                  ? imageUrls
                        .map(
                          (url) => Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  _showImage('http://localhost:5000$url'),
                              child: Container(
                                height: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      'http://localhost:5000$url',
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList()
                  : [
                      1,
                      2,
                    ].map((_) => Expanded(child: _placeholderFoto())).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.alamatKejadian ?? 'Lokasi GPS',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 6),
                      Chip(
                        label: Text(
                          statusConfig['label'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: statusConfig['color'],
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (l.latitude != null)
                      ElevatedButton.icon(
                        onPressed: () => _openMap(l.latitude!, l.longitude!),
                        icon: const Icon(Icons.location_on, size: 16),
                        label: const Text('Peta'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF7941D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailLaporanScreen(laporan: l),
                        ),
                      ),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Detail'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF7941D),
                        side: const BorderSide(color: Color(0xFFF7941D)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderFoto() {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'Tidak ada foto',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            const Text(
              'Belum Ada Laporan',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Laporan pertama Anda akan muncul di sini setelah dikirim.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'Selesai':
        return {'label': 'Selesai', 'color': Colors.green[600]};
      case 'Ditolak':
        return {'label': 'Ditolak', 'color': Colors.red[600]};
      case 'Diproses':
        return {'label': 'Diproses', 'color': Colors.orange[700]};
      default:
        return {'label': 'Menunggu', 'color': Colors.blue[600]};
    }
  }

  void _openMap(double lat, double lng) async {
    final url = 'http://maps.google.com/?q=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback jika tidak bisa membuka map
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak dapat membuka peta untuk koordinat $lat, $lng'),
        ),
      );
    }
  }

  void _showImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
