//lib/features/fitness_tracker/presentation/widgets/date_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/fitness_notifier.dart';

// FitnessNotifier'ı kullanmak için uyarlanmış DateSelector
class DateSelector extends ConsumerWidget {
  const DateSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fitnessNotifier = ref.read(
      fitnessNotifierProvider.notifier,
    ); // Eylem için Notifier
    final selectedDate = ref
        .watch(fitnessNotifierProvider)
        .selectedDate; // Sadece state'i izle
    final today = DateUtils.dateOnly(DateTime.now());
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        itemCount: 30,
        itemBuilder: (context, index) {
          final date = today.subtract(Duration(days: index));
          final isSelected = selectedDate == date;
          final isFuture = date.isAfter(today);

          String dayName;
          if (date == today) {
            dayName = 'Bugün';
          } else if (date == today.subtract(const Duration(days: 1))) {
            dayName = 'Dün';
          } else {
            dayName = '${date.day}';
          }

          return GestureDetector(
            onTap: isFuture
                ? null
                : () {
                    fitnessNotifier.setSelectedDate(date);
                  },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor
                    : isFuture
                    ? Colors.grey.shade700
                    : Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryColor.withOpacity(isSelected ? 1.0 : 0.2),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.5),
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
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey[500],
                      fontSize: 12,
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
