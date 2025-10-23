// lib/screens/auth/register.dart

import 'package:flutter/material.dart';
// 1. IMPORT ApiService
import '../../methods/api.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 2. BUAT INSTANCE ApiService
  final ApiService _apiService = ApiService();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controller untuk setiap field
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confirmEmailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _confirmEmailController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 3. FUNGSI REGISTER YANG SUDAH DIUPDATE
  Future<void> _register() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Cek email
    if (_emailController.text != _confirmEmailController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan Konfirmasi Email tidak cocok'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Cek password
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password dan Konfirmasi Password tidak cocok'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // --- MULAI PANGGIL API ---
    try {
      // Panggil metode register dari ApiService
      final response = await _apiService.register(
        _nameController.text,
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
      );

      // Jika sukses
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Registrasi berhasil!'),
          backgroundColor: Colors.green,
        ),
      );

      // Kembali ke halaman login setelah sukses
      Navigator.pop(context);
    } catch (e) {
      // Jika gagal, tampilkan error dari ApiService
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Pastikan loading berhenti
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
    // --- SELESAI PANGGIL API ---
  }

  // Helper widget untuk membuat text field
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    bool isConfirmPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword
            ? _obscurePassword
            : (isConfirmPassword ? _obscureConfirmPassword : false),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: isPassword || isConfirmPassword
              ? IconButton(
                  icon: Icon(
                    (isPassword ? _obscurePassword : _obscureConfirmPassword)
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isPassword) {
                        _obscurePassword = !_obscurePassword;
                      } else {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      }
                    });
                  },
                )
              : null,
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  Image.asset(
                    'Images/logo2.png', // Pastikan path ini benar
                    width: 180,
                    height: 180,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.local_fire_department,
                      size: 80,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Teks Judul
                  Text(
                    'Pemadam Kebakaran',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Teks Sub-Judul
                  Text(
                    'Kabupaten Subang',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 32),

                  // Field Email
                  _buildInputField(
                    controller: _emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email tidak boleh kosong';
                      }
                      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                        return 'Masukkan format email yang valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Field Konfirmasi Email
                  _buildInputField(
                    controller: _confirmEmailController,
                    hintText: 'Konfirmasi Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Konfirmasi email tidak boleh kosong';
                      }
                      if (value != _emailController.text) {
                        return 'Email tidak cocok';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Field Name
                  _buildInputField(
                    controller: _nameController,
                    hintText: 'Name',
                    keyboardType: TextInputType.name,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Nama tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Field Username
                  _buildInputField(
                    controller: _usernameController,
                    hintText: 'Username',
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Username tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Field Password
                  _buildInputField(
                    controller: _passwordController,
                    hintText: 'Password',
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      if (value.length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Field Konfirmasi Password
                  _buildInputField(
                    controller: _confirmPasswordController,
                    hintText: 'Konfirmasi Password',
                    isConfirmPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Konfirmasi password tidak boleh kosong';
                      }
                      if (value != _passwordController.text) {
                        return 'Password tidak cocok';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Tombol Register
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F), // Merah
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
                              'Register',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Link ke Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sudah punya akun? ',
                        style: TextStyle(color: Colors.black54),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Kembali ke halaman sebelumnya (Login)
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Login',
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
