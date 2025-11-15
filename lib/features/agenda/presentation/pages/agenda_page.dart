// lib/features/agenda/presentation/pages/agenda_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/agenda_item.dart';
import '../../domain/providers/agenda_providers.dart';
import '../widgets/agenda_item_modal.dart';

class AgendaPage extends ConsumerStatefulWidget {
  const AgendaPage({super.key});

  @override
  ConsumerState<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends ConsumerState<AgendaPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  // Kullanıcı listenin sonuna ulaştığında daha fazla veri yükle
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !ref.read(agendaListProvider).isLoading) {
      ref.read(agendaListProvider.notifier).loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Yeni görev ekleme modalını göster
  void _showAgendaModal({AgendaItem? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AgendaItemModal(
        // Riverpod'a erişmek için köprü
        item: item,
        onSubmit: (newItem) {
          ref.read(agendaListProvider.notifier).addItem(newItem);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // State'i dinle
    final state = ref.watch(agendaListProvider);
    final notifier = ref.read(agendaListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajandam'),
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            // Tamamen yeniden yüklemek için: (Örnek olarak: tüm listeyi sıfırla ve yeniden yükle)
            ref.invalidate(agendaListProvider);
          },
          child: ListView.builder(
            controller: _scrollController,
            itemCount: state.items.length + (state.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              // Yükleniyor göstergesi
              if (index == state.items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  ),
                );
              }

              final item = state.items[index];

              return Card(
                color: item.isCompleted ? Colors.green.shade100 : Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                child: ListTile(
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: item.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    'Son Tarih: ${item.dueDate.day}/${item.dueDate.month} - ${item.dueDate.year}',
                    style: TextStyle(
                      color:
                          item.dueDate.isBefore(DateTime.now()) &&
                              !item.isCompleted
                          ? Colors.red.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      item.isCompleted
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: item.isCompleted ? Colors.green : Colors.grey,
                      size: 28,
                    ),
                    onPressed: () => notifier.toggleCompletion(item),
                  ),
                  onTap: () =>
                      _showAgendaModal(item: item), // Düzenleme için modal
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAgendaModal(),
        backgroundColor: Colors.blueGrey.shade200,
        child: const Icon(Icons.add, color: Colors.blueGrey),
      ),
    );
  }
}
