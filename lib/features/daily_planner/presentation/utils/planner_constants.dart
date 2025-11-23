import 'package:flutter/material.dart';
import '../../domain/plan_models.dart';

class PlannerConstants {
  // Sabit Kategoriler (UI İçin)
  static const List<PlanCategory> categories = [
    PlanCategory('İş', Icons.work_outline, Colors.blue),
    PlanCategory('Spor', Icons.fitness_center, Colors.orange),
    PlanCategory('Kişisel', Icons.person_outline, Colors.purple),
    PlanCategory('Eğitim', Icons.school_outlined, Colors.green),
    PlanCategory('Sosyal', Icons.people_outline, Colors.pink),
    PlanCategory('Ev', Icons.home_outlined, Colors.brown),
  ];

  // Kategori isminden nesneye ulaşma (DB'den okurken lazım)
  static PlanCategory getCategoryByName(String name) {
    return categories.firstWhere(
      (cat) => cat.name == name,
      orElse: () => categories.first,
    );
  }

  // Tarih Karşılaştırma
  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Türkçe Gün İsimleri
  static String getDayName(int weekday) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[weekday - 1];
  }
}
