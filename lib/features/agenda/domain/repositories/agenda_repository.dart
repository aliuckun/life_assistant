// lib/features/agenda/domain/repositories/agenda_repository.dart
import '../../domain/models/agenda_item.dart';

abstract class AgendaRepository {
  Future<List<AgendaItem>> getAgendaItems({int offset, int limit});
  Future<void> createAgendaItem(AgendaItem item);
  Future<void> toggleCompletion(AgendaItem item);
  Future<void> deleteAgendaItem(String id);
}
