import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'dart:io' show Platform; 
import 'package:flutter/services.dart'; // <-- BARU: Untuk FilteringTextInputFormatter
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class DaftarKunjunganScreen extends StatefulWidget {
  const DaftarKunjunganScreen({Key? key}) : super(key: key);

  @override
  State<DaftarKunjunganScreen> createState() => _DaftarKunjunganScreenState();
}

class _DaftarKunjunganScreenState extends State<DaftarKunjunganScreen> {
  // Controllers
  final TextEditingController _namaSekolahController = TextEditingController();
  final TextEditingController _jumlahSiswaController = TextEditingController();
  final TextEditingController _pjSekolahController = TextEditingController();
  final TextEditingController _kontakPjController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();

  // State
  DateTime? _selectedDate;
  List<PlatformFile> _selectedFiles = [];
  bool _isSubmitting = false;
  
  final Dio _dio = Dio();

  // [LOGIKA URL DINAMIS]
  // Menyesuaikan URL backend berdasarkan platform (Web vs Android Emulator)
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
  void dispose() {
    _namaSekolahController.dispose();
    _jumlahSiswaController.dispose();
    _pjSekolahController.dispose();
    _kontakPjController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }

  // Format tanggal ke bahasa Indonesia
  String _formatDateToIndonesian(DateTime date) {
    try {
      final DateFormat formatter = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
      return formatter.format(date);
    } catch (e) {
      return DateFormat('yyyy-MM-dd').format(date);
    }
  }

  // Pilih tanggal
  Future<void> _selectDate() async {
    if (!mounted) return;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD32F2F),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
        // Format YYYY-MM-DD sesuai database SQL
        _tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Pilih file dokumen
  Future<void> _pickFiles() async {
    try {
      // withData: true SANGAT PENTING untuk Web agar bytes terbaca
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: true,
        withData: true, 
      );

      if (result != null) {
        // Filter ekstensi valid
        final validFiles = result.files.where((file) {
          final ext = file.extension?.toLowerCase() ?? '';
          return ['pdf', 'doc', 'docx'].contains(ext);
        }).toList();

        if (validFiles.isEmpty) {
          _showSnackBar('Format file tidak didukung. Gunakan PDF/Word.', isError: true);
          return;
        }

        setState(() {
          _selectedFiles.addAll(validFiles);
        });
      }
    } catch (e) {
      debugPrint('Error pick files: $e');
      _showSnackBar('Gagal memilih file. Izin akses mungkin ditolak.', isError: true);
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  // Validasi format angka 10-15 digit
  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    return phoneRegex.hasMatch(phone);
  }

