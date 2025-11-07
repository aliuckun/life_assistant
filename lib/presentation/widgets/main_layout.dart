import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// Proje adınıza göre import yolunu kontrol edin: 'package:life_assistant/...'
import 'package:life_assistant/core/providers/favorite_pages_provider.dart';
import 'navigation_drawer_widget.dart';

// ConsumerWidget olarak değiştirildi çünkü Riverpod kullanıyor
class MainLayout extends ConsumerWidget {
  final Widget child;
  final int
  selectedIndex; // Alt navigasyon bandında seçili olan sayfanın index'i

  const MainLayout({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ⭐️ Favori sayfaların listesini dinle (BottomNavigationBar'ı dinamik yapar)
    final favPages = ref.watch(favoritePagesProvider);

    return Scaffold(
      // Sol üstteki menü tıklandığında açılacak Drawer
      drawer: const NavigationDrawerWidget(),

      appBar: AppBar(
        // 1. Çift ikonu ve otomatik geri ok dönüşümünü engelle
        automaticallyImplyLeading: false,

        // 2. Leading: Sol Başlangıç Bölümü. Buraya sabit hamburger ikonumuzu koyuyoruz.
        leading: Builder(
          builder: (BuildContext innerContext) {
            // Builder kullanıyoruz, çünkü Drawer'ı açmak için
            // Scaffold'a ait bir BuildContext'e (innerContext) ihtiyacımız var.
            return IconButton(
              icon: const Icon(
                Icons.menu,
              ), // Hamburger ikonu her zaman sabit kalır
              onPressed: () {
                // Tıklandığında Drawer'ı açar.
                // Kapatma, Flutter'ın varsayılan sola kaydırma jesti ve
                // Drawer dışına tıklama ile otomatik olarak sağlanır.
                Scaffold.of(innerContext).openDrawer();
              },
            );
          },
        ),

        // Başlık kısmı, Hamburger ikonundan sonra görünür
        title: const Text('Life Assistant'),
      ),

      body: child,

      // Dinamik BottomNavigationBar
      bottomNavigationBar: BottomNavigationBar(
        // Alt bandın sadece favori sayfa sayısı kadar itemi olmalıdır.
        // Index değeri, favori sayfalar listesindeki konuma göre ayarlanır.
        currentIndex: selectedIndex,

        // Temanın karanlık moda uygun ayarlanması (tema dosyasında da yapılmalı)
        type: BottomNavigationBarType.fixed, // Daha fazla item için sabit tip

        onTap: (index) {
          // Güncel favori listesinden yolu al ve GoRouter ile geçiş yap
          // Bu, alt navigasyon bandını kullanır.
          if (index >= 0 && index < favPages.length) {
            context.go(favPages[index].path);
          }
        },

        // Dinamik olarak favori sayfalardan BottomNavigationBarItem'ları oluştur
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
