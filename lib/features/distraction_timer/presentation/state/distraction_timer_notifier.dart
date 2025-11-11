// lib/features/distraction_timer/presentation/state/distraction_timer_notifier.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_assistant/core/services/notification_service.dart';

enum TimerStatus { idle, running, exceeded }

class TimerSettings {
  final Duration limit;
  const TimerSettings({required this.limit});
}

class TimerState {
  final bool isInitialized;
  final bool isGloballyActive;
  final bool isAppInBackground;
  final TimerStatus status;
  final Duration elapsedDuration;
  final TimerSettings settings;

  const TimerState({
    required this.isInitialized,
    required this.isGloballyActive,
    required this.isAppInBackground,
    required this.status,
    required this.elapsedDuration,
    required this.settings,
  });

  TimerState copyWith({
    bool? isInitialized,
    bool? isGloballyActive,
    bool? isAppInBackground,
    TimerStatus? status,
    Duration? elapsedDuration,
    TimerSettings? settings,
  }) {
    return TimerState(
      isInitialized: isInitialized ?? this.isInitialized,
      isGloballyActive: isGloballyActive ?? this.isGloballyActive,
      isAppInBackground: isAppInBackground ?? this.isAppInBackground,
      status: status ?? this.status,
      elapsedDuration: elapsedDuration ?? this.elapsedDuration,
      settings: settings ?? this.settings,
    );
  }
}

class DistractionTimerNotifier extends StateNotifier<TimerState> {
  Timer? _timer;
  DateTime? _backgroundStartTime;
  bool _notificationSent = false;

  DistractionTimerNotifier()
    : super(
        const TimerState(
          isInitialized: true,
          isGloballyActive: false,
          isAppInBackground: false,
          status: TimerStatus.idle,
          elapsedDuration: Duration.zero,
          settings: TimerSettings(limit: Duration(minutes: 5)),
        ),
      );

  // ✅ YARDIMCI FONKSİYON: Gerçek geçen süreyi hesapla
  Duration _calculateRealElapsed() {
    if (_backgroundStartTime == null) return state.elapsedDuration;
    return state.elapsedDuration +
        DateTime.now().difference(_backgroundStartTime!);
  }

  // Arka plana geçtiğinde çağrılır
  void setBackground() {
    if (!state.isGloballyActive) return;

    _backgroundStartTime = DateTime.now();
    state = state.copyWith(
      isAppInBackground: true,
      status: TimerStatus.running,
    );
    _startTimer();
    print('📱 Arka plana geçildi. Başlangıç zamanı: $_backgroundStartTime');
  }

  // Ön plana geldiğinde çağrılır
  void setForeground() {
    if (_backgroundStartTime != null) {
      final realElapsed = _calculateRealElapsed();

      state = state.copyWith(
        isAppInBackground: false,
        elapsedDuration: realElapsed, // ✅ Gerçek süreyi kaydet
      );

      print('📱 Ön plana gelindi. Geçen süre: ${realElapsed.inSeconds} saniye');

      _backgroundStartTime = null;

      // ✅ Limit kontrolü
      if (realElapsed >= state.settings.limit &&
          state.status != TimerStatus.exceeded) {
        state = state.copyWith(status: TimerStatus.exceeded);
        _stopTimer();
        print('⚠️ Limit aşıldı (ön planda tespit edildi)');
      }
    } else {
      state = state.copyWith(isAppInBackground: false);
    }
  }

  // Timer'ı başlat
  void _startTimer() {
    _stopTimer();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isAppInBackground &&
          state.isGloballyActive &&
          _backgroundStartTime != null) {
        // ✅ Gerçek süreyi hesapla (her saniyede bir kontrol)
        final realElapsed = _calculateRealElapsed();

        // 🔔 LİMİT AŞILDIĞINDA SADECE BİR KEZ BİLDİRİM GÖNDER
        if (realElapsed >= state.settings.limit &&
            state.status != TimerStatus.exceeded &&
            !_notificationSent) {
          state = state.copyWith(
            status: TimerStatus.exceeded,
            elapsedDuration: realElapsed,
          );
          _notificationSent = true;
          _stopTimer();

          print(
            '🚨 LİMİT AŞILDI! Gerçek süre: ${realElapsed.inSeconds} saniye',
          );
          print('🔔 Bildirim gönderiliyor...');

          NotificationService().showLimitExceededNotification(
            minutes: state.settings.limit.inMinutes,
          );
        }
      }
    });
  }

  // Timer'ı durdur
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // Sayacı sıfırla
  void stopTimer() {
    _stopTimer();
    _notificationSent = false; // 🔥 YENİ: Bildirim flag'ini sıfırla
    state = state.copyWith(
      status: TimerStatus.idle,
      elapsedDuration: Duration.zero,
    );
    _backgroundStartTime = null;

    // Bildirimi kaldır
    NotificationService().cancelAllNotifications();
  }

  // Aktif/Pasif geçiş
  void setGlobalActive(bool active) {
    state = state.copyWith(isGloballyActive: active);
    if (!active) {
      stopTimer();
    }
  }

  // Limit ayarla
  void setLimit(Duration limit) {
    state = state.copyWith(settings: TimerSettings(limit: limit));
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

// Provider tanımı
final distractionTimerProvider =
    StateNotifierProvider<DistractionTimerNotifier, TimerState>((ref) {
      return DistractionTimerNotifier();
    });
