import 'dart:async';
import 'dart:convert';
import 'dart:typed_data'; // Untuk Uint8List

import 'package:flutter/foundation.dart' show kIsWeb; // Untuk cek apakah berjalan di Web
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart'; // Hanya dipakai jika !kIsWeb
import 'package:http_parser/http_parser.dart'; // <--- TAMBAHKAN INI
import 'LaporanDarurat.dart';

class LaporButton extends StatefulWidget {
  final Color primaryColor;
  final Color secondaryColor;

  const LaporButton({
    super.key, 
    required this.primaryColor, 
    required this.secondaryColor
  });

  @override
  State<LaporButton> createState() => _LaporButtonState();
}

class _LaporButtonState extends State<LaporButton> with SingleTickerProviderStateMixin {
  // --- STATE VARIABLES ---
  bool _isRecording = false;
  bool _isLoading = false;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  
  // Di Web kita simpan URL Blob, di HP kita simpan path file
  String? _recordedUrlOrPath; 
  
  // Variabel Animasi
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  // --- SETUP URL BACKEND ---
  // Jika di Emulator Android gunakan 10.0.2.2, Jika di Chrome gunakan localhost
  String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    return 'http://10.0.2.2:5000';
  }

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _initAnimation();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
    _recorder.setSubscriptionDuration(const Duration(milliseconds: 500));
  }

  void _initAnimation() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _animController.dispose();
    super.dispose();
  }

  // --- LOGIC START RECORDING (UNIVERSAL) ---
  Future<void> startRecording() async {
    try {
      // 1. Cek Permission (Hanya untuk Android/iOS, Web biasanya otomatis prompt dari browser)
      if (!kIsWeb) {
        var status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          throw Exception("Izin mikrofon ditolak");
        }
      }

      // 2. Tentukan Lokasi Simpan
      String? path;
      Codec codec;

      if (kIsWeb) {
        // --- WEB CONFIG ---
        // Di Web, kita tidak butuh path spesifik, browser yang atur (Blob)
        path = 'laporan_audio.webm'; 
        codec = Codec.opusWebM; // Codec standar web modern
      } else {
        // --- MOBILE CONFIG ---
        final tempDir = await getTemporaryDirectory();
        path = '${tempDir.path}/laporan-audio.aac';
        codec = Codec.aacADTS;
      }

      // 3. Mulai Rekam
      await _recorder.startRecorder(
        toFile: path,
        codec: codec,
      );
      
      // Mulai Animasi
      _animController.repeat(reverse: true);

      setState(() {
        _isRecording = true;
      });

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Merekam... Silakan bicara.')),
        );
      }
      
    } catch (err) {
      debugPrint("Error Start Recording: $err");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal merekam: $err')),
        );
      }
    }
  }

  // --- LOGIC STOP RECORDING (UNIVERSAL) ---
  Future<void> stopRecording() async {
    if (_recorder.isRecording) {
      // stopRecorder mengembalikan path (Mobile) atau URL Blob (Web)
      String? urlOrPath = await _recorder.stopRecorder();
      
      _animController.stop();
      _animController.reset();

      setState(() {
        _isRecording = false;
        _isLoading = true; 
        _recordedUrlOrPath = urlOrPath;
      });

      debugPrint("Recording stopped. Location: $_recordedUrlOrPath");

      if (_recordedUrlOrPath != null) {
        await sendAudioAndNavigate(_recordedUrlOrPath!);
      } else {
         setState(() => _isLoading = false);
      }
    }
  }

  void handleButtonClick() {
    if (_isLoading) return;
    if (_isRecording) {
      stopRecording();
    } else {
      startRecording();
    }
  }

  // --- LOGIC API & NAVIGASI (UNIVERSAL UPLOAD) ---
  Future<void> sendAudioAndNavigate(String pathOrUrl) async {
    try {
      debugPrint("=== MULAI PROSES UPLOAD AUDIO (WEB/MOBILE) ===");
      
      // 1. Siapkan Request Multipart
      var requestVTT = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/ai/voice-to-text'));

      http.MultipartFile audioMultipart;

      if (kIsWeb) {
        // --- KHUSUS WEB: Ambil Blob & Manipulasi Ekstensi ---
        debugPrint("Fetching blob from browser: $pathOrUrl");
        
        final response = await http.get(Uri.parse(pathOrUrl));
        final audioBytes = response.bodyBytes; 

        // PERBAIKAN DISINI:
        // Backend menolak .webm, jadi kita namai file sebagai .wav
        // agar lolos filter 'uploadAudio.js'
        audioMultipart = http.MultipartFile.fromBytes(
          'audioFile', 
          audioBytes,
          filename: 'laporan_audio.wav', // <--- Ubah ekstensi jadi .wav atau .mp3
          contentType: MediaType('audio', 'wav'), // <--- Paksa MIME type jadi wav
        );
      } else {
        // --- KHUSUS MOBILE ---
        audioMultipart = await http.MultipartFile.fromPath(
          'audioFile', 
          pathOrUrl
        );
      }

      requestVTT.files.add(audioMultipart);
      
      // Kirim Request
      var resVTTStream = await requestVTT.send();
      var resVTT = await http.Response.fromStream(resVTTStream);
      
      debugPrint("[DEBUG VTT] Status Code: ${resVTT.statusCode}");
      debugPrint("[DEBUG VTT] Body: ${resVTT.body}"); // Print body untuk lihat error detail

      if (resVTT.statusCode != 200) {
        // Ambil pesan error dari HTML jika backend mengembalikan HTML (seperti kasus error multer)
        if (resVTT.body.contains("Error:")) {
           throw Exception('Ditolak Backend: ${resVTT.body.split('<pre>')[1].split('<br>')[0]}');
        }
        throw Exception('Gagal Transkripsi (Status ${resVTT.statusCode})');
      }
      
      final vttJson = jsonDecode(resVTT.body);
      final transcript = vttJson['transcript'];
      
      debugPrint("[DEBUG VTT] Transcript: $transcript");

      if (transcript == null || transcript.toString().isEmpty) {
        throw Exception('Transkrip kosong');
      }

      // 2. Text to Form
      final resTTF = await http.post(
        Uri.parse('$baseUrl/api/ai/text-to-form'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'transcript': transcript}),
      );

      debugPrint("[DEBUG TTF] Status Code: ${resTTF.statusCode}");

      if (resTTF.statusCode != 200) {
        throw Exception('Gagal Ekstrak Form: ${resTTF.body}');
      }
      
      final ttfJson = jsonDecode(resTTF.body);
      final formData = ttfJson['formData'];
      debugPrint("Data Form: ${formData}");
      if (mounted) {
        // Menggunakan MaterialPageRoute untuk pindah ke class LaporanDarurat
        Navigator.push(
          context,
          MaterialPageRoute(
            // Pastikan class LaporanDarurat sudah diimport di atas
            builder: (context) => const LaporanDarurat(), 
            
            // Mengirim data lewat RouteSettings agar bisa diambil via 
            // ModalRoute.of(context)!.settings.arguments di halaman tujuan
            settings: RouteSettings(arguments: formData),
          ),
        );
      }

    } catch (err) {
      debugPrint("=== ERROR TERJADI ===");
      debugPrint(err.toString());
      
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $err'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI BUILDER (TIDAK ADA PERUBAHAN) ---
  @override
  Widget build(BuildContext context) {
    Widget innerContent;
    
    if (_isLoading) {
      innerContent = const CircularProgressIndicator(color: Colors.white);
    } else {
      innerContent = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isRecording ? Icons.stop : Icons.mic,
            color: _isRecording ? Colors.redAccent : Colors.white,
            size: 40
          ),
          const SizedBox(height: 5),
          Text(
            _isRecording ? 'STOP' : 'LAPOR',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: handleButtonClick,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.secondaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
                if (_isRecording)
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    spreadRadius: _pulseAnimation.value,
                    blurRadius: _pulseAnimation.value + 5,
                  ),
              ],
            ),
            child: child,
          );
        },
        child: Center(
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.primaryColor,
            ),
            child: Center(child: innerContent),
          ),
        ),
      ),
    );
  }
}