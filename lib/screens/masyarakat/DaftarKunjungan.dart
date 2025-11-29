import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter/services.dart'; // [PENTING] Untuk validasi angka
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart'; // Pastikan package ini terinstall

// Model Data Jadwal
class JadwalBooked {
  final DateTime date;
  final String namaSekolah;

  JadwalBooked({required this.date, required this.namaSekolah});
}

class DaftarKunjunganScreen extends StatefulWidget {
  const DaftarKunjunganScreen({Key? key}) : super(key: key);

  @override
  State<DaftarKunjunganScreen> createState() => _DaftarKunjunganScreenState();
}

class _DaftarKunjunganScreenState extends State<DaftarKunjunganScreen> {
  // --- CONTROLLERS ---
  final TextEditingController _namaSekolahController = TextEditingController();
  final TextEditingController _jumlahSiswaController = TextEditingController();
  final TextEditingController _pjSekolahController = TextEditingController();
  final TextEditingController _kontakPjController = TextEditingController();
  
  // Controller untuk Form Tanggal (Read Only, terisi otomatis dari Kalender)
  final TextEditingController _tanggalDisplayController = TextEditingController();

  // --- STATE ---
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDate;
  List<PlatformFile> _selectedFiles = [];
  bool _isSubmitting = false;
  bool _isLoadingJadwal = true;
  
  // Data Jadwal dari Database
  List<JadwalBooked> _bookedDates = [];
  final Dio _dio = Dio();

