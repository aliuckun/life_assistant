// -----------------------------------------------------------------------------
// DOSYA: lib/features/step_counter/presentation/state/step_controller.dart
// KATMAN: Presentation (Logic)
// AÇIKLAMA: Sensörden gelen ham veriyi işleyip "Bugünün Adımı"nı hesaplar.
//           Reboot (Telefonu yeniden başlatma) durumlarını yönetir.
// -----------------------------------------------------------------------------

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import '../../data/step_repository.dart';
import '../../domain/step_model.dart';

class StepController extends ChangeNotifier {
  final StepRepository _repository;
  StreamSubscription<StepCount>? _subscription;

  int _todaySteps = 0;
  List<DailySteps> _history = [];
  bool _isLoading = true;
  String _status = "Başlatılıyor...";

  StepController(this._repository) {
    _init();
  }

  int get todaySteps => _todaySteps;
  List<DailySteps> get history => _history;
  bool get isLoading => _isLoading;
  String get status => _status;

  // Ortalama
  double get monthlyAverage {
    if (_history.isEmpty) return 0;
    int total = _history.fold(0, (sum, item) => sum + item.steps);
    return total / _history.length;
  }

  Future<void> _init() async {
    await _repository.init();

    // 1. Veritabanından bugünün mevcut verisini çek
    _todaySteps = _repository.getStepsForDate(DateTime.now());
    _history = _repository.getMonthlyHistory();
    _isLoading = false;
    notifyListeners();

    // 2. İzin İste ve Dinlemeye Başla
    bool granted = await _repository.requestPermission();
    if (granted) {
      _startListening();
    } else {
      _status = "İzin reddedildi. Adım sayılamıyor.";
      notifyListeners();
    }
  }

  void _startListening() {
    _status = "Sensör Dinleniyor...";
    _subscription = _repository.getSensorStream().listen(
      (StepCount event) {
        _onStepCount(event);
      },
      onError: (error) {
        _status = "Sensör Hatası: $error";
        notifyListeners();
      },
    );
  }

  // --- KRİTİK LOGIC: DELTA HESAPLAMA ---
  void _onStepCount(StepCount event) {
    int sensorSteps = event.steps;
    int lastSavedSensorValue = _repository.getLastSensorReading();

    // Eğer veritabanında hiç kayıt yoksa (ilk kurulum), referansı şimdi oluştur.
    if (lastSavedSensorValue == -1) {
      _repository.saveLastSensorReading(sensorSteps);
      return;
    }

    // Farkı Hesapla
    int delta = sensorSteps - lastSavedSensorValue;

    // SENARYO: Telefon yeniden başlatıldı (Reboot)
    // Sensör 50.000'den 0'a düşmüştür. Delta negatif çıkar (Örn: -50.000).
    if (delta < 0) {
      // Reboot sonrası ilk adım. Delta'yı direkt sensör değeri kabul et.
      delta = sensorSteps;
    }

    // Eğer adım atıldıysa (delta > 0)
    if (delta > 0) {
      _todaySteps += delta;

      // Veritabanını Güncelle
      _repository.updateStepsForDate(DateTime.now(), _todaySteps);
      _repository.saveLastSensorReading(sensorSteps);

      // UI Güncelle
      _updateHistoryList();
      notifyListeners();
    }
  }

  void _updateHistoryList() {
    // History listesindeki son elemanı (bugünü) güncelle
    if (_history.isNotEmpty) {
      // Listenin son elemanını çıkarıp güncel halini ekle
      // (Daha performanslı bir yol bulunabilir ama 30 eleman için sorun değil)
      _history = _repository.getMonthlyHistory();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
