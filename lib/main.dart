import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Import Service Notifikasi yang baru dibuat
import 'service/notfikasi.dart';

// Pastikan path ini benar sesuai struktur project Anda
import 'screens/home.dart';
import 'firebase_options.dart';

void main() async {
  // 1. Pastikan binding widget siap
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Inisialisasi Notification Service (TAMBAHAN PENTING)
  // Ini akan meminta izin notifikasi dan setup channel
  await NotificationService().initialize();

  // 4. Jalankan Aplikasi
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
      // Halaman awal
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
      
      // Konfigurasi Bahasa/Lokalisasi
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English
        Locale('id', 'ID'), // Bahasa Indonesia
      ],
    );
  }
}