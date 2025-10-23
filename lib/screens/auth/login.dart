import 'package:flutter/material.dart';
// HAPUS: import 'package:http/http.dart' as http;
// HAPUS: import 'dart:convert';

// TAMBAHKAN: Impor untuk ApiService dan RegisterScreen
import 'package:mobile_damkar/methods/api.dart'; // <-- DIUPDATE
import 'package:mobile_damkar/screens/auth/register.dart'; // <-- DIUPDATE

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pemadam Kebakaran',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // TAMBAHKAN: Instance dari ApiService Anda
  final ApiService _apiService = ApiService();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- (FUNGSI LOGIN INI DI-UPDATE) ---
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Panggil ApiService, bukan 'http'
      final data = await _apiService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data['message'] ?? 'Login berhasil!',
          ), // Ambil pesan dari API
          backgroundColor: Colors.green,
        ),
      );

      // Navigasi ke halaman selanjutnya atau simpan token
      print('Login successful: $data');
      // CONTOH: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
    } catch (e) {
      // Tangkap Exception yang dilempar oleh ApiService
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ), // Pesan error sudah diformat oleh ApiService
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Pastikan loading berhenti, baik sukses maupun gagal
      setState(() {
        _isLoading = false;
      });
    }
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
                  // Logo
                  Container(
                    child: Center(
                      child: Image.asset(
                        'Images/logo2.png', // Ganti dengan path logo Anda
                        width: 220,
                        height: 220,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.local_fire_department,
                            size: 80,
                            color: Colors.red[700],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 44),

                  // Username Field
                  Container(
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Username/email tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  Container(
                    // ... (styling password field tidak berubah) ...
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
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  SizedBox(
                    // ... (styling login button tidak berubah) ...
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

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Tidak punya akun? ',
                        style: TextStyle(color: Colors.black54),
                      ),
                      GestureDetector(
                        onTap: () {
                          // --- (INI DI-UPDATE) ---
                          // Navigasi ke halaman register
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
