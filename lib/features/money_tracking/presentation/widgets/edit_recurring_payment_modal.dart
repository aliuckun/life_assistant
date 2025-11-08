// lib/features/money_tracking/presentation/widgets/edit_recurring_payment_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction.dart';
import '../state/money_tracker_notifier.dart';

const List<String> _expenseCategories = [
  'Gıda',
  'Fatura',
  'Eğitim',
  'Eğlence',
  'Ulaşım',
  'Diğer',
];

class EditRecurringPaymentModal extends ConsumerStatefulWidget {
  final RecurringPayment payment;

  const EditRecurringPaymentModal({super.key, required this.payment});

  @override
  ConsumerState<EditRecurringPaymentModal> createState() =>
      _EditRecurringPaymentModalState();
}

class _EditRecurringPaymentModalState
    extends ConsumerState<EditRecurringPaymentModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  late String _category;
  late int _paymentDay;

  @override
  void initState() {
    super.initState();
    // Mevcut verilerle başlat
    _amountController = TextEditingController(
      text: widget.payment.amount.toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(
      text: widget.payment.description,
    );
    _category = widget.payment.category;
    _paymentDay = widget.payment.paymentDayOfMonth;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedPayment = RecurringPayment(
        id: widget.payment.id,
        description: _descriptionController.text,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        category: _category,
        paymentDayOfMonth: _paymentDay,
      );

      // 🚨 Güncelleme işlemi
      ref
          .read(moneyTrackerNotifierProvider.notifier)
          .updateRecurringPayment(updatedPayment);
      Navigator.pop(context);
    }
  }

  // Faturayı silme
  void _deletePayment() async {
    final confirmed = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Silme Onayı'),
        content: Text(
          '${widget.payment.description} faturasını silmek istediğinizden emin misiniz?',
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

    if (confirmed == true) {
      // 🚨 Silme işlemi
      ref
          .read(moneyTrackerNotifierProvider.notifier)
          .deleteRecurringPayment(widget.payment.id);
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Faturayı Düzenle',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_forever,
                      color: Colors.redAccent,
                    ),
                    onPressed: _deletePayment,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ... (Form alanları AddRecurringPaymentModal ile aynı, değerleri initstate'den alır)

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
                label: const Text('Değişiklikleri Kaydet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
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
