import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_assistant/features/habit_tracker/domain/models/habit.dart';
import 'package:life_assistant/features/habit_tracker/presentation/notifiers/habit_notifier.dart';

// StatelessWidget yerine ConsumerWidget kullanıyoruz
class HabitSummaryPage extends ConsumerWidget {
  const HabitSummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // HabitNotifier'ın kendisini izle
    final habitNotifier = ref.watch(habitListProvider);

    // Alışkanlık listesini Notifier'dan al
    final habits =
        habitNotifier.habits; // Hata Çözümü: .habits getter'ı kullanıldı

    // Özet verilerini al
    final summaryData = habitNotifier.getSummaryData();
    final totalHabits = summaryData['totalHabits'] as int;
    final completionRate = summaryData['completionRate'] as double;

    // Koyu yazı rengi
    const Color darkText = Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alışkanlık Özet ve Analiz'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
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
              color: Theme.of(context).primaryColor.withOpacity(0.1),
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
                            color: darkText,
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
                color: darkText,
              ),
            ),
            const SizedBox(height: 10),

            if (habits.isEmpty) // Hata Çözümü: habits.isEmpty kullanıldı
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Henüz takibe alınmış bir alışkanlık yok.'),
                ),
              )
            else
              ...habits
                  .map(
                    (habit) => Padding(
                      // Hata Çözümü: habits.map kullanıldı
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: _buildHabitSummaryTile(
                        context,
                        habit,
                        habitNotifier,
                      ),
                    ),
                  )
                  .toList(),
          ],
        ),
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
    const Color darkText = Colors.black87;
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: darkText),
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
  Widget _buildHabitSummaryTile(
    BuildContext context,
    Habit habit,
    HabitNotifier notifier,
  ) {
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
    const Color darkText = Colors.black87;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
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
                  color: darkText,
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
