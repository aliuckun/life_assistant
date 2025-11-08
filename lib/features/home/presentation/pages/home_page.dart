// lib/features/home/presentation/pages/home_page.dart
import 'package:flutter/material.dart';

// Ana Sayfa: Uygulamanın genel özetini ve başlangıç noktasını gösterir
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Koyu tema ile uyumlu bir arayüz
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.dashboard, size: 80, color: Colors.amberAccent),
            const SizedBox(height: 20),
            Text(
              'Genel Durum Paneli',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tüm modüllerin (Para Takibi, Alışkanlıklar, Odaklanma) özetini burada göreceksiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
