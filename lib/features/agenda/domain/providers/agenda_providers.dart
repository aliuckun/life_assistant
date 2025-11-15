// lib/features/agenda/domain/providers/agenda_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/agenda_repository_impl.dart';
import '../../../../core/services/notification_service.dart';
import '../models/agenda_item.dart';
import '../repositories/agenda_repository.dart';

// Veri Kaynağı ve Repository'nin Tanımı
// agendaLocalDataSourceProvider kaldırıldı.

final notificationServiceProvider = Provider((ref) => NotificationService());

final agendaRepositoryProvider = Provider<AgendaRepository>((ref) {
  // Repository artık sadece NotificationService'i alıyor.
  return AgendaRepositoryImpl(ref.read(notificationServiceProvider));
});

// =========================================================
// PAGINATION (LAZY LOADING) MANTIĞI İÇİN STATE NOTIFIER
// =========================================================

class AgendaListState {
  final List<AgendaItem> items;
  final bool isLoading;
  final bool hasMore; // Daha yüklenecek veri var mı?
  final int offset;
  static const int limit = 5; // Sayfa başına yüklenecek öğe sayısı

  AgendaListState({
    required this.items,
    this.isLoading = false,
    this.hasMore = true,
    this.offset = 0,
  });

  AgendaListState copyWith({
    List<AgendaItem>? items,
    bool? isLoading,
    bool? hasMore,
    int? offset,
  }) {
    return AgendaListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
    );
  }
}

class AgendaListNotifier extends StateNotifier<AgendaListState> {
  final AgendaRepository repository;

  AgendaListNotifier(this.repository) : super(AgendaListState(items: [])) {
    loadNextPage(); // Başlangıçta ilk sayfayı yükle
  }

  // Yeni öğeler yükler (lazy loading)
  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final newItems = await repository.getAgendaItems(
        offset: state.offset,
        limit: AgendaListState.limit,
      );

      final allItems = [...state.items, ...newItems];

      // Yeni offset'i hesapla
      final newOffset = state.offset + newItems.length;

      state = state.copyWith(
        items: allItems,
        isLoading: false,
        // Yüklenen öğe sayısı limitin altındaysa daha fazla öğe yoktur
        hasMore: newItems.length == AgendaListState.limit,
        offset: newOffset,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      print('Veri yüklenirken hata: $e');
    }
  }

  // CRUD işlemleri (Ekleme/Güncelleme)
  Future<void> addItem(AgendaItem newItem) async {
    await repository.createAgendaItem(newItem);

    // YENİ ÖĞEYİ BAŞA EKLEME
    // Bu, verinin "gerçek zamanlı" görünmesini sağlar.
    final updatedItems = [newItem, ...state.items];

    state = state.copyWith(
      items: updatedItems,
      // Yeni bir öğe eklendiği için offset'i de bir artırıyoruz.
      offset: state.offset + 1,
    );
  }

  // Tamamlama durumunu değiştir
  Future<void> toggleCompletion(AgendaItem item) async {
    await repository.toggleCompletion(item);

    // Sadece state içindeki öğeyi güncelle
    final updatedItems = state.items.map((i) {
      return i.id == item.id ? item : i;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }
}

// State Notifier Provider
final agendaListProvider =
    StateNotifierProvider<AgendaListNotifier, AgendaListState>((ref) {
      return AgendaListNotifier(ref.watch(agendaRepositoryProvider));
    });
