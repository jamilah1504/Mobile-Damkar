import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // PENTING: Untuk inisialisasi locale
import 'dart:convert';
import 'package:http/http.dart' as http;

// Konfigurasi URL API
const String baseUrl = 'http://localhost:5000'; 

// Model Data
class ReportData {
  final int id;
  final String deskripsi;
  final String jenisKejadian;
  final String status;
  final String timestampDibuat;

  ReportData({
    required this.id,
    required this.deskripsi,
    required this.jenisKejadian,
    required this.status,
    required this.timestampDibuat,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      id: json['id'] ?? 0,
      deskripsi: json['deskripsi'] ?? '',
      jenisKejadian: (json['jenisKejadian'] as String?)?.trim() ?? 'Lainnya',
      status: json['status'] ?? 'Tanpa Status',
      timestampDibuat: json['timestampDibuat'] ?? DateTime.now().toIso8601String(),
    );
  }
}

class GrafikLaporanScreen extends StatefulWidget {
  const GrafikLaporanScreen({super.key});

  @override
  State<GrafikLaporanScreen> createState() => _GrafikLaporanScreenState();
}

class _GrafikLaporanScreenState extends State<GrafikLaporanScreen> {
  bool _loading = true;
  
  // State Data
  List<ReportData> _masterData = [];
  List<ReportData> _filteredData = [];

  // State Filter
  DateTime? _startDate;
  DateTime? _endDate;
  String _filterJenis = 'All';
  String _filterStatus = 'All';

  // State Statistik
  int _total = 0;
  int _kebakaran = 0;
  int _nonKebakaran = 0;
  
  // Data untuk Chart
  List<FlSpot> _trendSpots = [];
  List<String> _trendLabels = [];
  Map<String, double> _jenisMap = {};
  Map<String, double> _statusMap = {};

