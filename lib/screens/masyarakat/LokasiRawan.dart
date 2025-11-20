import 'dart:async';
import 'dart:convert';
import 'dart:io'; // Untuk deteksi Platform
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


// ==================== 1. MODEL DATA ====================
class LokasiRawan {
  final int id;
  final String namaLokasi;
  final String deskripsi;
  final double latitude;
  final double longitude;
  final List<String> images;
  final String thumbnail;

  LokasiRawan({
    required this.id,
    required this.namaLokasi,
    required this.deskripsi,
    required this.latitude,
    required this.longitude,
    required this.images,
    required this.thumbnail,
  });

  factory LokasiRawan.fromJson(Map<String, dynamic> json) {
    // Parsing array images dengan aman
    List<String> imgs = [];
    if (json['images'] != null) {
      imgs = List<String>.from(json['images']);
    }

    // Gambar default jika kosong
    String defaultImage = 'https://via.placeholder.com/150?text=No+Image';
    if (imgs.isNotEmpty) {
      defaultImage = imgs[0];
    }

    return LokasiRawan(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      namaLokasi: json['namaLokasi'] ?? 'Lokasi Tanpa Nama',
      deskripsi: json['deskripsi'] ?? 'Tidak ada deskripsi',
      // Menggunakan 'num' lalu toDouble() agar aman (int/double/string numeric)
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      images: imgs,
      thumbnail: defaultImage,
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
  // State Data
  List<LokasiRawan> markers = [];
  bool loading = true;
  String? error;
  
  // State UI
  bool isListOpen = true;
  int? selectedId;
  final MapController mapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchMarkers();
    _loadUserData();

  }

   Future<void> _loadUserData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? authToken = prefs.getString('authToken');

      if (authToken == null) {
        throw Exception("Pengguna belum login");
      }

      if (mounted) {
        setState(() {
          _authToken = authToken;  
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat data pengguna: $e"); 
      if (mounted) {
        setState(() {
          _authToken = "--"; 
        });
      }
    }
  }

  // --- FUNGSI FETCH API ASLI ---
  Future<void> _fetchMarkers() async {
    // SETTING URL (Sesuaikan dengan Environment Anda)
    String baseUrl;
    
    if (kIsWeb) {
      baseUrl = 'http://localhost:5000';
    } else if (Platform.isAndroid) {
      // Android Emulator IP khusus untuk akses localhost komputer
      baseUrl = 'http://10.0.2.2:5000'; 
    } else {
      // iOS Simulator atau default
      baseUrl = 'http://localhost:5000';
    }

    final String endpoint = '$baseUrl/api/lokasi-rawan';
    
    // Jika pakai token, masukkan di sini
    final String token = _authToken; 

    try {
      setState(() {
        loading = true;
        error = null;
      });

      debugPrint("Fetching data from: $endpoint");

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $token'}, // Uncomment jika perlu Auth
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Debug print untuk memastikan data masuk
        debugPrint("Data received: ${data.length} items");

        final List<LokasiRawan> mappedData = data
            .map((json) => LokasiRawan.fromJson(json))
            .toList();

        if (mounted) {
          setState(() {
            markers = mappedData;
            loading = false;
          });
          
          // Auto center ke data pertama jika ada
          if (mappedData.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              mapController.move(
                LatLng(mappedData[0].latitude, mappedData[0].longitude), 
                13.0
              );
            });
          }
        }
      } else {
        throw Exception('Gagal memuat data. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error fetching: $e");
      if (mounted) {
        setState(() {
          error = "Gagal terhubung ke server.\nPastikan backend jalan di port 5000.\n($e)";
          loading = false;
        });
      }
    }
  }

  void _handleLocationClick(LokasiRawan marker) {
    setState(() {
      selectedId = marker.id;
    });
    mapController.move(
      LatLng(marker.latitude, marker.longitude), 
      16.0
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final initialCenter = const LatLng(-6.565493, 107.827441); // Default center (misal: Subang/Bandung)

    return Scaffold(
      body: Stack(
        children: [
          // ================= LAYER 1: PETA =================
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 13.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: markers.map((item) {
                  final isSelected = selectedId == item.id;
                  return Marker(
                    point: LatLng(item.latitude, item.longitude),
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () => _handleLocationClick(item),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Nama lokasi melayang di atas marker jika dipilih
                          if (isSelected)
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: const [BoxShadow(blurRadius: 2)],
                              ),
                              child: Text(
                                item.namaLokasi,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          Icon(
                            Icons.location_on,
                            color: isSelected ? Colors.red : Colors.red.withOpacity(0.7),
                            size: isSelected ? 40 : 35,
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
             const Center(
               child: Card(
                 child: Padding(
                   padding: EdgeInsets.all(16.0),
                   child: CircularProgressIndicator(),
                 ),
               )
             )
          else if (error != null)
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 40),
                    const SizedBox(height: 10),
                    Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _fetchMarkers, 
                      child: const Text("Coba Lagi")
                    )
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
                  label: const Text("Lihat Daftar"),
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
                          "Lokasi Rawan (${markers.length})",
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
                    child: markers.isEmpty
                    ? const Center(child: Text("Tidak ada data lokasi."))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: markers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = markers[index];
                          final isSelected = selectedId == item.id;

                          return GestureDetector(
                            onTap: () => _handleLocationClick(item),
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
                                  // Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      item.thumbnail,
                                      width: 60, height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, _) => Container(
                                        width: 60, height: 60, color: Colors.grey[300],
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.namaLokasi,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          item.deskripsi,
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          maxLines: 2, overflow: TextOverflow.ellipsis,
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