// lib/features/money_tracking/domain/entities/transaction.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'transaction.g.dart'; // 🔥 Code generation için

// Gelir/Gider tipini tanımlar
@HiveType(typeId: 6)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

// 💰 Para İşlemi Entity'si
@HiveType(typeId: 7)
class MoneyTransaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final TransactionType type;

  MoneyTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
  });

  // copyWith metodu
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

// 🔄 Tekrar Eden Ödeme Entity'si
@HiveType(typeId: 8)
class RecurringPayment extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final int paymentDayOfMonth;

  RecurringPayment({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.paymentDayOfMonth,
  });

  // copyWith metodu
  RecurringPayment copyWith({
    String? id,
    String? description,
    double? amount,
    String? category,
    int? paymentDayOfMonth,
  }) {
    return RecurringPayment(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentDayOfMonth: paymentDayOfMonth ?? this.paymentDayOfMonth,
    );
  }
}
