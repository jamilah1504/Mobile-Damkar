import 'package:dio/dio.dart';
import '../models/edukasi.dart';
import '../models/laporan.dart';
import '../models/laporan_lapangan.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      // Port 5000 Anda sudah benar
      baseUrl: 'http://localhost:5000/api',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // --- (INI PERBAIKANNYA) ---
  // Parameter diubah dari 'username' menjadi 'email' agar sesuai dengan backend
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        // Mengirim 'email', bukan 'username'
        data: {'email': email, 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan');
      } else {
        throw Exception('Koneksi ke server gagal: ${e.message}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan yang tidak diketahui: $e');
    }
  }
  // -------------------------

  // Fungsi register (tetap sama)
  Future<Map<String, dynamic>> register(
    String name,
    String username,
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name,
          'username': username,
          'email': email,
          'password': password,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Registrasi gagal');
      } else {
        // Error jaringan
        throw Exception('Koneksi ke server gagal: ${e.message}');
      }
    } catch (e) {
      // Error tak terduga
      throw Exception('Terjadi kesalahan yang tidak diketahui: $e');
    }
  }

  Future<List<Edukasi>> getEdukasi() async {
    try {
      final response = await _dio.get('/edukasi');

      // DEBUG: Lihat respons (bisa dihapus nanti)
      print('API Response: ${response.data}');

      // Pastikan respons adalah Map dan memiliki 'data' berupa List
      if (response.data is Map<String, dynamic>) {
        final dataMap = response.data as Map<String, dynamic>;

        // Cek apakah 'data' ada dan berupa List
        if (dataMap['data'] is List) {
          return (dataMap['data'] as List)
              .map((item) => Edukasi.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(
            'Field "data" bukan List. Diterima: ${dataMap['data']}',
          );
        }
      } else {
        throw Exception('Respons bukan JSON Map. Diterima: ${response.data}');
      }
    } on DioException catch (e) {
      // Tangani error jaringan atau server
      if (e.response != null) {
        print('Server Error: ${e.response?.statusCode}');
        print('Body: ${e.response?.data}');
        throw Exception('Server error: ${e.response?.statusCode}');
      } else {
        throw Exception(
          'Tidak bisa terhubung ke server. Pastikan backend jalan.',
        );
      }
    } catch (e) {
      print('Parsing Error: $e');
      throw Exception('Gagal memproses data: $e');
    }
  }

  // GET RIWAYAT LAPORAN
  // Di dalam ApiService
  Future<List<Laporan>> getRiwayatLaporan(int userId) async {
    try {
      final response = await _dio.get('/reports');

      // DEBUG: Lihat struktur respons
      print('Raw Response: ${response.data}');

      // Pastikan respons adalah Map dan ada field 'data'
      if (response.data is! Map<String, dynamic>) {
        throw Exception('Format respons tidak valid');
      }

      final Map<String, dynamic> json = response.data;
      final List<dynamic> dataList = json['data'] as List<dynamic>;

      return dataList
          .where((r) => r['pelaporId'] == userId)
          .map((json) => Laporan.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Gagal memuat laporan');
      } else {
        throw Exception('Tidak dapat terhubung ke server');
      }
    } catch (e) {
      print('Error parsing laporan: $e');
      rethrow;
    }
  }
}
