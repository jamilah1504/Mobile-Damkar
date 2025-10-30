import 'package:flutter/material.dart';
import './laporan/RiwayatLaporanScreen.dart';
import 'DetailEdukasiScreen.dart'; // Halaman detail
import '../../models/edukasi.dart';
import '../../methods/api.dart';

class MasyarakatHomeScreen extends StatefulWidget {
  const MasyarakatHomeScreen({super.key});

  @override
  State<MasyarakatHomeScreen> createState() => _MasyarakatHomeScreenState();
}

class _MasyarakatHomeScreenState extends State<MasyarakatHomeScreen> {
  late Future<List<Edukasi>> futureEdukasi;

  @override
  void initState() {
    super.initState();
    _loadEdukasi();
  }

  void _loadEdukasi() {
    futureEdukasi = ApiService().getEdukasi();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.red.shade800;
    final Color secondaryColor = Colors.red.shade600;
    final Color backgroundColor = Colors.grey.shade100;
    final Color cardColor = Colors.white;
    final Color textColor = Colors.black87;
    final Color subtleTextColor = Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'Images/logo2.png',
            width: 40,
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.shield, color: Colors.white, size: 24),
          ),
        ),
        title: const Text(
          'Pemadam Kebakaran\nKabupaten Subang',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadEdukasi();
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.asset(
                    'Images/image.png',
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: Colors.grey.shade300,
                      child: const Center(child: Text('Gagal Memuat Banner')),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Lapor
                _buildLaporSection(context, primaryColor, secondaryColor),
                const SizedBox(height: 24),

                // Layanan
                _buildLayananSection(context, secondaryColor, textColor),
                const SizedBox(height: 24),

                // Edukasi
                _buildEdukasiSection(
                  context,
                  cardColor,
                  textColor,
                  subtleTextColor,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifikasi',
          ),
        ],
        currentIndex: 0,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RiwayatLaporanScreen(),
              ),
            );
          }
        },
      ),
    );
  }

  // Lapor Section
  Widget _buildLaporSection(
    BuildContext context,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryColor.withOpacity(0.2),
          ),
          child: Center(
            child: Text(
              'LAPOR',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigasi ke Lapor Teks')),
                );
              },
              icon: const Icon(Icons.text_fields),
              label: const Text('Lapor Via Teks'),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Membuka Panggilan Telepon')),
                );
              },
              icon: const Icon(Icons.phone),
              label: const Text('Telepon'),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Layanan
  Widget _buildLayananSection(
    BuildContext context,
    Color buttonColor,
    Color textColor,
  ) {
    final List<Map<String, dynamic>> services = [
      {
        'icon': Icons.local_fire_department,
        'label': 'Lapor\nKebakaran',
        'action': () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigasi ke Lapor Kebakaran')),
        ),
      },
      {
        'icon': Icons.support,
        'label': 'Lapor Non\nKebakaran',
        'action': () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigasi ke Lapor Non Kebakaran')),
        ),
      },
      {
        'icon': Icons.bar_chart,
        'label': 'Grafik\nKejadian',
        'action': () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigasi ke Grafik Kejadian')),
        ),
      },
      {
        'icon': Icons.book,
        'label': 'Daftar\nKunjungan',
        'action': () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigasi ke Daftar Kunjungan')),
        ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Layanan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: services.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final service = services[index];
            return _buildServiceButton(
              service['icon'],
              service['label'],
              buttonColor,
              textColor,
              service['action'],
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceButton(
    IconData icon,
    String label,
    Color buttonColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Edukasi Section
  Widget _buildEdukasiSection(
    BuildContext context,
    Color cardColor,
    Color textColor,
    Color subtleTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Materi Edukasi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Edukasi>>(
          future: futureEdukasi,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Card(
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade600, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Gagal memuat edukasi',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        snapshot.error.toString(),
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Card(
                color: cardColor,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Belum ada materi edukasi tersedia.'),
                ),
              );
            }

            final edukasiList = snapshot.data!;
            return Column(
              children: edukasiList.map((edukasi) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildEdukasiCard(
                    edukasi,
                    cardColor,
                    textColor,
                    subtleTextColor,
                    context,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // Edukasi Card
  Widget _buildEdukasiCard(
    Edukasi edukasi,
    Color cardColor,
    Color textColor,
    Color subtleTextColor,
    BuildContext context,
  ) {
    final String previewText = edukasi.isiKonten.length > 80
        ? '${edukasi.isiKonten.substring(0, 80)}...'
        : edukasi.isiKonten;

    final String formattedDate =
        '${edukasi.timestampDibuat.day}/${edukasi.timestampDibuat.month}/${edukasi.timestampDibuat.year}';

    final bool isPdf =
        edukasi.fileUrl != null &&
        edukasi.fileUrl!.toLowerCase().endsWith('.pdf');

    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailEdukasiScreen(edukasi: edukasi),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.network(
                      'https://placehold.co/100x20/cccccc/000000?text=Partner',
                      height: 20,
                      errorBuilder: (_, __, ___) => const SizedBox(height: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      edukasi.judul,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      previewText,
                      style: TextStyle(fontSize: 12, color: subtleTextColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dipublikasikan: $formattedDate',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (isPdf)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              color: Colors.red.shade700,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'File PDF',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: isPdf
                    ? Container(
                        width: 100,
                        height: 80,
                        color: Colors.red.shade50,
                        child: const Center(
                          child: Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      )
                    : Image.network(
                        edukasi.fileUrl ??
                            'https://placehold.co/100x80/FFA07A/FFFFFF?text=Edukasi',
                        width: 100,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 100,
                          height: 80,
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 30),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
