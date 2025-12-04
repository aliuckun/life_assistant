// -----------------------------------------------------------------------------
// DOSYA: lib/features/step_counter/presentation/pages/step_counter_page.dart
// KATMAN: Presentation (UI)
// AÇIKLAMA: Tasarım aynı kalırken, verileri artık gerçek Controller'dan alır.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/step_repository.dart';
import '../state/step_controller.dart';
import '../../domain/step_model.dart';

class StepCounterPage extends StatelessWidget {
  const StepCounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StepController(StepRepository()),
      child: const _StepCounterView(),
    );
  }
}

class _StepCounterView extends StatelessWidget {
  const _StepCounterView();

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<StepController>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Adım Sayar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => _showStatsModal(context, controller),
          ),
        ],
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Durum Mesajı (Debug/User Info)
                    if (controller.status.contains("Hata") ||
                        controller.status.contains("redd"))
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 10),
                        color: Colors.redAccent.withOpacity(0.1),
                        child: Text(
                          controller.status,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    // 1. Ana Halka
                    _buildDailyProgress(controller),

                    const SizedBox(height: 30),

                    // 2. Grafik Başlığı
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Son 30 Gün",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // 3. Grafik
                    SizedBox(height: 250, child: _buildChart(controller)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDailyProgress(StepController controller) {
    // Hedef: 10.000 adım
    double percent = (controller.todaySteps / 10000).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percent >= 1.0 ? Colors.green : Colors.orangeAccent,
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                children: [
                  const Icon(
                    Icons.directions_walk,
                    size: 30,
                    color: Colors.grey,
                  ),
                  Text(
                    "${controller.todaySteps}",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Text("Adım", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            percent >= 1.0
                ? "Hedef Tamamlandı! 🎉"
                : "${10000 - controller.todaySteps} adım kaldı",
            style: TextStyle(
              color: percent >= 1.0 ? Colors.green : Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(StepController controller) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 15000,
        // -----------------------------------------------------------------
        // GÜNCELLEME: Dokunma özellikleri (Touch Data) aktif edildi
        // -----------------------------------------------------------------
        barTouchData: BarTouchData(
          enabled: true, // Artık dokunulabilir!
          touchTooltipData: BarTouchTooltipData(
            // Tooltip arka plan rengi (Koyu gri/Mavi tonu modern durur)
            tooltipBgColor: Colors.blueGrey.shade900,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            // Tooltip'in ne kadar yuvarlak olacağı
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              // Hangi veriye tıklandığını bulalım
              final dailyData = controller.history[group.x.toInt()];
              final dateStr = DateFormat('d MMM').format(dailyData.date);
              final stepsStr = NumberFormat('#,###').format(dailyData.steps);

              return BarTooltipItem(
                // Baloncuk içindeki yazı
                '$dateStr\n',
                const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: '$stepsStr Adım',
                    style: const TextStyle(
                      color: Colors.white, // Sayı daha parlak beyaz
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                int index = value.toInt();
                // Sadece 5 günde bir tarih yaz (Kalabalığı önlemek için)
                if (index >= 0 &&
                    index < controller.history.length &&
                    index % 5 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('d/M').format(controller.history[index].date),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: controller.history.asMap().entries.map((entry) {
          int index = entry.key;
          DailySteps data = entry.value;
          bool isToday = index == controller.history.length - 1;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data.steps.toDouble(),
                // Bugün turuncu, diğer günler mavi, ama üzerine basılırsa renk değişimi
                // fl_chart bunu otomatik handle edebilir veya gradient kullanabiliriz.
                // Şimdilik sade tutuyoruz.
                color: isToday ? Colors.orange : Colors.blue.shade200,
                width:
                    12, // Çubukları biraz daha kalınlaştırdım, basması kolay olsun
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 15000,
                  color: Colors.grey.shade100,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showStatsModal(BuildContext context, StepController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "İstatistikler",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_month, color: Colors.blue),
              ),
              title: const Text("Aylık Ortalama"),
              trailing: Text(
                "${controller.monthlyAverage.toInt()} Adım",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
