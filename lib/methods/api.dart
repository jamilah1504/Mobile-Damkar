import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

class ApiService {
  // <-- 2. UBAH _dio MENJADI 'late'
  late Dio _dio; 
  
  // URL untuk emulator Android. Ganti ke localhost jika testing di web
  //final String _baseUrl = 'http://10.0.2.2:5000/api';
  final String _baseUrl = 'http://localhost:5000/api'; // <-- Gunakan ini untuk web

  // --- 3. TAMBAHKAN CONSTRUCTOR ---
  ApiService() {
    final BaseOptions options = BaseOptions(
      baseUrl: _baseUrl, // <-- Gunakan variabel _baseUrl
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio = Dio(options);

    // --- 4. TAMBAHKAN INTERCEPTOR OTOMATIS ---
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        // (handler) akan "menjeda" request
        onRequest: (options, handler) async {
          // Tentukan endpoint mana yang TIDAK perlu token
          final bool isAuthRequest = options.path == '/auth/login' || 
                                     options.path == '/auth/register';

          if (isAuthRequest) {
            // Jika ini request login/register, lanjutkan tanpa token
            return handler.next(options); 
          }

          // 1. Ambil token dari SharedPreferences
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          final String? token = prefs.getString('authToken');

          if (token == null || token.isEmpty) {
            // Jika token tidak ada (misal: belum login)
            // Anda bisa menghentikan request dengan error
            print('Interceptor: Token tidak ditemukan. Request dibatalkan.');
            return handler.reject(
              DioException(
                requestOptions: options,
                message: 'Token tidak ditemukan. Silakan login kembali.',
              ),
            );
          }

          // 2. Tambahkan token ke header
          print('Interceptor: Token ditemukan, ditambahkan ke header.');
          options.headers['Authorization'] = 'Bearer $token';

          // 3. Lanjutkan request dengan header baru
          return handler.next(options);
        },
        
        onResponse: (response, handler) {
          // Lanjutkan response (tidak perlu diubah)
          return handler.next(response);
        },
        
        onError: (err, handler) async {
          // --- 5. [OPSIONAL] LOGIC UNTUK REFRESH TOKEN ---
          // Jika token expired (misal status 401)
          if (err.response?.statusCode == 401) {
            // Di sini Anda bisa menambahkan logic untuk "refresh token"
            // jika API Anda mendukungnya.
            // Untuk saat ini, kita hanya teruskan error-nya.
            print('Interceptor: Terjadi Error 401 (Unauthorized)');
          }
          return handler.next(err); // Teruskan error
        },
      ),
    );
  }
  // --- AKHIR CONSTRUCTOR ---


  // Fungsi login (tidak berubah, sudah benar)
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      // Response.data akan berisi (misal):
      // { "message": "Login berhasil", "token": "...", "role": "..." }
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

  // Fungsi register (tidak berubah, sudah benar)
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

  // --- 6. CONTOH FUNGSI YANG MEMERLUKAN LOGIN ---
  // (Misalnya mengambil data profil atau laporan)
  
  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      // Anda TIDAK PERLU menambahkan header token di sini.
      // Interceptor akan melakukannya secara otomatis.
      final response = await _dio.get('/users/profile'); // Sesuaikan endpoint
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

  // CONTOH FUNGSI POST (Misal membuat laporan)
  Future<Map<String, dynamic>> createLaporan(String isiLaporan) async {
    try {
      final response = await _dio.post(
        '/laporan/create', // Sesuaikan endpoint
        data: {'isi_laporan': isiLaporan},
      );
      // Interceptor juga otomatis menambahkan token di sini
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
}