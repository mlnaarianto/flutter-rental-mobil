import 'package:flutter/material.dart';
import 'package:rentalcar/layouts/app.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Dashboard',
      currentIndex: 0,
      onTap: (index) {
        print(index);
      },
      content: const Center(child: Text('Isi Dashboard')),
    );
  }
}
