import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../../../models/laporan.dart'; // Pastikan path ini benar
import 'DetailLaporanScreen.dart'; 
import 'package:flutter/foundation.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:convert';

// --- WIDGET VIDEO PLAYER ---
class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  Future<void> initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoPlayerController.initialize();
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: true,
          looping: false,
          aspectRatio: _videoPlayerController.value.aspectRatio,
          errorBuilder: (context, errorMessage) {
            return Center(child: Text(errorMessage, style: const TextStyle(color: Colors.white)));
          },
        );
      });
    } catch (e) {
      debugPrint("Error Video: $e");
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white),
      body: Center(
        child: _chewieController != null && _videoPlayerController.value.isInitialized
            ? Chewie(controller: _chewieController!)
            : const CircularProgressIndicator(),
      ),
    );
  }
}

// --- SCREEN UTAMA ---
class RiwayatLaporan extends StatefulWidget {
  const RiwayatLaporan({super.key});

  @override
  State<RiwayatLaporan> createState() => _RiwayatLaporanState();
}

class _RiwayatLaporanState extends State<RiwayatLaporan> {
  // CONFIG BASE URL
  final String _baseUrl = kIsWeb
      ? 'http://localhost:5000' 
      : 'http://10.0.2.2:5000'; // IP Emulator Android Studio

  final Dio _dio = Dio();

  List<Laporan> _allReports = [];
  List<Laporan> _filteredReports = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _userId = 0; 
  
