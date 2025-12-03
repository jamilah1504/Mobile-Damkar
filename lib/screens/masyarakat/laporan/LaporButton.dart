import 'dart:convert';
import 'dart:io'; // Tetap ada untuk Mobile, tapi kita handle Web secara khusus
import 'package:flutter/foundation.dart'; // PENTING: Untuk cek kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Tambahkan ini di pubspec.yaml jika belum ada

// ==========================================
// 1. MODELS & SERVICES
// ==========================================

class LaporData {
  String? namaPelapor;
  String? jenisKejadian;
  String? detailKejadian;
  String? alamatKejadian;
  double? latitude;
  double? longitude;
  XFile? dokumen; // UBAH: Dari File? menjadi XFile?

  LaporData({
    this.namaPelapor,
    this.jenisKejadian,
    this.detailKejadian,
    this.alamatKejadian,
    this.latitude,
    this.longitude,
    this.dokumen,
  });
}

class ApiService {
  // Ganti URL sesuai IP komputer. Jika Web, localhost biasanya bisa (tergantung setting CORS backend)
  // Jika Android Emulator: 10.0.2.2
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api'; 
    return 'http://192.168.217.187:5000/api';
  }

  // UBAH PARAMETER: Terima XFile, bukan File
  static Future<Map<String, dynamic>> analyzeVideo(XFile videoFile) async {
    var uri = Uri.parse('$baseUrl/ai/analyze-report');
    var request = http.MultipartRequest('POST', uri);

    if (kIsWeb) {
      // --- LOGIC KHUSUS WEB (Kirim Bytes) ---
      var bytes = await videoFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file', // Nama field harus sama dengan backend
        bytes,
        filename: videoFile.name,
        contentType: MediaType('video', 'mp4'), // Sesuaikan tipe file
      ));
    } else {
      // --- LOGIC MOBILE (Kirim Path) ---
      request.files.add(await http.MultipartFile.fromPath('file', videoFile.path));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Gagal menganalisa video: ${response.body}');
    }
    return jsonDecode(response.body);
  }

  static Future<void> submitLaporan(LaporData data) async {
    if (data.latitude == null || data.longitude == null) {
      throw Exception('Lokasi wajib diisi.');
    }

    var uri = Uri.parse('$baseUrl/reports');
    var request = http.MultipartRequest('POST', uri);
    request.fields['namaPelapor'] = data.namaPelapor ?? 'Anonim';
    request.fields['jenisKejadian'] = data.jenisKejadian ?? 'Lainnya';
    request.fields['detailKejadian'] = data.detailKejadian ?? '-';
    request.fields['alamatKejadian'] = data.alamatKejadian ?? '-';
    request.fields['latitude'] = data.latitude.toString();
    request.fields['longitude'] = data.longitude.toString();

    if (data.dokumen != null) {
      
      var mimeType = MediaType('video', 'mp4'); // Default fallback
      
      // Deteksi sederhana berdasarkan ekstensi agar lebih akurat
      final ext = data.dokumen!.name.split('.').last.toLowerCase();
      if (ext == 'mov') mimeType = MediaType('video', 'quicktime');
      else if (ext == 'mkv') mimeType = MediaType('video', 'x-matroska');

      if (kIsWeb) {
        // --- LOGIC WEB ---
        var bytes = await data.dokumen!.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'dokumen',
          bytes,
          filename: data.dokumen!.name,
          contentType: mimeType,
        ));
      } else {
        // --- LOGIC MOBILE ---
        request.files.add(await http.MultipartFile.fromPath(
          'dokumen', 
          data.dokumen!.path,
          contentType: mimeType,
        ));
      }
    }

    var streamedResponse = await request.send();
    
    final respStr = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode != 200 && streamedResponse.statusCode != 201) {
      throw Exception('Gagal mengirim laporan: $respStr');
    }
  }
}

// ==========================================
// 2. MAIN WIDGET
// ==========================================

class LaporButton extends StatefulWidget {
  const LaporButton({super.key});

  @override
  State<LaporButton> createState() => _LaporButtonState();
}

class _LaporButtonState extends State<LaporButton> {
  // State
  bool _isLoading = false;
  String _loadingText = 'MEMPROSES...';
  
  // UBAH: Gunakan XFile agar kompatibel Web & Mobile
  XFile? _tempFile; 
  Position? _tempLocation;
  
