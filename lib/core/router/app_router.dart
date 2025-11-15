import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// Proje adınıza göre ayarlanmıştır (life_assistant)
import 'package:life_assistant/presentation/widgets/main_layout.dart';
import 'package:life_assistant/features/money_tracking/presentation/pages/money_tracker_page.dart';
import 'package:life_assistant/features/habit_tracker/presentation/pages/habit_tracker_page.dart';
import 'package:life_assistant/features/home/presentation/pages/home_page.dart';
import 'package:life_assistant/features/distraction_timer/presentation/pages/distraction_timer_page.dart';
import 'package:life_assistant/features/fitness_tracker/presentation/pages/fitness_tracker_page.dart';
// 🚨 YENİ SAYFA IMPORT EDİLDİ
import 'package:life_assistant/features/agenda/presentation/pages/agenda_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // MainLayout artık navigationShell alıyor
          return MainLayout(navigationShell: navigationShell);
        },
        // Alt navigasyon bandında görünecek sayfalar
        branches: [
          // Ana Sayfa (Index 0)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomePage()),
              ),
            ],
          ),
          // Para Takibi (Index 1)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/money',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: MoneyTrackerPage()),
              ),
            ],
          ),
          // ODAKLANMA KALKANI (Index 2)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/timer',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DistractionTimerPage()),
              ),
            ],
          ),
          // Alışkanlık Takibi (Index 3)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/habits',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HabitTrackerPage()),
              ),
            ],
          ),
          // SPOR/KALORİ TAKİBİ (Index 4)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/fitness',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: FitnessTrackerPage()),
              ),
            ],
          ),
          // 🚨 AJANDA/GÖREVLER (Index 5)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/agenda',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AgendaPage()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
