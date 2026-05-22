import 'package:flutter/material.dart';
import 'package:rentalcar/widgets/navbar.dart';
import 'package:rentalcar/widgets/sidebar.dart';
import 'package:rentalcar/widgets/bottom.dart';

class AppLayout extends StatelessWidget {
  final String title;
  final Widget content;
  final int currentIndex;
  final Function(int) onTap;

  const AppLayout({
    super.key,
    required this.title,
    required this.content,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navbar(title: title),
      drawer: const Sidebar(),
      body: content,
      bottomNavigationBar: Bottom(
        currentIndex: currentIndex,
        onTap: onTap,
      ),
    );
  }
}
