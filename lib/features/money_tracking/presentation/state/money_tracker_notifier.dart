// lib/features/money_tracking/presentation/state/money_tracker_notifier.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/money_repository.dart';
import '../../domain/entities/transaction.dart';
import '../../data/repositories/money_repository_impl.dart';

// 🚨 Hata Çözümü: MoneyTrackerState sınıfı tanımı eklendi
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

class MoneyTrackerState {
  final List<MoneyTransaction> transactions;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final bool hasMore;
  final int offset;
  final double totalExpense;
  final int resetDay;
  final List<CategorySummary> expenseSummary; // 🚨 Eklendi

  const MoneyTrackerState({
    required this.transactions,
    required this.isLoadingInitial,
    required this.isLoadingMore,
    required this.hasMore,
    required this.offset,
    required this.totalExpense,
    required this.resetDay,
    required this.expenseSummary,
  });

  MoneyTrackerState copyWith({
    List<MoneyTransaction>? transactions,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? hasMore,
    int? offset,
    double? totalExpense,
    int? resetDay,
    List<CategorySummary>? expenseSummary, // 🚨 Eklendi
  }) {
    return MoneyTrackerState(
      transactions: transactions ?? this.transactions,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      totalExpense: totalExpense ?? this.totalExpense,
      resetDay: resetDay ?? this.resetDay,
      expenseSummary: expenseSummary ?? this.expenseSummary, // 🚨 Eklendi
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
          expenseSummary: [], // 🚨 Başlangıç değeri
        ),
      ) {
    // 🚨 Hata Çözümü: Metot adları düzeltildi
    fetchInitialTransactions(); // Lazy loading listesi
    fetchTotalExpense(); // Toplam harcama kartı
    fetchExpenseSummary(); // PASTA GRAFİĞİ ÖZETİ
  }

  // Yeni İşlemleri İlk Kez Çekme Metodu
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

  // 🚨 Yeni Metot: Sıfırlama Gününü Ayarlar
  Future<void> setResetDay(int day) async {
    if (day < 1 || day > 31) return; // Geçersiz gün

    state = state.copyWith(resetDay: day);
    // Yeni güne göre toplam harcamayı yeniden hesapla
    await fetchTotalExpense();
    debugPrint('Reset day set to $day');
  }

  // Sonraki İşlemleri Çekme Metodu (Lazy Loading)
  Future<void> fetchNextTransactions() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final newTransactions = await _repository.getTransactions(
        limit: _limit,
        offset: state.offset, // Offset'i kullanıyoruz
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
    // Dönem başlangıç ve bitiş tarihini hesapla (resetDay baz alınarak)
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    if (now.day >= state.resetDay) {
      // Bu ayın sıfırlama gününden bu ayın sonuna kadar
      startDate = DateTime(now.year, now.month, state.resetDay);
      endDate = DateTime(
        now.year,
        now.month + 1,
        state.resetDay,
      ).subtract(const Duration(days: 1));
    } else {
      // Geçen ayın sıfırlama gününden bu ayın sıfırlama gününe kadar
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

  // CRUD işlemleri
  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);
    // Silme işleminden sonra listeyi ve toplamı güncelle
    state = state.copyWith(offset: 0, hasMore: true);
    await fetchInitialTransactions();
    await fetchTotalExpense();
    await fetchExpenseSummary(); // 🚨 Eklendi
  }

  Future<void> addTransaction(MoneyTransaction transaction) async {
    await _repository.addTransaction(transaction);
    // Veri eklendikten sonra listeyi ve toplamı güncellemek için yeniden çekim yapılabilir
    state = state.copyWith(offset: 0, hasMore: true);
    await fetchInitialTransactions();
    await fetchTotalExpense();
    await fetchExpenseSummary(); // 🚨 Eklendi
  }

  Future<void> fetchExpenseSummary() async {
    // Toplam harcamayı, tüm dönem için değil, basitçe local verideki tüm giderler üzerinden yapalım
    final allTransactions = await _repository
        .getAllTransactions(); // Yeni repository metodu varsayılıyor

    // Giderleri filtrele
    final expenses = allTransactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    // Kategori bazlı toplamları bul
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

    // Yüzdeleri hesapla
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
}

// Notifier Provider'ı
final moneyTrackerNotifierProvider =
    StateNotifierProvider<MoneyTrackerNotifier, MoneyTrackerState>((ref) {
      // Bağımlılık Enjeksiyonu
      return MoneyTrackerNotifier(MoneyRepositoryImpl());
    });
