// lib/features/fitness_tracker/presentation/pages/fitness_summary_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/fitness_notifier.dart';
import '../../domain/entities/fitness_entities.dart';
import '../../data/repositories/fitness_repository_impl.dart'; // Repository erişimi için
import 'package:intl/intl.dart';

// --- CUSTOM PAINTER (DÜZELTİLMİŞ HALİ) ---
class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final double maxWeight;
  final double minWeight;
  final double? targetValue; // Hedef Kalori

  _LineChartPainter(
    this.values,
    this.maxWeight,
    this.minWeight, {
    this.targetValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final effectiveMax = (targetValue != null && targetValue! > maxWeight)
        ? targetValue!
        : maxWeight;
    final range = effectiveMax - minWeight;
    final scale = size.height / (range > 0 ? range : 1);
    final widthStep = size.width / (values.length > 1 ? values.length - 1 : 1);

    // 1. HEDEF ÇİZGİSİ (Varsa ve manuel kesikli çizgi)
    if (targetValue != null) {
      final targetY = size.height - (targetValue! - minWeight) * scale;
      final targetPaint = Paint()
        ..color = Colors.white30
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      double dashWidth = 5, dashSpace = 5, startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, targetY),
          Offset(startX + dashWidth, targetY),
          targetPaint,
        );
        startX += dashWidth + dashSpace;
      }
    }

    // 2. GRAFİK ÇİZGİSİ
    for (int i = 0; i < values.length - 1; i++) {
      final x1 = i * widthStep;
      final y1 = size.height - (values[i] - minWeight) * scale;
      final x2 = (i + 1) * widthStep;
      final y2 = size.height - (values[i + 1] - minWeight) * scale;

      // Renk: Hedef varsa ve aşıldıysa Kırmızı, değilse Yeşil (veya Teal)
      Color segmentColor = Colors.tealAccent;
      if (targetValue != null) {
        segmentColor = values[i + 1] > targetValue!
            ? Colors.redAccent
            : Colors.greenAccent;
      }

      final linePaint = Paint()
        ..color = segmentColor
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);
      canvas.drawCircle(Offset(x2, y2), 4, Paint()..color = segmentColor);
      if (i == 0)
        canvas.drawCircle(Offset(x1, y1), 4, Paint()..color = segmentColor);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}

// --- MODELLER & PROVIDERLAR ---

@immutable
class DailyCalorie {
  final DateTime date;
  final int calories;
  const DailyCalorie(this.date, this.calories);
}

// Workout Verisi Çeken Provider
final workoutSummaryProvider = FutureProvider.autoDispose<List<WorkoutEntry>>((
  ref,
) async {
  final repo = await FitnessRepositoryImpl.getInstance();
  // Burada tüm workoutları çekip client-side filtreleyebiliriz veya repo'ya 'getAllWorkouts' ekleyebiliriz.
  // Şimdilik repo yapını bozmamak için 'son 30 gün' mantığını simüle edelim.
  // Ancak FitnessRepository'de 'getAllWorkoutEntries' yoksa eklemen gerekebilir.
  // Var sayarak ilerliyorum, yoksa FitnessRepositoryImpl içine eklemen gerekir.
  // Şimdilik 'getWorkoutEntries' sadece belirli bir gün çekiyor.
  // Basitlik adına, son 7 günü tek tek çekip birleştirelim:

  List<WorkoutEntry> allWorkouts = [];
  final now = DateTime.now();
  for (int i = 0; i < 30; i++) {
    final date = now.subtract(Duration(days: i));
    final daily = await repo.getWorkoutEntries(date);
    allWorkouts.addAll(daily);
  }
  return allWorkouts;
});

class FitnessSummaryPage extends ConsumerStatefulWidget {
  const FitnessSummaryPage({super.key});

  @override
  ConsumerState<FitnessSummaryPage> createState() => _FitnessSummaryPageState();
}

class _FitnessSummaryPageState extends ConsumerState<FitnessSummaryPage> {
  String _selectedTab = 'Calorie'; // Calorie, Weight, Workout

