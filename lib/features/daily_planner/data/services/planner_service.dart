import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/plan_models.dart';

class PlannerService {
  static const String _boxName = 'daily_plans_box';

  // Servisi başlat ve adaptörleri kaydet
  Future<void> init() async {
    // Hive başlatılmamışsa başlat (Main'de yapılmadıysa diye önlem)
    if (!Hive.isAdapterRegistered(kPlanTypeId)) {
      await Hive.initFlutter();
      Hive.registerAdapter(PlanItemAdapter());
    }

    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<PlanItem>(_boxName);
    }
  }

  // Kutuya erişim
  Box<PlanItem> get _box => Hive.box<PlanItem>(_boxName);

  // Belirli bir tarihe ait planları getir
  List<PlanItem> getPlansByDate(DateTime date) {
    if (!_box.isOpen) return [];

    final allPlans = _box.values.toList();
    return allPlans.where((plan) {
      return plan.date.year == date.year &&
          plan.date.month == date.month &&
          plan.date.day == date.day;
    }).toList();
  }

  // Yeni plan ekle
  Future<void> addPlan(PlanItem plan) async {
    await _box.put(plan.id, plan); // ID'yi key olarak kullanıyoruz
  }

  // Planı güncelle (Tamamlandı durumu vb.)
  Future<void> updatePlan(PlanItem plan) async {
    await plan.save(); // HiveObject özelliği sayesinde direkt kaydedebiliriz
  }

  // Plan sil
  Future<void> deletePlan(String id) async {
    await _box.delete(id);
  }
}
