// lib/features/money_tracking/presentation/widgets/summary_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction.dart';
import '../state/money_tracker_notifier.dart';

// Renk haritası (Kategorilere tutarlı renkler atamak için)
const Map<String, Color> _categoryColors = {
  'Gıda': Colors.teal,
  'Fatura': Colors.indigo,
  'Eğitim': Colors.orange,
  'Diğer': Colors.blueGrey,
  'Maaş': Colors.green, // Gelirler grafikte yer almaz, ama burada dursun
};

class SummarySection extends ConsumerWidget {
  const SummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(
      moneyTrackerNotifierProvider.select((s) => s.expenseSummary),
    );

    if (summary.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Henüz gider işlemi yok.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Toplam harcamayı hesapla (yüzde hesaplaması zaten notifier'da yapıldı)
    final grandTotal = summary.fold(0.0, (sum, item) => sum + item.amount);

    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aylık Harcama Özeti',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                // Pasta Grafik Bölümü
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CustomPaint(
                    painter: PieChartPainter(summary: summary),
                  ),
                ),
                const SizedBox(width: 20),
                // Lejant (Gösterge) Bölümü
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: summary.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color:
                                    _categoryColors[item.category] ??
                                    Colors.deepPurple,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${item.category} (${(item.percentage * 100).toStringAsFixed(1)}%)',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${item.amount.toStringAsFixed(0)} ₺',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Toplam Gider: ${grandTotal.toStringAsFixed(2)} ₺',
                style: const TextStyle(fontSize: 14, color: Colors.amberAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pasta Grafiği Çizen Sınıf
class PieChartPainter extends CustomPainter {
  final List<CategorySummary> summary;

  PieChartPainter({required this.summary});

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = size.width / 2;
    double startAngle = -3.14159 / 2; // Başlangıç açısı (Üst nokta)

    for (var item in summary) {
      final sweepAngle = 2 * 3.14159 * item.percentage;
      final color = _categoryColors[item.category] ?? Colors.deepPurple;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      // Pasta dilimini çiz
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true, // Center ile birleştir (pasta dilimi oluştur)
        paint,
      );

      // Sonraki dilimin başlangıç açısını güncelle
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    // Veriler değiştiyse yeniden çiz
    return oldDelegate.summary != summary;
  }
}
