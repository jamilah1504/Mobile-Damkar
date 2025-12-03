import 'dart:async';
import 'dart:convert';
import 'dart:io'; // Tetap butuh untuk Mobile/Desktop
import 'package:flutter/foundation.dart'; // [BARU] Untuk cek kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home.dart';

enum TaskState { ready, onTheWay, arrived, reporting }

class DetailTugasScreen extends StatefulWidget {
  final PanggilanLaporan laporan;
  final VoidCallback onTerimaTugas;

  const DetailTugasScreen({
    super.key,
    required this.laporan,
    required this.onTerimaTugas,
  });

  @override
  State<DetailTugasScreen> createState() => _DetailTugasScreenState();
}

class _DetailTugasScreenState extends State<DetailTugasScreen> {
  TaskState _currentState = TaskState.ready;
  int? _tugasId;
  DateTime? _startTime;
  DateTime? _arrivalTime;
  Timer? _timer;
  String _timerText = "00:00";

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _korbanController = TextEditingController();
  final TextEditingController _kerugianController = TextEditingController();
  final TextEditingController _penyebabController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  
  // [PERBAIKAN 1] Ganti File? jadi XFile? agar support Web
  XFile? _selectedImage; 

  // Sesuaikan URL Backend Anda
  final String _baseUrl = 'http://localhost:5000'; 

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Langsung kembalikan token tanpa popup
    return prefs.getString('authToken') ?? prefs.getString('token');
  }

  Future<void> _openGoogleMaps() async {
    final double? lat = widget.laporan.latitude;
    final double? lng = widget.laporan.longitude;

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koordinat lokasi tidak tersedia.')),
      );
      return;
    }

    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'
    );

    try {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Fallback jika gagal buka app, buka di browser
      await launchUrl(googleMapsUrl, mode: LaunchMode.platformDefault);
    }
  }

  void _startTimer() {
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final difference = now.difference(_startTime!);
      setState(() {
        _timerText = _formatDuration(difference);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return d.inHours > 0 ? "$hours:$minutes:$seconds" : "$minutes:$seconds";
  }

  // --- API CALLS ---

  Future<void> _handleTerimaTugas() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse('$_baseUrl/api/tugas/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'insidenId': widget.laporan.id}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          _tugasId = data['id'];
          _currentState = TaskState.onTheWay;
          _startTimer();
        });
        widget.onTerimaTugas();
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: ${response.body}')));
      }
    } catch (e) {
      print("Error start tugas: $e");
    }
  }

  Future<void> _handleTibaDiLokasi() async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/api/tugas/arrive'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'tugasId': _tugasId}),
      );

      if (response.statusCode == 200) {
        _stopTimer();
        setState(() {
          _arrivalTime = DateTime.now();
          _currentState = TaskState.arrived;
        });
      }
    } catch (e) {
      print("Error tiba tugas: $e");
    }
  }

  Future<void> _handlePenanganan() async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/api/tugas/handle'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'tugasId': _tugasId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _currentState = TaskState.reporting;
        });
      }
    } catch (e) {
      print("Error finish tugas: $e");
    }
  }

  // [PERBAIKAN 2] Upload Gambar Support Web & Mobile
  Future<void> _handleSubmitLaporan() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final token = await _getToken();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/laporan-lapangan'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['tugasId'] = _tugasId.toString();
      request.fields['jumlahKorban'] = _korbanController.text;
      request.fields['estimasiKerugian'] = _kerugianController.text;
      request.fields['dugaanPenyebab'] = _penyebabController.text;
      request.fields['catatan'] = _catatanController.text;

      // Logika Upload Gambar
      if (_selectedImage != null) {
        if (kIsWeb) {
          // KHUSUS WEB: Baca bytes
          var bytes = await _selectedImage!.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'files', // Sesuaikan dengan key di backend Anda (misal 'files' atau 'gambar')
              bytes,
              filename: _selectedImage!.name,
            ),
          );
        } else {
          // KHUSUS MOBILE/DESKTOP: Pakai Path
          request.files.add(
            await http.MultipartFile.fromPath('files', _selectedImage!.path),
          );
        }
      }

      var res = await request.send();
      if (res.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Laporan Berhasil Disimpan!')),
          );
        }
      } else {
        final respStr = await res.stream.bytesToString();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal upload: $respStr')),
          );
        }
      }
    } catch (e) {
      print("Error submit laporan: $e");
    }
  }

  // [PERBAIKAN 3] Pick Image simpan ke XFile
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile; // Simpan sebagai XFile
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.red.shade800;
    final bool hasCoordinates = widget.laporan.latitude != null && widget.laporan.longitude != null;
    final LatLng centerLocation = hasCoordinates
        ? LatLng(widget.laporan.latitude!, widget.laporan.longitude!)
        : const LatLng(-6.571589, 107.758736);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // PETA
          if (_currentState != TaskState.reporting)
            Positioned.fill(
              bottom: MediaQuery.of(context).size.height * 0.35,
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: centerLocation,
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: centerLocation,
                            width: 80,
                            height: 80,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 50,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if(hasCoordinates)
                    Positioned(
                      bottom: 20,
                      right: 16,
                      child: FloatingActionButton.extended(
                        onPressed: _openGoogleMaps,
                        backgroundColor: Colors.blueAccent,
                        icon: const Icon(Icons.directions, color: Colors.white),
                        label: const Text("Rute", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),

          // Header Back Button
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _currentState == TaskState.reporting ? primaryColor : Colors.white,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: _currentState == TaskState.reporting ? Colors.white : primaryColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Detail Tugas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Timer
          if (_currentState == TaskState.onTheWay)
            Positioned(
              top: 100,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(_timerText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
            ),

          // Pesan Tiba
          if (_currentState == TaskState.arrived && _startTime != null && _arrivalTime != null)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  'TIBA ${_arrivalTime!.difference(_startTime!).inMinutes} MENIT SETELAH PANGGILAN',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          // Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: _currentState == TaskState.reporting ? MediaQuery.of(context).size.height * 0.85 : MediaQuery.of(context).size.height * 0.40,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
              ),
              child: _currentState == TaskState.reporting ? _buildReportingForm(primaryColor) : _buildTaskInfo(primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskInfo(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.laporan.jenisKejadian.toUpperCase()} - ${widget.laporan.namaPelapor}',
            style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(children: [const Icon(Icons.map, size: 16, color: Colors.grey), const SizedBox(width: 5), Expanded(child: Text(widget.laporan.alamatKejadian, style: const TextStyle(color: Colors.black87), maxLines: 2))]),
          const SizedBox(height: 8),
          Text("WAKTU TIBA : ${_arrivalTime != null ? DateFormat('HH:mm').format(_arrivalTime!) : '-'}", style: const TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),
          const Text("Kronologi:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          Text(widget.laporan.deskripsi, maxLines: 3, overflow: TextOverflow.ellipsis),
          const Spacer(),
          SizedBox(width: double.infinity, child: _buildActionBtn()),
        ],
      ),
    );
  }

  Widget _buildActionBtn() {
    switch (_currentState) {
      case TaskState.ready:
        return ElevatedButton.icon(onPressed: _handleTerimaTugas, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF154c79), padding: const EdgeInsets.symmetric(vertical: 16)), icon: const Icon(Icons.check_circle, color: Colors.white), label: const Text('TERIMA & MULAI JALAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)));
      case TaskState.onTheWay:
        return ElevatedButton.icon(onPressed: _handleTibaDiLokasi, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700], padding: const EdgeInsets.symmetric(vertical: 16)), icon: const Icon(Icons.flag, color: Colors.white), label: const Text('TIBA DI LOKASI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)));
      case TaskState.arrived:
        return ElevatedButton.icon(onPressed: _handlePenanganan, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)), icon: const Icon(Icons.medical_services, color: Colors.white), label: const Text('MULAI PENANGANAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildReportingForm(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Laporan Lapangan', style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(thickness: 2),
            Expanded(
              child: ListView(
                children: [
                  const Text("Dokumentasi", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _selectedImage == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                                Text("Tap untuk ambil foto"),
                              ],
                            )
                          : ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  // [PERBAIKAN UTAMA] Gunakan logika ini
                                  child: kIsWeb
                                      ? Image.network(
                                          _selectedImage!.path, // Web pakai ini
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, o, s) => const Icon(Icons.error),
                                        )
                                      : Image.file(
                                          File(_selectedImage!.path), // HP pakai ini
                                          fit: BoxFit.cover,
                                        ),
                                  ),
                          ),
                        ),
                  const SizedBox(height: 20),
                  TextFormField(controller: _korbanController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah Korban', border: OutlineInputBorder(), prefixIcon: Icon(Icons.people))),
                  const SizedBox(height: 10),
                  TextFormField(controller: _kerugianController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Estimasi Kerugian (Rp)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.money))),
                  const SizedBox(height: 10),
                  TextFormField(controller: _penyebabController, decoration: const InputDecoration(labelText: 'Dugaan Penyebab', border: OutlineInputBorder(), prefixIcon: Icon(Icons.help_outline))),
                  const SizedBox(height: 10),
                  TextFormField(controller: _catatanController, maxLines: 3, decoration: const InputDecoration(labelText: 'Catatan Tambahan', border: OutlineInputBorder(), prefixIcon: Icon(Icons.note))),
                ],
              ),
            ),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _handleSubmitLaporan, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF154c79), padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('KIRIM LAPORAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }
}