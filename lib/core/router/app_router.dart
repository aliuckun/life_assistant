// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_assistant/presentation/widgets/main_layout.dart';
import 'package:life_assistant/features/money_tracking/presentation/pages/money_tracker_page.dart';
import 'package:life_assistant/features/habit_tracker/presentation/pages/habit_tracker_page.dart';
import 'package:life_assistant/presentation/pages/home_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // MainLayout'u kullanarak alt navigasyon bandını yönet
          return MainLayout(
            child: navigationShell,
            selectedIndex: navigationShell.currentIndex,
          );
        },
        // Alt navigasyon bandında görünecek sayfalar (Favoriler)
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
          // Alışkanlık Takibi (Index 2)
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
      // ... Alt Navigasyon Bandında Olmayacak Diğer Sayfalar Buraya Eklenebilir
      // Örneğin: GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
    ],
  );
}
