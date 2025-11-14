import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ⚠️ provider DEĞIL riverpod!
import 'package:life_assistant/features/habit_tracker/presentation/notifiers/habit_notifier.dart';

// ✅ ConsumerWidget kullan (StatelessWidget yerine)
class DateSelector extends ConsumerWidget {
  const DateSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ ref.watch ile provider'a eriş
    final habitNotifier = ref.watch(habitListProvider);
    final selectedDate = habitNotifier.selectedDate;
    final today = DateUtils.dateOnly(DateTime.now());

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        itemCount: 30, // Son 30 günün gösterimi
        itemBuilder: (context, index) {
          final date = today.subtract(Duration(days: index));
          final isSelected = selectedDate == date;

          String dayName;
          if (date == today) {
            dayName = 'Bugün';
          } else if (date == today.subtract(const Duration(days: 1))) {
            dayName = 'Dün';
          } else {
            dayName = '${date.day}';
          }

          return GestureDetector(
            onTap: () {
              habitNotifier.setSelectedDate(date);
            },
            child: Container(
              width: 50,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.5),
                          blurRadius: 5,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.black54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
