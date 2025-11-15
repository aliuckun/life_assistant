// lib/features/fitness_tracker/presentation/widgets/food_entry_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/fitness_entities.dart';

class FoodEntryCard extends StatelessWidget {
  final FoodEntry entry;
  final Function(String) onDelete;
  final Function(FoodEntry) onEdit;

  const FoodEntryCard({
    super.key,
    required this.entry,
    required this.onDelete,
    required this.onEdit,
  });

  String _getMealLabel(MealType type) {
    switch (type) {
      case MealType.sabah:
        return 'Sabah';
      case MealType.ogle:
        return 'Öğle';
      case MealType.aksam:
        return 'Akşam';
      case MealType.ekstra:
        return 'Ekstra';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade700,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Silme Onayı'),
            content: Text(
              '${entry.description} kaydını silmek istediğinizden emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sil', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => onDelete(entry.id),
      child: Card(
        color: Colors.grey[850],
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade700,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _getMealLabel(entry.mealType),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            entry.description,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            DateFormat('HH:mm').format(entry.date),
            style: TextStyle(color: Colors.grey[400]),
          ),
          trailing: Text(
            '${entry.calories} Kcal',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          onTap: () => onEdit(entry),
        ),
      ),
    );
  }
}