  final TextEditingController _filterJenisController = TextEditingController();
  final TextEditingController _filterTanggalController = TextEditingController();
  String _filterStatus = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // --- FUNGSI PENTING: MEMBERSIHKAN URL GAMBAR ---
  String _getCleanImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Hapus 'uploads/' di depan jika ada, biar gak double saat digabung _baseUrl
    String cleanPath = path.replaceAll(RegExp(r'^/?uploads/'), '');
    return '$_baseUrl/uploads/$cleanPath';
  }

  Future<void> _loadUserData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('userId'); 

      debugPrint("USER ID DARI SHARED PREF: $userId"); // Cek Log ini di Terminal

      if (userId == null) {
        throw Exception("User ID belum tersimpan (Mungkin belum login?)");
      }

      if (mounted) {
        setState(() {
          _userId = userId; 
        });
      }
      await _fetchReports();

    } catch (e) {
      debugPrint("Gagal memuat data pengguna: $e"); 
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Gagal memuat profil user. Silakan Login ulang.";
        });
      }
    }
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
  
    try {
      debugPrint('Fetching data from: $_baseUrl/api/reports');

      final response = await _dio.get('$_baseUrl/api/reports');
      
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        
        // --- BAGIAN DEBUGGING (SUDAH BENAR POSISINYA) ---
        if (data.isNotEmpty) {
           debugPrint("🔥 DATA JSON DARI SERVER (ITEM PERTAMA): 🔥");
           
           // REVISI DIKIT: Pakai 'jsonEncode' biar formatnya jadi JSON string asli
           // Jadi kamu bisa lihat jelas ada key "insiden" atau tidak
           debugPrint(jsonEncode(data[0])); 
        }
        // ------------------------------------------------

        // Filter laporan milik user ini saja
        List<Laporan> userReports = data
            .map((json) => Laporan.fromJson(json))
            .where((l) => l.pelaporId == _userId)
            .toList();

        // Urutkan terbaru
        userReports.sort((a, b) => b.timestampDibuat.compareTo(a.timestampDibuat));
        
        debugPrint("Jumlah Laporan Ditemukan: ${userReports.length}");

        setState(() {
          _allReports = userReports;
          _filteredReports = userReports;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error Fetching: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal koneksi ke server.\nCek apakah backend nyala & URL benar.';
      });
    }
}

  void _applyFilter() {
    List<Laporan> temp = _allReports;

    if (_filterJenisController.text.isNotEmpty) {
      temp = temp.where((l) => l.jenisKejadian
          .toLowerCase()
          .contains(_filterJenisController.text.toLowerCase())).toList();
    }

    if (_filterTanggalController.text.isNotEmpty) {
      temp = temp.where((l) {
        String dateOnly = l.timestampDibuat.split('T')[0];
        return dateOnly == _filterTanggalController.text;
      }).toList();
    }

    if (_filterStatus.isNotEmpty) {
      temp = temp.where((l) => l.status == _filterStatus).toList();
    }

    setState(() {
      _filteredReports = temp;
    });
  }

  void _resetFilter() {
    _filterJenisController.clear();
    _filterTanggalController.clear();
    setState(() {
      _filterStatus = '';
      _filteredReports = _allReports;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Selesai': return Colors.green;
      case 'Ditolak': return Colors.red;
      case 'Diproses': return Colors.orange;
      case 'Menunggu Verifikasi': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _formatDate(String rawDate) {
    try {
      DateTime dt = DateTime.parse(rawDate);
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (e) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.red.shade800,
        title: const Text('Riwayat Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              label: Text('${_filteredReports.length} Laporan', 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.red.shade800,
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData, // Refresh memuat ulang user & data
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),

                    // --- FILTER SECTION ---
                    Card(
                      elevation: 2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Filter Laporan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            
                            TextField(
                              controller: _filterJenisController,
                              decoration: const InputDecoration(
                                labelText: 'Jenis Kejadian',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => _applyFilter(),
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: _filterTanggalController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Tanggal',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                                isDense: true,
                              ),
                              onTap: () async {
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (pickedDate != null) {
                                  String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                                  _filterTanggalController.text = formattedDate;
                                  _applyFilter();
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            DropdownButtonFormField<String>(
                              value: _filterStatus.isEmpty ? null : _filterStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(value: '', child: Text('Semua Status')),
                                DropdownMenuItem(value: 'Menunggu Verifikasi', child: Text('Menunggu Verifikasi')),
                                DropdownMenuItem(value: 'Diproses', child: Text('Diproses')),
                                DropdownMenuItem(value: 'Selesai', child: Text('Selesai')),
                                DropdownMenuItem(value: 'Ditolak', child: Text('Ditolak')),
                              ],
                              onChanged: (val) {
                                setState(() => _filterStatus = val ?? '');
                                _applyFilter();
                              },
                            ),
                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _resetFilter,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Reset Filter'),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- LIST DATA ---
                    _filteredReports.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _filteredReports.length,
                            itemBuilder: (context, index) {
                              final laporan = _filteredReports[index];
                              return _buildLaporanCard(laporan);
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLaporanCard(Laporan laporan) {
    Color statusColor = _getStatusColor(laporan.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
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
                  label: Text(laporan.jenisKejadian),
                  backgroundColor: const Color(0xFFDC2626),
                  labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Chip(
                  avatar: const Icon(Icons.calendar_today, size: 16, color: Colors.white),
                  label: Text(_formatDate(laporan.timestampDibuat)),
                  backgroundColor: Colors.grey[700],
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // --- BAGIAN GAMBAR/VIDEO DIPERBAIKI ---
            if (laporan.dokumentasi.isNotEmpty)
              SizedBox(
                height: 140,
                child: Row(
                  children: laporan.dokumentasi.take(2).map((doc) {
                    
                    // PAKAI FUNGSI CLEANER DI SINI
                    String fullUrl = _getCleanImageUrl(doc.fileUrl);
                    bool isVideo = doc.tipeFile.toLowerCase() == 'video';

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (isVideo) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerScreen(videoUrl: fullUrl),
                              ),
                            );
                          }
                          // Print URL untuk debug
                          debugPrint("Mencoba buka media: $fullUrl");
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black12,
                          ),
                          child: ClipRRect( // Agar gambar tidak keluar border
                            borderRadius: BorderRadius.circular(8),
                            child: isVideo
                                ? Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(color: Colors.black54),
                                      const Icon(Icons.play_circle_fill, color: Colors.white, size: 48),
                                      const Positioned(
                                        bottom: 8, right: 8,
                                        child: Text("VIDEO", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      )
                                    ],
                                  )
                                : Image.network(
                                    fullUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    // Handle Error Gambar
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(child: CircularProgressIndicator(strokeWidth: 2));
                                    },
                                  ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )
            else
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('Tidak ada foto', style: TextStyle(color: Colors.grey))),
              ),
            
            const SizedBox(height: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  laporan.alamatKejadian ?? 'Lokasi GPS',
                  style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(laporan.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (laporan.latitude != null && laporan.longitude != null)
                      TextButton.icon(
                        onPressed: () async {
                          final Uri googleMapsUrl = Uri.parse(
                              "https://www.google.com/maps/search/?api=1&query=${laporan.latitude},${laporan.longitude}");
                          if (await canLaunchUrl(googleMapsUrl)) {
                            await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.location_on),
                        label: const Text('Peta'),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                      ),
                    const SizedBox(width: 8),
                    
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailLaporanScreen(laporan: laporan),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Detail'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFDC2626)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Laporan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Laporan pertama Anda akan muncul di sini setelah dikirim.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          // Tambahan: Tombol Refresh manual
          ElevatedButton(
             onPressed: _loadUserData,
             child: const Text("Coba Refresh"),
          )
        ],
      ),
    );
  }
}