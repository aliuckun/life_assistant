// lib/features/money_tracking/presentation/widgets/transaction_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// 🚨 MoneyTransaction sınıfı MoneyTransaction Entity'sini import ediyoruz
import '../../domain/entities/transaction.dart';

class TransactionCard extends StatelessWidget {
  final MoneyTransaction transaction; // MoneyTransaction olarak değiştirildi
  final Function(String) onDelete;
  final Function(MoneyTransaction) onEdit;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // 🚨 Hata Çözümü: isExpense artık TransactionType üzerinden kontrol ediliyor
    final isExpense = transaction.type == TransactionType.expense;
    final finalAmountColor = isExpense ? Colors.redAccent : Colors.greenAccent;
    final sign = isExpense ? '-' : '+';
    final formattedDate = DateFormat('dd MMM yyyy').format(transaction.date);

    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExpense ? Colors.red[900] : Colors.green[900],
          child: Icon(
            isExpense ? Icons.arrow_downward : Icons.arrow_upward,
            color: Colors.white,
          ),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          '${transaction.category} - $formattedDate',
          style: TextStyle(color: Colors.grey[400]),
        ),
        trailing: Text(
          '$sign${transaction.amount.toStringAsFixed(2)} ₺',
          style: TextStyle(
            color: finalAmountColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: () => onEdit(transaction),
      ),
    );
  }
}
