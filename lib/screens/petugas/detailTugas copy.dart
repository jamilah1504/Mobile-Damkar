import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // <--- SUDAH DITAMBAHKAN
import 'home.dart';

// Enum untuk melacak Status Tampilan UI
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
  // State Variables
  TaskState _currentState = TaskState.ready;
  int? _tugasId;
  DateTime? _startTime;
  DateTime? _arrivalTime;
  Timer? _timer;
  String _timerText = "00:00";

  // Form Variables
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _korbanController = TextEditingController();
  final TextEditingController _kerugianController = TextEditingController();
  final TextEditingController _penyebabController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  File? _selectedImage;

  // Ganti URL sesuai environment
  final String _baseUrl = 'http://localhost:5000';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- HELPER: AMBIL TOKEN ---
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // --- LOGIKA TIMER ---
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

  // 1. API: Terima & Mulai Jalan
  Future<void> _handleTerimaTugas() async {
    try {
      final token = await _getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token tidak ditemukan, login ulang.')),
        );
        return;
      }

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: ${response.body}')));
      }
    } catch (e) {
      print("Error start tugas: $e");
    }
  }

  // 2. API: Tiba Di Lokasi
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

  // 3. API: Penanganan
  Future<void> _handlePenanganan() async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/api/tugas/finish'),
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

  // 4. API: Simpan Laporan Lapangan
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

      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('files', _selectedImage!.path),
        );
      }

      var res = await request.send();
      if (res.statusCode == 201) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan Berhasil Disimpan!')),
        );
      } else {
        final respStr = await res.stream.bytesToString();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal upload: $respStr')));
      }
    } catch (e) {
      print("Error submit laporan: $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.red.shade800;
    final bool hasCoordinates =
        widget.laporan.latitude != null && widget.laporan.longitude != null;
    final LatLng centerLocation = hasCoordinates
        ? LatLng(widget.laporan.latitude!, widget.laporan.longitude!)
        : const LatLng(-6.571589, 107.758736);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          if (_currentState != TaskState.reporting)
            Positioned.fill(
              bottom: MediaQuery.of(context).size.height * 0.35,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: centerLocation,
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
            ),

          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _currentState == TaskState.reporting
                      ? primaryColor
                      : Colors.white,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: _currentState == TaskState.reporting
                          ? Colors.white
                          : primaryColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Detail Tugas',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_currentState == TaskState.onTheWay)
            Positioned(
              top: 100,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _timerText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_currentState == TaskState.arrived &&
              _startTime != null &&
              _arrivalTime != null)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'TIBA ${_arrivalTime!.difference(_startTime!).inMinutes} MENIT SETELAH PANGGILAN',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: _currentState == TaskState.reporting
                  ? MediaQuery.of(context).size.height * 0.85
                  : MediaQuery.of(context).size.height * 0.40,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: _currentState == TaskState.reporting
                  ? _buildReportingForm(primaryColor)
                  : _buildTaskInfo(primaryColor),
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
            style: TextStyle(
              color: primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            widget.laporan.alamatKejadian,
            style: const TextStyle(color: Colors.black87),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          // BAGIAN YANG TADI ERROR SEKARANG SUDAH AMAN
          Text(
            "WAKTU TIBA : ${_arrivalTime != null ? DateFormat('HH:mm').format(_arrivalTime!) : '-'}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const Text(
            "Kronologi",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          Text(
            widget.laporan.deskripsi,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          SizedBox(width: double.infinity, child: _buildActionBtn()),
        ],
      ),
    );
  }

  Widget _buildActionBtn() {
    switch (_currentState) {
      case TaskState.ready:
        return ElevatedButton(
          onPressed: _handleTerimaTugas,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF154c79),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'TERIMA & MULAI JALAN',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
      case TaskState.onTheWay:
        return ElevatedButton(
          onPressed: _handleTibaDiLokasi,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'TIBA DI LOKASI',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
      case TaskState.arrived:
        return ElevatedButton(
          onPressed: _handlePenanganan,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'PENANGANAN',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
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
            Text(
              '${widget.laporan.jenisKejadian.toUpperCase()} - ${widget.laporan.namaPelapor}',
              style: TextStyle(
                color: primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.laporan.alamatKejadian,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(thickness: 2),

            Expanded(
              child: ListView(
                children: [
                  const Text(
                    "Bukti Penanganan",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _selectedImage == null
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt),
                                  Text("Foto/Video"),
                                ],
                              ),
                            )
                          : Image.file(_selectedImage!, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _korbanController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Korban',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _kerugianController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Estimasi Kerugian (Rp)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _penyebabController,
                    decoration: const InputDecoration(
                      labelText: 'Dugaan Penyebab',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _catatanController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Tambahan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSubmitLaporan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF154c79),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'SIMPAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
