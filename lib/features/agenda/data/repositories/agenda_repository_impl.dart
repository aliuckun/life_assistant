// lib/features/agenda/data/repositories/agenda_repository_impl.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../domain/models/agenda_item.dart';
import '../../domain/repositories/agenda_repository.dart';
// 🚨 Düzeltme: NotificationService'in yolu düzeltildi
import '../../../../core/services/notification_service.dart';

// Hive kutusunun adı
const String _agendaBoxName = 'agendaBox';

class AgendaRepositoryImpl implements AgendaRepository {
  final NotificationService _notificationService; // Bildirim servisi

  AgendaRepositoryImpl(this._notificationService);

  Future<Box<AgendaItem>> _openBox() async {
    // UYARI: main.dart'ta Hive.init() ve Adapter kaydı yapılmalıdır.
    if (Hive.isBoxOpen(_agendaBoxName)) {
      return Hive.box<AgendaItem>(_agendaBoxName);
    }
    return await Hive.openBox<AgendaItem>(_agendaBoxName);
  }

  @override
  Future<List<AgendaItem>> getAgendaItems({
    int offset = 0,
    int limit = 5,
  }) async {
    final box = await _openBox();

    final allItems = box.values.toList();
    allItems.sort((a, b) => b.dueDate.compareTo(a.dueDate));

    if (offset >= allItems.length) {
      return [];
    }

    final endIndex = (offset + limit).clamp(0, allItems.length);

    return allItems.sublist(offset, endIndex);
  }

  @override
  Future<void> createAgendaItem(AgendaItem item) async {
    final box = await _openBox();
    await box.put(item.id, item);

    if (item.hasNotification) {
      _notificationService.scheduleNotification(
        id: item.id.hashCode,
        title: "Ajanda Hatırlatıcı: ${item.title}",
        body:
            "Göreviniz yarın (${item.dueDate.day}/${item.dueDate.month}) doluyor!",
        scheduleDate: item.dueDate.subtract(const Duration(days: 1)),
        // 🚨 NotificationService'deki metotlar sizin verdiğiniz kodda yoktu,
        // bu yüzden Repository'de tanımlanan mock metotları kullanmaya devam ediyorum.
        // Eğer NotificationService sınıfınızda scheduleNotification metodunu eklemediyseniz, eklemelisiniz.
      );
    }
  }

  @override
  Future<void> toggleCompletion(AgendaItem item) async {
    item.toggleCompletion();
    final box = await _openBox();
    await box.put(item.id, item);
  }

  @override
  Future<void> deleteAgendaItem(String id) async {
    final box = await _openBox();
    await box.delete(id);
    _notificationService.cancelNotification(id.hashCode);
  }
}

// 🚨 UYARI: Bu tanım silindi, çünkü NotificationService artık lib/core/services/notification_service.dart'tan geliyor.
// class NotificationService { ... }
