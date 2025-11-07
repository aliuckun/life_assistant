// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  // Riverpod için ana widget'ı sarmalama
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // GoRouter kullanıldığı için MaterialApp.router kullanılır
    return MaterialApp.router(
      title: 'Kişisel Takip Uygulaması',
      theme: AppTheme.lightTheme, // Temayı merkezi olarak tanımlıyoruz
      routerConfig: AppRouter.router, // GoRouter konfigürasyonu
    );
  }
}
