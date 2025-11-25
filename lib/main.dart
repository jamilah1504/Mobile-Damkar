import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// Impor HomeScreen yang umum (pastikan path dan nama file benar)
import 'screens/home.dart';

void main() {
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
