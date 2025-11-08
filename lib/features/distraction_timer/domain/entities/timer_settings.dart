// lib/features/distraction_timer/domain/entities/timer_settings.dart
import 'package:flutter/foundation.dart';

@immutable
class TimerSettings {
  final Duration limit;
  final String appName;
  final String packageName;

  const TimerSettings({
    required this.limit,
    required this.appName,
    required this.packageName,
  });

  // copyWith metodu
  TimerSettings copyWith({
    Duration? limit,
    String? appName,
    String? packageName,
  }) {
    return TimerSettings(
      limit: limit ?? this.limit,
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
    );
  }
}
