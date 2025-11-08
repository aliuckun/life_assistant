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
  final double percentage; // Yüzde kaç harcandı
  final double amount; // Toplam miktar

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
  // 🚨 Hata Çözümü: Bu alanlar MoneyTrackerState'e aittir
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
    // 🚨 Yeni Alanlar
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
    // 🚨 Yeni Alanlar copyWith içinde
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
      // 🚨 Değer Atamaları
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
          // 🚨 Başlangıç Değerleri
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

  // 🚨 Yeni Metot: Fatura Düzenleme
  Future<void> updateRecurringPayment(RecurringPayment payment) async {
    await _repository.updateRecurringPayment(payment);
    await fetchRecurringPayments(); // Listeyi güncelle
    debugPrint('Recurring payment updated: ${payment.id}');
  }

  // Fatura Listesini Çekme (Güncel hali)
  Future<void> fetchRecurringPayments() async {
    try {
      final payments = await _repository.getRecurringPayments();
      state = state.copyWith(recurringPayments: payments);
    } catch (e) {
      debugPrint('Error fetching recurring payments: $e');
    }
  }

  // 🚨 Yeni Fatura Tanımlama (DÜZELTİLDİ: Listeyi yeniden çekiyor)
  Future<void> addRecurringPayment(RecurringPayment payment) async {
    await _repository.addRecurringPayment(payment);
    await fetchRecurringPayments(); // ⭐️ Çözüm: Yeni faturayı UI'a yansıtmak için listeyi yeniden çek
  }

  // 🚨 Fatura Silme Metodu (EKLEME)
  Future<void> deleteRecurringPayment(String id) async {
    await _repository.deleteRecurringPayment(id);
    // Silme işleminden sonra listeyi yeniden çek
    await fetchRecurringPayments();
  }

  // Otomatik Fatura Kaydı Kontrolü (Simülasyon)
  Future<void> checkAndApplyRecurringPayments() async {
    // 🚨 State'deki doğru alandan okuma yapıldı
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

    // 🚨 State'deki doğru alana atama yapıldı
    state = state.copyWith(isRecurringCheckDone: true);

    await fetchInitialTransactions();
    await fetchTotalExpense();
    await fetchExpenseSummary();
  }

  // 🚨 fatura güncelleme
  Future<void> updateTransaction(MoneyTransaction transaction) async {
    await _repository.updateTransaction(transaction);

    // Güncelleme yapıldıktan sonra listeyi, toplamı ve özeti yeniden çek
    // Liste güncellendiğinde kaydırma pozisyonu değişmesin diye listeyi tamamen sıfırlamıyoruz.
    // Ancak basitlik ve tutarlılık için ilk sayfayı yeniden çekelim:
    state = state.copyWith(offset: 0, hasMore: true);
    await fetchInitialTransactions();
    await fetchTotalExpense();
    await fetchExpenseSummary();
  }
  // ----------------------------- DİĞER METOTLAR -----------------------------

  // Yeni İşlemleri İlk Kez Çekme Metodu
  Future<void> fetchInitialTransactions() async {
    // ... (metot içeriği aynı)
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

  // Sonraki İşlemleri Çekme Metodu (Lazy Loading)
  Future<void> fetchNextTransactions() async {
    // ... (metot içeriği aynı)
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

  // Toplam Harcamayı Hesaplama Metodu
  Future<void> fetchTotalExpense() async {
    // ... (metot içeriği aynı)
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

  // Sıfırlama Gününü Ayarlar
  Future<void> setResetDay(int day) async {
    if (day < 1 || day > 31) return;

    state = state.copyWith(resetDay: day);
    await fetchTotalExpense();
    debugPrint('Reset day set to $day');
  }

  // Harcama Özetini Çekme (Pasta Grafik)
  Future<void> fetchExpenseSummary() async {
    // ... (metot içeriği aynı)
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

  // CRUD metotları
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

// Notifier Provider'ı
final moneyTrackerNotifierProvider =
    StateNotifierProvider<MoneyTrackerNotifier, MoneyTrackerState>((ref) {
      return MoneyTrackerNotifier(MoneyRepositoryImpl());
    });
