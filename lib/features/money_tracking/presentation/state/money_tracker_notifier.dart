// lib/features/money_tracking/presentation/state/money_tracker_notifier.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/money_repository.dart';
import '../../domain/entities/transaction.dart';
import '../../data/repositories/money_repository_impl.dart';

// 1. Kategori Özet Sınıfı (Pasta Grafik Verisi)
@immutable
class CategorySummary {
  final String category;
  final double percentage;
  final double amount;

  const CategorySummary({
    required this.category,
    required this.percentage,
    required this.amount,
  });
}

// 2. ANA STATE SINIFI
@immutable
class MoneyTrackerState {
  final List<MoneyTransaction> transactions;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final bool hasMore;
  final int offset;
  final double totalExpense;
  final int resetDay;
  final List<CategorySummary> expenseSummary;
  final List<RecurringPayment> recurringPayments;
  final bool isRecurringCheckDone;

  const MoneyTrackerState({
    required this.transactions,
    required this.isLoadingInitial,
    required this.isLoadingMore,
    required this.hasMore,
    required this.offset,
    required this.totalExpense,
    required this.resetDay,
    required this.expenseSummary,
    required this.recurringPayments,
    required this.isRecurringCheckDone,
  });

  MoneyTrackerState copyWith({
    List<MoneyTransaction>? transactions,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? hasMore,
    int? offset,
    double? totalExpense,
    int? resetDay,
    List<CategorySummary>? expenseSummary,
    List<RecurringPayment>? recurringPayments,
    bool? isRecurringCheckDone,
  }) {
    return MoneyTrackerState(
      transactions: transactions ?? this.transactions,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      totalExpense: totalExpense ?? this.totalExpense,
      resetDay: resetDay ?? this.resetDay,
      expenseSummary: expenseSummary ?? this.expenseSummary,
      recurringPayments: recurringPayments ?? this.recurringPayments,
      isRecurringCheckDone: isRecurringCheckDone ?? this.isRecurringCheckDone,
    );
  }
}

// Notifier: State'i yöneten ana sınıf
class MoneyTrackerNotifier extends StateNotifier<MoneyTrackerState> {
  final MoneyRepository _repository;
  final int _limit = 5;

  MoneyTrackerNotifier(this._repository)
    : super(
        const MoneyTrackerState(
          transactions: [],
          isLoadingInitial: false,
          isLoadingMore: false,
          hasMore: true,
          offset: 0,
          totalExpense: 0.0,
          resetDay: 1,
          expenseSummary: [],
          recurringPayments: [],
          isRecurringCheckDone: false,
        ),
      ) {
    fetchInitialTransactions();
    fetchTotalExpense();
    fetchExpenseSummary();
    fetchRecurringPayments();
    checkAndApplyRecurringPayments();
  }

  // ------------------------- FATURA TAKİBİ METOTLARI -------------------------

  Future<void> updateRecurringPayment(RecurringPayment payment) async {
    await _repository.updateRecurringPayment(payment);
    await fetchRecurringPayments();
    debugPrint('Recurring payment updated: ${payment.id}');
  }

  Future<void> fetchRecurringPayments() async {
    try {
      final payments = await _repository.getRecurringPayments();
      state = state.copyWith(recurringPayments: payments);
    } catch (e) {
      debugPrint('Error fetching recurring payments: $e');
    }
  }

  Future<void> addRecurringPayment(RecurringPayment payment) async {
    await _repository.addRecurringPayment(payment);
    await fetchRecurringPayments();
  }

  Future<void> deleteRecurringPayment(String id) async {
    await _repository.deleteRecurringPayment(id);
    await fetchRecurringPayments();
  }

  Future<void> checkAndApplyRecurringPayments() async {
    if (state.isRecurringCheckDone) return;

    final payments = await _repository.getRecurringPayments();
    final today = DateTime.now();

    for (var payment in payments) {
      if (payment.paymentDayOfMonth == today.day) {
        final isAlreadyRecorded = state.transactions.any(
          (t) =>
              t.description == payment.description &&
              t.date.month == today.month &&
              t.type == TransactionType.expense,
        );

        if (!isAlreadyRecorded) {
          final automaticTransaction = MoneyTransaction(
            id: '',
            description: payment.description,
            amount: payment.amount,
            date: today,
            category: payment.category,
            type: TransactionType.expense,
          );

          await _repository.addTransaction(automaticTransaction);
          debugPrint('AUTOMATICALLY APPLIED: ${payment.description}');
        }
      }
    }

    state = state.copyWith(isRecurringCheckDone: true);

    await fetchInitialTransactions();
    await fetchTotalExpense();
    await fetchExpenseSummary();
  }

  Future<void> updateTransaction(MoneyTransaction transaction) async {
    await _repository.updateTransaction(transaction);

    state = state.copyWith(offset: 0, hasMore: true);
    await fetchInitialTransactions();
    await fetchTotalExpense();
    await fetchExpenseSummary();
  }

