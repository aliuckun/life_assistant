// lib/features/fitness_tracker/presentation/widgets/add_food_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/fitness_entities.dart';
import '../state/fitness_notifier.dart';

class AddFoodModal extends ConsumerStatefulWidget {
  const AddFoodModal({super.key});

  @override
  ConsumerState<AddFoodModal> createState() => _AddFoodModalState();
}

class _AddFoodModalState extends ConsumerState<AddFoodModal> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _caloriesController = TextEditingController();
  MealType _mealType = MealType.sabah;

  // Notifier'daki seçili tarihi kullan
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = ref.read(fitnessNotifierProvider).selectedDate;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final now = DateTime.now();

      // Kaydı seçili tarihle ve şu anki saatle birleştir
      final entryDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        now.hour,
        now.minute,
        now.second,
      );

      final newEntry = FoodEntry(
        id: '',
        date: entryDate,
        mealType: _mealType,
        description: _descriptionController.text,
        calories: int.tryParse(_caloriesController.text) ?? 0,
      );

      ref.read(fitnessNotifierProvider.notifier).addFoodEntry(newEntry);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        20,
        16,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Yeni Yemek Kaydı',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Öğün Tipi (ComboBox)
            DropdownButtonFormField<MealType>(
              value: _mealType,
              decoration: const InputDecoration(
                labelText: 'Öğün Zamanı',
                prefixIcon: Icon(Icons.access_time),
              ),
              dropdownColor: Colors.grey[800],
              items: MealType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    _getMealLabel(type),
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (type) {
                if (type != null) setState(() => _mealType = type);
              },
            ),
            const SizedBox(height: 15),

            // Açıklama
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Ne yedin? (örn: Tavuklu Salata)',
                prefixIcon: Icon(Icons.restaurant),
              ),
              validator: (v) => v!.isEmpty ? 'Gerekli alan' : null,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 15),

            // Kalori
            TextFormField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kalori (Kcal)',
                prefixIcon: Icon(Icons.local_fire_department),
              ),
              validator: (v) =>
                  (v == null || int.tryParse(v) == null || int.parse(v) <= 0)
                  ? 'Geçerli kalori girin'
                  : null,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: _submitForm,
              icon: const Icon(Icons.save),
              label: const Text('Yemek Kaydını Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
}
