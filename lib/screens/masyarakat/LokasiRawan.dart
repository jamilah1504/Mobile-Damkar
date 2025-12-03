import 'dart:async';
import 'dart:convert';
import 'dart:io'; 
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ==================== 1. MODEL DATA ====================

class MapItem {
  final int originalId;
  final String type; // 'rawan' atau 'laporan'
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String mediaUrl; // Bisa URL Gambar atau Video
  final bool isVideo;    // Penanda apakah ini video
  final String status;   

  MapItem({
    required this.originalId,
    required this.type,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.mediaUrl,
    required this.isVideo,
    this.status = '',
  });

  String get uniqueId => "$type-$originalId";

  // Helper untuk cek ekstensi video
  static bool _checkIsVideo(String url, String? explicitType) {
    if (explicitType != null && explicitType.toLowerCase() == 'video') return true;
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.mp4') || lowerUrl.endsWith('.mov') || lowerUrl.endsWith('.avi') || lowerUrl.endsWith('.mkv');
  }

  // Factory untuk Lokasi Rawan
  factory MapItem.fromLokasiRawan(Map<String, dynamic> json, String baseUrl) {
    List<String> imgs = [];
    if (json['images'] != null) {
      imgs = List<String>.from(json['images']);
    }
    
    String rawUrl = imgs.isNotEmpty ? imgs[0] : '';
    String fullUrl = rawUrl.startsWith('http') ? rawUrl : (rawUrl.isNotEmpty ? '$baseUrl$rawUrl' : '');
    bool isVid = _checkIsVideo(rawUrl, null);

    return MapItem(
      originalId: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      type: 'rawan',
      title: json['namaLokasi'] ?? 'Lokasi Tanpa Nama',
      description: json['deskripsi'] ?? '-',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      mediaUrl: fullUrl,
      isVideo: isVid,
    );
  }

  // Factory untuk Laporan
  factory MapItem.fromLaporan(Map<String, dynamic> json, String baseUrl) {
    String rawUrl = '';
    String tipeFile = 'Gambar';

    // Ambil file dari array Dokumentasis
    if (json['Dokumentasis'] != null && (json['Dokumentasis'] as List).isNotEmpty) {
      var doc = json['Dokumentasis'][0];
      rawUrl = doc['fileUrl'] ?? '';
      tipeFile = doc['tipeFile'] ?? 'Gambar';
    }

    String fullUrl = rawUrl.startsWith('http') ? rawUrl : (rawUrl.isNotEmpty ? '$baseUrl$rawUrl' : '');
    bool isVid = _checkIsVideo(rawUrl, tipeFile);

    return MapItem(
      originalId: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      type: 'laporan',
      title: json['jenisKejadian'] ?? 'Laporan Kejadian',
      description: json['deskripsi'] ?? '-',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      mediaUrl: fullUrl,
      isVideo: isVid,
      status: json['status'] ?? 'Pending',
    );
  }
}

