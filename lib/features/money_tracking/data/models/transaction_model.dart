// lib/features/money_tracking/data/models/transaction_model.dart
// 🚨 Firebase ve Timestamp bağımlılığı KALDIRILDI
import '../../domain/entities/transaction.dart'; // MoneyTransaction'ı içeriyor

// MoneyTransaction sınıfından miras alıyor
class TransactionModel extends MoneyTransaction {
  // 🔥 const kaldırıldı - HiveObject const olamaz
  TransactionModel({
    required super.id,
    required super.description,
    required super.amount,
    required super.date,
    required super.category,
    required super.type,
  });

  // 🔥 Map'e Çevirme: Tarihi milisaniye olarak kaydet
  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'category': category,
      'type': type.name,
    };
  }

  // Map'ten Oluşturma: Milisaniyeyi geri DateTime'a çevir
  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    // Tarih, milisaniye cinsinden int veya num olarak gelebilir
    final dateValue = map['date'];

    DateTime date;
    if (dateValue is int) {
      date = DateTime.fromMillisecondsSinceEpoch(dateValue);
    } else {
      date = DateTime.now(); // Varsayılan değer
    }

    return TransactionModel(
      id: id,
      description: map['description'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: date,
      category: map['category'] ?? 'Diğer',
      type: (map['type'] == 'income')
          ? TransactionType.income
          : TransactionType.expense,
    );
  }
}
