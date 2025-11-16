import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Sayfa Veri Yapısı (Aynı Kalır)
class PageData {
  final String path;
  final String title;
  final IconData icon;

  const PageData({required this.path, required this.title, required this.icon});
}

// 🚨 TÜM ANA SAYFALARIN LİSTESİ (Bottom Nav ve Drawer için Kaynak)
const List<PageData> allMainPages = [
  PageData(path: '/home', title: 'Ana Sayfa', icon: Icons.home),
  PageData(path: '/money', title: 'Para Takibi', icon: Icons.attach_money),
  PageData(path: '/timer', title: 'Odaklanma Kalkanı', icon: Icons.alarm_on),
  PageData(path: '/habits', title: 'Alışkanlık Takibi', icon: Icons.checklist),
  PageData(path: '/fitness', title: 'Spor/Kalori', icon: Icons.fitness_center),
  // 🚨 YENİ SAYFA EKLENDİ
  PageData(
    path: '/agenda',
    title: 'Ajanda/Görevler',
    icon: Icons.calendar_today,
  ),
  PageData(path: '/language', title: 'Dil Öğrenme', icon: Icons.language),
];

// allPages listesi artık sadece main sayfaları içerir
const List<PageData> allPages = [...allMainPages];

// YENİ PROVIDER: SADECE ALT NAVİGASYON ÇUBUĞUNU SABİT TUTAR
final bottomNavigationPagesProvider = Provider<List<PageData>>((ref) {
  // Alt menü çubuğunda görünecek sayfaların sırası ve tam listesi
  return allMainPages;
});

// StateNotifier: Favori sayfaların durumunu yönetir (Sadece yıldızlar için)
class FavoritePagesNotifier extends StateNotifier<List<PageData>> {
  // Başlangıçta tüm ana sayfaları favori olarak işaretleyelim.
  FavoritePagesNotifier() : super(allMainPages);

  // ... (toggleFavorite ve isFavorite metotları aynı kalır)
  void toggleFavorite(PageData page) {
    if (state.any((p) => p.path == page.path)) {
      state = state.where((p) => p.path != page.path).toList();
    } else {
      // Favori limiti 5'ten fazla olamaz
      if (state.length < 6) {
        state = [...state, page];
      }
    }
  }

  bool isFavorite(PageData page) {
    return state.any((p) => p.path == page.path);
  }
}

// Provider Tanımı
final favoritePagesProvider =
    StateNotifierProvider<FavoritePagesNotifier, List<PageData>>((ref) {
      return FavoritePagesNotifier();
    });
