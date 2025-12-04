// lib/core/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String habitTask = "habit_notification_task";

  /// Bildirimleri başlat ve Timezone'u ayarla
  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    } catch (e) {
      debugPrint('Timezone hatası veya bulunamadı: $e, UTC kullanılıyor.');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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

    await _requestPermissions();

    _isInitialized = true;
  }

  /// WorkManager başlat
  Future<void> initializeWorkManager() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
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
  }

  // =========================================================
  // 🌿 BÖLÜM 1: HABIT TRACKER (GÜNLÜK TEKRARLI BİLDİRİM)
  // =========================================================

  /// Her gün belirli bir saatte tekrarlayan bildirim kur
  Future<void> scheduleDailyHabitNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    if (!_isInitialized) await initialize();

    final scheduledTime = _nextInstanceOfTime(time);
    debugPrint('📅 Hesaplanan Bildirim Zamanı: $scheduledTime');
    debugPrint('⌚ Şu anki Emülatör Saati: ${tz.TZDateTime.now(tz.local)}');

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_habit_channel',
            'Günlük Alışkanlıklar',
            channelDescription: 'Alışkanlık hatırlatıcıları',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'habit_$id',
      );
      debugPrint('✅ Bildirim Başarıyla Android Sistemine İletildi!');
    } catch (e) {
      debugPrint('❌ Bildirim Kurulurken HATA: $e');
    }
  }

  /// WorkManager ile Habit bildirimi kur
  Future<void> scheduleHabitWithWorkManager({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    final delay = scheduled.isBefore(now)
        ? scheduled.add(const Duration(days: 1)).difference(now)
        : scheduled.difference(now);

    await Workmanager().registerOneOffTask(
      id.toString(),
      habitTask,
      initialDelay: delay,
      inputData: {"title": title, "body": body, "id": id},
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  // =========================================================
  // 📅 BÖLÜM 2: AJANDA (TEK SEFERLİK TARİHLİ BİLDİRİM)
  // =========================================================
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduleDate,
  }) async {
    if (!_isInitialized) await initialize();

    final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(
      scheduleDate,
      tz.local,
    );

    if (scheduledTZDate.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint("Bildirim tarihi geçmiş, planlanmadı.");
      return;
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTZDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'agenda_reminder_channel',
          'Ajanda Hatırlatıcıları',
          channelDescription: 'Ajanda görevleri için hatırlatıcılar',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          color: Colors.blueGrey,
          colorized: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: 'agenda_$id',
    );
    debugPrint('Ajanda bildirimi planlandı: ID $id, Tarih $scheduledTZDate');
  }

  // =========================================================
  // 🛡️ BÖLÜM 3: ODAKLANMA KALKANI (ACİL & TAM EKRAN)
  // =========================================================
  Future<void> showLimitExceededNotification({required int minutes}) async {
    if (!_isInitialized) await initialize();

    await _notifications.show(
      99999,
      '⚠️ ODAKLANMA KORUMASI DEVREDE!',
      '$minutes dakikalık dikkat dağılma limiti doldu. Lütfen odağına geri dön!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'distraction_timer_channel',
          'Odaklanma Kalkanı',
          channelDescription: 'Dikkat dağılma limiti bildirimleri',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          color: Colors.red,
          colorized: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'limit_exceeded',
    );
  }

  // =========================================================
  // 📝 BÖLÜM 4: DAILY PLANNER (GÜNLÜK PLANLAYICI BİLDİRİMİ)
  // =========================================================
  Future<void> schedulePlanReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    if (!_isInitialized) await initialize();

    final scheduledTime = _nextInstanceOfTime(time);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_planner_channel',
          'Günlük Planlayıcı',
          channelDescription: 'Plan hatırlatmaları',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          color: Colors.blueAccent,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'plan_$id',
    );
  }

  // =========================================================
  // 🗑️ İPTAL İŞLEMLERİ
  // =========================================================
  Future<void> cancelNotification(int id) async =>
      await _notifications.cancel(id);
  Future<void> cancelAllNotifications() async =>
      await _notifications.cancelAll();

  // Yardımcı: Verilen saatin bir sonraki örneğini bul
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
}

/// WorkManager callback
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final notificationService = NotificationService();
    await notificationService.initialize();

    final title = inputData?['title'] as String? ?? "Hatırlatıcı";
    final body = inputData?['body'] as String? ?? "";
    final id = inputData?['id'] as int? ?? 0;

    await notificationService._notifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_habit_channel',
          'Günlük Alışkanlıklar',
          channelDescription: 'Alışkanlık hatırlatıcıları',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
        ),
      ),
    );
    return Future.value(true);
  });
}
