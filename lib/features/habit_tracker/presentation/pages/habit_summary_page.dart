// lib/features/habit_tracker/presentation/pages/habit_summary_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_assistant/features/habit_tracker/domain/entities/habit.dart'; // Entity güncellendi
import '../notifers/habit_notifier.dart';

// StatelessWidget yerine ConsumerWidget kullanıyoruz
class HabitSummaryPage extends ConsumerWidget {
  const HabitSummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Özet verilerini FutureProvider'dan almalıyız (Notifier'daki metod asenkron)
    // Şimdilik sadece notifier'ı kullanıyoruz
    final notifier = ref.read(habitListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alışkanlık Özet ve Analiz'),
        backgroundColor: Colors.grey[900], // Koyu tema
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        // Asenkron metodu çağır
        future: notifier.getSummaryData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Özet verisi yüklenemedi.'));
          }

          final summaryData = snapshot.data!;
          final totalHabits = summaryData['totalHabits'] as int;
          final completionRate = summaryData['completionRate'] as double;

          // Alışkanlık listesini Notifier'dan çek (görselleştirmek için)
          final allHabits = ref.watch(habitListProvider).habits;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Genel Bakış Kartı ---
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.grey[850], // Koyu tema rengi
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Genel İstatistikler',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 15),
                        _buildStatRow(
                          context,
                          icon: Icons.track_changes,
                          title: 'Toplam Alışkanlık',
                          value: totalHabits.toString(),
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(height: 10),
                        _buildStatRow(
                          context,
                          icon: Icons.star_rate,
                          title: 'Ortalama Tamamlanma Oranı (Son 7 Gün)',
                          value: '${completionRate.toStringAsFixed(1)}%',
                          color: Colors.teal.shade700,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- Tüm Alışkanlıkların Durumu ---
                Text(
                  'Tüm Alışkanlıklar',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),

                if (allHabits.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'Henüz takibe alınmış bir alışkanlık yok.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...allHabits
                      .map(
                        (habit) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: _buildHabitSummaryTile(context, habit),
                        ),
                      )
                      .toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  // İstatistik satırı oluşturucu
  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Alışkanlık özet döşemesi oluşturucu
  Widget _buildHabitSummaryTile(BuildContext context, Habit habit) {
    // Alışkanlığın son 7 gündeki tamamlanma gün sayısı
    int completedDays = 0;
    for (int i = 0; i < 7; i++) {
      final date = DateUtils.dateOnly(
        DateTime.now().subtract(Duration(days: i)),
      );
      if (habit.isCompletedForDate(date)) {
        completedDays++;
      }
    }

    final isGain = habit.type == HabitType.gain;
    final Color indicatorColor = isGain
        ? Colors.green.shade700
        : Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isGain ? Icons.add_circle_outline : Icons.remove_circle_outline,
                color: indicatorColor,
              ),
              const SizedBox(width: 10),
              Text(
                habit.name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isGain ? 'Kazanılacak' : 'Bırakılacak',
                style: TextStyle(
                  fontSize: 12,
                  color: isGain ? Colors.green.shade500 : Colors.red.shade500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Son 7 günde: $completedDays ${isGain ? 'Tamamlandı' : 'Başarılı'}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
