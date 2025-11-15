// lib/features/agenda/domain/models/agenda_item.dart
import 'package:hive/hive.dart';

part 'agenda_item.g.dart'; // Hive build_runner ile oluşturulacak

// 🚨 DÜZELTME: TypeId 6'dan 10'a yükseltildi. (Çakışmayı önlemek için)
@HiveType(typeId: 10)
class AgendaItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime dueDate; // Görev veya etkinlik tarihi

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  bool hasNotification; // Bildirim ayarlandı mı?

  AgendaItem({
    required this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.isCompleted = false,
    this.hasNotification = false,
  });

  // Görevi tamamlanmış olarak işaretlemek için
  void toggleCompletion() {
    isCompleted = !isCompleted;
  }
}
