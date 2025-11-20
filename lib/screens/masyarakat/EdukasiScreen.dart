import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/screens/masyarakat/DetailEdukasiScreen.dart';
import 'package:http/http.dart' as http;
import '../../models/edukasi.dart';


// --- 2. Halaman List Edukasi ---
class EdukasiListScreen extends StatefulWidget {
  const EdukasiListScreen({super.key});

  @override
  State<EdukasiListScreen> createState() => _EdukasiListScreenState();
}

class _EdukasiListScreenState extends State<EdukasiListScreen> {
  // State variables mirip dengan useState di React
  List<Edukasi> edukasiList = [];
  bool isLoading = true;
  String errorMessage = '';

  // Konfigurasi API
  // CATATAN PENTING: 
  // Jika pakai Emulator Android, gunakan '10.0.2.2' bukan 'localhost'.
  // Jika di HP fisik, gunakan IP Address Laptop (misal '192.168.1.x').
  final String baseUrl = 'http://localhost:5000/api/edukasi';
  final String placeholderImage = 'https://via.placeholder.com/300x160.png?text=Info+Damkar';

  @override
  void initState() {
    super.initState();
    fetchEdukasi();
  }

  // Logic Fetch Data (Pengganti fetchEdukasi di React)
  Future<void> fetchEdukasi() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];
        
        setState(() {
          edukasiList = data.map((item) => Edukasi.fromJson(item)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal mengambil data dari server: $e';
        isLoading = false;
      });
      debugPrint('Error fetching edukasi: $e');
    }
  }

  // Helper: Strip HTML Tags (Pengganti fungsi stripHtml)
  String stripHtml(String htmlString) {
    final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '');
  }

  // Helper: Cek Image URL
  bool isImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return RegExp(r'\.(jpg|jpeg|png|gif|webp)$', caseSensitive: false).hasMatch(url);
  }

  // Navigasi ke Detail
  void _navigateToDetail(BuildContext context, Edukasi Edukasi) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Kita kirim seluruh objek ke halaman detail
        builder: (context) => DetailEdukasiScreen(edukasi: Edukasi),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edukasi Masyarakat"),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(), // Kembali ke Home
        ),
      ),
      backgroundColor: Colors.grey[100], // Latar abu-abu muda netral
      body: RefreshIndicator(
        onRefresh: fetchEdukasi,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // 1. Loading State
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Error State
    if (errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchEdukasi,
                child: const Text("Coba Lagi"),
              )
            ],
          ),
        ),
      );
    }

    // 3. Empty State
    if (edukasiList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              "Belum ada konten edukasi",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Konten baru akan segera ditambahkan.",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // 4. List Content (Grid View untuk Tablet, ListView untuk HP)
    // Di sini kita gunakan ListView agar rapi di Mobile, mirip tumpukan Card
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: edukasiList.length,
      itemBuilder: (context, index) {
        final item = edukasiList[index];
        return _buildEdukasiCard(item);
      },
    );
  }

  Widget _buildEdukasiCard(Edukasi item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2, // Shadow lembut
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Agar gambar mengikuti border radius
      child: InkWell(
        onTap: () => _navigateToDetail(context, item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Header
            SizedBox(
              height: 160,
              width: double.infinity,
              child: Image.network(
                isImageUrl(item.fileUrl) ? item.fileUrl! : placeholderImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.network(placeholderImage, fit: BoxFit.cover);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
            
            // Konten Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul
                  Text(
                    item.judul,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Chip Kategori (Warna Warning/Orange Damkar)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100], // warning.light equivalent
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      item.kategori,
                      style: TextStyle(
                        color: Colors.orange[900], // warning.dark equivalent
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Deskripsi Singkat (Stripped HTML)
                  Text(
                    stripHtml(item.isiKonten),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600], // text.secondary
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}