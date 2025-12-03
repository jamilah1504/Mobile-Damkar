import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../methods/api.dart';
import 'register.dart';

// Import Service Notifikasi untuk ambil token
import '../../service/notfikasi.dart'; 

import '../masyarakat/home.dart';
import '../petugas/home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Lakukan Login Biasa
      final data = await _apiService.login(
        _usernameController.text,
        _passwordController.text,
      );
      
      print("Login berhasil, data diterima: $data");
      
      if (!mounted) return;

      final String? token = data['token'];
      final String role = data['role']?.toLowerCase() ?? '';
      final String? name = data['name'];
      final int? id = data['id'];

      if (token == null || token.isEmpty) throw Exception('Token kosong');
      if (name == null) throw Exception('Nama kosong');
      if (id == null) throw Exception('ID kosong');

      // 2. Simpan Data ke SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('authToken', token);
      await prefs.setString('userRole', role);
      await prefs.setString('userName', name);
      await prefs.setInt('userId', id);

      print("Data user disimpan lokal.");

      // === [BARU] 3. AMBIL FCM TOKEN & KIRIM KE BACKEND ===
      try {
        print("Mencoba mengambil FCM Token...");
        // Pastikan NotificationService().initialize() sudah dipanggil di main.dart
        // Tapi kita panggil getFcmToken() aman saja
        String? fcmToken = await NotificationService().getFcmToken();

        if (fcmToken != null) {
          print("FCM Token didapat: $fcmToken");
          print("Mengirim token ke Backend...");
          
          // Panggil API update token (karena auth token sudah tersimpan di prefs di langkah 2, api service bisa membacanya)
          await _apiService.updateFcmToken(fcmToken);
        } else {
          print("Warning: FCM Token null (Mungkin di Emulator atau Izin ditolak)");
        }
      } catch (fcmError) {
        // Jangan gagalkan login hanya karena notifikasi error, cukup print saja
        print("Error saat update FCM Token: $fcmError");
      }
      // ====================================================

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Login berhasil!'),
          backgroundColor: Colors.green,
        ),
      );

      // 4. Navigasi Halaman
      Widget destinationScreen;
      switch (role) {
        case 'petugas':
          destinationScreen = const PetugasHomeScreen();
          break;
        case 'masyarakat':
          destinationScreen = const MasyarakatHomeScreen();
          break;
        default:
          print("Role '$role' tidak dikenal. Default ke Masyarakat.");
          destinationScreen = const MasyarakatHomeScreen();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destinationScreen),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login Gagal: ${e.toString().replaceAll("Exception:", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ... (Sisa kode UI _buildInputContainer dan build tidak perlu diubah) ...
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
                      'Images/logo2.png',
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
                  _buildInputContainer(
                    child: TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        hintText: 'Username/email',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) => (value == null || value.isEmpty) ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInputContainer(
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: const OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) => (value == null || value.isEmpty) ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Tidak punya akun? ', style: TextStyle(color: Colors.black54)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                        child: const Text('Register', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}