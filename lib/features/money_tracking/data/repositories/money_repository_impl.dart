// lib/features/money_tracking/data/repositories/money_repository_impl.dart
import 'package:flutter/material.dart'; // debugPrint için gerekli
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/money_repository.dart';
import '../models/transaction_model.dart'; // Kullanılmayacak ama modeli tutuyoruz
// 🚨 Firebase bağımlılıkları kaldırıldı. main.dart'tan sadece appId alınacak
import '../../../../main.dart' show appId;

// 🚨 LOKAL VERİ KAYNAĞI (Simüle Edilmiş Veritabanı)
List<MoneyTransaction> _localTransactions = [];

class MoneyRepositoryImpl implements MoneyRepository {
  // 🚨 Lokal çalışacağı için Firebase değişkenleri kaldırıldı.
  final String _userId = 'local_user'; // Artık sabit bir ID kullanıyoruz

  // ------------------------------------------------------------------------
  // 💰 LAZY LOADING / INFINITE SCROLL İşlemi (Lokal Pagination)
  // ------------------------------------------------------------------------
  @override
  Future<List<MoneyTransaction>> getTransactions({
    required int limit,
    required int offset,
  }) async {
    // Lokal veriyi tarihe göre tersten sırala (en yeniler en başta)
    final sortedList = _localTransactions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Belirtilen offset ve limitle veriyi parçala
    int start = offset;
    int end = (offset + limit);
    if (start >= sortedList.length) {
      return []; // Daha fazla veri yok
    }
    if (end > sortedList.length) {
      end = sortedList.length;
    }

    // Gecikmeyi simüle et (yüklenme ekranını görmek için)
    await Future.delayed(const Duration(milliseconds: 500));

    return sortedList.sublist(start, end);
  }

  // ------------------------------------------------------------------------
  // 💸 HARCAMA TOPLAMI (Dönemsel Toplama)
  // ------------------------------------------------------------------------
  @override
  Future<double> getTotalExpenseForPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final filtered = _localTransactions.where((t) {
      final isExpense = t.type == TransactionType.expense;
      final isAfterStart = t.date.isAfter(
        startDate.subtract(const Duration(milliseconds: 1)),
      );
      final isBeforeEnd = t.date.isBefore(
        endDate.add(const Duration(milliseconds: 1)),
      );

      return isExpense && isAfterStart && isBeforeEnd;
    }).toList();

    double total = filtered.fold(0.0, (sum, t) => sum + t.amount);

    await Future.delayed(const Duration(milliseconds: 200));
    return total;
  }

  // ------------------------------------------------------------------------
  // ➕ CRUD ve 🔄 TEKRAR EDEN ÖDEMELER
  // ------------------------------------------------------------------------
  @override
  Future<void> addTransaction(MoneyTransaction transaction) async {
    // Yeni bir ID oluştur ve listeye ekle
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newTransaction = transaction.copyWith(id: newId);
    _localTransactions.add(newTransaction);
    debugPrint('Added local transaction: $newId');
  }

  @override
  Future<void> updateTransaction(MoneyTransaction transaction) async {
    final index = _localTransactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _localTransactions[index] = transaction;
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _localTransactions.removeWhere((t) => t.id == id);
  }

  @override
  Future<List<RecurringPayment>> getRecurringPayments() async {
    // Lokal tutulan bir liste döndürelim
    return const [
      RecurringPayment(
        id: 'R1',
        description: 'Netflix',
        amount: 150.0,
        category: 'Eğlence',
        paymentDayOfMonth: 10,
      ),
      RecurringPayment(
        id: 'R2',
        description: 'Spor Salonu',
        amount: 400.0,
        category: 'Sağlık',
        paymentDayOfMonth: 5,
      ),
    ];
  }

  @override
  Future<void> addRecurringPayment(RecurringPayment payment) async {
    // Şimdilik sadece logluyoruz, ekleme mantığı karmaşıklaşır
    debugPrint('Recurring payment added locally: ${payment.description}');
  }

  @override
  Future<List<MoneyTransaction>> getAllTransactions() async {
    // Local listeyi olduğu gibi döndür
    await Future.delayed(const Duration(milliseconds: 200));
    return _localTransactions.toList();
  }
}