  // --- FUNGSI SUBMIT DENGAN PERBAIKAN FILE UPLOAD ---
  Future<void> _submitForm() async {
    // 1. Validasi Input
    if (_namaSekolahController.text.isEmpty ||
        _jumlahSiswaController.text.isEmpty ||
        _pjSekolahController.text.isEmpty ||
        _kontakPjController.text.isEmpty ||
        _selectedDate == null) {
      _showSnackBar('Harap lengkapi semua data yang diperlukan', isError: true);
      return;
    }

    if (_selectedFiles.isEmpty) {
      _showSnackBar('Wajib mengupload Surat Permohonan (PDF/Word)!', isError: true);
      return;
    }

    if (!_isValidPhone(_kontakPjController.text)) {
      _showSnackBar('Format nomor telepon tidak valid (10-15 angka).', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 2. Ambil Token
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token') ?? prefs.getString('authToken');

      if (token == null || token.isEmpty) {
        throw Exception('AUTH_ERROR');
      }

      // 3. Siapkan FormData
      FormData formData = FormData.fromMap({
        'namaSekolah': _namaSekolahController.text,
        'jumlahSiswa': _jumlahSiswaController.text,
        'tanggal': _tanggalController.text,
        'pjSekolah': _pjSekolahController.text,
        'kontakPj': _kontakPjController.text,
      });

      // 4. Attach Files (FIXED LOGIC)
      for (var file in _selectedFiles) {
        MultipartFile multipartFile;

        if (kIsWeb) {
          // [WEB] Gunakan BYTES. Jangan akses .path!
          if (file.bytes != null) {
            multipartFile = MultipartFile.fromBytes(
              file.bytes!,
              filename: file.name,
            );
          } else {
             continue; 
          }
        } else {
          // [MOBILE] Gunakan PATH agar hemat memori
          if (file.path != null) {
            multipartFile = await MultipartFile.fromFile(
              file.path!,
              filename: file.name,
            );
          } else {
             // Fallback
             multipartFile = MultipartFile.fromBytes(
                file.bytes ?? [],
                filename: file.name,
             );
          }
        }

        formData.files.add(MapEntry('suratFiles', multipartFile));
      }

      // 5. Kirim Request
      final response = await _dio.post(
        '$_baseUrl/kunjungan',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30), 
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Pendaftaran berhasil diajukan!', isError: false);
        
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      }

    } on DioException catch (e) {
      String msg = 'Gagal terhubung ke server.';
      
      if (e.response != null) {
        if (e.response?.statusCode == 401) {
          msg = 'Sesi berakhir. Silakan login kembali.';
           if (mounted) Navigator.pushReplacementNamed(context, '/login');
        } else if (e.response?.data != null && e.response?.data['msg'] != null) {
          msg = e.response?.data['msg'];
        }
      } 
      _showSnackBar(msg, isError: true);

    } catch (e) {
      if (e.toString().contains('AUTH_ERROR')) {
         _showSnackBar('Anda belum login.', isError: true);
         if(mounted) Navigator.pushReplacementNamed(context, '/login');
      } else {
         _showSnackBar('Gagal mengirim data. Periksa koneksi.', isError: true);
         debugPrint('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
            centerTitle: true,
        ),
        body: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        _buildInputContainer(
                            child: TextField(
                                controller: _namaSekolahController,
                                decoration: _inputDecoration('Nama Sekolah'),
                                enabled: !_isSubmitting,
                            ),
                        ),
                        const SizedBox(height: 12),
                        _buildInputContainer(
                            child: TextField(
                                controller: _jumlahSiswaController,
                                decoration: _inputDecoration('Jumlah Siswa'),
                                keyboardType: TextInputType.number,
                                enabled: !_isSubmitting,
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
                        // Kontak PJ DENGAN PEMBATASAN ANGKA
                        _buildInputContainer(
                            child: TextField(
                                controller: _kontakPjController,
                                decoration: _inputDecoration('Kontak PJ'),
                                // UBAH keyboardType menjadi number
                                keyboardType: TextInputType.number, 
                                // TAMBAHKAN inputFormatters ini
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                enabled: !_isSubmitting,
                            ),
                        ),
                        const SizedBox(height: 12),
                        _buildInputContainer(
                            child: InkWell(
                                onTap: _isSubmitting ? null : _selectDate,
                                child: InputDecorator(
                                    decoration: _inputDecoration(
                                        _selectedDate != null ? _formatDateToIndonesian(_selectedDate!) : 'Pilih Tanggal Kunjungan',
                                    ),
                                    child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                            Text(
                                                _selectedDate != null ? _formatDateToIndonesian(_selectedDate!) : 'Pilih Tanggal Kunjungan',
                                                style: TextStyle(
                                                    color: _selectedDate != null ? Colors.black87 : Colors.grey,
                                                ),
                                            ),
                                            const Icon(Icons.calendar_today, color: Colors.grey),
                                        ],
                                    ),
                                ),
                            ),
                        ),
                        const SizedBox(height: 24),
                        _buildUploadSection(),
                        const SizedBox(height: 24),
                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD32F2F),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                    : const Text(
                                        'Ajukan Pendaftaran',
                                        style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                            ),
                        ),
                    ],
                ),
            ),
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
      contentPadding: const EdgeInsets.all(16),
    );
  }

  Widget _buildUploadSection() {
     return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Upload Surat Permohonan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: Colors.red, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _isSubmitting ? null : _pickFiles,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: Column(
                children: [
                  Icon(Icons.upload_file, size: 32, color: Colors.grey.shade600),
                  const SizedBox(height: 8),
                  Text('Pilih File Dokumen (PDF/Word)', style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                ],
              ),
            ),
          ),
          if (_selectedFiles.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('File Terpilih:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ...List.generate(_selectedFiles.length, (index) => _buildFilePreview(index)),
          ],
          const SizedBox(height: 12),
          Text('* Wajib upload file .pdf, .doc, atau .docx', style: TextStyle(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildFilePreview(int index) {
    final file = _selectedFiles[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(Icons.description, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(child: Text(file.name, style: TextStyle(fontSize: 14, color: Colors.grey.shade800), overflow: TextOverflow.ellipsis)),
          if (!_isSubmitting)
            IconButton(icon: const Icon(Icons.close, size: 20), color: Colors.red, onPressed: () => _removeFile(index)),
        ],
      ),
    );
  }
}