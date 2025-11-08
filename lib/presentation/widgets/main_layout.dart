import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_assistant/core/providers/favorite_pages_provider.dart';
import 'navigation_drawer_widget.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  final int selectedIndex;

  const MainLayout({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favPages = ref.watch(favoritePagesProvider);

    // ✅ MEVCUT ROTAYI AL
    final currentPath = GoRouterState.of(context).uri.path;

    // ✅ FAVORİLER LİSTESİNDEKİ INDEX'İ BUL
    // Eğer mevcut sayfa favorilerde yoksa, alt menüyü devre dışı bırak
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

      body: child,

      // ✅ SADECE FAVORİLER VARSA ALT MENÜYÜ GÖSTER
      bottomNavigationBar: favPages.isEmpty
          ? null
          : BottomNavigationBar(
              // ✅ GÜVENLİ INDEX KONTROLÜ
              currentIndex:
                  currentIndexInFavorites >= 0 &&
                      currentIndexInFavorites < favPages.length
                  ? currentIndexInFavorites
                  : 0,

              type: BottomNavigationBarType.fixed,

              onTap: (index) {
                if (index >= 0 && index < favPages.length) {
                  context.go(favPages[index].path);
                }
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
