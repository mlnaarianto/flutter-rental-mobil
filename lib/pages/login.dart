import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalcar/menu/dashboard.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // 1. Dapatkan akun Google dari HP
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // Jika user menekan tombol batal / back saat pop-up Google muncul
      if (googleUser == null) {
        print('Login dibatalkan user');
        return;
      }

      // 2. Dapatkan Access Token otentikasi dari Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        throw Exception('Gagal mendapatkan access token dari Google');
      }

      // 3. Kirim Token ke API Laravel
      // PENTING: Atur IP sesuai perangkat Anda!
      // Jika Emulator Android = http://10.0.2.2:8000
      // Jika HP Fisik = http://192.168.x.x:8000 (IP WiFi Laptop Anda)
      // Gunakan IPv4 dari adapter Wi-Fi Anda
      final String apiUrl = 'http://192.168.189.7:8000/api/auth/google/mobile';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Accept': 'application/json'},
        body: {'token': accessToken},
      );

      // 4. Handle Respons dari API Laravel
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String sanctumToken = data['access_token'];

        // 5. Simpan Token Sanctum ke penyimpanan HP
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', sanctumToken);

        print('Login API Sukses! Token: $sanctumToken');

        // 6. Pindah ke Dashboard
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Dashboard()),
          );
        }
      } else {
        print('Gagal dari Server: ${response.body}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal verifikasi di server. Coba lagi.'),
            ),
          );
        }
      }
    } catch (e) {
      print('Error login Google: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(title: const Text('Login'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.directions_car, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'Login to Rental Car',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _signInWithGoogle(context),
                  icon: const Icon(Icons.login),
                  label: const Text(
                    'Sign in with Google',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
