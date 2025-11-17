import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// QuizEffectsController
/// Doğru/yanlış sesleri, seri (streak) sistemi ve animasyon yönetimi.

class QuizEffectsOverlay extends StatelessWidget {
  final QuizEffectsController controller;

  const QuizEffectsOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Streak göstergesi
            if (controller.showStreakUI)
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: controller.showStreakUI ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    "🔥 Streak: ${controller.streak}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black45,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Ateş animasyonu (Lottie yerine basit animasyon)
            if (controller.showFire)
              Center(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('fire_${controller.streak}'),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.5 + (value * 0.5),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: _getFireColors(controller.fireLevel),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _getFireEmoji(controller.fireLevel),
                              style: const TextStyle(fontSize: 80),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Yanlış animasyonu
            if (controller.showFailAnimation)
              Center(
                child: TweenAnimationBuilder<double>(
                  key: const ValueKey('fail_animation'),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 1.0 + (value * 0.3),
                      child: Opacity(
                        opacity: 1.0 - value,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withOpacity(0.3),
                          ),
                          child: const Center(
                            child: Text('❌', style: TextStyle(fontSize: 100)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  List<Color> _getFireColors(int level) {
    switch (level) {
      case 1:
        return [Colors.orange, Colors.deepOrange, Colors.transparent];
      case 2:
        return [Colors.deepOrange, Colors.red, Colors.transparent];
      case 3:
        return [Colors.red, Colors.purple, Colors.transparent];
      default:
        return [Colors.yellow, Colors.orange, Colors.transparent];
    }
  }

  String _getFireEmoji(int level) {
    switch (level) {
      case 1:
        return '🔥';
      case 2:
        return '🔥🔥';
      case 3:
        return '🔥🔥🔥';
      default:
        return '✨';
    }
  }
}

class QuizEffectsController extends ChangeNotifier {
  final _audioPlayers = <AudioPlayer>[];

  int streak = 0;
  bool showStreakUI = false;
  bool showFire = false;
  bool showFailAnimation = false;

  /// Alev yoğunluk seviyeleri
  int fireLevel = 0; // 0 = yok, 1, 2, 3...

  /// Aynı anda birden fazla ses oynatabilmek için yeni AudioPlayer üretir
  AudioPlayer _newPlayer() {
    final p = AudioPlayer();
    // Android'de aynı anda birden fazla ses çalabilmesi için
    p.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers}, // Liste yerine Set
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none, // ÖNEMLI: Audio focus isteme
        ),
      ),
    );
    _audioPlayers.add(p);
    return p;
  }

  /// Doğru cevaptan sonra tetiklenir
  Future<void> onCorrect() async {
    streak++;

    // Streak UI aç
    showStreakUI = true;

    // Fire aç
    showFire = true;

    // Fire Level belirleme
    if (streak >= 8) {
      fireLevel = 3;
    } else if (streak >= 5) {
      fireLevel = 2;
    } else if (streak >= 3) {
      fireLevel = 1;
    } else {
      fireLevel = 0;
    }

    // Ses seçimi
    try {
      if (streak == 1) {
        debugPrint("STREAK 1 → FIRST sesleri oynatılıyor");
        await _playMulti([
          "Killstreak_SFX_Multikill_Point_First.ogg",
          "Killstreak_SFX_Multikill_Melody_First.ogg",
        ]);
      } else if (streak == 2) {
        debugPrint("STREAK 2 → DOUBLE sesleri oynatılıyor");
        await _playMulti([
          "Killstreak_SFX_Multikill_Point_Double.ogg",
          "Killstreak_SFX_Multikill_Melody_Double.ogg",
        ]);
      } else if (streak == 3) {
        debugPrint("STREAK 3 → TRIPLE sesleri oynatılıyor");
        await _playMulti([
          "Killstreak_SFX_Multikill_Point_Triple.ogg",
          "Killstreak_SFX_Multikill_Melody_Triple.ogg",
        ]);
      } else if (streak == 4) {
        debugPrint("STREAK 4 → QUADRA sesleri oynatılıyor");
        await _playMulti([
          "Killstreak_SFX_Multikill_Point_Quadra.ogg",
          "Killstreak_SFX_Multikill_Melody_Quadra.ogg",
        ]);
      } else if (streak >= 5) {
        debugPrint("STREAK 5+ → PENTA sesleri oynatılıyor");
        await _playMulti([
          "Killstreak_SFX_Multikill_Point_Penta.ogg",
          "Killstreak_SFX_Multikill_Melody_Penta.ogg",
        ]);
      } else {
        debugPrint("DEFAULT ses oynuyor");
        await _playSingle("Killstreak_SFX_Multikill_Point_First.ogg");
      }
    } catch (e) {
      debugPrint("Ses oynatma hatası: $e");
    }

    notifyListeners();

    // 800ms sonra ateş animasyonunu kapat
    Future.delayed(const Duration(milliseconds: 800), () {
      showFire = false;
      notifyListeners();
    });
  }

  /// Yanlış cevaptan sonra tetiklenir
  Future<void> onWrong() async {
    // Seri sıfırla
    streak = 0;

    // Fire kapat
    showFire = false;
    fireLevel = 0;

    // Streak UI gizle
    showStreakUI = false;

    // Yanlış animasyon göster
    showFailAnimation = true;

    // Yanlış sesi
    try {
      await _playSingle("Killstreak_SFX_Assist.ogg");
    } catch (e) {
      debugPrint("Ses oynatma hatası: $e");
    }

    notifyListeners();

    // 1 saniye sonra animasyonu kapat
    Future.delayed(const Duration(seconds: 1), () {
      showFailAnimation = false;
      notifyListeners();
    });
  }

  /// Tek ses - hata kontrolü ile
  Future<void> _playSingle(String assetPath) async {
    try {
      // Dosyanın varlığını kontrol et
      final fullPath = 'assets/audio/$assetPath';
      await rootBundle.load(fullPath);

      final p = _newPlayer();
      await p.play(AssetSource('audio/$assetPath'));
    } catch (e) {
      debugPrint("⚠️ Ses dosyası bulunamadı: $assetPath - $e");
    }
  }

  /// Aynı anda birden fazla ses - hata kontrolü ile
  Future<void> _playMulti(List<String> assets) async {
    final players = <AudioPlayer>[];

    // Önce tüm player'ları hazırla
    for (final s in assets) {
      try {
        final fullPath = 'assets/audio/$s';
        await rootBundle.load(fullPath);

        final p = _newPlayer();
        players.add(p);
      } catch (e) {
        debugPrint("⚠️ Ses dosyası bulunamadı: $s - $e");
      }
    }

    // Sonra hepsini aynı anda başlat
    for (int i = 0; i < players.length && i < assets.length; i++) {
      unawaited(players[i].play(AssetSource('audio/${assets[i]}')));
    }
  }

  /// Temizleme
  @override
  void dispose() {
    for (var p in _audioPlayers) {
      p.dispose();
    }
    _audioPlayers.clear();
    super.dispose();
  }
}

/// Async işlemleri beklemeden devam etmek için
void unawaited(Future<void> future) {
  future.catchError((error) {
    debugPrint("Async hata: $error");
  });
}
