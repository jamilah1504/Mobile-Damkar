import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// Impor HomeScreen yang umum (pastikan path dan nama file benar)
import 'screens/home.dart';
import 'firebase_options.dart'; 


void main() async { // 3. Jadikan 'async'
  
  // 4. Pastikan binding widget sudah siap sebelum inisialisasi
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // 5. INI ADALAH PERBAIKANNYA: Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 6. Jalankan aplikasi Anda
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pemadam Kebakaran',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red.shade800),
        useMaterial3: true,
      ),
      // --- PERUBAHAN DI SINI ---
      // Halaman awal sekarang adalah HomeScreen yang umum
      home: const HomeScreen(),
      // --- AKHIR PERUBAHAN ---
      debugShowCheckedModeBanner: false,
      // Tambahkan localizations untuk DatePicker dan widget lainnya
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English (default)
        Locale('id', 'ID'), // Bahasa Indonesia
      ],
    );
  }
}
