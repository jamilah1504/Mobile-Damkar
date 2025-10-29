import 'package:flutter/material.dart';
// Hapus impor yang tidak perlu jika ada
// import 'methods/api.dart';
// import 'screens/auth/register.dart';

// Impor LoginScreen dari file yang benar
import 'screens/auth/login.dart'; // Pastikan path ini benar

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pemadam Kebakaran',
      // Gunakan tema yang konsisten dengan HomeScreen
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red.shade800),
        useMaterial3: true,
      ),
      // Halaman awal sekarang adalah LoginScreen yang diimpor
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// HAPUS SEMUA KODE LoginScreen DAN _LoginScreenState DARI FILE INI
// class LoginScreen extends StatefulWidget { ... }
// class _LoginScreenState extends State<LoginScreen> { ... }
