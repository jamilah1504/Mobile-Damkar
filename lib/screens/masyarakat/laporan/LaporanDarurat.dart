import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Pastikan library di pubspec.yaml sudah lengkap:
// dio, image_picker, geolocator, flutter_map, latlong2, shared_preferences

class LaporanDarurat extends StatefulWidget {
  const LaporanDarurat({Key? key}) : super(key: key);

  @override
  State<LaporanDarurat> createState() => _LaporanDaruratState();
}

class _LaporanDaruratState extends State<LaporanDarurat> {
  // --- KONTROLER TEXT ---
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  
  // Default dropdown value
  String _selectedKebakaran = 'Kebakaran';
  // List opsi dropdown agar mudah divalidasi
  final List<String> _kategoriList = ['Kebakaran', 'Non Kebakaran'];

  int _userId = 0; 
  
  // Flag agar data argumen hanya diisi sekali
  bool _isDataInitialized = false;

  // --- STATE LOGIKA ---
  LatLng _currentLocation = const LatLng(-6.5522, 107.7587); 
  final MapController _mapController = MapController(); 
  
  String _gpsStatus = 'Mencari lokasi...';
  bool _isLocating = false;
  bool _isSubmitting = false;

  final List<XFile> _mediaFiles = [];
  final ImagePicker _picker = ImagePicker();
  final int _maxFiles = 5;

  // Ganti URL sesuai environment (localhost untuk web/emulator android 10.0.2.2)
  final String _baseUrl = 'http://localhost:5000/api'; 
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadUserData();
  }

  // --- FUNGSI PENERIMA DATA DARI LAPOR BUTTON (AI) ---
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Cek apakah data sudah pernah diisi agar tidak menimpa editan user saat set state
    if (!_isDataInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      
      // Debugging: Cek data yang masuk
      debugPrint("Data diterima di LaporanDarurat: $args");

      if (args != null && args is Map) {
        setState(() {
          // 1. Isi Nama (Jika ada dari AI, jika null biarkan kosong/dari SharedPref)
          if (args['namaPelapor'] != null && args['namaPelapor'].toString().isNotEmpty) {
            _namaController.text = args['namaPelapor'];
          }

          // 2. Isi Detail Kejadian
          if (args['detailKejadian'] != null) {
            _deskripsiController.text = args['detailKejadian'];
          }

          // 3. Isi Alamat
          if (args['alamatKejadian'] != null) {
            _lokasiController.text = args['alamatKejadian'];
          }

          // 4. Isi Dropdown (Validasi apakah nilai dari AI ada di list dropdown kita)
          if (args['jenisKejadian'] != null) {
            String incidentType = args['jenisKejadian'].toString();
            // Cocokkan case sensitive atau default ke Kebakaran jika tidak match
            if (_kategoriList.contains(incidentType)) {
              _selectedKebakaran = incidentType;
            } else {
              // Logika fallback sederhana: jika mengandung kata 'non', set non kebakaran
              if (incidentType.toLowerCase().contains('non')) {
                _selectedKebakaran = 'Non Kebakaran';
              } else {
                _selectedKebakaran = 'Kebakaran';
              }
            }
          }
        });
      }
      // Tandai bahwa inisialisasi selesai
      _isDataInitialized = true;
    }
  }

  Future<void> _loadUserData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('userId'); 
      // Jika nama masih kosong dan ada nama di SharedPref, bisa diisi disini (opsional)
      // final String? savedName = prefs.getString('userName');
      // if (_namaController.text.isEmpty && savedName != null) _namaController.text = savedName;

      if (mounted) {
        setState(() {
          _userId = userId ?? 0; 
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat data pengguna: $e"); 
    }
  }

  // --- 1. LOGIKA MENGAMBIL LOKASI ---
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

      LatLng newPos = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = newPos;
        _gpsStatus = 'GPS: ${newPos.latitude.toStringAsFixed(4)}, ${newPos.longitude.toStringAsFixed(4)}';
      });
      
      _mapController.move(newPos, 16.0);

    } catch (e) {
      setState(() => _gpsStatus = 'Gagal: $e');
      _showSnackBar('Gagal mendapatkan lokasi: $e', isError: true);
    } finally {
      setState(() => _isLocating = false);
    }
  }

  // --- 2. LOGIKA PILIH FILE ---
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
        setState(() => _mediaFiles.add(pickedFile!));
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  // --- 3. LOGIKA PENGIRIMAN API ---
  Future<void> _submitLaporan() async {
    if (_namaController.text.isEmpty ||
        _lokasiController.text.isEmpty ||
        _deskripsiController.text.isEmpty) {
      _showSnackBar('Harap lengkapi semua formulir.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Siapkan data fields
      Map<String, dynamic> fields = {
        'namaPelapor': _namaController.text,
        'jenisKejadian': _selectedKebakaran,
        'detailKejadian': _deskripsiController.text,
        'alamatKejadian': _lokasiController.text,
        'latitude': _currentLocation.latitude.toString(),
        'longitude': _currentLocation.longitude.toString(),
        'pelaporId': _userId,
      };

      FormData formData = FormData.fromMap(fields);

      // Tambahkan file (support Web & Mobile)
      for (var file in _mediaFiles) {
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
        setState(() => _mediaFiles.clear());
        
        // Opsional: Kembali ke home setelah sukses
        // Navigator.pop(context); 
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
                    // Menggunakan list variable agar konsisten dengan validasi
                    items: _kategoriList.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                    onChanged: (val) => setState(() => _selectedKebakaran = val!),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Deskripsi & Alamat (Otomatis terisi dari AI)
              _buildInputContainer(child: TextField(controller: _deskripsiController, maxLines: 3, decoration: _inputDecoration('Detail Kejadian'))),
              const SizedBox(height: 12),
              _buildInputContainer(child: TextField(controller: _lokasiController, maxLines: 2, decoration: _inputDecoration('Alamat Lengkap'))),
              const SizedBox(height: 12),

              // --- MAP SECTION ---
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
                    
                    // FLUTTER MAP
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 250, 
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _currentLocation,
                                initialZoom: 15.0,
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