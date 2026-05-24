import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalcar/menu/dashboard.dart';
import 'package:rentalcar/pages/loginpage.dart'; // ← import halaman login manual
import 'package:rentalcar/config/api_config.dart'; // ← Import file config

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  // ⚠️ GANTI dengan IP laptop kamu saat ini
  // static const String _apiUrl =
  //     'http://192.168.189.7:8000/api/auth/google/mobile';

  // Web Client ID (bukan Android)
  static const String _serverClientId =
      '1055921517849-kd3ps2tleptf1tmpqqadvnb9f64m7tpr.apps.googleusercontent.com';

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: _serverClientId,
        scopes: ['email', 'profile'],
      );

      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Login dibatalkan oleh user');
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      debugPrint('--- DEBUG TOKEN ---');
      debugPrint(
        'idToken: ${idToken != null ? "ADA (${idToken.length} chars)" : "NULL ❌"}',
      );
      debugPrint('accessToken: ${accessToken != null ? "ADA" : "NULL"}');
      debugPrint('-------------------');

      if (idToken == null) {
        throw Exception(
          'id_token null. Pastikan serverClientId sudah benar (gunakan Web Client ID).',
        );
      }

      debugPrint('Mengirim ke Laravel: ${ApiConfig.googleLogin}');
      
      final response = await http
          .post(
            Uri.parse(ApiConfig.googleLogin),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {'id_token': idToken},
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                'Timeout! Server tidak merespons.\n'
                'Cek:\n'
                '1. IP ${ApiConfig.googleLogin} bisa diakses dari HP?\n'
                '2. php artisan serve --host=0.0.0.0 sudah jalan?\n'
                '3. HP dan laptop di WiFi yang sama?',
              );
            },
          );

      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Response: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        final String sanctumToken = data['access_token'];
        final userData = data['user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', sanctumToken);

        if (userData != null) {
          await prefs.setString('user_name', userData['name'] ?? '');
          await prefs.setString('user_email', userData['email'] ?? '');
          if (userData['avatar'] != null) {
            await prefs.setString('avatar_url', userData['avatar']);
          }
        }

        debugPrint('✅ Login sukses! User: ${userData?['email']}');

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Dashboard()),
          );
        }
      } else {
        final String errorMsg =
            data['message'] ?? 'Gagal login (status: ${response.statusCode})';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FlutterLogo(size: 80),
              const SizedBox(height: 40),
              const Text(
                'Rental Car',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Masuk dengan akun Google kamu',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),

              // ── Tombol Sign in with Google ──
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : OutlinedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: const Icon(Icons.login),
                        label: const Text('Sign in with Google'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 12),

              // ── Divider ──
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'atau',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 12),

              // ── Tombol Login Manual (khusus pengguna sistem) ──
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManualLoginPage(),
                            ),
                          );
                        },
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Login Sistem'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
