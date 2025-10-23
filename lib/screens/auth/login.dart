import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/auth/login'),

        headers: {'Content-Type': 'application/json'},

        body: jsonEncode({
          'username': _usernameController.text,

          'password': _passwordController.text,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login berhasil!'),

            backgroundColor: Colors.green,
          ),
        );

        // Navigasi ke halaman selanjutnya atau simpan token

        print('Login successful: $data');
      } else {
        final errorData = jsonDecode(response.body);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? 'Login gagal'),

            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),

          backgroundColor: Colors.red,
        ),
      );
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
                          // Navigasi ke halaman register

                          print('Navigate to register');
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
