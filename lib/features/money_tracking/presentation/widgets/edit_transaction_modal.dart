// lib/features/money_tracking/presentation/widgets/edit_transaction_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/transaction.dart';
import '../state/money_tracker_notifier.dart';

// Mevcut Kategori ve Tipler
const List<String> _categories = [
  'Gıda',
  'Fatura',
  'Eğitim',
  'Eğlence',
  'Ulaşım',
  'Maaş',
  'Diğer',
];

class EditTransactionModal extends ConsumerStatefulWidget {
  final MoneyTransaction transaction;

  const EditTransactionModal({super.key, required this.transaction});

  @override
  ConsumerState<EditTransactionModal> createState() =>
      _EditTransactionModalState();
}

class _EditTransactionModalState extends ConsumerState<EditTransactionModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  late TransactionType _type;
  late String _category;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    // 🚨 Düzenlenecek verilerle state'i başlat
    _amountController = TextEditingController(
      text: widget.transaction.amount.toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(
      text: widget.transaction.description,
    );
    _type = widget.transaction.type;
    _category = widget.transaction.category;
    _date = widget.transaction.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedTransaction = widget.transaction.copyWith(
        description: _descriptionController.text,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        date: _date,
        category: _category,
        type: _type,
      );

      // 🚨 Notifier'ı update metodu ile güncelle
      ref
          .read(moneyTrackerNotifierProvider.notifier)
          .updateTransaction(updatedTransaction);
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
                'İşlemi Düzenle (${widget.transaction.id})',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 20),

              // Gelir / Gider Seçimi
              Row(
                children: TransactionType.values.map((type) {
                  final isSelected = _type == type;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _type = type;
                            // Kategori mantığı
                            if (type == TransactionType.income &&
                                !_categories.contains(_category)) {
                              _category = 'Maaş';
                            }
                            if (type == TransactionType.expense &&
                                _category == 'Maaş') {
                              _category = 'Gıda';
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? (_type == TransactionType.income
                                    ? Colors.green[700]
                                    : Colors.red[700])
                              : Colors.grey[700],
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          type == TransactionType.income ? 'Gelir' : 'Gider',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 15),

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
                  labelText: 'Açıklama',
                  prefixIcon: Icon(Icons.description),
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
                items: _categories.map((String value) {
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

              // Tarih Seçimi
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tarih',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_date),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _selectDate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text('Tarih Seç'),
                  ),
                ],
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
