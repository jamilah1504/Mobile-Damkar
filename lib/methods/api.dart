// lib/methods/api.dart

import 'package:dio/dio.dart';

class ApiService {
  // Instance Dio Anda
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:5000/api', // Base URL Anda
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Metode Login (sudah ada)
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
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

  // --- INI ADALAH FUNGSI BARU YANG WAJIB DITAMBAHKAN ---
  Future<Map<String, dynamic>> register(
    String name,
    String username,
    String email,
    String password,
  ) async {
    try {
      // Pastikan endpoint '/auth/register' ini sesuai dengan API Anda
      final response = await _dio.post(
        '/auth/register', // Sesuaikan jika endpoint Anda berbeda
        data: {
          'name': name,
          'username': username,
          'email': email,
          'password': password,
        },
      );
      // Mengembalikan data jika sukses (misal: "registrasi berhasil")
      return response.data;
    } on DioException catch (e) {
      // Menangani error spesifik dari server (misal: "username sudah dipakai")
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
}
