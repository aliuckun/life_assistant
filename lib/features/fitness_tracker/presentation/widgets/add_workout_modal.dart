// lib/features/fitness_tracker/presentation/widgets/add_workout_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/fitness_entities.dart';
import '../state/fitness_notifier.dart';

// Yaratıcılık alanı: Spor kaydı modu
class AddWorkoutModal extends ConsumerStatefulWidget {
  const AddWorkoutModal({super.key});

  @override
  ConsumerState<AddWorkoutModal> createState() => _AddWorkoutModalState();
}

class _AddWorkoutModalState extends ConsumerState<AddWorkoutModal> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseController = TextEditingController();
  final _weightController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  String _region = 'Göğüs';

  final List<String> _regions = [
    'Göğüs',
    'Sırt',
    'Bacak',
    'Omuz',
    'Kol',
    'Karın',
    'Kardiyo',
  ];

  @override
  void dispose() {
    _exerciseController.dispose();
    _weightController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final newEntry = WorkoutEntry(
        id: '',
        date: ref.read(fitnessNotifierProvider).selectedDate,
        region: _region,
        exercise: _exerciseController.text,
        sets: int.tryParse(_setsController.text) ?? 0,
        reps: int.tryParse(_repsController.text) ?? 0,
        weight: double.tryParse(_weightController.text) ?? 0.0,
      );

      ref.read(fitnessNotifierProvider.notifier).addWorkoutEntry(newEntry);
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
              'Yeni Egzersiz Kaydı',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Bölge Seçimi
            DropdownButtonFormField<String>(
              value: _region,
              decoration: const InputDecoration(
                labelText: 'Antrenman Bölgesi',
                prefixIcon: Icon(Icons.directions_run),
              ),
              dropdownColor: Colors.grey[800],
              items: _regions
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(
                        r,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (r) {
                if (r != null) setState(() => _region = r);
              },
            ),
            const SizedBox(height: 15),

            // Hareket Adı
            TextFormField(
              controller: _exerciseController,
              decoration: const InputDecoration(
                labelText: 'Hareket Adı (örn: Bench Press)',
                prefixIcon: Icon(Icons.straighten),
              ),
              validator: (v) => v!.isEmpty ? 'Gerekli alan' : null,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 15),

            // Setler ve Tekrarlar
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _setsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Set Sayısı'),
                    style: const TextStyle(color: Colors.white),
                    validator: (v) =>
                        (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Set' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tekrar Sayısı',
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (v) =>
                        (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Tekrar' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Kaldırılan Ağırlık
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kaldırılan Ağırlık (kg)',
                prefixIcon: Icon(Icons.scale),
              ),
              validator: (v) =>
                  (double.tryParse(v ?? '') ?? 0.0) < 0 ? 'Geçerli kilo' : null,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: _submitForm,
              icon: const Icon(Icons.save),
              label: const Text('Egzersizi Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
