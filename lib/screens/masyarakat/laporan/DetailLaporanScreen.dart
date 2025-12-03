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

  // --- 1. MEMBERSIHKAN URL GAMBAR ---
  String _getCleanImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    String cleanPath = path.replaceAll(RegExp(r'^/?uploads/'), '');
    return '$_baseUrl/uploads/$cleanPath';
  }

  // --- 2. FORMAT TANGGAL ---
  String _formatDate(String rawDate) {
    try {
      DateTime dt = DateTime.parse(rawDate);
      return DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (e) {
      return rawDate;
    }
  }

  // --- 3. FORMAT RUPIAH (BARU) ---
  String _formatRupiah(dynamic number) {
    if (number == null) return 'Rp 0';
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID', 
      symbol: 'Rp ', 
      decimalDigits: 0
    );
    return currencyFormatter.format(number);
  }

  // --- 4. HELPER AMBIL LAPORAN LAPANGAN (FINAL) ---
  Map<String, dynamic>? _getLaporanLapangan() {
    try {
      final dynamic insidenObj = laporan.insiden;
      if (insidenObj == null) return null;

      final Map<String, dynamic> insidenMap = Map<String, dynamic>.from(insidenObj as Map);
      
      // Cek Tugas
      final dynamic tugasObj = insidenMap['tugas'] ?? insidenMap['Tugas'];
      if (tugasObj == null) return null;

      // Handle Tugas sebagai List atau Object
      Map<String, dynamic> tugasItem;
      if (tugasObj is List) {
        if (tugasObj.isEmpty) return null;
        tugasItem = Map<String, dynamic>.from(tugasObj[0]);
      } else if (tugasObj is Map) {
        tugasItem = Map<String, dynamic>.from(tugasObj);
      } else {
        return null;
      }

      // Ambil Laporan Lapangan
      final lapLap = tugasItem['laporanLapangan'] ?? tugasItem['LaporanLapangan'];
      if (lapLap != null) {
        return Map<String, dynamic>.from(lapLap);
      }
      return null;
    } catch (e) {
      debugPrint("Error parsing Laporan Lapangan: $e");
      return null;
    }
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
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // === BAGIAN 1: INFO UTAMA (Sama seperti Web Kolom Kiri) ===
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      laporan.jenisKejadian,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(_formatDate(laporan.timestampDibuat), style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      ],
                    ),
                    const Divider(height: 30),

                    _buildSectionTitle(Icons.description, "Deskripsi"),
                    const SizedBox(height: 6),
                    Text(
                      laporan.deskripsi,
                      style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 20),

                    _buildSectionTitle(Icons.location_on, "Lokasi"),
                    const SizedBox(height: 6),
                    Text(laporan.alamatKejadian ?? 'Lokasi GPS', style: const TextStyle(fontSize: 15)),
                    
                    if (laporan.latitude != null && laporan.longitude != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${laporan.latitude},${laporan.longitude}");
                              if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                            },
                            icon: const Icon(Icons.map, size: 18),
                            label: const Text("Lihat di Google Maps"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade800,
                              side: BorderSide(color: Colors.red.shade800),
                              padding: const EdgeInsets.symmetric(vertical: 10)
                            ),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    _buildSectionTitle(Icons.info_outline, "Status Terkini"),
                    const SizedBox(height: 8),
                    _buildStatusChip(laporan.status),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // === BAGIAN 2: DETAIL TERKAIT (Pelapor & Insiden) ===
            // Meniru "Informasi Tambahan" di Web
            if (laporan.pelapor != null || laporan.insiden != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Informasi Tambahan", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      // Info Pelapor
                      if (laporan.pelapor != null)
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.blue.shade50,
                              child: Icon(Icons.person, color: Colors.blue.shade800, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("PELAPOR", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                                Text(
                                  laporan.pelapor!['name'] ?? 'User',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            )
                          ],
                        ),
                      
                      if (laporan.pelapor != null && laporan.insiden != null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(),
                        ),

                      // Info Insiden (Dari Backend 'insiden')
                      if (laporan.insiden != null)
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.orange.shade50,
                              child: Icon(Icons.local_fire_department, color: Colors.orange.shade800, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded( 
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("INSIDEN TERKAIT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                                  Text(
                                    laporan.insiden!['statusInsiden'] ?? '-',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Text(
                                    laporan.insiden!['judulInsiden'] ?? '',
                                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // === BAGIAN 3: LAPORAN LAPANGAN (HASIL PENANGANAN) ===
            // Style mirip Web: Hijau jika ada, Oranye jika kosong
            Card(
              elevation: 2,
              color: hasLaporanLapangan ? const Color(0xFFF1F8E9) : const Color(0xFFFFF8E1), // Hijau Muda vs Oranye Muda
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: hasLaporanLapangan ? Colors.green.shade300 : Colors.orange.shade300,
                  width: 1
                )
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasLaporanLapangan ? Icons.check_circle : Icons.warning_amber_rounded,
                          color: hasLaporanLapangan ? Colors.green[800] : Colors.orange[800],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hasLaporanLapangan ? "Laporan Lapangan (Selesai)" : "Belum Ada Laporan Lapangan",
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold,
                              color: hasLaporanLapangan ? Colors.green[900] : Colors.orange[900]
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (hasLaporanLapangan) ...[
                      // Gunakan Divider putus-putus
                      _buildDashedDivider(),
                      _buildResultItem("Jumlah Korban", "${laporanLapangan!['jumlahKorban'] ?? 0} orang"),
                      _buildDashedDivider(),
                      _buildResultItem("Estimasi Kerugian", _formatRupiah(laporanLapangan['estimasiKerugian']), isRed: true),
                      _buildDashedDivider(),
                      _buildResultItem("Dugaan Penyebab", "${laporanLapangan['dugaanPenyebab'] ?? '-'}"),
                      _buildDashedDivider(),
                      _buildResultItem("Catatan Petugas", "${laporanLapangan['catatan'] ?? '-'}", isItalic: true),
                    ] else 
                      Text(
                        "Petugas damkar belum mengisi laporan hasil penanganan di lapangan. Mohon tunggu hingga proses selesai.",
                        style: TextStyle(color: Colors.grey[800], height: 1.4),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // === BAGIAN 4: DOKUMENTASI ===
            if (laporan.dokumentasi.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Dokumentasi Bukti", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
                ),
                itemCount: laporan.dokumentasi.length,
                itemBuilder: (context, index) {
                  final doc = laporan.dokumentasi[index];
                  final fullUrl = _getCleanImageUrl(doc.fileUrl);
                  final isVideo = doc.tipeFile.toLowerCase() == 'video';

                  return GestureDetector(
                    onTap: () {
                      if (isVideo) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoUrl: fullUrl)),
                        );
                      } else {
                        showDialog(context: context, builder: (_) => Dialog(
                          child: InteractiveViewer(
                            child: Image.network(
                              fullUrl,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                            ),
                          )
                        ));
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                        border: Border.all(color: Colors.grey.shade300),
                        image: isVideo ? null : DecorationImage(
                          image: NetworkImage(fullUrl),
                          fit: BoxFit.cover,
                          onError: (e, s) => const AssetImage('assets/placeholder.png'),
                        ),
                      ),
                      child: Stack(
                        children: [
                          if (isVideo) 
                            Center(
                              child: Container(
                                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(30)),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
                              ),
                            ),
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                              ),
                              child: Text(
                                doc.tipeFile, 
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        ],
                      ),
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

  // --- WIDGET HELPERS ---

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'Selesai': color = Colors.green; icon = Icons.check_circle; break;
      case 'Ditolak': color = Colors.red; icon = Icons.cancel; break;
      case 'Diproses': color = Colors.orange; icon = Icons.warning; break;
      default: color = Colors.blue; icon = Icons.info;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value, {bool isRed = false, bool isItalic = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(height: 2),
          Text(
            value, 
            style: TextStyle(
              fontSize: 15, 
              color: isRed ? Colors.red[800] : Colors.black87,
              fontWeight: isRed ? FontWeight.bold : FontWeight.normal,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal
            )
          ),
        ],
      ),
    );
  }

  Widget _buildDashedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 6.0;
          final dashHeight = 1.0;
          final dashCount = (boxWidth / (2 * dashWidth)).floor();
          return Flex(
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: dashHeight,
                child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey[300])),
              );
            }),
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
          );
        },
      ),
    );
  }
}

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
          errorBuilder: (context, errorMessage) {
            return Center(child: Text(errorMessage, style: const TextStyle(color: Colors.white)));
          },
        );
      });
    } catch (e) {
      debugPrint("Error loading video: $e");
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