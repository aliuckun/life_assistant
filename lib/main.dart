// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';

// 🔥 HIVE ADAPTÖRLER
import 'features/fitness_tracker/domain/entities/fitness_entities.dart';
import 'features/habit_tracker/domain/entities/habit.dart';
import 'features/money_tracking/domain/entities/transaction.dart';

const String appId = String.fromEnvironment(
  'APP_ID',
  defaultValue: 'default-app-id',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 HIVE'I BAŞLAT - Path Provider ile (Daha güvenli)
  try {
    await Hive.initFlutter();
    debugPrint('✅ Hive initialized successfully');
  } catch (e) {
    debugPrint('❌ Hive initialization error: $e');
    // Alternatif path dene
    final appDocDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocDir.path);
    debugPrint('✅ Hive initialized with custom path: ${appDocDir.path}');
  }

  // 🔥 FITNESS ADAPTÖRLERI KAYDET
  try {
    Hive.registerAdapter(MealTypeAdapter());
    Hive.registerAdapter(FoodEntryAdapter());
    Hive.registerAdapter(WorkoutEntryAdapter());
    Hive.registerAdapter(WeightEntryAdapter());
    debugPrint('✅ Fitness adapters registered');
  } catch (e) {
    debugPrint('❌ Fitness adapter registration error: $e');
  }

  // 🔥 HABIT ADAPTÖRLERI KAYDET
  try {
    Hive.registerAdapter(HabitTypeAdapter());
    Hive.registerAdapter(HabitAdapter());
    debugPrint('✅ Habit adapters registered');
  } catch (e) {
    debugPrint('❌ Habit adapter registration error: $e');
  }

  // 🔥 MONEY TRACKING ADAPTÖRLERI KAYDET
  try {
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(MoneyTransactionAdapter());
    Hive.registerAdapter(RecurringPaymentAdapter());
    debugPrint('✅ Money tracking adapters registered');
  } catch (e) {
    debugPrint('❌ Money tracking adapter registration error: $e');
  }

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
