// lib/features/fitness_tracker/presentation/pages/fitness_summary_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/fitness_notifier.dart';
import '../../domain/entities/fitness_entities.dart';
import 'package:intl/intl.dart';

// Basit bir çizgi grafik simülasyonu için Custom Painter
class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final double maxWeight;
  final double minWeight;

  _LineChartPainter(this.values, this.maxWeight, this.minWeight);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = Colors.tealAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final pointCount = values.length;
    final widthStep = size.width / (pointCount > 1 ? pointCount - 1 : 1);
    final range = maxWeight - minWeight;
    final scale = size.height / (range > 0 ? range : 1);

    for (int i = 0; i < pointCount; i++) {
      final x = i * widthStep;
      // Kilo değerini ters çevirip y koordinatına ölçekle
      final y = size.height - (values[i] - minWeight) * scale;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Noktayı çiz
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = Colors.white);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

// Kalori Özet Veri Modeli
@immutable
class DailyCalorie {
  final DateTime date;
  final int calories;
  const DailyCalorie(this.date, this.calories);
}

class FitnessSummaryPage extends ConsumerStatefulWidget {
  const FitnessSummaryPage({super.key});

  @override
  ConsumerState<FitnessSummaryPage> createState() => _FitnessSummaryPageState();
}

class _FitnessSummaryPageState extends ConsumerState<FitnessSummaryPage> {
  // 🚨 Google Sekmeleri Simülasyonu için State
  String _selectedTab = 'Calorie';

  @override
  Widget build(BuildContext context) {
    // 🚨 Kilo ve Kalori verilerini FutureProvider'lardan çek
    final weightAsync = ref.watch(weightSummaryProvider);
    final calorieAsync = ref.watch(calorieSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Özet ve Grafikler')),
      body: Column(
        children: [
          // 1. Google Sekmeleri Simülasyonu
          _buildTabView(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_selectedTab == 'Calorie')
                    calorieAsync.when(
                      data: (foodEntries) => _buildCalorieGraph(foodEntries),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Text(
                        'Kalori verisi yüklenemedi: $err',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  if (_selectedTab == 'Weight')
                    weightAsync.when(
                      data: (weightEntries) => _buildWeightGraph(weightEntries),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Text(
                        'Kilo verisi yüklenemedi: $err',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabView() {
    // Koyu tema ile uyumlu basit sekme çubuğu
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTabButton('Calorie', 'KALORİ GRAFİĞİ'),
          _buildTabButton('Weight', 'KİLO GRAFİĞİ'),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String label) {
    final isSelected = _selectedTab == tab;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () => setState(() => _selectedTab = tab),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.amberAccent : Colors.grey[700],
            foregroundColor: isSelected ? Colors.black : Colors.white,
            elevation: 0,
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // --- Kalori Grafiği ---
  Widget _buildCalorieGraph(List<FoodEntry> entries) {
    // Günlük toplam kaloriyi hesapla
    final Map<DateTime, int> dailyTotals = {};
    for (var entry in entries) {
      final date = DateUtils.dateOnly(entry.date);
      dailyTotals[date] = (dailyTotals[date] ?? 0) + entry.calories;
    }

    // Son 7 günü al
    final List<DailyCalorie> graphData = [];
    final today = DateUtils.dateOnly(DateTime.now());
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      graphData.add(DailyCalorie(date, dailyTotals[date] ?? 0));
    }

    final values = graphData.map((e) => e.calories.toDouble()).toList();
    final maxCalorie = values.isEmpty
        ? 0
        : values.reduce((a, b) => a > b ? a : b);

    return _buildGraphCard(
      title: 'Son 7 Günlük Kalori Tüketimi',
      data: values,
      labels: graphData.map((e) => DateFormat('EE').format(e.date)).toList(),
      maxValue: maxCalorie.toInt(),
    );
  }

  // --- Kilo Grafiği ---
  Widget _buildWeightGraph(List<WeightEntry> entries) {
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Henüz kilo kaydı yok.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Kilo verilerini listele
    final values = entries.map((e) => e.weightKg).toList();
    final labels = entries
        .map((e) => DateFormat('dd.MM').format(e.date))
        .toList();

    final maxWeight = values.reduce((a, b) => a > b ? a : b) + 1;
    final minWeight = values.reduce((a, b) => a < b ? a : b) - 1;

    return _buildGraphCard(
      title: 'Haftalık Kilo Gelişimi (kg)',
      data: values,
      labels: labels,
      maxValue: maxWeight.toInt(),
      minValue: minWeight.toInt(),
    );
  }

  // Ortak Grafik Kartı
  Widget _buildGraphCard({
    required String title,
    required List<double> data,
    required List<String> labels,
    required int maxValue,
    int minValue = 0,
  }) {
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Grafik verisi mevcut değil.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Grafik Alanı
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: CustomPaint(
                painter: _LineChartPainter(
                  data,
                  maxValue.toDouble(),
                  minValue.toDouble(),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Etiketler (X ekseni)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labels
                  .map(
                    (label) =>
                        Text(label, style: TextStyle(color: Colors.grey[400])),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),

            // Değerler (Max/Min)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Min: $minValue',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                Text(
                  'Max: $maxValue',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
