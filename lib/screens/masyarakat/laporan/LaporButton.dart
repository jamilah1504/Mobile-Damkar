import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart'; // [BARU] Import ini

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
  XFile? dokumen;
  int? pelaporId; // [BARU] Tambah field pelaporId

  LaporData({
    this.namaPelapor,
    this.jenisKejadian,
    this.detailKejadian,
    this.alamatKejadian,
    this.latitude,
    this.longitude,
    this.dokumen,
    this.pelaporId, // [BARU]
  });
}

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api'; 
    return 'http://192.168.217.187:5000/api';
  }

  static Future<Map<String, dynamic>> analyzeVideo(XFile videoFile) async {
    var uri = Uri.parse('$baseUrl/ai/analyze-report');
    var request = http.MultipartRequest('POST', uri);

    if (kIsWeb) {
      var bytes = await videoFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: videoFile.name,
        contentType: MediaType('video', 'mp4'),
      ));
    } else {
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
    
    // [BARU] Kirim pelaporId jika ada
    if (data.pelaporId != null) {
      request.fields['pelaporId'] = data.pelaporId.toString();
    }

    if (data.dokumen != null) {
      var mimeType = MediaType('video', 'mp4');
      final ext = data.dokumen!.name.split('.').last.toLowerCase();
      if (ext == 'mov') mimeType = MediaType('video', 'quicktime');
      else if (ext == 'mkv') mimeType = MediaType('video', 'x-matroska');

      if (kIsWeb) {
        var bytes = await data.dokumen!.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'dokumen',
          bytes,
          filename: data.dokumen!.name,
          contentType: mimeType,
        ));
      } else {
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
  bool _isLoading = false;
  String _loadingText = 'MEMPROSES...';
  
  XFile? _tempFile; 
  Position? _tempLocation;
  
  final _namaController = TextEditingController();
  final _detailController = TextEditingController();
  final _alamatController = TextEditingController();
  String? _selectedJenisKejadian;

  // [BARU] Variable untuk menyimpan data user sementara
  int _userId = 0;
  String _userName = '';

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _namaController.dispose();
    _detailController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

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

  Future<void> _handleFileSelection(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(source: source);
      if (pickedFile == null) return;

      setState(() {
        _isLoading = true;
        _tempFile = pickedFile;
        _loadingText = 'MEMUAT DATA USER...';
      });

      // [BARU] 1. Ambil data dari Local Storage (Shared Preferences)
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getInt('userId') ?? 0;
      _userName = prefs.getString('userName') ?? ''; 
      
      // Jika userId tersimpan sebagai String, handle fallbacknya:
      if (_userId == 0) {
        String? idString = prefs.getString('userId');
        if (idString != null) _userId = int.tryParse(idString) ?? 0;
      }

      setState(() => _loadingText = 'MENCARI LOKASI...');

      // 2. Ambil Lokasi
      final position = await _getCurrentLocation();
      _tempLocation = position;

      // 3. Analisa AI
      setState(() => _loadingText = 'ANALISA AI...');
      final aiResult = await ApiService.analyzeVideo(_tempFile!);
      final extracted = aiResult['formData'];

      // [BARU] LOGIKA PENENTUAN NAMA
      // Ambil nama dari AI, jika kosong ambil dari _userName (Local Storage)
      String finalName = extracted['namaPelapor'] ?? '';
      if (finalName.trim().isEmpty) {
        finalName = _userName;
      }

      // Cek kelengkapan (Nama dianggap lengkap jika AI dapat atau ada di LocalStorage)
      bool isDataComplete = (finalName.isNotEmpty) &&
                            (extracted['jenisKejadian'] != null && extracted['jenisKejadian'] != '') &&
                            (extracted['alamatKejadian'] != null && extracted['alamatKejadian'] != '');

      if (isDataComplete) {
        setState(() => _loadingText = 'MENGIRIM...');
        await _executeSubmit(LaporData(
          namaPelapor: finalName, // Pakai nama yang sudah diproses
          jenisKejadian: extracted['jenisKejadian'],
          detailKejadian: extracted['detailKejadian'],
          alamatKejadian: extracted['alamatKejadian'],
          latitude: position.latitude,
          longitude: position.longitude,
          dokumen: _tempFile,
          pelaporId: _userId, // [BARU] Kirim userId sebagai pelaporId
        ));
      } else {
        // Jika data tidak lengkap, buka form manual
        // Update extracted data dengan nama fix agar form terisi otomatis
        extracted['namaPelapor'] = finalName;
        
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
    _selectedJenisKejadian = data['jenisKejadian'];
    _detailController.text = data['detailKejadian'] ?? '';
    _alamatController.text = data['alamatKejadian'] ?? '';
  }

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

  // --- UI Helpers --- (Tidak ada perubahan signifikan di bawah ini, kecuali pemanggilan _executeSubmit di dialog)

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
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                                    // [BARU] Kirim manual juga menyertakan _userId
                                    _executeSubmit(LaporData(
                                      namaPelapor: _namaController.text,
                                      jenisKejadian: _selectedJenisKejadian,
                                      alamatKejadian: _alamatController.text,
                                      detailKejadian: _detailController.text,
                                      latitude: _tempLocation?.latitude,
                                      longitude: _tempLocation?.longitude,
                                      dokumen: _tempFile,
                                      pelaporId: _userId, // [BARU]
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

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Colors.red; 
    final Color secondaryColor = Colors.red.shade100;

    return Center(
      child: GestureDetector(
        onTap: _isLoading ? null : _showSourceMenu,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: secondaryColor,
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
                color: primaryColor,
              ),
              child: Center(
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
                              _loadingText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
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