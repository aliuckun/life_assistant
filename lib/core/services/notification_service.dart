// lib/core/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Bildirimleri başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

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

  /// 🚨 ODAKLANMA KALKANI BİLDİRİMİ (Tam Ekran + Titreşim + Ses)
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
      0, // Bildirim ID
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
