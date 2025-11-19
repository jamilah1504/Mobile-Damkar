import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
// Import paket Map
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laporan Kejadian',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const LaporanKejadianPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LaporanKejadianPage extends StatefulWidget {
  const LaporanKejadianPage({Key? key}) : super(key: key);

  @override
  State<LaporanKejadianPage> createState() => _LaporanKejadianPageState();
}

class _LaporanKejadianPageState extends State<LaporanKejadianPage> {
  // --- KONTROLER TEXT ---
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  String _selectedKebakaran = 'Kebakaran';
  int _userId = 0; // Simpan userId jika diperlukan

  // --- STATE LOGIKA ---
  // Koordinat default (Contoh: Jakarta/Subang)
  LatLng _currentLocation = const LatLng(-6.5522, 107.7587); 
  final MapController _mapController = MapController(); // Kontroler untuk menggerakkan map
  
  String _gpsStatus = 'Mencari lokasi...';
  bool _isLocating = false;
  bool _isSubmitting = false;

  // Menggunakan XFile agar kompatibel dengan Web & Mobile tanpa dart:io error
  final List<XFile> _mediaFiles = [];
  final ImagePicker _picker = ImagePicker();
  final int _maxFiles = 5;

  final String _baseUrl = 'http://localhost:5000/api'; // Ganti dengan IP laptop jika tes di HP Asli (misal 192.168.1.x)
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadUserData();
  }

    // Fungsi dari State kedua (digabung)
  Future<void> _loadUserData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      final int? userId = prefs.getInt('userId'); 

      if (userId == null) {
        throw Exception("Data pengguna (ID) tidak lengkap di SharedPreferences");
      }

      if (mounted) {
        setState(() {
          _userId = userId; 
        });
      }
    } catch (e) {
      // Ganti 'print' dengan 'debugPrint' untuk praktik yang lebih baik
      debugPrint("Gagal memuat data pengguna: $e"); 
      if (mounted) {
        setState(() {
          _userId = 0 ; // Fallback
        });
      }
    }
  }


  // --- 1. LOGIKA MENGAMBIL LOKASI (GEOLOCATOR) ---
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _gpsStatus = 'Mendapatkan lokasi GPS...';
    });

    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Layanan lokasi tidak aktif.';

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Izin lokasi ditolak.';
      }

      if (permission == LocationPermission.deniedForever) throw 'Izin lokasi ditolak permanen.';

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Update koordinat dan pindahkan kamera map
      LatLng newPos = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = newPos;
        _gpsStatus = 'GPS: ${newPos.latitude.toStringAsFixed(4)}, ${newPos.longitude.toStringAsFixed(4)}';
      });
      
      // Gerakkan map ke lokasi GPS
      _mapController.move(newPos, 16.0);

    } catch (e) {
      setState(() {
        _gpsStatus = 'Gagal: $e';
      });
      _showSnackBar('Gagal mendapatkan lokasi: $e', isError: true);
    } finally {
      setState(() {
        _isLocating = false;
      });
    }
  }

  // --- 2. LOGIKA PILIH FILE (IMAGE PICKER) ---
  Future<void> _pickMedia({required bool isVideo}) async {
    if (_mediaFiles.length >= _maxFiles) {
      _showSnackBar('Maksimal $_maxFiles file.', isError: true);
      return;
    }

    try {
      final XFile? pickedFile;
      if (isVideo) {
        pickedFile = await _picker.pickVideo(source: ImageSource.camera);
      } else {
        pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
      }

      if (pickedFile != null) {
        setState(() {
          _mediaFiles.add(pickedFile!);
        });
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _mediaFiles.removeAt(index);
    });
  }

  // --- 3. LOGIKA PENGIRIMAN API (PERBAIKAN ERROR MULTIPART) ---
  Future<void> _submitLaporan() async {
    if (_namaController.text.isEmpty ||
        _lokasiController.text.isEmpty ||
        _deskripsiController.text.isEmpty) {
      _showSnackBar('Harap lengkapi semua formulir.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      FormData formData = FormData.fromMap({
        'namaPelapor': _namaController.text,
        'jenisKejadian': _selectedKebakaran,
        'detailKejadian': _deskripsiController.text,
        'alamatKejadian': _lokasiController.text,
        'latitude': _currentLocation.latitude.toString(),
        'longitude': _currentLocation.longitude.toString(),
        'pelaporId': _userId,
      });

      // PERBAIKAN UTAMA: Gunakan fromBytes agar jalan di Web & Mobile
      for (var file in _mediaFiles) {
        // Baca file sebagai bytes (aman untuk web & mobile)
        List<int> fileBytes = await file.readAsBytes(); 
        String fileName = file.name;

        formData.files.add(MapEntry(
          'dokumen',
          MultipartFile.fromBytes(
            fileBytes,
            filename: fileName,
          ),
        ));
      }

      Response response = await _dio.post(
        '$_baseUrl/reports',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Laporan berhasil dikirim!');
        _namaController.clear();
        _deskripsiController.clear();
        _lokasiController.clear();
        setState(() {
          _mediaFiles.clear();
        });
      } else {
        throw Exception('Gagal mengirim. Kode: ${response.statusCode}');
      }

    } on DioException catch (e) {
       String message = 'Terjadi kesalahan jaringan.';
       if (e.response != null) {
         message = e.response?.data['message'] ?? e.message;
       }
       _showSnackBar('Gagal: $message', isError: true);
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        title: const Text('Laporan Kejadian', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Input Nama
              _buildInputContainer(child: TextField(controller: _namaController, decoration: _inputDecoration('Nama Pelapor'))),
              const SizedBox(height: 12),
              
              // Dropdown
              _buildInputContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedKebakaran,
                    isExpanded: true,
                    items: ['Kebakaran', 'Non Kebakaran'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                    onChanged: (val) => setState(() => _selectedKebakaran = val!),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Deskripsi & Alamat
              _buildInputContainer(child: TextField(controller: _deskripsiController, maxLines: 3, decoration: _inputDecoration('Detail Kejadian'))),
              const SizedBox(height: 12),
              _buildInputContainer(child: TextField(controller: _lokasiController, maxLines: 2, decoration: _inputDecoration('Alamat Lengkap'))),
              const SizedBox(height: 12),

              // --- MAP SECTION (DIGANTI MENJADI INTERAKTIF) ---
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Lokasi (Tap peta untuk ubah)', style: TextStyle(fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: _isLocating ? null : _getCurrentLocation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: const Color(0xFFFFC107), borderRadius: BorderRadius.circular(12)),
                            child: Text(_isLocating ? 'Mencari...' : 'Reset GPS', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_gpsStatus, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 8),
                    
                    // FLUTTER MAP (LEAFLET)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 250, // Tinggi Peta
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _currentLocation,
                                initialZoom: 15.0,
                                // Logika Tap Peta: Pindahkan pin ke lokasi yang diklik
                                onTap: (tapPosition, point) {
                                  setState(() {
                                    _currentLocation = point;
                                    _gpsStatus = 'Manual: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
                                  });
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.app',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _currentLocation,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Tombol Loading di atas peta jika sedang mencari GPS
                            if (_isLocating)
                              Container(
                                color: Colors.black12,
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),

              // Upload Section
              _buildUploadSection(),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || _isLocating) ? null : _submitLaporan,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Ajukan Laporan', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---
  Widget _buildInputContainer({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      padding: padding,
      child: child,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(hintText: hint, border: InputBorder.none, contentPadding: const EdgeInsets.all(16));
  }

  Widget _buildUploadSection() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dokumentasi (${_mediaFiles.length}/$_maxFiles)'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: ElevatedButton.icon(onPressed: () => _pickMedia(isVideo: false), icon: const Icon(Icons.camera_alt), label: const Text('Foto'))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(onPressed: () => _pickMedia(isVideo: true), icon: const Icon(Icons.videocam), label: const Text('Video'))),
            ],
          ),
          if (_mediaFiles.isNotEmpty) 
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _mediaFiles.length,
                itemBuilder: (context, index) => Container(
                  margin: const EdgeInsets.only(right: 8, top: 8),
                  width: 60,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.file_present)),
                ),
              ),
            )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _lokasiController.dispose();
    _mapController.dispose();
    super.dispose();
  }
}