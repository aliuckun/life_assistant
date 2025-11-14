import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod import edildi
import 'package:life_assistant/features/habit_tracker/presentation/notifiers/habit_notifier.dart'; // <<< BU IMPORT SATIRI EKLENMELİ!
import 'package:life_assistant/features/habit_tracker/presentation/widgets/add_habit_modal.dart';
import 'package:life_assistant/features/habit_tracker/presentation/widgets/date_selector.dart';
import 'package:life_assistant/features/habit_tracker/presentation/widgets/habit_card.dart';
import 'package:life_assistant/features/habit_tracker/presentation/pages/habit_summary_page.dart';

// StatelessWidget yerine ConsumerWidget kullanıyoruz
class HabitTrackerPage extends ConsumerWidget {
  const HabitTrackerPage({super.key});

  void _showAddHabitModal(BuildContext context, WidgetRef ref) {
    // ref.read(habitListProvider) ile Notifier'ın kendisini alıyoruz
    final notifier = ref.read(habitListProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return AddHabitModal(
          onSave: (habit) {
            notifier.addHabit(habit);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // WidgetRef eklendi
    // HabitNotifier'ın kendisini izle
    final habitNotifier = ref.watch(habitListProvider);
    // Gerçek alışkanlık listesine erişmek için: .habits getter'ı kullanıldı (Hata Çözümü!)
    final habits = habitNotifier.habits;
    // Seçili tarihi izle
    final selectedDate = habitNotifier.selectedDate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alışkanlık Takibi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  // HabitSummaryPage artık Riverpod'dan veriyi kendisi okuyacak, notifier'a ihtiyacı yok
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
          // Tarih Seçici
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: DateSelector(),
          ),

          // Seçili Tarih Başlığı
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              // Seçili günün formatı
              '${selectedDate.day}.${selectedDate.month}.${selectedDate.year} Alışkanlıkları',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),

          // Alışkanlık Listesi
          Expanded(
            // Hata Çözümü: habitNotifier.habits.isEmpty yerine habits.isEmpty kullanıldı
            child: habits.isEmpty
                ? const Center(
                    child: Text('Henüz eklenmiş bir alışkanlığınız yok.'),
                  )
                : ListView.builder(
                    itemCount:
                        habits.length, // Hata Çözümü: habits.length kullanıldı
                    itemBuilder: (context, index) {
                      return HabitCard(
                        habit: habits[index],
                      ); // Hata Çözümü: habits[index] kullanıldı
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showAddHabitModal(context, ref), // ref'i fonksiyona geçiriyoruz
        child: const Icon(Icons.add),
      ),
    );
  }
}
