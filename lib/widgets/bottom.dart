import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rentalcar/pages/login.dart';
import 'package:rentalcar/menu/profil.dart';
import 'package:rentalcar/menu/chat.dart';
import 'package:rentalcar/menu/dashboard.dart';
import 'package:rentalcar/config/api_config.dart';

class Bottom extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const Bottom({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<Bottom> createState() => _BottomState();
}

class _BottomState extends State<Bottom> {
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  /// ================== LOAD AVATAR DARI SHARED PREFERENCES ==================
  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final String? url = prefs.getString('avatar_url');
    if (mounted) {
      setState(() {
        _avatarUrl = url;
      });
    }
  }

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

        // 2. Hapus token dari server Laravel
        if (token != null) {
          // final String apiUrl = 'http://192.168.189.7:8000/api/logout';
          await http.post(
            Uri.parse(ApiConfig.logout),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        }

        // 3. Hapus semua data dari penyimpanan HP
        await prefs.remove('auth_token');
        await prefs.remove('avatar_url'); // ✅ hapus juga avatar

        // 4. Logout dari Google SDK
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      } catch (e) {
        print('Error saat logout: $e');
        // Fallback: tetap paksa hapus token lokal
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        await prefs.remove('avatar_url');
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

  /// ================== WIDGET AVATAR ==================
  Widget _buildAvatar() {
    final bool isActive = widget.currentIndex == 3;

    return CircleAvatar(
      radius: 14,
      backgroundColor: isActive ? Colors.blue : Colors.grey.shade300,
      child: CircleAvatar(
        radius: 12,
        // ✅ Prioritas: URL dari API → fallback ke asset lokal
        backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
            ? NetworkImage(_avatarUrl!) as ImageProvider
            : const AssetImage('assets/anya.jpg'),
      ),
    );
  }

  /// ================== BUILD ==================
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      onTap: (index) {
        if (index == 0) {
          // HOME → DASHBOARD
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const Dashboard()),
            (route) => false,
          );
        } else if (index == 2) {
          // CHAT
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatPage()),
          );
        } else if (index == 3) {
          // PROFILE → reload avatar setelah kembali dari halaman profil
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilPage()),
          ).then((_) => _loadAvatar()); // ✅ refresh avatar setelah balik dari profil
        } else {
          widget.onTap(index);
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
            child: _buildAvatar(), // ✅ pakai widget avatar dinamis
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}