  // Controller... (Sama seperti sebelumnya)
  final _namaController = TextEditingController();
  final _detailController = TextEditingController();
  final _alamatController = TextEditingController();
  String? _selectedJenisKejadian;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _namaController.dispose();
    _detailController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  // --- Logic 1: Ambil Lokasi ---
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('GPS tidak aktif.');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw Exception('Izin lokasi ditolak.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen.');
    }

    return await Geolocator.getCurrentPosition();
  }

  // --- Logic 2: Handle File & AI Process ---
 Future<void> _handleFileSelection(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(source: source);
      if (pickedFile == null) return;

      setState(() {
        _isLoading = true;
        _tempFile = pickedFile; // Langsung simpan XFile
        _loadingText = 'MENCARI LOKASI...';
      });

      // 1. Ambil Lokasi
      final position = await _getCurrentLocation();
      _tempLocation = position;

      // 2. Analisa AI
      setState(() => _loadingText = 'ANALISA AI...');
      
      // Kirim XFile langsung ke ApiService
      final aiResult = await ApiService.analyzeVideo(_tempFile!);
      final extracted = aiResult['formData'];

      // ... (Validasi kelengkapan data sama seperti sebelumnya) ...
      bool isDataComplete = (extracted['namaPelapor'] != null && extracted['namaPelapor'] != '') &&
                            (extracted['jenisKejadian'] != null && extracted['jenisKejadian'] != '') &&
                            (extracted['alamatKejadian'] != null && extracted['alamatKejadian'] != '');


      if (isDataComplete) {
        setState(() => _loadingText = 'MENGIRIM...');
        await _executeSubmit(LaporData(
          namaPelapor: extracted['namaPelapor'],
          jenisKejadian: extracted['jenisKejadian'],
          detailKejadian: extracted['detailKejadian'],
          alamatKejadian: extracted['alamatKejadian'],
          latitude: position.latitude,
          longitude: position.longitude,
          dokumen: _tempFile,
        ));
      } else {
        _prefillManualForm(extracted);
        setState(() => _isLoading = false);
        if (mounted) _showManualFormDialog();
      }

    } catch (e) {
      setState(() => _isLoading = false);
      _showNotification('Error: ${e.toString()}', isError: true);
    }
  }

  void _prefillManualForm(Map<String, dynamic> data) {
    _namaController.text = data['namaPelapor'] ?? '';
    _selectedJenisKejadian = data['jenisKejadian']; // Pastikan value match dengan dropdown
    _detailController.text = data['detailKejadian'] ?? '';
    _alamatController.text = data['alamatKejadian'] ?? '';
  }

  // --- Logic 3: Submit Final ---
  Future<void> _executeSubmit(LaporData data) async {
    try {
      await ApiService.submitLaporan(data);
      _showNotification('Laporan Berhasil Terkirim!', isError: false);
      _resetState();
    } catch (e) {
      _showNotification(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetState() {
    setState(() {
      _tempFile = null;
      _tempLocation = null;
      _namaController.clear();
      _detailController.clear();
      _alamatController.clear();
      _selectedJenisKejadian = null;
    });
  }

  // --- UI Helpers: Notifications & Popups ---

  void _showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSourceMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Pilih Sumber Video", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildSourceOption(
              icon: Icons.videocam,
              title: "Ambil Video Langsung",
              subtitle: "Rekam kejadian secara real-time",
              color: Colors.red.shade50,
              iconColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _handleFileSelection(ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
            _buildSourceOption(
              icon: Icons.image,
              title: "Pilih dari Galeri",
              subtitle: "Upload video yang tersimpan",
              color: Colors.blue.shade50,
              iconColor: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                _handleFileSelection(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({required IconData icon, required String title, required String subtitle, required Color color, required Color iconColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showManualFormDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder( // Agar state form bisa update di dalam dialog
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        border: Border(bottom: BorderSide(color: Colors.amber.shade200)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 28),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Data Belum Lengkap", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF78350F))),
                                Text("AI membutuhkan bantuan Anda.", style: TextStyle(fontSize: 12, color: Color(0xFF92400E))),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    // Form Body
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Nama Pelapor *"),
                          TextField(controller: _namaController, decoration: _inputDeco("Nama Anda")),
                          const SizedBox(height: 16),
                          
                          _buildLabel("Jenis Kejadian *"),
                          DropdownButtonFormField<String>(
                            value: _selectedJenisKejadian,
                            decoration: _inputDeco("Pilih Jenis"),
                            items: ['Kebakaran', 'Non Kebakaran'].map((String val) {
                              return DropdownMenuItem(value: val, child: Text(val));
                            }).toList(),
                            onChanged: (val) => setStateDialog(() => _selectedJenisKejadian = val),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildLabel("Alamat Kejadian *"),
                          TextField(controller: _alamatController, maxLines: 2, decoration: _inputDeco("Lokasi lengkap...")),
                          const SizedBox(height: 16),

                          _buildLabel("Detail Tambahan"),
                          TextField(controller: _detailController, maxLines: 2, decoration: _inputDeco("Keterangan opsional...")),
                          
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _resetState();
                                  },
                                  style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                                  child: const Text("Batal"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.send, size: 16, color: Colors.white),
                                  label: const Text("Kirim", style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      _isLoading = true;
                                      _loadingText = "MENGIRIM MANUAL...";
                                    });
                                    _executeSubmit(LaporData(
                                      namaPelapor: _namaController.text,
                                      jenisKejadian: _selectedJenisKejadian,
                                      alamatKejadian: _alamatController.text,
                                      detailKejadian: _detailController.text,
                                      latitude: _tempLocation?.latitude,
                                      longitude: _tempLocation?.longitude,
                                      dokumen: _tempFile,
                                    ));
                                  },
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  // ==========================================
  // 3. RENDER (BUILD)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    // Definisi warna agar sesuai dengan snippet desain
    // Anda bisa memindahkannya ke global theme jika perlu
    const Color primaryColor = Colors.red; 
    final Color secondaryColor = Colors.red.shade100;

    return Center(
      child: GestureDetector(
        // LOGIC: Jika loading, tombol tidak bisa ditekan
        onTap: _isLoading ? null : _showSourceMenu,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: secondaryColor, // Warna lingkaran luar
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor, // Warna lingkaran dalam
              ),
              child: Center(
                // LOGIC: Mengatur tampilan saat Loading vs Standby
                child: _isLoading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              _loadingText, // Text dinamis (Mencari lokasi/Analisa AI)
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10, // Font diperkecil agar muat di lingkaran
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // PERUBAHAN: Icon mic diganti menjadi videocam
                          Icon(Icons.videocam, color: Colors.white, size: 40),
                          SizedBox(height: 5),
                          Text(
                            'LAPOR',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}