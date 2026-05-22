import 'package:flutter/material.dart';

class NotifikasiPage extends StatelessWidget {
  const NotifikasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          'Belum ada notifikasi',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
