// screens/DetailLaporanScreen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import '../../../models/laporan.dart';
import '../../../models/laporan_lapangan.dart';

class DetailLaporanScreen extends StatefulWidget {
  final Laporan laporan;

  const DetailLaporanScreen({Key? key, required this.laporan})
    : super(key: key);

  @override
  State<DetailLaporanScreen> createState() => _DetailLaporanScreenState();
}

class _DetailLaporanScreenState extends State<DetailLaporanScreen> {
  late Laporan laporan;
  bool loading = true;
  String? error;
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000/api'));

  @override
  void initState() {
    super.initState();
    laporan = widget.laporan;
    _fetchFullLaporan();
  }

  Future<void> _fetchFullLaporan() async {
    try {
      setState(() => loading = true);
      final response = await _dio.get('/reports/${laporan.id}');
      final data = response.data;

      setState(() {
        laporan = Laporan.fromJson(data);
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e is DioException
            ? e.response?.data['message'] ?? 'Gagal memuat detail'
            : 'Terjadi kesalahan';
        loading = false;
      });
    }
  }

  String _formatDate(dynamic iso) {
    final date = iso is String ? DateTime.parse(iso) : iso as DateTime;
    return DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(date);
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'Selesai':
        return {
          'label': 'Selesai',
          'color': Colors.green,
          'icon': Icons.check_circle,
        };
      case 'Ditolak':
        return {'label': 'Ditolak', 'color': Colors.red, 'icon': Icons.cancel};
      case 'Diproses':
        return {
          'label': 'Diproses',
          'color': Colors.orange,
          'icon': Icons.warning,
        };
      default:
        return {'label': 'Menunggu', 'color': Colors.blue, 'icon': Icons.info};
    }
  }

  void _openMap(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  void _openImage(String url) async {
    final fullUrl = 'http://localhost:5000$url';
    if (await canLaunch(fullUrl)) {
      await launch(fullUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF7941D)),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 60, color: Colors.red),
              SizedBox(height: 16),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back),
                label: Text('Kembali'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF7941D),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final statusConfig = _getStatusConfig(laporan.status);
    final laporanLapangan = laporan.laporanLapangan;

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Laporan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Main Grid: 8:4
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return GridView.count(
                  crossAxisCount: isWide ? 2 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 2.2 : 2.8,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    // Kiri: Detail Utama
                    _buildMainCard(statusConfig),
                    // Kanan: Laporan Lapangan
                    _buildLaporanLapanganCard(laporanLapangan),
                  ],
                );
              },
            ),

            // Dokumentasi
            if (laporan.dokumentasi.isNotEmpty) ...[
              SizedBox(height: 24),
              Text(
                'Dokumentasi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600
                      ? 4
                      : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: laporan.dokumentasi.length,
                itemBuilder: (context, i) {
                  final doc = laporan.dokumentasi[i];
                  return GestureDetector(
                    onTap: () => _openImage(doc),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Image.network(
                              'http://localhost:5000$doc',
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                color: Colors.black54,
                                child: Text(
                                  'Bukti ${i + 1}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(Map<String, dynamic> statusConfig) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul + Tanggal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    laporan.jenisKejadian,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF7941D),
                    ),
                  ),
                ),
                Chip(
                  avatar: Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _formatDate(laporan.timestampDibuat),
                    style: TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.grey[100],
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(height: 1),
            SizedBox(height: 16),

            // Deskripsi
            _buildSection(
              'Deskripsi',
              laporan.deskripsi.isNotEmpty
                  ? laporan.deskripsi
                  : 'Tidak ada deskripsi.',
            ),

            // Lokasi
            _buildSection(
              'Lokasi',
              laporan.alamatKejadian ?? 'Lokasi GPS',
              icon: Icons.location_on,
              action: laporan.latitude != null
                  ? ElevatedButton.icon(
                      onPressed: () =>
                          _openMap(laporan.latitude!, laporan.longitude!),
                      icon: Icon(Icons.map, size: 16),
                      label: Text('Buka Peta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFF7941D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  : null,
            ),

            // Status
            _buildSection(
              'Status',
              null,
              child: Chip(
                avatar: Icon(
                  statusConfig['icon'],
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  statusConfig['label'],
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: statusConfig['color'],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaporanLapanganCard(LaporanLapangan? lapangan) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: lapangan != null ? Color(0xFFE8F5E9) : Color(0xFFFFF3E0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: lapangan != null ? Colors.green : Colors.orange,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lapangan != null
                  ? 'Hasil Penanganan'
                  : 'Belum Ada Laporan Lapangan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: lapangan != null
                    ? Colors.green[700]
                    : Colors.orange[700],
              ),
            ),
            SizedBox(height: 16),
            if (lapangan != null) ...[
              _buildInfoRow('Korban', '${lapangan.jumlahKorban} orang'),
              if (lapangan.estimasiKerugian != null)
                _buildInfoRow(
                  'Kerugian',
                  'Rp ${lapangan.estimasiKerugian!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                ),
              if (lapangan.dugaanPenyebab != null)
                _buildInfoRow(
                  'Penyebab',
                  '"${lapangan.dugaanPenyebab}"',
                  italic: true,
                ),
              if (lapangan.catatan != null)
                _buildInfoRow('Catatan', '"${lapangan.catatan}"', italic: true),
            ] else
              Text(
                'Petugas belum mengirimkan laporan lapangan.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    String? content, {
    IconData? icon,
    Widget? action,
    Widget? child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Color(0xFFF7941D), size: 20),
              SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SizedBox(height: 8),
        if (content != null)
          Text(content, style: TextStyle(color: Colors.grey[700], height: 1.6)),
        if (child != null) child,
        if (action != null) ...[SizedBox(height: 8), action],
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool italic = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontStyle: italic ? FontStyle.italic : null,
          ),
        ),
        SizedBox(height: 12),
      ],
    );
  }
}
