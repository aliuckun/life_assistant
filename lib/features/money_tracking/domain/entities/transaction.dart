// lib/features/money_tracking/domain/entities/transaction.dart
import 'package:flutter/foundation.dart';

// Gelir/Gider tipini tanımlar
enum TransactionType { income, expense }

// 🚨 Entity sınıfının adı 'Transaction' yerine 'MoneyTransaction' olarak değiştirildi
@immutable
class MoneyTransaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final TransactionType type;

  const MoneyTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
  });

  // Gerekli copyWith metodu
  MoneyTransaction copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    String? category,
    TransactionType? type,
  }) {
    return MoneyTransaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      type: type ?? this.type,
    );
  }
}

// Tekrar Eden Ödeme Entity'si
@immutable
class RecurringPayment {
  final String id;
  final String description;
  final double amount;
  final String category;
  final int paymentDayOfMonth;

  const RecurringPayment({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.paymentDayOfMonth,
  });
}
