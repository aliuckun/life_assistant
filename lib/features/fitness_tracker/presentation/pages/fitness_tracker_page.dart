// lib/features/fitness_tracker/presentation/pages/fitness_tracker_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/fitness_entities.dart';
import '../state/fitness_notifier.dart';
import '../widgets/date_selector.dart'; // Habit'ten alınan tarih seçici
import '../widgets/add_food_modal.dart';
import '../widgets/add_workout_modal.dart';
import '../widgets/add_weight_modal.dart';
import '../widgets/food_entry_card.dart';
import '../widgets/fitness_summary_page.dart';

class FitnessTrackerPage extends ConsumerStatefulWidget {
  const FitnessTrackerPage({super.key});

  @override
  ConsumerState<FitnessTrackerPage> createState() => _FitnessTrackerPageState();
}

class _FitnessTrackerPageState extends ConsumerState<FitnessTrackerPage> {
  final _scrollController = ScrollController();
  static const _scrollThreshold = 200.0;

  @override
  void initState() {
    super.initState();
    // Lazy Loading için listener
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll - currentScroll <= _scrollThreshold) {
      ref.read(fitnessNotifierProvider.notifier).fetchNextEntries();
    }
  }

  // --- Modallar ---

  void _showAddFoodModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => const AddFoodModal(),
    );
  }

  void _showAddWeightModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => const AddWeightModal(),
    );
  }

  void _showAddWorkoutModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => const AddWorkoutModal(),
    );
  }

  // Düzenleme
  void _showEditFoodModal(FoodEntry entry) {
    // Aynı AddFoodModal'ı kullanabiliriz, sadece var olan veriyi iletmeliyiz
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fitnessNotifierProvider);
    final notifier = ref.read(fitnessNotifierProvider.notifier);

    if (state.isLoading && state.foodEntries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spor ve Kalori Takibi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FitnessSummaryPage(),
                ),
              );
            },
            tooltip: 'Özet ve Analiz',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Günlük Seçici (Habit'ten alınan widget)
          const DateSelector(),

          // 2. Toplam Kalori Kartı
          _buildCalorieCard(state.totalCalories, state.selectedDate),

          const SizedBox(height: 10),

          // 3. Kalori ve Egzersiz Giriş Butonları
          _buildEntryButtons(),

          // 4. Günlük Yemek Giriş Listesi (Lazy Loading)
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount:
                  state.foodEntries.length +
                  (state.hasMore || state.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.foodEntries.length) {
                  return const Center(child: CircularProgressIndicator());
                }

                final entry = state.foodEntries[index];
                return FoodEntryCard(
                  entry: entry,
                  onDelete: (id) => notifier.deleteFoodEntry(id),
                  onEdit: _showEditFoodModal,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWeightModal, // Kilo kaydı için FAB kullan
        tooltip: 'Kilo Kaydı',
        child: const Icon(Icons.monitor_weight),
      ),
    );
  }

  Widget _buildCalorieCard(int totalCalories, DateTime date) {
    return Card(
      color: Colors.blueGrey.shade800,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DateFormat('dd MMMM yyyy').format(date)} Alınan Kalori',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '$totalCalories Kcal',
              style: const TextStyle(
                color: Colors.amberAccent,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMiniButton(Icons.fastfood, 'Yemek Ekle', _showAddFoodModal),
          _buildMiniButton(
            Icons.directions_run,
            'Egzersiz Kaydet',
            _showAddWorkoutModal,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label, style: const TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}
