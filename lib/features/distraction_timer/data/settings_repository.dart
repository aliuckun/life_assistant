// lib/features/distraction_timer/data/settings_repository.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/timer_settings.dart';

class SettingsRepository {
  static const _keyIsActive = 'timer_is_active';
  static const _keyLimitMinutes = 'timer_limit_minutes';

  // 🚨 Aktiflik Durumunu Oku
  Future<bool> getIsActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsActive) ?? false; // Varsayılan: Kapalı
  }

  // 🚨 Aktiflik Durumunu Kaydet
  Future<void> setIsActive(bool isActive) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsActive, isActive);
  }

  // 🚨 Süre Limitini Oku
  Future<Duration> getLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final minutes = prefs.getInt(_keyLimitMinutes) ?? 5; // Varsayılan: 5 dakika
    return Duration(minutes: minutes);
  }

  // 🚨 Süre Limitini Kaydet
  Future<void> setLimit(Duration limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLimitMinutes, limit.inMinutes);
  }
}