  @override
  Widget build(BuildContext context) {
    final weightAsync = ref.watch(weightSummaryProvider);
    final calorieAsync = ref.watch(calorieSummaryProvider);
    final workoutAsync = ref.watch(workoutSummaryProvider);

    // Ana state'ten o anki HEDEFİ alıyoruz:
    final currentTarget = ref.watch(fitnessNotifierProvider).targetCalories;

    return Scaffold(
      appBar: AppBar(title: const Text('Özet ve Analiz')),
      body: Column(
        children: [
          _buildTabView(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_selectedTab == 'Calorie')
                    calorieAsync.when(
                      data: (entries) => _buildCalorieGraph(
                        entries,
                        currentTarget,
                      ), // Hedefi buraya pass ediyoruz
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Text(
                        'Hata: $e',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  if (_selectedTab == 'Weight')
                    weightAsync.when(
                      data: (entries) => _buildWeightGraph(entries),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Text('Hata: $e'),
                    ),

                  if (_selectedTab == 'Workout')
                    workoutAsync.when(
                      data: (entries) => _buildWorkoutSummary(entries),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Text('Hata: $e'),
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
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTabButton('Calorie', 'KALORİ'),
          _buildTabButton('Weight', 'KİLO'),
          _buildTabButton('Workout', 'EGZERSİZ'),
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
            backgroundColor: isSelected ? Colors.amberAccent : Colors.grey[800],
            foregroundColor: isSelected ? Colors.black : Colors.white60,
            padding: const EdgeInsets.symmetric(vertical: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // --- GRAFİKLER ---

  Widget _buildCalorieGraph(List<FoodEntry> entries, int targetCalories) {
    // Veri hazırlama
    final Map<DateTime, int> dailyTotals = {};
    for (var entry in entries) {
      final date = DateUtils.dateOnly(entry.date);
      dailyTotals[date] = (dailyTotals[date] ?? 0) + entry.calories;
    }
    final List<DailyCalorie> graphData = [];
    final today = DateUtils.dateOnly(DateTime.now());
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      graphData.add(DailyCalorie(date, dailyTotals[date] ?? 0));
    }

    final values = graphData.map((e) => e.calories.toDouble()).toList();
    final maxVal = values.fold(0.0, (p, c) => c > p ? c : p); // Basit max bulma

    return _buildGraphCard(
      title: 'Son 7 Günlük Kalori',
      data: values,
      labels: graphData.map((e) => DateFormat('EE').format(e.date)).toList(),
      maxValue: maxVal.toInt(),
      targetValue: targetCalories.toDouble(), // <-- Hedefi gönderiyoruz
    );
  }

  Widget _buildWeightGraph(List<WeightEntry> entries) {
    if (entries.isEmpty)
      return const Text('Veri yok', style: TextStyle(color: Colors.white));
    // Son 10 veri
    final recentEntries = entries.length > 10
        ? entries.sublist(entries.length - 10)
        : entries;
    final values = recentEntries.map((e) => e.weightKg).toList();
    final labels = recentEntries
        .map((e) => DateFormat('dd.MM').format(e.date))
        .toList();
    final maxVal = values.fold(0.0, (p, c) => c > p ? c : p) + 2;
    final minVal = values.fold(1000.0, (p, c) => c < p ? c : p) - 2;

    return _buildGraphCard(
      title: 'Kilo Gelişimi',
      data: values,
      labels: labels,
      maxValue: maxVal.toInt(),
      minValue: minVal.toInt(),
    );
  }

  // --- YENİ: Workout Summary Tasarımı ---
  Widget _buildWorkoutSummary(List<WorkoutEntry> entries) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: const Column(
          children: [
            Icon(Icons.fitness_center, size: 48, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Henüz kayıtlı egzersiz yok.',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    // İstatistik Hesaplama
    final totalSets = entries.fold(0, (sum, e) => sum + e.sets);
    // En çok çalışılan bölgeyi bul
    final regionCounts = <String, int>{};
    for (var e in entries) {
      regionCounts[e.region] = (regionCounts[e.region] ?? 0) + 1;
    }
    String topRegion = '-';
    if (regionCounts.isNotEmpty) {
      topRegion = regionCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    // Listeyi tarihe göre tersten sırala (en yeni en üstte)
    final sortedEntries = List.of(entries)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: [
        // 1. İstatistik Kartları
        Row(
          children: [
            _buildStatCard(
              'Toplam Set',
              '$totalSets',
              Icons.format_list_numbered,
              Colors.blueAccent,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Favori Bölge',
              topRegion.toUpperCase(),
              Icons.accessibility_new,
              Colors.orangeAccent,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. Başlık
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Son Antrenmanlar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 3. Liste
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedEntries.length,
          itemBuilder: (context, index) {
            final entry = sortedEntries[index];
            return Card(
              color: Colors.grey[850],
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[800],
                  child: Icon(
                    Icons.fitness_center,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
                title: Text(
                  entry.exercise,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${entry.sets} Set x ${entry.reps} Tekrar @ ${entry.weight}kg',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('dd MMM').format(entry.date),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      entry.region,
                      style: TextStyle(color: Colors.amber[200], fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // --- ORTAK GRAFİK KARTI ---
  Widget _buildGraphCard({
    required String title,
    required List<double> data,
    required List<String> labels,
    required int maxValue,
    int minValue = 0,
    double? targetValue, // Hedef eklendi
  }) {
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: CustomPaint(
                painter: _LineChartPainter(
                  data,
                  maxValue.toDouble(),
                  minValue.toDouble(),
                  targetValue: targetValue, // Painter'a gönder
                ),
              ),
            ),
            const SizedBox(height: 10),
            // X Ekseni Label'ları
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labels
                  .map(
                    (l) => Text(
                      l,
                      style: TextStyle(color: Colors.grey[500], fontSize: 10),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
