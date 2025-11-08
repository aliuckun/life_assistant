// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_assistant/presentation/widgets/main_layout.dart';
import 'package:life_assistant/features/money_tracking/presentation/pages/money_tracker_page.dart';
import 'package:life_assistant/features/habit_tracker/presentation/pages/habit_tracker_page.dart';
import 'package:life_assistant/features/home/presentation/pages/home_page.dart';
import 'package:life_assistant/features/distraction_timer/presentation/pages/distraction_timer_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // ✅ ÇÖZÜM: navigationShell'i child olarak, currentIndex'i selectedIndex olarak gönder
          return MainLayout(
            child: navigationShell,
            selectedIndex: navigationShell.currentIndex,
          );
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
        ],
      ),
    ],
  );
}
