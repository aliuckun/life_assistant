// lib/features/money_tracking/presentation/widgets/recurring_payment_card.dart
import 'package:flutter/material.dart';
import '../../domain/entities/transaction.dart';

class RecurringPaymentCard extends StatelessWidget {
  final RecurringPayment payment;
  final VoidCallback onTap;

  const RecurringPaymentCard({
    super.key,
    required this.payment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.indigo, width: 0.5),
      ),
      child: ListTile(
        leading: const Icon(Icons.receipt, color: Colors.indigoAccent),
        title: Text(
          '${payment.description} - ${payment.amount.toStringAsFixed(0)} ₺',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Ödeme Günü: Ayın ${payment.paymentDayOfMonth}. Günü',
          style: TextStyle(color: Colors.grey[400]),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap, // İleride düzenleme modalı açılabilir
      ),
    );
  }
}
