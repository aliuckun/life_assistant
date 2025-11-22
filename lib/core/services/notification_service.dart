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

    // DÜZELTİLEN KISIM: Gereksiz getClass kontrolü kaldırıldı
    try {
      // Türkiye saati için 'Europe/Istanbul' kullanıyoruz.
      // Eğer bu ID veritabanında bulunamazsa catch bloğuna düşer ve UTC yapar.
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    } catch (e) {
      debugPrint('Timezone hatası veya bulunamadı: $e, UTC kullanılıyor.');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Android ayarları
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS ayarları
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
    // Navigation işlemleri buraya eklenebilir
  }

  // =========================================================
  // 🌿 BÖLÜM 1: HABIT TRACKER (GÜNLÜK TEKRARLI BİLDİRİM)
  // =========================================================

  /// Her gün belirli bir saatte tekrarlayan bildirim kurar
  Future<void> scheduleDailyHabitNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    if (!_isInitialized) {
      debugPrint('⚠️ Servis initialize edilmemiş, ediliyor...');
    }
    await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_habit_channel', // Kanal ID
          'Günlük Alışkanlıklar', // Kanal Adı
          channelDescription: 'Alışkanlık hatırlatıcıları',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final scheduledTime = _nextInstanceOfTime(time);
    debugPrint('📅 Hesaplanan Bildirim Zamanı: $scheduledTime'); // LOG 2
    debugPrint(
      '⌚ Şu anki Emülatör Saati: ${tz.TZDateTime.now(tz.local)}',
    ); // LOG 3

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'habit_$id',
      );
      debugPrint('✅ Bildirim Başarıyla Android Sistemine İletildi!'); // LOG 4
    } catch (e) {
      debugPrint('❌ Bildirim Kurulurken HATA: $e'); // LOG 5
    }

    debugPrint('Habit bildirimi kuruldu: $time (ID: $id)');
  }

  // Yardımcı: Verilen saatin bir sonraki örneğini bul (Bugün geçtiyse yarına atar)
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // =========================================================
  // 📅 BÖLÜM 2: AJANDA (TEK SEFERLİK TARİHLİ BİLDİRİM)
  // =========================================================

  /// Belirli bir tarihte tek seferlik bildirim gönder
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduleDate,
  }) async {
    if (!_isInitialized) await initialize();

    // Zamanı TZDateTime objesine çevir
    final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(
      scheduleDate,
      tz.local,
    );

    // Eğer geçmiş bir tarihse, bildirim planlama.
    if (scheduledTZDate.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint("Bildirim tarihi geçmiş, planlanmadı.");
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'agenda_reminder_channel', // Kanal ID
          'Ajanda Hatırlatıcıları', // Kanal Adı
          channelDescription: 'Ajanda görevleri için hatırlatıcılar',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          color: Colors.blueGrey,
          colorized: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTZDate,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents.dateAndTime, // Tarih ve Saate göre tek sefer
      payload: 'agenda_$id',
    );
    debugPrint('Ajanda bildirimi planlandı: ID $id, Tarih $scheduledTZDate');
  }

  // =========================================================
  // 🛡️ BÖLÜM 3: ODAKLANMA KALKANI (ACİL & TAM EKRAN)
  // =========================================================

  /// ODAKLANMA KALKANI BİLDİRİMİ (Tam Ekran + Titreşim + Ses)
  Future<void> showLimitExceededNotification({required int minutes}) async {
    if (!_isInitialized) await initialize();

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
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(
      99999, // Sabit ID (Her zaman üstüne yazar)
      '⚠️ ODAKLANMA KORUMASI DEVREDE!',
      '$minutes dakikalık dikkat dağılma limiti doldu. Lütfen odağına geri dön!',
      details,
      payload: 'limit_exceeded',
    );
  }

  // =========================================================
  // 🗑️ İPTAL İŞLEMLERİ
  // =========================================================

  /// Tek bir bildirimi iptal et
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Tüm bildirimleri iptal et
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
