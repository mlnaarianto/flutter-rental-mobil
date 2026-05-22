import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rentalcar/pages/login.dart';
import 'package:rentalcar/menu/profil.dart';
import 'package:rentalcar/menu/chat.dart';
import 'package:rentalcar/menu/dashboard.dart';

class Bottom extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const Bottom({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// ================== DIALOG LOGOUT ==================
  Future<void> _confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah ingin mengakhiri sesi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        // 1. Ambil token dari penyimpanan HP
        final prefs = await SharedPreferences.getInstance();
        final String? token = prefs.getString('auth_token');

        // 2. Hapus token dari server Laravel (Database)
        if (token != null) {
          // Sesuaikan IP address jika jaringan Wi-Fi Anda berubah
          final String apiUrl = 'http://192.168.189.7:8000/api/logout';

          await http.post(
            Uri.parse(apiUrl),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        }

        // 3. Hapus token dari penyimpanan HP secara lokal
        await prefs.remove('auth_token');

        // 4. Logout dari Google SDK
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();

      } catch (e) {
        print('Error saat logout: $e');
        // Fallback: Jika internet mati / server error, tetap paksa hapus token lokal
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
      }

      // 5. Tendang user kembali ke halaman Login
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  /// ================== MENU PROFILE ==================
  void _showProfileMenu(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () => Navigator.pop(sheetContext),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmLogout(parentContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// ================== BUILD ==================
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      onTap: (index) {
        if (index == 0) {
          // HOME → DASHBOARD
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const Dashboard(),
            ),
            (route) => false,
          );
        } else if (index == 2) {
          // CHAT
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ChatPage(),
            ),
          );
        } else if (index == 3) {
          // PROFILE
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProfilPage(),
            ),
          );
        } else {
          onTap(index);
        }
      },
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.car_rental),
          label: 'Mobil',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: GestureDetector(
            onLongPress: () => _showProfileMenu(context),
            child: CircleAvatar(
              radius: 14,
              backgroundColor:
                  currentIndex == 3 ? Colors.blue : Colors.grey.shade300,
              child: const CircleAvatar(
                radius: 12,
                backgroundImage: AssetImage('assets/anya.jpg'),
              ),
            ),
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}