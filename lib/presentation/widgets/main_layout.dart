import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_assistant/core/providers/favorite_pages_provider.dart';
import 'navigation_drawer_widget.dart';

class MainLayout extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favPages = ref.watch(favoritePagesProvider);

    // ✅ MEVCUT ROTAYI AL
    final currentPath = GoRouterState.of(context).uri.path;

    // ✅ FAVORİLER LİSTESİNDEKİ INDEX'İ BUL
    final currentIndexInFavorites = favPages.indexWhere(
      (page) => page.path == currentPath,
    );

    return Scaffold(
      drawer: const NavigationDrawerWidget(),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (BuildContext innerContext) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(innerContext).openDrawer();
              },
            );
          },
        ),
        title: const Text('Life Assistant'),
      ),

      // ✅ navigationShell body olarak kullanılıyor
      body: navigationShell,

      // ✅ SADECE FAVORİLER VARSA ALT MENÜYÜ GÖSTER
      bottomNavigationBar: favPages.isEmpty
          ? null
          : BottomNavigationBar(
              // ✅ navigationShell'in currentIndex'ini kullan
              currentIndex: navigationShell.currentIndex,

              type: BottomNavigationBarType.fixed,

              onTap: (index) {
                // ✅ navigationShell ile branch değiştir
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },

              items: favPages.map((page) {
                return BottomNavigationBarItem(
                  icon: Icon(page.icon),
                  label: page.title,
                );
              }).toList(),
            ),
    );
  }
}
