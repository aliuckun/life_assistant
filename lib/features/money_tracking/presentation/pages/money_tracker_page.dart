// lib/features/money_tracking/presentation/pages/money_tracker_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/money_tracker_notifier.dart';
import '../widgets/transaction_card.dart';
import '../widgets/summary_section.dart';
import '../widgets/total_expense_card.dart';
import '../../domain/entities/transaction.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/recurring_payment_card.dart';
import '../widgets/add_recurring_payment_modal.dart';
import '../widgets/edit_transaction_modal.dart';
import '../widgets/edit_recurring_payment_modal.dart'; // 🚨 Yeni Düzenleme Modalını Ekle

class MoneyTrackerPage extends ConsumerStatefulWidget {
  const MoneyTrackerPage({super.key});

  @override
  ConsumerState<MoneyTrackerPage> createState() => _MoneyTrackerPageState();
}

class _MoneyTrackerPageState extends ConsumerState<MoneyTrackerPage> {
  final _scrollController = ScrollController();
  static const _scrollThreshold = 200.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll - currentScroll <= _scrollThreshold) {
      ref.read(moneyTrackerNotifierProvider.notifier).fetchNextTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(moneyTrackerNotifierProvider);
    final recurringPayments = state.recurringPayments;

    if (state.isLoadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        final notifier = ref.read(moneyTrackerNotifierProvider.notifier);
        // Tüm verileri ve faturaları yeniden çek
        await notifier.fetchInitialTransactions();
        await notifier.fetchTotalExpense();
        await notifier.fetchExpenseSummary();
        await notifier.fetchRecurringPayments();
      },
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TotalExpenseCard(
                    totalExpense: state.totalExpense,
                    resetDay: state.resetDay,
                  ),

                  const SizedBox(height: 20),
                  const SummarySection(), // 🚨 Grafik burada
                  const SizedBox(height: 20),

                  // Fatura Bölümü
                  _buildRecurringPaymentsSection(
                    context,
                    ref,
                    recurringPayments,
                  ),

                  // ❌ ÇİFT GRAFİK HATA ÇÖZÜMÜ: Bu SummarySection'ı sildik
                  // const SizedBox(height: 20),
                  const SizedBox(height: 20),
                  const Text(
                    'Tüm İşlemler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount:
                        state.transactions.length +
                        (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.transactions.length) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final transaction = state.transactions[index];
                      return TransactionCard(
                        transaction: transaction,
                        onDelete: (id) => _deleteTransaction(context, ref, id),
                        onEdit: (t) =>
                            _showEditTransactionDialog(context, ref, t),
                      );
                    },
                  ),

                  if (!state.hasMore && state.transactions.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Tüm verilere ulaşıldı.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'add_transaction',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.grey[900],
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25.0),
                    ),
                  ),
                  builder: (context) => const AddTransactionModal(),
                );
              },
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteTransaction(BuildContext context, WidgetRef ref, String id) {
    ref.read(moneyTrackerNotifierProvider.notifier).deleteTransaction(id);
  }

  void _showEditTransactionDialog(
    BuildContext context,
    WidgetRef ref,
    MoneyTransaction transaction,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => EditTransactionModal(transaction: transaction),
    );
  }

  // 🚨 YENİ METOT: Fatura Düzenleme Modalı
  void _showEditRecurringPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    RecurringPayment payment,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      // 🚨 EditRecurringPaymentModal'ı aç
      builder: (context) => EditRecurringPaymentModal(payment: payment),
    );
  }

  // Fatura Bölümünü Oluşturma
  Widget _buildRecurringPaymentsSection(
    BuildContext context,
    WidgetRef ref,
    List<RecurringPayment> payments,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tekrar Eden Ödemeler (Faturalar)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            // Yeni fatura ekleme butonu
            IconButton(
              icon: const Icon(
                Icons.add_box_outlined,
                color: Colors.indigoAccent,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.grey[900],
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25.0),
                    ),
                  ),
                  builder: (context) => const AddRecurringPaymentModal(),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (payments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              'Henüz tanımlı fatura yok. Sağdaki butonla ekleyin.',
              style: TextStyle(color: Colors.grey[500]),
            ),
          )
        else
          ...payments
              .map(
                (p) => RecurringPaymentCard(
                  payment: p,
                  // 🚨 Fatura kartına tıklandığında düzenleme modalını aç
                  onTap: () => _showEditRecurringPaymentDialog(context, ref, p),
                ),
              )
              .toList(),
      ],
    );
  }
}
