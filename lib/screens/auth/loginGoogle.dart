import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // URL Backend Node.js Anda
  final String _nodeBackendUrl = 'http://localhost:5000/api/auth/verify-token';

  Future<void> signInWithGoogle() async {
    try {
      // 1. Memulai alur Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Pengguna membatalkan login
        return;
      }

      // 2. Mendapatkan detail autentikasi dari Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Membuat kredensial Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Login ke Firebase menggunakan kredensial tersebut
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // 5. Mendapatkan ID Token Firebase (JWT)
        final String? idToken = await user.getIdToken();

        if (idToken != null) {
          // 6. Kirim token ini ke backend Node.js Anda untuk verifikasi
          await _sendTokenToBackend(idToken);
        }
      }
    } catch (e) {
      print("Error saat login Google: $e");
      // Tampilkan error ke pengguna
    }
  }

  Future<void> _sendTokenToBackend(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse(_nodeBackendUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        print("Backend berhasil memverifikasi token.");
        // Navigasi ke halaman home
      } else {
        print("Backend gagal memverifikasi token: ${response.body}");
        // Tampilkan error
      }
    } catch (e) {
      print("Error mengirim token ke backend: $e");
    }
  }
}