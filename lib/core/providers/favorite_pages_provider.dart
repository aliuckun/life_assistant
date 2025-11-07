// lib/core/providers/favorite_pages_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

// Sayfa Veri Yapısı
class PageData {
  final String path; // GoRouter yolu (örneğin: '/money')
  final String title; // Menüde gözükecek başlık
  final IconData icon; // BottomNavigationBar ikonu

  const PageData({required this.path, required this.title, required this.icon});
}

// Tüm Uygulama Sayfalarının Listesi
const List<PageData> allPages = [
  PageData(path: '/home', title: 'Ana Sayfa', icon: Icons.home),
  PageData(path: '/money', title: 'Para Takibi', icon: Icons.attach_money),
  PageData(path: '/habits', title: 'Alışkanlık Takibi', icon: Icons.checklist),
  PageData(path: '/settings', title: 'Ayarlar', icon: Icons.settings),
  // ... İleride eklenecek diğer tüm sayfalar
];

// StateNotifier: Favori sayfaların durumunu yönetir
class FavoritePagesNotifier extends StateNotifier<List<PageData>> {
  // Başlangıçta Ana Sayfa ve Para Takibi favori olsun.
  FavoritePagesNotifier()
    : super([
        allPages.firstWhere((p) => p.path == '/home'),
        allPages.firstWhere((p) => p.path == '/money'),
      ]);

  // Sayfayı favorilere ekler/kaldırır
  void toggleFavorite(PageData page) {
    if (state.any((p) => p.path == page.path)) {
      // Zaten favoriyse kaldır
      state = state.where((p) => p.path != page.path).toList();
    } else {
      // Favori değilse ekle
      // NOT: Alt navigasyon bandında mantıklı bir limit olmalıdır (örneğin max 5 sayfa)
      if (state.length < 5) {
        state = [...state, page];
      }
    }
  }

  // Belirli bir sayfanın favori olup olmadığını kontrol eder
  bool isFavorite(PageData page) {
    return state.any((p) => p.path == page.path);
  }
}

// Provider Tanımı
final favoritePagesProvider =
    StateNotifierProvider<FavoritePagesNotifier, List<PageData>>((ref) {
      return FavoritePagesNotifier();
    });
