// lib/features/money_tracking/presentation/widgets/total_expense_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/money_tracker_notifier.dart';

class TotalExpenseCard extends ConsumerWidget {
  final double totalExpense;
  final int resetDay;

  const TotalExpenseCard({
    super.key,
    required this.totalExpense,
    required this.resetDay,
  });

  // Sıfırlama Günü Ayar Diyaloğu
  void _showResetDayDialog(BuildContext context, WidgetRef ref) {
    int selectedDay = resetDay;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Harcama Dönemi Sıfırlama Günü'),
          content: DropdownButtonFormField<int>(
            value: selectedDay,
            decoration: const InputDecoration(labelText: 'Ayın Günü'),
            items: List.generate(31, (index) => index + 1)
                .map(
                  (day) => DropdownMenuItem(
                    value: day,
                    child: Text('Ayın $day. Günü'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                selectedDay = value;
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                // Notifier'ı yeni gün ile güncelle
                ref
                    .read(moneyTrackerNotifierProvider.notifier)
                    .setResetDay(selectedDay);
                Navigator.pop(ctx);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dönem Başlangıcı ve Bitişini Görüntüleme Mantığı (Basitleştirilmiş)
    // NOTE: Bu mantık Notifier içinde de var ama gösterim için burada tekrar ediyoruz
    final now = DateTime.now();
    int startDay = now.day >= resetDay
        ? resetDay
        : DateTime(now.year, now.month - 1, resetDay).day;
    int startMonth = now.day >= resetDay ? now.month : now.month - 1;
    startMonth = startMonth < 1 ? 12 : startMonth; // Ay 1'den küçükse 12 yap

    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dönemlik Harcama (Ayın $resetDay. Günü)',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
                // 🚨 Ayar İkonu Eklendi
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.grey),
                  onPressed: () => _showResetDayDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${totalExpense.toStringAsFixed(2)} ₺',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              // Basit bir dönem gösterimi
              'Dönem Başlangıcı: Ayın $resetDay. Günü',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