// ==================== 2. WIDGET UTAMA ====================
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _authToken = "Memuat...";
  
  List<MapItem> mapItems = [];
  bool loading = true;
  String? error;
  
  bool isListOpen = true;
  String? selectedUniqueId; 
  final MapController mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadUserData().then((_) => _fetchAllData());
  }

  Future<void> _loadUserData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? authToken = prefs.getString('authToken');
      if (mounted) {
        setState(() {
          _authToken = authToken ?? ""; 
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat data pengguna: $e");
    }
  }

  Future<void> _fetchAllData() async {
    String baseUrl;
    if (kIsWeb) {
      baseUrl = 'http://localhost:5000';
    } else if (Platform.isAndroid) {
      baseUrl = 'http://10.0.2.2:5000'; 
    } else {
      baseUrl = 'http://localhost:5000';
    }

    final String token = _authToken; 
    final headers = {'Authorization': 'Bearer $token'};

    try {
      setState(() {
        loading = true;
        error = null;
      });

      // Request Parallel
      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/lokasi-rawan'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/reports'), headers: headers), 
      ]);

      final responseRawan = results[0];
      final responseLaporan = results[1];

      List<MapItem> loadedItems = [];

      // Proses Rawan
      if (responseRawan.statusCode == 200) {
        final List<dynamic> dataRawan = json.decode(responseRawan.body);
        loadedItems.addAll(dataRawan.map((json) => MapItem.fromLokasiRawan(json, baseUrl)));
      }

      // Proses Laporan
      if (responseLaporan.statusCode == 200) {
        final dynamic decodedLaporan = json.decode(responseLaporan.body);
        List<dynamic> dataLaporan = [];
        if (decodedLaporan is List) {
          dataLaporan = decodedLaporan;
        } else if (decodedLaporan is Map && decodedLaporan['data'] != null) {
          dataLaporan = decodedLaporan['data'];
        }
        loadedItems.addAll(dataLaporan.map((json) => MapItem.fromLaporan(json, baseUrl)));
      }

      if (mounted) {
        setState(() {
          mapItems = loadedItems;
          loading = false;
        });
        
        if (loadedItems.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            mapController.move(
              LatLng(loadedItems[0].latitude, loadedItems[0].longitude), 
              13.0
            );
          });
        }
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          error = "Gagal memuat data.\n($e)";
          loading = false;
        });
      }
    }
  }

  void _handleMarkerClick(MapItem item) {
    setState(() {
      selectedUniqueId = item.uniqueId;
      isListOpen = true; 
    });
    mapController.move(
      LatLng(item.latitude, item.longitude), 
      16.0
    );
  }

  // --- WIDGET HELPER UNTUK THUMBNAIL (VIDEO/GAMBAR) ---
  Widget _buildMediaThumbnail(String url, bool isVideo, {double size = 60}) {
    if (url.isEmpty) {
      return Container(
        width: size, height: size, color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    if (isVideo) {
      // Tampilan Placeholder Video (Kotak Hitam + Icon Play)
      return Container(
        width: size,
        height: size,
        color: Colors.black87,
        child: Center(
          child: Icon(Icons.play_circle_fill, color: Colors.white, size: size * 0.5),
        ),
      );
    } else {
      // Tampilan Gambar Biasa
      return Image.network(
        url,
        width: size, height: size,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, _) => Container(
          width: size, height: size, color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final initialCenter = const LatLng(-6.9206016, 107.6166656); 

    return Scaffold(
      body: Stack(
        children: [
          // ================= LAYER 1: PETA =================
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 12.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.damkar.app',
              ),
              MarkerLayer(
                markers: mapItems.map((item) {
                  final isSelected = selectedUniqueId == item.uniqueId;
                  final isRawan = item.type == 'rawan';

                  return Marker(
                    point: LatLng(item.latitude, item.longitude),
                    // [PERBAIKAN] Ukuran marker diperbesar agar label teks muat dan tidak overflow
                    width: 80, 
                    height: 80, 
                    child: GestureDetector(
                      onTap: () => _handleMarkerClick(item),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min, // Agar column menyesuaikan isi
                        children: [
                          // Label melayang (Hanya muncul jika dipilih)
                          if (isSelected)
                            Flexible(
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: const [BoxShadow(blurRadius: 2)],
                                ),
                                child: Text(
                                  item.title,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          // Icon Marker
                          Icon(
                            isRawan ? Icons.location_on : Icons.report_problem, 
                            color: isRawan 
                                ? (isSelected ? Colors.red : Colors.red.withOpacity(0.8)) 
                                : (isSelected ? Colors.orange[900] : Colors.orange), 
                            size: isSelected ? 45 : 35,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ================= LAYER 2: LOADING / ERROR =================
          if (loading)
             const Center(child: CircularProgressIndicator())
          else if (error != null)
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    Text(error!),
                    ElevatedButton(onPressed: _fetchAllData, child: const Text("Retry"))
                  ],
                ),
              ),
            ),

          // ================= LAYER 3: TOMBOL BUKA LIST =================
          if (!isListOpen && !loading && error == null)
            Positioned(
              bottom: 30,
              left: 0, right: 0,
              child: Center(
                child: FloatingActionButton.extended(
                  onPressed: () => setState(() => isListOpen = true),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  icon: const Icon(Icons.format_list_bulleted),
                  label: const Text("Lihat Data"),
                ),
              ),
            ),

          // ================= LAYER 4: LIST CARD =================
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 16, right: 16,
            bottom: isListOpen ? 20 : -600,
            height: size.height * 0.45,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white.withOpacity(0.96),
              child: Column(
                children: [
                  // HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Data Peta (${mapItems.length})",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down),
                          onPressed: () => setState(() => isListOpen = false),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  
                  // LIST
                  Expanded(
                    child: mapItems.isEmpty
                    ? const Center(child: Text("Tidak ada data."))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: mapItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = mapItems[index];
                          final isSelected = selectedUniqueId == item.uniqueId;
                          final isRawan = item.type == 'rawan';

                          return GestureDetector(
                            onTap: () => _handleMarkerClick(item),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue.shade50 : Colors.white,
                                border: Border.all(
                                  color: isSelected ? Colors.blue : Colors.grey.shade300
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // MEDIA THUMBNAIL (Video / Gambar)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: _buildMediaThumbnail(item.mediaUrl, item.isVideo),
                                  ),
                                  const SizedBox(width: 10),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            // Badge Tipe
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isRawan ? Colors.red[100] : Colors.orange[100],
                                                borderRadius: BorderRadius.circular(4)
                                              ),
                                              child: Text(
                                                isRawan ? "Rawan" : "Laporan",
                                                style: TextStyle(
                                                  fontSize: 10, 
                                                  color: isRawan ? Colors.red[800] : Colors.orange[800],
                                                  fontWeight: FontWeight.bold
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.description,
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          maxLines: 2, overflow: TextOverflow.ellipsis,
                                        ),
                                        if (!isRawan) 
                                           Padding(
                                             padding: const EdgeInsets.only(top: 4),
                                             child: Text(
                                               "Status: ${item.status}",
                                               style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                                             ),
                                           ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}