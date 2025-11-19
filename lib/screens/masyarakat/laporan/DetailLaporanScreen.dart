import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

// Import Model
import '../../../models/laporan.dart'; 

class DetailLaporanScreen extends StatelessWidget {
  final Laporan laporan;

  // URL Base logic
  final String _baseUrl = kIsWeb ? 'http://localhost:5000' : 'http://10.0.2.2:5000';

  DetailLaporanScreen({Key? key, required this.laporan}) : super(key: key);

  // Helper Format Tanggal
  String _formatDate(String rawDate) {
    try {
      DateTime dt = DateTime.parse(rawDate);
      return DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (e) {
      return rawDate;
    }
  }

  // Helper untuk mengambil Laporan Lapangan dari JSON yang bersarang
  Map<String, dynamic>? _getLaporanLapangan() {
    if (laporan.insiden != null && laporan.insiden!['tugas'] != null) {
      List tugas = laporan.insiden!['tugas'];
      if (tugas.isNotEmpty && tugas[0]['laporanLapangan'] != null) {
        return tugas[0]['laporanLapangan'];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final laporanLapangan = _getLaporanLapangan();
    final hasLaporanLapangan = laporanLapangan != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Detail Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // === BAGIAN 1: INFO UTAMA (Kiri di Web) ===
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul & Tanggal
                    Text(
                      laporan.jenisKejadian,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      avatar: const Icon(Icons.calendar_today, size: 16, color: Colors.white),
                      label: Text(_formatDate(laporan.timestampDibuat)),
                      backgroundColor: Colors.grey[700],
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                    const Divider(height: 30),

                    // Deskripsi
                    const Text("Deskripsi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      laporan.deskripsi,
                      style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 20),

                    // Lokasi
                    const Text("Lokasi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.red.shade800),
                        const SizedBox(width: 8),
                        Expanded(child: Text(laporan.alamatKejadian ?? 'Lokasi GPS')),
                      ],
                    ),
                    if (laporan.latitude != null && laporan.longitude != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${laporan.latitude},${laporan.longitude}");
                            if (await canLaunchUrl(url)) await launchUrl(url);
                          },
                          icon: const Icon(Icons.map),
                          label: const Text("Buka Peta"),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade800),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    // Status
                    const Text("Status Laporan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildStatusChip(laporan.status),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // === BAGIAN 2: DETAIL TERKAIT (Kanan Atas di Web) ===
            if (laporan.pelapor != null || laporan.insidenTerkait != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Detail Terkait", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      // Info Pelapor
                      if (laporan.pelapor != null)
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Icon(Icons.person, color: Colors.blue.shade800),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Pelapor", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  laporan.pelapor!['name'] ?? 'User',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            )
                          ],
                        ),
                      
                      if (laporan.pelapor != null && laporan.insidenTerkait != null)
                        const Divider(height: 24),

                      // Info Insiden Terkait
                      if (laporan.insidenTerkait != null)
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.orange.shade100,
                              child: Icon(Icons.local_fire_department, color: Colors.orange.shade800),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Insiden Terkait", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  laporan.insidenTerkait!['statusInsiden'] ?? '-',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  laporan.insidenTerkait!['judulInsiden'] ?? '',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            )
                          ],
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // === BAGIAN 3: LAPORAN LAPANGAN / HASIL PENANGANAN (Kanan Bawah di Web) ===
            Card(
              elevation: 2,
              color: hasLaporanLapangan ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0), // Hijau jika ada, Orange jika belum
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: hasLaporanLapangan ? Colors.green : Colors.orange,
                  width: 1
                )
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasLaporanLapangan ? "Hasil Penanganan" : "Belum Ada Laporan Lapangan",
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: hasLaporanLapangan ? Colors.green.shade800 : Colors.orange.shade900
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (hasLaporanLapangan) ...[
                      _buildFieldInfo("Korban", "${laporanLapangan!['jumlahKorban']} Orang"),
                      if (laporanLapangan['estimasiKerugian'] != null)
                         _buildFieldInfo("Kerugian", "Rp ${NumberFormat('#,###', 'id_ID').format(laporanLapangan['estimasiKerugian'])}"),
                      if (laporanLapangan['dugaanPenyebab'] != null)
                         _buildFieldInfo("Penyebab", "${laporanLapangan['dugaanPenyebab']}"),
                      if (laporanLapangan['catatan'] != null)
                         _buildFieldInfo("Catatan", "${laporanLapangan['catatan']}", isItalic: true),
                    ] else 
                      const Text("Petugas belum mengirimkan laporan lapangan.", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // === BAGIAN 4: DOKUMENTASI (Gambar & Video) ===
            if (laporan.dokumentasi.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Dokumentasi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1, // Kotak
                ),
                itemCount: laporan.dokumentasi.length,
                itemBuilder: (context, index) {
                  final doc = laporan.dokumentasi[index];
                  final fullUrl = '$_baseUrl/uploads/${doc.fileUrl}';
                  final isVideo = doc.tipeFile.toLowerCase() == 'video';

                  return GestureDetector(
                    onTap: () {
                      if (isVideo) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoUrl: fullUrl)),
                        );
                      } else {
                        // Buka gambar full (bisa pakai dialog atau library photo_view)
                        showDialog(context: context, builder: (_) => Dialog(child: Image.network(fullUrl)));
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black12,
                        image: isVideo ? null : DecorationImage(
                          image: NetworkImage(fullUrl),
                          fit: BoxFit.cover,
                          onError: (e, s) => const AssetImage('assets/placeholder.png'),
                        ),
                      ),
                      child: isVideo ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                              child: const Text("VIDEO", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      ) : null,
                    ),
                  );
                },
              )
            ]
          ],
        ),
      ),
    );
  }

  // Helper Widget: Status Chip
  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'Selesai': color = Colors.green; icon = Icons.check_circle; break;
      case 'Ditolak': color = Colors.red; icon = Icons.cancel; break;
      case 'Diproses': color = Colors.orange; icon = Icons.warning; break;
      default: color = Colors.blue; icon = Icons.info;
    }
    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 18),
      label: Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: color,
    );
  }

  // Helper Widget: Field Info Laporan Lapangan
  Widget _buildFieldInfo(String label, String value, {bool isItalic = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(value, style: TextStyle(fontSize: 15, fontStyle: isItalic ? FontStyle.italic : FontStyle.normal)),
        ],
      ),
    );
  }
}

// --- WIDGET VIDEO PLAYER (WAJIB ADA) ---
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
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    await _videoPlayerController.initialize();
    setState(() {
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
      );
    });
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