import 'package:flutter/material.dart';
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
        _usernameController.text,
        _passwordController.text,
      );
      print("Login berhasil, data diterima: $data");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Login berhasil!'),
          backgroundColor: Colors.green,
        ),
      );

      final String role = data['role']?.toLowerCase() ?? '';
      print("Role terdeteksi: $role");

      Widget destinationScreen;

      // --- PERBAIKAN: Case 'admin' dihapus ---
      switch (role) {
        // case 'admin': // <-- HAPUS CASE INI
        //   print("Cocok dengan case 'admin'. Navigasi ke AdminHomeScreen.");
        //   destinationScreen = const AdminHomeScreen();
        //   break;
        case 'petugas':
          print("Cocok dengan case 'petugas'. Navigasi ke PetugasHomeScreen.");
          destinationScreen =
              const PetugasHomeScreen(); // Gunakan home screen Petugas
          break;
        case 'masyarakat':
          print(
            "Cocok dengan case 'masyarakat'. Navigasi ke MasyarakatHomeScreen.",
          );
          destinationScreen =
              const MasyarakatHomeScreen(); // Gunakan home screen Masyarakat
          break;
        default:
          print(
            "Tidak cocok (default). Navigasi ke MasyarakatHomeScreen sebagai fallback.",
          );
          destinationScreen =
              const MasyarakatHomeScreen(); // Fallback ke home Masyarakat
      }
      // --- AKHIR PERBAIKAN ---

      print("Mencoba navigasi ke destinationScreen...");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destinationScreen),
      );
      print("Navigasi seharusnya sudah dipanggil.");
    } catch (e) {
      print("Error saat login atau navigasi: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
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
