// lib/features/habit_tracker/presentation/pages/habit_tracker_page.dart
import 'package:flutter/material.dart';

// Riverpod kullanacağımız için ConsumerWidget ile başlatalım
class HabitTrackerPage extends StatelessWidget {
  const HabitTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Alışkanlık Takibi Sayfası (Infinite Scroll burada olacak)',
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
  }
}
