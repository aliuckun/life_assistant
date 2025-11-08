// lib/features/money_tracking/domain/repositories/money_repository.dart
import '../entities/transaction.dart'; // MoneyTransaction'ı içerir

abstract class MoneyRepository {
  // 🚨 MoneyTransaction sınıf adı kullanıldı
  Future<List<MoneyTransaction>> getTransactions({
    required int limit,
    required int offset,
  });

  Future<double> getTotalExpenseForPeriod({
    required DateTime startDate,
    required DateTime endDate,
  });

  // CRUD işlemleri
  Future<void> addTransaction(MoneyTransaction transaction);
  Future<void> deleteTransaction(String id);
  Future<void> updateTransaction(MoneyTransaction transaction);

  // Otomatik Ödemeler
  Future<List<RecurringPayment>> getRecurringPayments();
  Future<void> addRecurringPayment(RecurringPayment payment);
  // 🚨 Yeni metod tanımı
  Future<void> deleteRecurringPayment(String id);
  // 🚨 İleride düzenleme için:
  Future<void> updateRecurringPayment(RecurringPayment payment);

  Future<List<MoneyTransaction>> getAllTransactions();
}