  @override
  void initState() {
    super.initState();
    // 1. PERBAIKAN TREN: Inisialisasi format tanggal Indonesia sebelum fetch data
    initializeDateFormatting('id_ID', null).then((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/reports'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final rawData = jsonData.map((e) => ReportData.fromJson(e)).toList();

        if (mounted) {
          setState(() {
            _masterData = rawData;
            _filteredData = List.from(rawData);
            _loading = false;
          });
          _processData(_filteredData);
        }
      } else {
        throw Exception('Gagal mengambil data: ${response.statusCode}');
      }

    } catch (error) {
      debugPrint("Error Fetch Data: $error");
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    if (_masterData.isEmpty) return;

    List<ReportData> temp = List.from(_masterData);

    // Filter Jenis
    if (_filterJenis != 'All') {
      if (_filterJenis == 'Lainnya') {
        temp = temp.where((d) {
          final jenis = d.jenisKejadian.trim().toLowerCase();
          return jenis != 'kebakaran' && jenis != 'non kebakaran';
        }).toList();
      } else {
        temp = temp.where((d) => 
          d.jenisKejadian.trim().toLowerCase() == _filterJenis.toLowerCase()
        ).toList();
      }
    }

    // Filter Status
    if (_filterStatus != 'All') {
      temp = temp.where((d) => d.status == _filterStatus).toList();
    }

    // Filter Tanggal
    if (_startDate != null) {
      temp = temp.where((d) {
        final t = DateTime.parse(d.timestampDibuat);
        return t.isAfter(_startDate!) || t.isAtSameMomentAs(_startDate!);
      }).toList();
    }

    if (_endDate != null) {
      final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      temp = temp.where((d) {
        final t = DateTime.parse(d.timestampDibuat);
        return t.isBefore(endOfDay);
      }).toList();
    }

    setState(() {
      _filteredData = temp;
    });
    _processData(temp);
  }

  void _processData(List<ReportData> data) {
    int total = data.length;
    int keb = data.where((d) => d.jenisKejadian.trim().toLowerCase() == 'kebakaran').length;
    int nonKeb = data.where((d) => d.jenisKejadian.trim().toLowerCase() == 'non kebakaran').length;

    // --- Logic Tren Harian ---
    Map<String, int> dateMap = {};
    
    // Clone dan sort agar tidak merusak list asli
    List<ReportData> sortedData = List.from(data);
    sortedData.sort((a, b) => a.timestampDibuat.compareTo(b.timestampDibuat));
    
    for (var item in sortedData) {
      try {
        final date = DateTime.parse(item.timestampDibuat);
        // Gunakan id_ID karena sudah di-init di initState
        final formatted = DateFormat('d MMM', 'id_ID').format(date); 
        dateMap[formatted] = (dateMap[formatted] ?? 0) + 1;
      } catch (e) {
        debugPrint("Error parsing date: $e");
      }
    }

    List<FlSpot> spots = [];
    List<String> labels = [];
    int index = 0;
    dateMap.forEach((key, value) {
      spots.add(FlSpot(index.toDouble(), value.toDouble()));
      labels.add(key);
      index++;
    });

    // --- Logic Pie Chart ---
    Map<String, double> jMap = {};
    for (var item in data) {
      String rawJenis = item.jenisKejadian.trim();
      String jenis = rawJenis.isEmpty ? 'Lainnya' : rawJenis;
      jenis = toBeginningOfSentenceCase(jenis.toLowerCase()) ?? jenis;
      jMap[jenis] = (jMap[jenis] ?? 0) + 1;
    }

    // --- Logic Bar Chart ---
    Map<String, double> sMap = {};
    for (var item in data) {
      String status = item.status.isEmpty ? 'Tanpa Status' : item.status;
      sMap[status] = (sMap[status] ?? 0) + 1;
    }

    setState(() {
      _total = total;
      _kebakaran = keb;
      _nonKebakaran = nonKeb;
      _trendSpots = spots;
      _trendLabels = labels;
      _jenisMap = jMap;
      _statusMap = sMap;
    });
  }

  void _resetFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _filterJenis = 'All';
      _filterStatus = 'All';
    });
    _applyFilters();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked; else _endDate = picked;
      });
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),

        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("Grafik Kejadian", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: OutlinedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.restart_alt, color: Colors.white),
              label: const Text("Reset", style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterPanel(context), // 2. PERBAIKAN FILTER: Menggunakan layout responsif
            const SizedBox(height: 24),
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildChartContainer(
              title: "Tren Kejadian",
              height: 350,
              child: _trendSpots.isEmpty 
                ? const Center(child: Text("Tidak ada data untuk ditampilkan")) 
                : _buildLineChart(),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 600;
                return Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                       width: isWide ? (constraints.maxWidth / 2) - 12 : constraints.maxWidth,
                       margin: EdgeInsets.only(right: isWide ? 12 : 0, bottom: isWide ? 0 : 24),
                       child: _buildChartContainer(
                         title: "Proporsi Jenis",
                         height: 350,
                         child: _jenisMap.isEmpty 
                            ? const Center(child: Text("Tidak ada data"))
                            : _buildPieChart(),
                       ),
                    ),
                    Container(
                       width: isWide ? (constraints.maxWidth / 2) - 12 : constraints.maxWidth,
                       margin: EdgeInsets.only(left: isWide ? 12 : 0),
                       child: _buildChartContainer(
                         title: "Sebaran Status",
                         height: 350,
                         child: _statusMap.isEmpty 
                            ? const Center(child: Text("Tidak ada data"))
                            : _buildBarChart(),
                       ),
                    ),
                  ],
                );
              }
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  // 2. PERBAIKAN FILTER: Membuat layout responsif (Column di HP, Wrap di Tablet)
  Widget _buildFilterPanel(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.red, width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.filter_list, color: Colors.grey),
              const SizedBox(width: 8),
              const Text("Filter Data", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            
            // Menggunakan LayoutBuilder agar widget menyesuaikan lebar layar
            LayoutBuilder(builder: (context, constraints) {
              // Jika lebar layar < 600 (HP), gunakan Column (vertical stack)
              // Jika lebar layar > 600 (Tablet), gunakan Wrap/Row
              bool isMobile = constraints.maxWidth < 600;
              
              List<Widget> filterWidgets = [
                _buildDateField("Dari Tanggal", _startDate, true),
                _buildDateField("Sampai Tanggal", _endDate, false),
                _buildDropdownField("Jenis Kejadian", _filterJenis, ['All', 'Kebakaran', 'Non Kebakaran'], (val) => _filterJenis = val!),
                _buildDropdownField("Status Laporan", _filterStatus, ['All', 'Menunggu Verifikasi', 'Investigasi', 'Diproses', 'Selesai'], (val) => _filterStatus = val!),
              ];

              if (isMobile) {
                // Tampilan Mobile: Column dengan jarak
                return Column(
                  children: filterWidgets.map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: w,
                  )).toList(),
                );
              } else {
                // Tampilan Tablet: Grid/Wrap
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: filterWidgets.map((w) => SizedBox(
                    width: (constraints.maxWidth - 48) / 2, // Bagi 2 kolom
                    child: w
                  )).toList(),
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk input tanggal
  Widget _buildDateField(String label, DateTime? value, bool isStart) {
    return TextField(
      readOnly: true,
      onTap: () => _selectDate(context, isStart),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today, size: 16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        hintText: value == null ? '-' : DateFormat('yyyy-MM-dd').format(value),
        isDense: true,
      ),
      controller: TextEditingController(text: value == null ? '' : DateFormat('yyyy-MM-dd').format(value)),
    );
  }

  // Helper widget untuk dropdown
  Widget _buildDropdownField(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label, 
        border: const OutlineInputBorder(), 
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      items: items.map((e) {
        String text = e == 'All' ? 'Semua' : e;
        return DropdownMenuItem(value: e, child: Text(text, style: const TextStyle(fontSize: 14)));
      }).toList(),
      onChanged: (val) {
        setState(() => onChanged(val));
        _applyFilters();
      },
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(builder: (context, constraints) {
      double width = constraints.maxWidth;
      int columns = width > 900 ? 3 : 1;
      double cardWidth = (width - ((columns - 1) * 16)) / columns;

      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(
            width: cardWidth,
            child: _buildSummaryItem("TOTAL", _total.toString(), Icons.assignment, Colors.blue),
          ),
          SizedBox(
            width: cardWidth,
            child: _buildSummaryItem("KEBAKARAN", _kebakaran.toString(), Icons.local_fire_department, Colors.red),
          ),
          SizedBox(
            width: cardWidth,
            child: _buildSummaryItem("NON KEBAKARAN", _nonKebakaran.toString(), Icons.warning, Colors.amber.shade800),
          ),
        ],
      );
    });
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4), topRight: Radius.circular(8), bottomRight: Radius.circular(8))),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 5)),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 32)),
              ],
            ),
            Icon(icon, size: 50, color: color.withValues(alpha: 0.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContainer({required String title, required double height, required Widget child}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    // Jika data kurang dari 2, FlChart kadang tidak merender garis dengan baik tanpa konfigurasi min/max X
    // Namun defaultnya biasanya cukup.
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < _trendLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    // Rotasi sedikit teks tanggal agar muat jika banyak data
                    child: Text(
                      _trendLabels[index], 
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox();
              },
              interval: 1, // Pastikan interval 1 agar semua label tanggal muncul (atau sesuaikan jika terlalu padat)
              reservedSize: 30,
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1)), // interval 1 agar sumbu Y bilangan bulat
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
        lineBarsData: [
          LineChartBarData(
            spots: _trendSpots,
            isCurved: true,
            color: Colors.red.shade700,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: Colors.red.withValues(alpha: 0.2)),
          ),
        ],
        minY: 0, // Mulai dari 0
      ),
    );
  }

  Widget _buildPieChart() {
    final List<Color> colors = [Colors.red, Colors.amber, Colors.grey, Colors.blue];
    int i = 0;

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: _jenisMap.entries.map((entry) {
          final color = colors[i % colors.length];
          i++;
          return PieChartSectionData(
            color: color,
            value: entry.value,
            title: '${entry.value.toInt()}',
            radius: 60,
            titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            badgeWidget: _buildBadge(entry.key, color),
            badgePositionPercentageOffset: 1.4, // Jarak label dari chart
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBarChart() {
    final List<Color> colors = [Colors.blue, Colors.green, Colors.orange, Colors.red];
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey, 
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.round().toString(),
                const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                int index = value.toInt();
                if (index >= 0 && index < _statusMap.keys.length) {
                  String text = _statusMap.keys.elementAt(index);
                  if (text.length > 8) text = "${text.substring(0, 8)}..";
                  return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: const TextStyle(fontSize: 10)));
                }
                return const SizedBox();
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: _statusMap.entries.map((entry) {
          final index = _statusMap.keys.toList().indexOf(entry.key);
          final color = colors[index % colors.length];
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: color,
                width: 20,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
              )
            ],
          );
        }).toList(),
      ),
    );
  }
}