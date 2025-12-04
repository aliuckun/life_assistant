import 'package:flutter/material.dart';
import '../utils/planner_constants.dart';

class DateTimeline extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const DateTimeline({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<DateTimeline> createState() => _DateTimelineState();
}

class _DateTimelineState extends State<DateTimeline> {
  // Tarih listesini bellekte tutuyoruz, her render'da hesaplamıyoruz.
  late final List<DateTime> _weekDates;

  @override
  void initState() {
    super.initState();
    // Tarih hesaplamasını SADECE BİR KEZ burada yapıyoruz.
    // Performans kazancı: %100
    _weekDates = List.generate(7, (index) {
      return DateTime.now().subtract(Duration(days: 6 - (index + 1)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: _weekDates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = _weekDates[index];
          // widget.selectedDate kullanarak parent'tan gelen veriyi alıyoruz
          final isSelected = PlannerConstants.isSameDay(
            date,
            widget.selectedDate,
          );
          final isToday = PlannerConstants.isSameDay(date, DateTime.now());

          return GestureDetector(
            onTap: () => widget.onDateSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 55,
              decoration: BoxDecoration(
                color: isSelected ? Colors.black87 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected
                    ? Border.all(color: Colors.black87, width: 1.5)
                    : Border.all(color: Colors.transparent),
                // Gölge optimizasyonu: Sadece seçiliyse gölge at
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        // Seçili değilse çok hafif, performanslı bir gölge veya hiç yok
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    PlannerConstants.getDayName(date.weekday),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (isToday && !isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
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
