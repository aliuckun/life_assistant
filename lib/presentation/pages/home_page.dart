// lib/presentation/pages/home_page.dart
import 'package:flutter/material.dart';

// Ana Sayfanın basit bir yer tutucusu
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Ana Sayfa İçeriği',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}
