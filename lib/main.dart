// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart'; // 👈 YENİ

const String appId = String.fromEnvironment(
  'APP_ID',
  defaultValue: 'default-app-id',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔔 Bildirim servisini başlat
  await NotificationService().initialize();

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
      debugShowCheckedModeBanner: false,
    );
  }
}
