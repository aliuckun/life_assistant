// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

// 🚨 Firebase bağımlılıkları ve başlatma kodları kaldırıldı.

// Global değişkenler tanımlanmaya devam ediyor (diğer dosyalar için lazım)
// Ancak artık Firebase'e ait değiller.
const String appId = String.fromEnvironment(
  'APP_ID',
  defaultValue: 'default-app-id',
);

void main() {
  // WidgetsFlutterBinding.ensureInitialized() artık gerekli değil
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kişisel Takip Uygulaması',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
