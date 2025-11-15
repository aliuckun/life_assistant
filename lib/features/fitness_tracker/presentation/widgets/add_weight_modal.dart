// lib/features/fitness_tracker/presentation/widgets/add_weight_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../state/fitness_notifier.dart';

class AddWeightModal extends ConsumerStatefulWidget {
  const AddWeightModal({super.key});

  @override
  ConsumerState<AddWeightModal> createState() => _AddWeightModalState();
}

class _AddWeightModalState extends ConsumerState<AddWeightModal> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final weight = double.tryParse(_weightController.text) ?? 0.0;

      // Notifier'a kilo kaydını gönder
      ref.read(fitnessNotifierProvider.notifier).addWeightEntry(weight);

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
              'Haftalık Kilo Kaydı',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Kilo Girişi
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kilo (kg)',
                prefixIcon: Icon(Icons.monitor_weight),
              ),
              validator: (v) =>
                  (v == null ||
                      double.tryParse(v) == null ||
                      double.parse(v) <= 0)
                  ? 'Geçerli bir kilo girin'
                  : null,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 15),

            // Not: Kilo kaydı her hafta aynı gün yapılmalıdır, ancak şu an gün sınırlaması yok.
            Text(
              'Kayıt Tarihi: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}',
              style: TextStyle(color: Colors.grey[400]),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: _submitForm,
              icon: const Icon(Icons.save),
              label: const Text('Kilo Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
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
