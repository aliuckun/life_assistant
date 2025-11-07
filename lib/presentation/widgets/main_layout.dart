// lib/presentation/widgets/main_layout.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex; // Alt bant için seçili index

  const MainLayout({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  // Favori Sayfalar (Alt Navigasyon İçin)
  static const List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home, 'label': 'Ana Sayfa', 'path': '/home'},
    {'icon': Icons.attach_money, 'label': 'Para Takibi', 'path': '/money'},
    {'icon': Icons.checklist, 'label': 'Alışkanlık', 'path': '/habits'},
    // ... İleride eklenecek favori sayfalar
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sol üst hamburger menü (resimdeki yapı) için AppBar
      appBar: AppBar(
        automaticallyImplyLeading: false, // Varsayılan geri tuşunu kaldır
        title: Row(
          children: [
            // Resimdeki hamburger menü ikonu
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                // Burada Navigation Drawer'ı açma veya özel menüyü gösterme mantığı olacak
                Scaffold.of(context).openDrawer();
              },
            ),
            const Spacer(), // Başlık ile araya boşluk
          ],
        ),
      ),
      // Sol üstteki menü tıklandığında açılacak Drawer
      drawer: const NavigationDrawerWidget(),

      // Sayfanın ana içeriği
      body: child,

      // Favori sayfalara hızlı geçiş için BottomNavigationBar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          // Alt banttaki sayfaya GoRouter ile geçiş yap
          context.go(_navItems[index]['path']);
        },
        items: _navItems.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item['icon']),
            label: item['label'],
          );
        }).toList(),
      ),
    );
  }
}

// Menü çekmecesi (Navigation Drawer) örneği
class NavigationDrawerWidget extends StatelessWidget {
  const NavigationDrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Tüm Sayfalar/Ayarlar',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ListTile(
            title: const Text('Para Takibi'),
            onTap: () => context.go('/money'),
          ),
          ListTile(
            title: const Text('Alışkanlık Takibi'),
            onTap: () => context.go('/habits'),
          ),
          // ... Diğer tüm sayfalar
        ],
      ),
    );
  }
}
