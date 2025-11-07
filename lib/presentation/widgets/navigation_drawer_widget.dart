// lib/presentation/widgets/navigation_drawer_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_assistant/core/providers/favorite_pages_provider.dart';

class NavigationDrawerWidget extends ConsumerWidget {
  const NavigationDrawerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Favori durum yöneticisini oku
    final favoriteNotifier = ref.watch(favoritePagesProvider.notifier);

    return Drawer(
      child: Container(
        // Koyu temanın rengini korumak için
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black54),
              child: Text(
                'Tüm Uygulama Sayfaları',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            // Tüm sayfalar listeleniyor
            ...allPages.map((page) {
              final isFav = favoriteNotifier.isFavorite(page);
              return ListTile(
                title: Text(
                  page.title,
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: IconButton(
                  icon: Icon(
                    isFav ? Icons.star : Icons.star_border,
                    color: isFav ? Colors.yellow : Colors.grey,
                  ),
                  // Favori durumunu değiştir
                  onPressed: () {
                    favoriteNotifier.toggleFavorite(page);
                  },
                ),
                onTap: () {
                  context.go(page.path); // Sayfaya git
                  Navigator.pop(context); // Çekmeceyi kapat
                },
              );
            }).toList(),
            // ... Diğer menü öğeleri (Ayarlar, Çıkış vb.)
          ],
        ),
      ),
    );
  }
}
