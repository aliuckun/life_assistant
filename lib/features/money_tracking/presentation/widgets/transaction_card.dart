// lib/features/money_tracking/presentation/widgets/transaction_card.dart (Güncellendi)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/transaction.dart';

class TransactionCard extends StatelessWidget {
  final MoneyTransaction transaction;
  // Silme metodu artık onay gerektirdiği için Future<void> olarak tanımlanabilir
  final Function(String) onDelete;
  final Function(MoneyTransaction) onEdit;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // 🚨 Dismissible Widget Eklendi (Sola Kaydırarak Silme)
    return Dismissible(
      key: ValueKey(transaction.id), // Her öğe için benzersiz anahtar
      direction: DismissDirection.endToStart, // Sadece sağdan sola kaydırma
      background: Container(
        color: Colors.red.shade700,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      // Kaydırma bittiğinde ne yapılacağı
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Silme Onayı'),
            content: Text(
              '${transaction.description} işlemini silmek istediğinizden emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sil', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        // Kullanıcı onayladıktan sonra silme işlemini tetikle
        onDelete(transaction.id);
        // İsteğe bağlı: Kullanıcıya geri alma (undo) butonu gösterilebilir.
      },
      child: Card(
        color: Colors.grey[850],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          onTap: () =>
              onEdit(transaction), // Tıklayınca düzenleme modalı açılacak
          // ... (Diğer ListTile öğeleri aynı kalır)
          leading: CircleAvatar(
            backgroundColor: transaction.type == TransactionType.expense
                ? Colors.red[900]
                : Colors.green[900],
            child: Icon(
              transaction.type == TransactionType.expense
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              color: Colors.white,
            ),
          ),
          title: Text(
            transaction.description,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            '${transaction.category} - ${DateFormat('dd MMM yyyy').format(transaction.date)}',
            style: TextStyle(color: Colors.grey[400]),
          ),
          trailing: Text(
            '${transaction.type == TransactionType.expense ? '-' : '+'}${transaction.amount.toStringAsFixed(2)} ₺',
            style: TextStyle(
              color: transaction.type == TransactionType.expense
                  ? Colors.redAccent
                  : Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
