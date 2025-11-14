// lib/features/habit_tracker/presentation/pages/habit_tracker_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 🚨 Düzeltme: state klasöründen show ile çekildi
import '../notifers/habit_notifier.dart' show habitListProvider;
import '../widgets/add_habit_modal.dart';
import '../widgets/date_selector.dart';
import '../widgets/habit_card.dart';
import './habit_summary_page.dart';
import '../../domain/entities/habit.dart'; // Habit Entity'si için
import '../widgets/edit_habit_modal.dart'; // Edit Habit Modalı için

class HabitTrackerPage extends ConsumerStatefulWidget {
  const HabitTrackerPage({super.key});

  @override
  ConsumerState<HabitTrackerPage> createState() => _HabitTrackerPageState();
}

class _HabitTrackerPageState extends ConsumerState<HabitTrackerPage> {
  final _scrollController = ScrollController();
  static const _scrollThreshold = 200.0;

  @override
  void initState() {
    super.initState();
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
      ref.read(habitListProvider.notifier).fetchNextHabits();
    }
  }

  // 🚨 ADD MODAL metodu (Burada Metot Bitiyor)
  void _showAddHabitModal(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(habitListProvider.notifier);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return AddHabitModal(
          onSave: (habit) {
            notifier.addHabit(habit);
          },
        );
      },
    );
  }

  // 🚨 EDIT MODAL metodu (Burada Metot Bitiyor)
  void _showEditHabitModal(BuildContext context, Habit habit) {
    final notifier = ref.read(habitListProvider.notifier);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return EditHabitModal(
          habit: habit,
          onUpdate: (updatedHabit) => notifier.updateHabit(updatedHabit),
          onDelete: (id) => notifier.deleteHabit(id),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(habitListProvider);
    final habits = state.habits;

    if (state.isLoadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alışkanlık Takibi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const HabitSummaryPage(),
                ),
              );
            },
            tooltip: 'Özet ve Analiz',
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: DateSelector(),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${state.selectedDate.day}.${state.selectedDate.month}.${state.selectedDate.year} Alışkanlıkları',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
          ),

          Expanded(
            child: habits.isEmpty && !state.isLoadingInitial
                ? const Center(
                    child: Text(
                      'Henüz eklenmiş bir alışkanlığınız yok.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: habits.length + (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == habits.length) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final habit = habits[index];
                      return GestureDetector(
                        // Tıklama ile düzenlemeyi aç
                        onTap: () => _showEditHabitModal(context, habit),
                        child: HabitCard(habit: habit),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHabitModal(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
