import 'package:dio/dio.dart';
// --- PERBAIKAN DI SINI ---
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // <-- Tambahan untuk debugPrint
// -------------------------
import '../models/edukasi.dart';
import '../models/laporan.dart';
import '../models/laporan_lapangan.dart';

class ApiService {
  late Dio _dio;

  final String _baseUrl = 'http://localhost:5000/api';
  ApiService() {
    final BaseOptions options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio = Dio(options);
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final bool isAuthRequest =
              options.path == '/auth/login' || options.path == '/auth/register';
          if (isAuthRequest) {
            return handler.next(options);
          }

          // Baris ini sekarang valid karena sudah di-import
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          final String? token = prefs.getString('authToken');

          if (token == null || token.isEmpty) {
            // --- Ganti print -> debugPrint ---
            debugPrint(
              'Interceptor: Token tidak ditemukan. Request dibatalkan.',
            );
            return handler.reject(
              DioException(
                requestOptions: options,
                message: 'Token tidak ditemukan. Silakan login kembali.',
              ),
            );
          }

          // --- Ganti print -> debugPrint ---
          debugPrint('Interceptor: Token ditemukan, ditambahkan ke header.');
          options.headers['Authorization'] = 'Bearer $token';

          return handler.next(options);
        },

        onResponse: (response, handler) {
          return handler.next(response);
        },

        onError: (err, handler) async {
          if (err.response?.statusCode == 401) {
            // --- Ganti print -> debugPrint ---
            debugPrint('Interceptor: Terjadi Error 401 (Unauthorized)');
          }
          return handler.next(err);
        },
      ),
    );
  }

  // ... (Fungsi login dan register tidak perlu diubah) ...
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
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
        throw Exception('Koneksi ke server gagal: ${e.message}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan yang tidak diketahui: $e');
    }
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final response = await _dio.get('/users/profile');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Gagal ambil profil');
      } else {
        throw Exception('Koneksi ke server gagal: ${e.message}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan yang tidak diketahui: $e');
    }
  }

  Future<Map<String, dynamic>> createLaporan(String isiLaporan) async {
    try {
      final response = await _dio.post(
        '/laporan/create',
        data: {'isi_laporan': isiLaporan},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Gagal buat laporan');
      } else {
        throw Exception('Koneksi ke server gagal: ${e.message}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan yang tidak diketahui: $e');
    }
  }

  Future<List<Edukasi>> getEdukasi() async {
    try {
      final response = await _dio.get('/edukasi');

      // --- Ganti print -> debugPrint ---
      debugPrint('API Response: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        final dataMap = response.data as Map<String, dynamic>;

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
      if (e.response != null) {
        // --- Ganti print -> debugPrint ---
        debugPrint('Server Error: ${e.response?.statusCode}');
        debugPrint('Body: ${e.response?.data}');
        throw Exception('Server error: ${e.response?.statusCode}');
      } else {
        throw Exception(
          'Tidak bisa terhubung ke server. Pastikan backend jalan.',
        );
      }
    } catch (e) {
      // --- Ganti print -> debugPrint ---
      debugPrint('Parsing Error: $e');
      throw Exception('Gagal memproses data: $e');
    }
  }

  Future<List<Laporan>> getRiwayatLaporan(int userId) async {
    try {
      final response = await _dio.get('/reports');

      debugPrint('Raw Response: ${response.data}');

      if (response.data is List) {
        // Jika respons adalah List (array JSON langsung), ini adalah data laporan.
        final List<dynamic> dataList = response.data as List<dynamic>;
        return dataList
            .where((r) => r['pelaporId'] == userId)
            .map((json) => Laporan.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.data is Map<String, dynamic>) {
        // Jika respons adalah Map (struktur standar API: {data: [...]})
        final Map<String, dynamic> json = response.data as Map<String, dynamic>;

        // Periksa apakah key 'data' ada dan berupa List
        if (json.containsKey('data') && json['data'] is List) {
          final List<dynamic> dataList = json['data'] as List<dynamic>;

          // Lakukan pemfilteran seperti sebelumnya
          return dataList
              .where((r) => r['pelaporId'] == userId)
              .map((json) => Laporan.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          // Respons Map tetapi tidak memiliki key 'data' yang valid
          throw Exception(
            'Format respons laporan tidak valid (Map tanpa data List)',
          );
        }
      } else {
        // Jika format respons benar-benar tidak terduga
        throw Exception(
          'Format respons tidak valid: Diterima bukan List atau Map',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Gagal memuat laporan');
      } else {
        throw Exception('Tidak dapat terhubung ke server. ${e.message}');
      }
    } catch (e) {
      debugPrint('Error parsing laporan: $e');
      // Ganti rethrow yang mungkin menghasilkan error yang kurang informatif
      throw Exception('Gagal memproses data laporan: ${e.toString()}');
    }
  }
}
