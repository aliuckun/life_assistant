// lib/core/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
// 🚨 ZAMANLANMIŞ BİLDİRİMLER İÇİN GEREKLİ KÜTÜPHANELER
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Bildirimleri başlat ve Timezone'u ayarla
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 🚨 Timezone Verisini Başlat
    tz.initializeTimeZones();
    // Yerel zaman dilimini al
    final location = tz.getLocation(tz.local.name);
    tz.setLocalLocation(location);

    // Android ayarları
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS ayarları (isteğe bağlı)
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android 13+ için bildirim izni iste
    await _requestPermissions();

    _isInitialized = true;
  }

  /// Android 13+ için izin kontrolü
  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  /// Bildirime tıklandığında çalışacak fonksiyon
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Bildirime tıklandı: ${response.payload}');
    // İsterseniz burada belirli bir sayfaya yönlendirme yapabilirsiniz
  }

  // =========================================================
  // 🚨 YENİ METOT: AJANDA İÇİN ZAMANLANMIŞ BİLDİRİM
  // =========================================================
  /// Belirli bir tarihte bildirim gönder
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduleDate,
  }) async {
    if (!_isInitialized) {
      debugPrint("Bildirim servisi başlatılmamış.");
      return;
    }

    // Zamanı TZDateTime objesine çevir
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      scheduleDate,
      tz.local,
    );

    // Eğer geçmiş bir tarihse, bildirim planlama.
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint("Bildirim tarihi geçmiş, planlanmadı.");
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'agenda_reminder_channel', // Yeni kanal ID
          'Ajanda Hatırlatıcıları', // Kanal Adı
          channelDescription: 'Ajanda görevleri için hatırlatıcılar',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          color: Colors.blueGrey,
          colorized: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
    debugPrint('Bildirim başarıyla planlandı: ID $id, Tarih $scheduledDate');
  }

  /// 🚨 ODAKLANMA KALKANI BİLDİRİMİ (Tam Ekran + Titreşim + Ses) - Kodu aynı kaldı
  Future<void> showLimitExceededNotification({required int minutes}) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'distraction_timer_channel', // Kanal ID
          'Odaklanma Kalkanı', // Kanal Adı
          channelDescription: 'Dikkat dağılma limiti bildirimleri',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          fullScreenIntent: true, // 🔥 TAM EKRAN BİLDİRİM
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          color: Colors.red,
          colorized: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      // Bildirim ID
      1,
      '⚠️ ODAKLANMA KORUMASI DEVREDE!',
      '$minutes dakikalık dikkat dağılma limiti doldu. Lütfen odağına geri dön!',
      details,
      payload: 'limit_exceeded',
    );
  }

  /// Bildirimi iptal et
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Tüm bildirimleri iptal et
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