  // URL Setup (Menyesuaikan Emulator/Web)
  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:5000/api';
    } catch (e) {
      return 'http://localhost:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  @override
  void initState() {
    super.initState();
    _fetchExistingJadwal();
  }

  @override
  void dispose() {
    _namaSekolahController.dispose();
    _jumlahSiswaController.dispose();
    _pjSekolahController.dispose();
    _kontakPjController.dispose();
    _tanggalDisplayController.dispose();
    super.dispose();
  }

  // --- FETCH DATA JADWAL DARI API ---
  Future<void> _fetchExistingJadwal() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token') ?? prefs.getString('authToken');
      if (token == null) return;

      final response = await _dio.get(
        '$_baseUrl/kunjungan',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = (response.data['data'] is List) 
            ? response.data['data'] 
            : response.data;

        final List<JadwalBooked> loadedJadwal = [];
        
        // Filter hanya yang statusnya 'approved'
        for (var item in data) {
          if (item['status'] == 'approved' && item['tanggal_kunjungan'] != null) {
            try {
              DateTime parsedDate = DateTime.parse(item['tanggal_kunjungan'].toString());
              loadedJadwal.add(JadwalBooked(
                date: parsedDate,
                namaSekolah: item['nama_sekolah'] ?? 'Terisi',
              ));
            } catch (e) {
              debugPrint("Error parse date: $e");
            }
          }
        }
        if (mounted) setState(() { _bookedDates = loadedJadwal; _isLoadingJadwal = false; });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingJadwal = false);
    }
  }

  // Helper: Cek apakah tanggal tertentu sudah dibooking
  List<JadwalBooked> _getBookedInfoForDay(DateTime day) {
    return _bookedDates.where((jadwal) => isSameDay(jadwal.date, day)).toList();
  }

  // Helper: Format Tanggal Indonesia
  String _formatDateToIndonesian(DateTime date) {
    try {
      // Menggunakan locale 'id_ID' (Pastikan initializeDateFormatting sudah dipanggil di main.dart jika perlu)
      // Jika error locale, fallback ke format sederhana
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return DateFormat('yyyy-MM-dd').format(date);
    }
  }

  // --- LOGIKA UPLOAD FILE ---
  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: true,
        withData: true, // Penting untuk Web
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files.where((file) => 
            ['pdf', 'doc', 'docx'].contains(file.extension?.toLowerCase() ?? '')).toList());
        });
      }
    } catch (e) {
      _showSnackBar('Gagal memilih file.', isError: true);
    }
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  // --- SUBMIT FORM ---
  Future<void> _submitForm() async {
    // 1. Validasi Input Kosong
    if (_namaSekolahController.text.isEmpty ||
        _jumlahSiswaController.text.isEmpty ||
        _pjSekolahController.text.isEmpty ||
        _kontakPjController.text.isEmpty ||
        _selectedDate == null) {
      _showSnackBar('Harap lengkapi semua data dan pilih tanggal!', isError: true);
      return;
    }

    // 2. Validasi Tanggal Penuh (Double Check)
    if (_getBookedInfoForDay(_selectedDate!).isNotEmpty) {
      _showSnackBar('Maaf, tanggal tersebut sudah penuh.', isError: true);
      return;
    }

    // 3. Validasi File
    if (_selectedFiles.isEmpty) {
      _showSnackBar('Wajib upload surat permohonan.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token') ?? prefs.getString('authToken');
      if (token == null) throw Exception('AUTH_ERROR');

      // 4. Siapkan Data
      FormData formData = FormData.fromMap({
        'namaSekolah': _namaSekolahController.text,
        'jumlahSiswa': _jumlahSiswaController.text,
        'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate!), // Format API YYYY-MM-DD
        'pjSekolah': _pjSekolahController.text,
        'kontakPj': _kontakPjController.text,
      });

      // 5. Attach Files
      for (var file in _selectedFiles) {
        MultipartFile multipartFile;
        if (kIsWeb && file.bytes != null) {
            multipartFile = MultipartFile.fromBytes(file.bytes!, filename: file.name);
        } else if (file.path != null) {
            multipartFile = await MultipartFile.fromFile(file.path!, filename: file.name);
        } else {
             continue;
        }
        formData.files.add(MapEntry('suratFiles', multipartFile));
      }

      // 6. Kirim Request
      final response = await _dio.post(
        '$_baseUrl/kunjungan',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Pendaftaran berhasil diajukan!', isError: false);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Gagal mengirim data. Periksa koneksi.', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // --- UI UTAMA ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        title: const Text('Daftar Kunjungan', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              // [BAGIAN 1] WIDGET KALENDER
              _buildCalendarSection(),
              
              const SizedBox(height: 24),
              const Text("Data Kunjungan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              // [BAGIAN 2] FORM INPUT
              _buildInputContainer(
                child: TextField(
                  controller: _namaSekolahController,
                  decoration: _inputDecoration('Nama Sekolah'),
                  enabled: !_isSubmitting,
                ),
              ),
              const SizedBox(height: 12),

              // Form Jumlah Siswa (Hanya Angka)
              _buildInputContainer(
                child: TextField(
                  controller: _jumlahSiswaController,
                  decoration: _inputDecoration('Jumlah Siswa'),
                  keyboardType: TextInputType.number, 
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly], // [FIX] Hanya Angka
                  enabled: !_isSubmitting,
                ),
              ),
              const SizedBox(height: 12),

              // Form Tanggal (Read Only - Terhubung ke Kalender)
              _buildInputContainer(
                child: TextField(
                  controller: _tanggalDisplayController,
                  readOnly: true, // User tidak bisa mengetik manual
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    hintText: 'Pilih Tanggal pada Kalender di atas',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                  ),
                  onTap: () {
                     // Scroll ke atas saat diklik agar user lihat kalender
                     Scrollable.ensureVisible(context, alignment: 0.0);
                  },
                ),
              ),
              const SizedBox(height: 12),

              _buildInputContainer(
                child: TextField(
                  controller: _pjSekolahController,
                  decoration: _inputDecoration('Nama PJ Sekolah'),
                  enabled: !_isSubmitting,
                ),
              ),
              const SizedBox(height: 12),

              // Form Kontak PJ (Hanya Angka)
              _buildInputContainer(
                child: TextField(
                  controller: _kontakPjController,
                  decoration: _inputDecoration('Kontak PJ (HP)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly], // [FIX] Hanya Angka
                  enabled: !_isSubmitting,
                ),
              ),
              const SizedBox(height: 24),

              // [BAGIAN 3] UPLOAD & SUBMIT
              _buildUploadSection(),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Ajukan Pendaftaran', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET KALENDER YANG SUDAH DIPERBAIKI ---
  Widget _buildCalendarSection() {
    // [FIX UTAMA] Normalisasi Waktu agar Hari Ini bisa diklik
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Jam di-set ke 00:00:00

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _isLoadingJadwal 
            ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())
            : TableCalendar(
                locale: 'id_ID',
                // [FIX] Gunakan 'today' yang bersih dari jam/menit
                firstDay: today, 
                lastDay: DateTime(today.year + 1, today.month, today.day),
                focusedDay: _focusedDay,
                currentDay: today,
                
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                
                // Menentukan Hari yang Terpilih
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDate, day);
                },

                // LOGIKA SAAT TANGGAL DIKLIK
                onDaySelected: (selectedDay, focusedDay) {
                  // Cek apakah hari tersebut penuh (merah)
                  final booked = _getBookedInfoForDay(selectedDay);
                  if (booked.isNotEmpty) {
                    _showSnackBar("Tanggal ini penuh oleh ${booked.first.namaSekolah}", isError: true);
                    return; 
                  }

                  setState(() {
                    _selectedDate = selectedDay;
                    _focusedDay = focusedDay; 
                    
                    // [FIX] Update Form Tanggal di bawah secara otomatis
                    _tanggalDisplayController.text = _formatDateToIndonesian(selectedDay);
                  });
                },

                // Custom Tampilan Hari
                calendarBuilders: CalendarBuilders(
                  // 1. Hari Booked (Merah)
                  defaultBuilder: (context, day, focusedDay) {
                     final booked = _getBookedInfoForDay(day);
                     if (booked.isNotEmpty) return _buildBookedDay(day, booked.first.namaSekolah);
                     return null;
                  },
                  // 2. Hari Ini (Biru atau Merah jika booked)
                  todayBuilder: (context, day, focusedDay) {
                     final booked = _getBookedInfoForDay(day);
                     if (booked.isNotEmpty) return _buildBookedDay(day, booked.first.namaSekolah);
                     return Container(
                       margin: const EdgeInsets.all(4), alignment: Alignment.center,
                       decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                       child: Text('${day.day}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                     );
                  },
                  // 3. Hari Terpilih (Orange)
                  selectedBuilder: (context, day, focusedDay) {
                    return Container(
                      margin: const EdgeInsets.all(4), alignment: Alignment.center,
                      decoration: BoxDecoration(color: const Color(0xFFFCD3B2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange)),
                      child: Text('${day.day}', style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
            // Legend
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 12, height: 12, color: const Color(0xFFFFEDED)),
                  const SizedBox(width: 4), const Text("Penuh", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(width: 16),
                  Container(width: 12, height: 12, color: const Color(0xFFFCD3B2)),
                  const SizedBox(width: 4), const Text("Pilihan Anda", style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildBookedDay(DateTime day, String label) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: const Color(0xFFFFEDED), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFF8C6C6))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${day.day}', style: const TextStyle(color: Colors.red, fontSize: 12)),
          // Chip kecil nama sekolah
          Text(label, style: const TextStyle(fontSize: 7, color: Colors.red), overflow: TextOverflow.ellipsis, maxLines: 1),
        ],
      ),
    );
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Upload Dokumen", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickFiles,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8), color: Colors.grey.shade50),
              child: Center(child: Column(children: const [Icon(Icons.upload_file, color: Colors.grey), Text("Pilih PDF/Word", style: TextStyle(color: Colors.grey))])),
            ),
          ),
          const SizedBox(height: 8),
          ..._selectedFiles.asMap().entries.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.description, size: 20),
              title: Text(e.value.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 20), onPressed: () => _removeFile(e.key)),
            ),
          )),
        ],
      ),
    );
  }
}