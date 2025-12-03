import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; 
import '../models/edukasi.dart';
import '../models/laporan.dart';
import '../models/laporan_lapangan.dart';

class ApiService {
  late Dio _dio; 

  // Sesuaikan URL ini dengan IP server/laptop Anda jika menggunakan Emulator/HP Fisik
  // final String _baseUrl = 'http://localhost:5000/api';
  final String _baseUrl = 'http://192.168.1.7:5000/api'; // Contoh IP LAN

  ApiService() {
    final BaseOptions options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10), // Naikkan timeout sedikit
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio = Dio(options);
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          // Daftar URL yang TIDAK butuh token
          final bool isAuthRequest = options.path == '/auth/login' || 
                                     options.path == '/auth/register';
           
           if (isAuthRequest) {
             return handler.next(options); 
           }

          // Ambil token untuk request lain
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          final String? token = prefs.getString('authToken');

          if (token == null || token.isEmpty) {
            debugPrint('Interceptor: Token tidak ditemukan. Request dibatalkan.');
            return handler.reject(
              DioException(
                requestOptions: options,
                message: 'Token tidak ditemukan. Silakan login kembali.',
              ),
            );
          }

          // Tambahkan token ke header
          // debugPrint('Interceptor: Token ditemukan, ditambahkan ke header.');
          options.headers['Authorization'] = 'Bearer $token';

          return handler.next(options);
        },
        
        onResponse: (response, handler) {
          return handler.next(response);
        },
        
        onError: (err, handler) async {
          if (err.response?.statusCode == 401) {
            debugPrint('Interceptor: Terjadi Error 401 (Unauthorized)');
          }
          return handler.next(err); 
        },
      ),
    );
  }

  // === AUTH ===
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login', // Pastikan route backend benar (/users/login atau /auth/login)
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

  // === USER & PROFILE ===
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

  // === NOTIFIKASI (UPDATE FCM TOKEN) ===
  // Fungsi baru ditambahkan di sini
  Future<void> updateFcmToken(String fcmToken) async {
    try {
      // Kita tidak perlu ambil token Auth manual, Interceptor _dio akan menambahkannya
      final response = await _dio.put(
        '/notifikasi/update-token',
        data: {'fcmToken': fcmToken},
      );
      
      if (response.statusCode == 200) {
        debugPrint("FCM Token berhasil diupdate di database");
      }
    } on DioException catch (e) {
      debugPrint("Gagal update FCM Token: ${e.response?.data ?? e.message}");
      // Kita tidak throw error agar tidak mengganggu flow login jika notif gagal
    }
  }

  // === LAPORAN ===
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

  Future<List<Laporan>> getRiwayatLaporan(int userId) async {
    try {
      final response = await _dio.get('/reports'); // Sesuaikan endpoint backend
      debugPrint('Raw Response Reports: ${response.data}');

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
      debugPrint('Error parsing laporan: $e');
      rethrow;
    }
  }

  // === EDUKASI ===
  Future<List<Edukasi>> getEdukasi() async {
    try {
      final response = await _dio.get('/edukasi');
      // debugPrint('API Response Edukasi: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        final dataMap = response.data as Map<String, dynamic>;

        if (dataMap['data'] is List) {
          return (dataMap['data'] as List)
              .map((item) => Edukasi.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Respons bukan JSON Map.');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Server error: ${e.response?.statusCode}');
      } else {
        throw Exception('Tidak bisa terhubung ke server.');
      }
    } catch (e) {
      debugPrint('Parsing Error: $e');
      throw Exception('Gagal memproses data: $e');
    }
  }
}