import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/edukasi.dart';

class DetailEdukasiScreen extends StatelessWidget {
  final Edukasi edukasi;

  const DetailEdukasiScreen({super.key, required this.edukasi});

  Future<void> _launchPDF(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Tidak bisa membuka $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPdf = edukasi.fileUrl != null && edukasi.fileUrl!.toLowerCase().endsWith('.pdf');
    final String formattedDate =
        '${edukasi.timestampDibuat.day}/${edukasi.timestampDibuat.month}/${edukasi.timestampDibuat.year}';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade800,
        title: const Text('Detail Edukasi'),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(edukasi.judul, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
                  child: Text(edukasi.kategori, style: TextStyle(fontSize: 12, color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Text('Dipublikasikan: $formattedDate', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 16),
            if (edukasi.fileUrl != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: isPdf
                      ? Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.red.shade50,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.picture_as_pdf, size: 60, color: Colors.red),
                              const SizedBox(height: 8),
                              const Text('File PDF'),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () => _launchPDF(edukasi.fileUrl!),
                                icon: const Icon(Icons.download),
                                label: const Text('Buka PDF'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
                              ),
                            ],
                          ),
                        )
                      : Image.network(
                          edukasi.fileUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(height: 200, color: Colors.grey.shade300, child: const Center(child: Icon(Icons.broken_image, size: 50))),
                        ),
                ),
              ),
            const SizedBox(height: 16),
            const Text('Isi Konten:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(edukasi.isiKonten, style: const TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            if (isPdf)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _launchPDF(edukasi.fileUrl!),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Buka File PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}