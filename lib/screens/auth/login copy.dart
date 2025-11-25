import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../methods/api.dart'; // Sesuaikan path jika perlu
import 'register.dart'; // Sesuaikan path jika perlu

// --- 1. IMPOR BARU UNTUK GOOGLE SIGN-IN ---
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

// --- 2. Impor Halaman Beranda (Seperti sebelumnya) ---
import '../masyarakat/home.dart';
import '../petugas/home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- Variabel untuk Login Manual ---
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // --- 3. VARIABEL BARU DARI AUTHSERVICE ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  // Pastikan URL ini benar sesuai backend Anda
  final String _nodeBackendUrl = 'http://localhost:5000/api/auth/verify-token';
  // final String _nodeBackendUrl = 'http://10.0.2.2:5000/api/auth/verify-token';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- 4. FUNGSI BARU (TERPUSAT) UNTUK MENANGANI DATA LOGIN ---
  /// Fungsi ini mengambil data yang sudah dinormalisasi dan menangani
  /// penyimpanan ke SharedPreferences serta navigasi.
  Future<void> _handleSuccessfulLogin(Map<String, dynamic> data,
      {String? message}) async {
    try {
      // Normalisasi data (pastikan 'id' adalah integer)
      final String? token = data['token']?.toString();
      final String role = data['role']?.toString().toLowerCase() ?? 'masyarakat';
      final String? name = data['name']?.toString();
      final int? id = data['id'] is int
          ? data['id']
          : int.tryParse(data['id']?.toString() ?? '');

      // Validasi data
      if (token == null || token.isEmpty) throw Exception('Token tidak diterima.');
      if (name == null || name.isEmpty) throw Exception('Nama pengguna tidak diterima.');
      if (id == null) throw Exception('ID pengguna tidak diterima.');

      // Simpan semuanya ke SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('authToken', token);
      await prefs.setString('userRole', role);
      await prefs.setString('userName', name);
      await prefs.setInt('userId', id); // Gunakan setInt

      print("Login sukses. Data disimpan (Role: $role, Nama: $name, ID: $id).");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? 'Login berhasil!'),
          backgroundColor: Colors.green,
        ),
      );

      // Tentukan halaman tujuan
      Widget destinationScreen;
      switch (role) {
        case 'petugas':
          destinationScreen = const PetugasHomeScreen();
          break;
        case 'masyarakat':
          destinationScreen = const MasyarakatHomeScreen();
          break;
        default:
          print("Role '$role' masuk ke default. Fallback ke MasyarakatHome.");
          destinationScreen = const MasyarakatHomeScreen();
      }

      // Navigasi
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destinationScreen),
      );
    } catch (e) {
      print("Error saat memproses login sukses: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses data login: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- 5. FUNGSI LOGIN MANUAL (DIPERBARUI) ---
  /// Login manual kini memanggil _handleSuccessfulLogin
  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);

    try {
      // 1. Panggil ApiService untuk login manual
      final data = await _apiService.login(
        _usernameController.text,
        _passwordController.text,
      );
      print("Login manual berhasil, data diterima: $data");
      if (!mounted) return;

      // 2. Data dari login manual sudah dalam format yang benar
      //    { "token": "...", "role": "...", "name": "...", "id": ..., "message": "..." }
      await _handleSuccessfulLogin(data, message: data['message']);
    } catch (e) {
      print("Error saat login manual: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()), // ApiService harusnya melempar error yg jelas
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- 6. FUNGSI BARU UNTUK LOGIN GOOGLE ---
  Future<void> _loginWithGoogle() async {
    if (_isLoading) return; // Jangan jalankan jika sudah loading
    setState(() => _isLoading = true);

    try {
      UserCredential userCredential; // Variabel untuk menampung hasil

      // ==========================================================
      // INI ADALAH LOGIKA PLATFORM BARU
      // ==========================================================
      if (kIsWeb) {
        // --------------------------------
        // ALUR UNTUK FLUTTER WEB
        // --------------------------------
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        // 'signInWithPopup' menangani popup dan login sekaligus di web
        userCredential = await _auth.signInWithPopup(googleProvider);
        
      } else {
        // --------------------------------
        // ALUR UNTUK MOBILE (Android/iOS)
        // (Kode yang sudah Anda miliki sebelumnya)
        // --------------------------------
        final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
        if (googleUser == null) {
          // Pengguna membatalkan
          if (mounted) setState(() => _isLoading = false);
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          // accessToken tidak ada/tidak diperlukan di versi ini
        );

        // Login ke Firebase dengan kredensial mobile
        userCredential = await _auth.signInWithCredential(credential);
      }
      // ==========================================================
      // AKHIR DARI LOGIKA PLATFORM
      // ==========================================================

      // --- Logika Umum (berjalan setelah Web atau Mobile berhasil) ---
      final User? user = userCredential.user;

      if (user != null) {
        // 4. Mendapatkan ID Token Firebase (JWT)
        final String? idToken = await user.getIdToken();

        if (idToken != null) {
          // 5. Kirim token ke backend dan dapatkan data
          final Map<String, dynamic> backendResponse =
              await _sendTokenToBackend(idToken);

          // 6. Normalisasi data dari backend Google
          final Map<String, dynamic> normalizedData = {
            'token': backendResponse['myCustomToken'],
            'role': backendResponse['user']['role'],
            'name': backendResponse['user']['name'],
            'id': backendResponse['user']['id'],
          };

          // 7. Panggil handler login sukses
          await _handleSuccessfulLogin(normalizedData,
              message: backendResponse['message']);
        } else {
          throw Exception('Gagal mendapatkan ID Token Firebase.');
        }
      } else {
        throw Exception('Gagal mendapatkan data pengguna Firebase.');
      }
    } catch (e) {
      print("Error saat login Google: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login Google Gagal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- 7. FUNGSI HELPER (DARI AUTHSERVICE) ---
  /// Mengirim token ke backend dan mengembalikan respons body
  Future<Map<String, dynamic>> _sendTokenToBackend(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse(_nodeBackendUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'idToken': idToken}),
      );

      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        print("Backend berhasil memverifikasi token.");
        return body; // Kembalikan data yang sudah di-decode
      } else {
        print("Backend gagal memverifikasi token: ${response.body}");
        throw Exception(body['message'] ?? 'Autentikasi gagal');
      }
    } catch (e) {
      print("Error mengirim token ke backend: $e");
      throw Exception('Gagal menghubungi server: ${e.toString()}');
    }
  }

  // --- Widget _buildInputContainer (tidak berubah) ---
  Widget _buildInputContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // --- 8. BUILD WIDGET (DIPERBARUI DENGAN TOMBOL GOOGLE) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Image.asset(
                      'Images/logo2.png', // Pastikan path benar
                      width: 220,
                      height: 220,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.local_fire_department,
                        size: 80,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 44),
                  
                  // --- Form Login Manual (tidak berubah) ---
                  _buildInputContainer(
                    child: TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        hintText: 'Username/email',
                        // ... (sisa dekorasi)
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Username/email tidak boleh kosong'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInputContainer(
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        // ... (sisa dekorasi)
                        border:
                            const OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Password tidak boleh kosong'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // --- Tombol Login Manual (tidak berubah) ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // --- Link Register (tidak berubah) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Tidak punya akun? ',
                        style: TextStyle(color: Colors.black54),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- 9. PEMISAH DAN TOMBOL GOOGLE BARU ---
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text("atau",
                            style: TextStyle(color: Colors.black54)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // --- TOMBOL LOGIN GOOGLE BARU ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _loginWithGoogle,
                      icon: Image.asset(
                        'Images/google_logo.png', // <-- PASTIKAN ANDA PUNYA ASET INI
                        height: 24.0,
                        width: 24.0,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.g_mobiledata, color: Colors.black87),
                      ),
                      label: const Text(
                        'Masuk dengan Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Latar belakang putih
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[300]!), // Garis tepi
                        ),
                        elevation: 2,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}