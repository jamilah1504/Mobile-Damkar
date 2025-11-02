import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../methods/api.dart'; // Sesuaikan path jika perlu
import 'register.dart'; // Sesuaikan path jika perlu

// --- 1. Impor Halaman Beranda (Admin Dihapus) ---
// Pastikan nama class di dalam file-file ini sesuai
import '../masyarakat/home.dart';
// import '../admin/home.dart'; // <-- HAPUS IMPOR INI
import '../petugas/home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ... (State variables tidak berubah)
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
      final data = await _apiService.login(
        _usernameController.text, // Pastikan ini dikirim sebagai email ke ApiService
        _passwordController.text,
      );
      print("Login berhasil, data diterima: $data");
      if (!mounted) return;

      // --- PERBARUI BAGIAN INI ---
      final String? token = data['token'];
      final String role = data['role']?.toLowerCase() ?? '';
      
      // 1. Ambil 'name' dan 'id' dari respons login
    final String? name = data['name'];
    // Gunakan 'int?' agar sesuai untuk disimpan
    final int? id = data['id']; 

    if (token == null || token.isEmpty) {
      throw Exception('Login berhasil tetapi token tidak diterima.');
    }
    if (name == null || name.isEmpty) {
      throw Exception('Login berhasil tetapi nama pengguna tidak diterima.');
    }
    // TAMBAHKAN: Validasi untuk 'id' juga
    if (id == null) {
      throw Exception('Login berhasil tetapi ID pengguna tidak diterima.');
    }

    // Simpan semuanya ke SharedPreferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    await prefs.setString('userRole', role);
    
    // PERBAIKAN 1: Tambahkan baris ini untuk menyimpan nama
    await prefs.setString('userName', name); 
    
    // PERBAIKAN 2: Gunakan 'setInt' untuk 'id', bukan 'setString'
    await prefs.setInt('userId', id); 

    print("Token, role, nama, dan ID berhasil disimpan.");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Login berhasil!'),
          backgroundColor: Colors.green,
        ),
      );

      
      Widget destinationScreen;
      switch (role) {
        case 'petugas':
          destinationScreen = const PetugasHomeScreen();
          break;
        case 'masyarakat':
          destinationScreen = const MasyarakatHomeScreen();
          break;
        default:
          // Jika role dari backend adalah "Admin" (seperti contoh Anda)
          // dan Anda tidak punya case 'admin', ini akan masuk ke default.
          // Pastikan 'masyarakat' adalah fallback yang benar.
          print("Role '$role' masuk ke default. Fallback ke MasyarakatHome.");
          destinationScreen = const MasyarakatHomeScreen(); 
      }
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destinationScreen),
      );

    } catch (e) {
      // ... (Error handling tidak berubah) ...
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Widget _buildInputContainer (tidak berubah)
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
    // UI LoginScreen (tidak berubah)
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
                  _buildInputContainer(
                    child: TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        hintText: 'Username/email',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
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
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
