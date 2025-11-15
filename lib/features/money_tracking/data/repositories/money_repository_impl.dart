// lib/features/money_tracking/data/repositories/money_repository_impl.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/money_repository.dart';

class MoneyRepositoryImpl implements MoneyRepository {
  // 🔥 HIVE BOX İSİMLERİ
  static const String _transactionsBoxName = 'money_transactions';
  static const String _recurringPaymentsBoxName = 'recurring_payments';

  // 🔥 HIVE BOX'LARI
  Box<MoneyTransaction>? _transactionsBox;
  Box<RecurringPayment>? _recurringPaymentsBox;

  // 🔥 SINGLETON PATTERN
  static MoneyRepositoryImpl? _instance;
  static Future<MoneyRepositoryImpl> getInstance() async {
    if (_instance == null) {
      _instance = MoneyRepositoryImpl._internal();
      await _instance!._initBoxes();
    }
    return _instance!;
  }

  // Private constructor
  MoneyRepositoryImpl._internal();

  Future<void> _initBoxes() async {
    _transactionsBox = await Hive.openBox<MoneyTransaction>(
      _transactionsBoxName,
    );
    _recurringPaymentsBox = await Hive.openBox<RecurringPayment>(
      _recurringPaymentsBoxName,
    );
    debugPrint('✅ Money tracking boxes opened successfully');
  }

  // ------------------------------------------------------------------------
  // 💰 LAZY LOADING / INFINITE SCROLL İşlemi
  // ------------------------------------------------------------------------
  @override
  Future<List<MoneyTransaction>> getTransactions({
    required int limit,
    required int offset,
  }) async {
    if (_transactionsBox == null || !_transactionsBox!.isOpen) {
      _transactionsBox = await Hive.openBox<MoneyTransaction>(
        _transactionsBoxName,
      );
    }

    // Lokal veriyi tarihe göre tersten sırala (en yeniler en başta)
    final sortedList = _transactionsBox!.values.toList()
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

    // Gecikmeyi simüle et
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
    if (_transactionsBox == null || !_transactionsBox!.isOpen) {
      _transactionsBox = await Hive.openBox<MoneyTransaction>(
        _transactionsBoxName,
      );
    }

    final filtered = _transactionsBox!.values.where((t) {
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
  // ➕ CRUD İşlemleri - Transactions
  // ------------------------------------------------------------------------
  @override
  Future<void> addTransaction(MoneyTransaction transaction) async {
    if (_transactionsBox == null || !_transactionsBox!.isOpen) {
      _transactionsBox = await Hive.openBox<MoneyTransaction>(
        _transactionsBoxName,
      );
    }

    // Yeni bir ID oluştur
    final newId = 'T${DateTime.now().millisecondsSinceEpoch}';
    final newTransaction = transaction.copyWith(id: newId);

    // 🔥 HIVE'a kaydet
    await _transactionsBox!.put(newId, newTransaction);
    debugPrint('Added transaction: $newId');
  }

  @override
  Future<void> updateTransaction(MoneyTransaction transaction) async {
    if (_transactionsBox == null || !_transactionsBox!.isOpen) {
      _transactionsBox = await Hive.openBox<MoneyTransaction>(
        _transactionsBoxName,
      );
    }

    // 🔥 Mevcut kaydı güncelle
    await _transactionsBox!.put(transaction.id, transaction);
    debugPrint('Updated transaction: ${transaction.id}');
  }

  @override
  Future<void> deleteTransaction(String id) async {
    if (_transactionsBox == null || !_transactionsBox!.isOpen) {
      _transactionsBox = await Hive.openBox<MoneyTransaction>(
        _transactionsBoxName,
      );
    }

    // 🔥 ID ile kaydı sil
    await _transactionsBox!.delete(id);
    debugPrint('Deleted transaction: $id');
  }

  @override
  Future<List<MoneyTransaction>> getAllTransactions() async {
    if (_transactionsBox == null || !_transactionsBox!.isOpen) {
      _transactionsBox = await Hive.openBox<MoneyTransaction>(
        _transactionsBoxName,
      );
    }
    await Future.delayed(const Duration(milliseconds: 200));
    return _transactionsBox!.values.toList();
  }

  // ------------------------------------------------------------------------
  // 🔄 TEKRAR EDEN ÖDEMELER
  // ------------------------------------------------------------------------
  @override
  Future<List<RecurringPayment>> getRecurringPayments() async {
    if (_recurringPaymentsBox == null || !_recurringPaymentsBox!.isOpen) {
      _recurringPaymentsBox = await Hive.openBox<RecurringPayment>(
        _recurringPaymentsBoxName,
      );
    }
    await Future.delayed(const Duration(milliseconds: 200));
    return _recurringPaymentsBox!.values.toList();
  }

  @override
  Future<void> addRecurringPayment(RecurringPayment payment) async {
    if (_recurringPaymentsBox == null || !_recurringPaymentsBox!.isOpen) {
      _recurringPaymentsBox = await Hive.openBox<RecurringPayment>(
        _recurringPaymentsBoxName,
      );
    }

    // Yeni ID oluştur
    final newId = 'R${DateTime.now().millisecondsSinceEpoch}';
    final newPayment = payment.copyWith(id: newId);

    // 🔥 HIVE'a kaydet
    await _recurringPaymentsBox!.put(newId, newPayment);
    debugPrint('Recurring payment added: $newId');
  }

  @override
  Future<void> updateRecurringPayment(RecurringPayment payment) async {
    if (_recurringPaymentsBox == null || !_recurringPaymentsBox!.isOpen) {
      _recurringPaymentsBox = await Hive.openBox<RecurringPayment>(
        _recurringPaymentsBoxName,
      );
    }

    // 🔥 Mevcut kaydı güncelle
    await _recurringPaymentsBox!.put(payment.id, payment);
    debugPrint('Recurring payment updated: ${payment.id}');
  }

  @override
  Future<void> deleteRecurringPayment(String id) async {
    if (_recurringPaymentsBox == null || !_recurringPaymentsBox!.isOpen) {
      _recurringPaymentsBox = await Hive.openBox<RecurringPayment>(
        _recurringPaymentsBoxName,
      );
    }

    // 🔥 ID ile kaydı sil
    await _recurringPaymentsBox!.delete(id);
    debugPrint('Recurring payment deleted: $id');
  }
}
