import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ provider değil riverpod!
import 'package:life_assistant/features/habit_tracker/domain/models/habit.dart';
import 'package:life_assistant/features/habit_tracker/presentation/notifiers/habit_notifier.dart';

// ✅ ConsumerWidget kullan
class HabitCard extends ConsumerWidget {
  final Habit habit;
  const HabitCard({super.key, required this.habit});

  // Hedefe ulaşıldığında gösterilecek animasyon
  void _showCompletionAnimation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: scale,
                child: AlertDialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🥳', style: TextStyle(fontSize: 100)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade600,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Tebrikler! Günlük Hedefe Ulaşıldı!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ ref.read ile HabitNotifier'a eriş (listen: false yerine read kullan)
    final habitNotifier = ref.read(habitListProvider);
    final selectedDate = ref.watch(habitListProvider).selectedDate;

    // Seçili gün için ilerleme ve durum
    final progress = habit.getProgressForDate(selectedDate);
    final isCompleted = habit.isCompletedForDate(selectedDate);
    final isFuture = selectedDate.isAfter(DateUtils.dateOnly(DateTime.now()));

    // Renkleri koyulaştırma
    final Color gainColor = Colors.green.shade50;
    final Color quitColor = Colors.red.shade50;
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color darkText = Colors.black87;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: habit.type == HabitType.quit ? quitColor : gainColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              habit.type == HabitType.gain
                  ? Icons.check_circle_outline
                  : Icons.block,
              color: habit.type == HabitType.gain
                  ? Colors.green.shade700
                  : Colors.red.shade700,
              size: 30,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (habit.type == HabitType.gain)
                    Text(
                      'Hedef: ${habit.targetCount} kez',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: darkText),
                    ),
                  if (habit.type == HabitType.quit)
                    Text(
                      'Bırakılacak Alışkanlık (Günde 0 kez hedef)',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: darkText),
                    ),
                  if (habit.enableNotification &&
                      habit.notificationTime != null)
                    Text(
                      'Bildirim: ${habit.notificationTime!.format(context)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: darkText),
                    ),
                ],
              ),
            ),

            // İlerleme Göstergesi ve + Butonu
            if (habit.type == HabitType.gain)
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: Text(
                      '$progress/${habit.targetCount}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.white : darkText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // + Butonu
                  if (!isFuture)
                    GestureDetector(
                      onTap: isCompleted
                          ? null
                          : () {
                              habitNotifier.incrementHabit(habit, selectedDate);
                              // Tamamlanma kontrolü ve animasyon
                              if (habit.getProgressForDate(selectedDate) ==
                                  habit.targetCount) {
                                _showCompletionAnimation(context);
                              }
                            },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.grey.shade400
                              : primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          color: isCompleted ? darkText : Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),

            // Bırakılacak alışkanlıklar (Quit) için durum göstergesi
            if (habit.type == HabitType.quit && !isFuture)
              Column(
                children: [
                  // Durum İkonu
                  Icon(
                    progress == 0 ? Icons.check_circle_outline : Icons.cancel,
                    color: progress == 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    size: 30,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    progress == 0
                        ? 'Başarılı (0/1)'
                        : 'Başarısız ($progress/1)',
                    style: TextStyle(
                      color: progress == 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // + Butonu (Bırakılacak alışkanlıklar için artırma butonu)
                  GestureDetector(
                    onTap: () {
                      if (progress < 1) {
                        habitNotifier.incrementHabit(habit, selectedDate);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: progress > 0
                            ? Colors.grey.shade400
                            : Colors.red.shade400,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_amber,
                        color: progress > 0 ? darkText : Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
