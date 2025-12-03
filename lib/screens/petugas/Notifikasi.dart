import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal
import 'package:intl/date_symbol_data_local.dart'; // Untuk locale Indonesia
import 'package:flutter/foundation.dart'; // Untuk kIsWeb

// --- 1. MODEL DATA (Sesuai Interface TypeScript) ---
class Notifikasi {
  final int id;
  final String judul;
  final String isiPesan;
  final String timestamp;
  final int? userId;

  Notifikasi({
    required this.id,
    required this.judul,
    required this.isiPesan,
    required this.timestamp,
    this.userId,
  });

  factory Notifikasi.fromJson(Map<String, dynamic> json) {
    return Notifikasi(
      id: json['id'] ?? 0,
      judul: json['judul'] ?? 'Tanpa Judul',
      isiPesan: json['isiPesan'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      userId: json['userId'],
    );
  }
}

// --- 2. HALAMAN UTAMA ---
class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  // Logika Base URL (Web vs Emulator)
  final String _baseUrl = 'http://localhost:5000';
  final Dio _dio = Dio();

  List<Notifikasi> _notifikasiList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null); // Inisialisasi locale format tanggal
    _fetchNotifikasi();
  }

  Future<void> _fetchNotifikasi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Request ke API
      final response = await _dio.get('$_baseUrl/api/notifikasi');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        // Mapping JSON ke List<Notifikasi>
        List<Notifikasi> parsedList = data.map((json) => Notifikasi.fromJson(json)).toList();
        
        // Opsional: Sort berdasarkan waktu terbaru
        parsedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        setState(() {
          _notifikasiList = parsedList;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat notifikasi. Periksa koneksi server.';
      });
      debugPrint("Error fetching notifikasi: $e");
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Warna Body Putih
      backgroundColor: Colors.white, 

      // 2. Header Merah menggunakan AppBar
      appBar: AppBar(
        backgroundColor: const Color(0xFFDC2626), // Merah
        elevation: 0, // Hilangkan bayangan agar terlihat flat (opsional)
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Ikon Putih
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white, // Teks Putih
          ),
        ),
      ),

      // 3. Isi Halaman (Body)
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Jarak pinggir untuk isi konten
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header manual yang lama DIHAPUS karena sudah diganti AppBar di atas
              
              // --- CONTENT LIST ---
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFDC2626)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_notifikasiList.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada notifikasi saat ini.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _notifikasiList.length,
      itemBuilder: (context, index) {
        return NotificationCard(item: _notifikasiList[index]);
      },
    );
  }
}

// --- 3. WIDGET KARTU NOTIFIKASI (NotificationCard) ---
class NotificationCard extends StatefulWidget {
  final Notifikasi item;

  const NotificationCard({super.key, required this.item});

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  bool _expanded = false;

  // Helper Format Tanggal (Mirip fungsi di TSX)
  String _formatTanggal(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      // Format: "17:00, Sabtu 17 Agustus 2024"
      return DateFormat('HH:mm, EEEE d MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _expanded = !_expanded;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6), // Abu-abu muda (#F3F4F6)
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD1D5DB)), // Border abu (#D1D5DB)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row Atas: Judul & Icon Panah
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul
                Expanded(
                  child: Text(
                    widget.item.judul,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626), // Merah (#DC2626)
                    ),
                  ),
                ),
                // Icon Panah
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xFF374151), // Abu tua (#374151)
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Isi Pesan (Expandable)
            AnimatedCrossFade(
              firstChild: Text(
                widget.item.isiPesan,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF374151), height: 1.5),
              ),
              secondChild: Text(
                widget.item.isiPesan,
                style: const TextStyle(color: Color(0xFF374151), height: 1.5),
              ),
              crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),

            const SizedBox(height: 12),

            // Timestamp (Kanan Bawah)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _formatTanggal(widget.item.timestamp),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFEF4444), // Merah agak muda (#EF4444)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}