  // ----------------------------- DİĞER METOTLAR -----------------------------

  Future<void> fetchInitialTransactions() async {
    state = state.copyWith(isLoadingInitial: true, hasMore: true, offset: 0);
    try {
      final newTransactions = await _repository.getTransactions(
        limit: _limit,
        offset: 0,
      );
      state = state.copyWith(
        transactions: newTransactions,
        isLoadingInitial: false,
        offset: newTransactions.length,
        hasMore: newTransactions.length == _limit,
      );
    } catch (e) {
      debugPrint('Error fetching initial transactions: $e');
      state = state.copyWith(isLoadingInitial: false);
    }
  }

  Future<void> fetchNextTransactions() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final newTransactions = await _repository.getTransactions(
        limit: _limit,
        offset: state.offset,
      );

      state = state.copyWith(
        transactions: [...state.transactions, ...newTransactions],
        isLoadingMore: false,
        offset: state.offset + newTransactions.length,
        hasMore: newTransactions.length == _limit,
      );
    } catch (e) {
      debugPrint('Error fetching next transactions: $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> fetchTotalExpense() async {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    if (now.day >= state.resetDay) {
      startDate = DateTime(now.year, now.month, state.resetDay);
      endDate = DateTime(
        now.year,
        now.month + 1,
        state.resetDay,
      ).subtract(const Duration(days: 1));
    } else {
      startDate = DateTime(now.year, now.month - 1, state.resetDay);
      endDate = DateTime(
        now.year,
        now.month,
        state.resetDay,
      ).subtract(const Duration(days: 1));
    }

    try {
      final total = await _repository.getTotalExpenseForPeriod(
        startDate: startDate,
        endDate: endDate,
      );
      state = state.copyWith(totalExpense: total);
    } catch (e) {
      debugPrint('Error fetching total expense: $e');
    }
  }

  Future<void> setResetDay(int day) async {
    if (day < 1 || day > 31) return;

    state = state.copyWith(resetDay: day);
    await fetchTotalExpense();
    debugPrint('Reset day set to $day');
  }

  Future<void> fetchExpenseSummary() async {
    final allTransactions = await _repository.getAllTransactions();

    final expenses = allTransactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    final Map<String, double> categoryTotals = {};
    double grandTotal = 0;

    for (var t in expenses) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
      grandTotal += t.amount;
    }

    if (grandTotal == 0) {
      state = state.copyWith(expenseSummary: []);
      return;
    }

    final List<CategorySummary> summary = [];
    categoryTotals.forEach((category, amount) {
      final percentage = (amount / grandTotal);
      summary.add(
        CategorySummary(
          category: category,
          amount: amount,
          percentage: percentage,
        ),
      );
    });

    state = state.copyWith(expenseSummary: summary);
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);
    state = state.copyWith(offset: 0, hasMore: true);
    await fetchInitialTransactions();
    await fetchTotalExpense();
    await fetchExpenseSummary();
  }

  Future<void> addTransaction(MoneyTransaction transaction) async {
    await _repository.addTransaction(transaction);
    state = state.copyWith(offset: 0, hasMore: true);
    await fetchInitialTransactions();
    await fetchTotalExpense();
    await fetchExpenseSummary();
  }
}

// 🔥 Repository Provider
final moneyRepositoryProvider = FutureProvider<MoneyRepository>((ref) async {
  return await MoneyRepositoryImpl.getInstance();
});

// 🔥 Notifier Provider - Repository hazır olana kadar bekle
final moneyTrackerNotifierProvider =
    StateNotifierProvider<MoneyTrackerNotifier, MoneyTrackerState>((ref) {
      final repoAsync = ref.watch(moneyRepositoryProvider);
      return repoAsync.when(
        data: (repo) => MoneyTrackerNotifier(repo),
        loading: () => MoneyTrackerNotifier(_DummyMoneyRepository()),
        error: (_, __) => MoneyTrackerNotifier(_DummyMoneyRepository()),
      );
    });

// 🔥 Dummy Repository (Loading durumu için)
class _DummyMoneyRepository implements MoneyRepository {
  @override
  Future<void> addRecurringPayment(RecurringPayment payment) async {}

  @override
  Future<void> addTransaction(MoneyTransaction transaction) async {}

  @override
  Future<void> deleteRecurringPayment(String id) async {}

  @override
  Future<void> deleteTransaction(String id) async {}

  @override
  Future<List<MoneyTransaction>> getAllTransactions() async => [];

  @override
  Future<List<RecurringPayment>> getRecurringPayments() async => [];

  @override
  Future<double> getTotalExpenseForPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async => 0.0;

  @override
  Future<List<MoneyTransaction>> getTransactions({
    required int limit,
    required int offset,
  }) async => [];

  @override
  Future<void> updateRecurringPayment(RecurringPayment payment) async {}

  @override
  Future<void> updateTransaction(MoneyTransaction transaction) async {}
}
