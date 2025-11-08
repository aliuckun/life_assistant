// lib/features/money_tracking/presentation/widgets/add_recurring_payment_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction.dart';
import '../state/money_tracker_notifier.dart';

// Kategoriler
const List<String> _expenseCategories = [
  'Gıda',
  'Fatura',
  'Eğitim',
  'Eğlence',
  'Ulaşım',
  'Diğer',
];

class AddRecurringPaymentModal extends ConsumerStatefulWidget {
  const AddRecurringPaymentModal({super.key});

  @override
  ConsumerState<AddRecurringPaymentModal> createState() =>
      _AddRecurringPaymentModalState();
}

class _AddRecurringPaymentModalState
    extends ConsumerState<AddRecurringPaymentModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = _expenseCategories.first;
  int _paymentDay = 1; // Ayın 1. günü varsayılan

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final newPayment = RecurringPayment(
        id: '',
        description: _descriptionController.text,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        category: _category,
        paymentDayOfMonth: _paymentDay,
      );

      ref
          .read(moneyTrackerNotifierProvider.notifier)
          .addRecurringPayment(newPayment);
      Navigator.pop(context); // Modalı kapat
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Yeni Otomatik Ödeme (Fatura) Tanımla',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 20),

              // Miktar
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Miktar (₺)',
                  prefixIcon: Icon(Icons.monetization_on),
                ),
                validator: (value) =>
                    (value == null ||
                        double.tryParse(value) == null ||
                        double.parse(value) <= 0)
                    ? 'Geçerli bir miktar girin'
                    : null,
              ),
              const SizedBox(height: 15),

              // Açıklama
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Fatura Adı/Açıklaması',
                  prefixIcon: Icon(Icons.receipt_long),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Açıklama gerekli'
                    : null,
              ),
              const SizedBox(height: 15),

              // Kategori Seçimi
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category),
                ),
                dropdownColor: Colors.grey[800],
                items: _expenseCategories.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _category = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 15),

              // Ödeme Günü Seçimi
              DropdownButtonFormField<int>(
                value: _paymentDay,
                decoration: const InputDecoration(
                  labelText: 'Ayın Ödeme Günü',
                  prefixIcon: Icon(Icons.calendar_month),
                ),
                dropdownColor: Colors.grey[800],
                items: List.generate(28, (index) => index + 1).map((day) {
                  // 28 ile sınırlandırdık
                  return DropdownMenuItem<int>(
                    value: day,
                    child: Text(
                      '$day. Gün',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _paymentDay = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 25),

              // Kaydet Butonu
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.save),
                label: const Text('Faturayı Tanımla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
