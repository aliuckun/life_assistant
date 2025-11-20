import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- UI: OVERLAY WIDGET ---
class QuizEffectsOverlay extends StatelessWidget {
  final QuizEffectsController controller;

  const QuizEffectsOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        // PointerEvents.none ile tıklamaları arkaya geçiriyoruz
        return IgnorePointer(
          ignoring: true,
          child: Stack(
            children: [
              // --- DÜZELTİLEN KISIM: STREAK GÖSTERGESİ ---
              if (controller.showStreakUI)
                Positioned(
                  top: 0, // En tepeye sabitledik (eskiden 80'di)
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    // Çentik/Notch alanını korur
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 10,
                      ), // Tepeden hafif boşluk
                      child: AnimatedOpacity(
                        opacity: controller.showStreakUI ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "🔥 STREAK 🔥",
                              style: TextStyle(
                                fontSize:
                                    14, // Yazıyı biraz küçülttük ki yer kaplamasın
                                fontWeight: FontWeight.w900,
                                color: Colors.orange[300],
                                letterSpacing: 4,
                                shadows: const [
                                  Shadow(blurRadius: 5, color: Colors.black),
                                ],
                              ),
                            ),
                            Text(
                              "${controller.streak}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 40, // Rakam boyutunu optimize ettik
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10.0,
                                    color: Colors.black,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // ---------------------------------------------

              // Alev Animasyonu (Düzeltilmiş Clamp'li versiyon)
              if (controller.showFire)
                Center(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('fire_${controller.streak}'),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.5 + (value * 0.8),
                        child: Opacity(
                          opacity: value.clamp(0.0, 1.0), // Hata önleyici clamp
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: _getFireColors(controller.fireLevel),
                                stops: const [0.4, 0.7, 1.0],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _getFireEmoji(controller.fireLevel),
                                style: const TextStyle(fontSize: 90),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Hata Animasyonu (Kocaman X)
              if (controller.showFailAnimation)
                Center(
                  child: TweenAnimationBuilder<double>(
                    key: const ValueKey('fail_animation'),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.bounceOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (value * 0.4),
                        child: Opacity(
                          opacity: (1.0 - (value * 0.2)).clamp(0.0, 1.0),
                          child: const Text(
                            '❌',
                            style: TextStyle(
                              fontSize: 120,
                              shadows: [
                                Shadow(blurRadius: 20, color: Colors.black),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Color> _getFireColors(int level) {
    switch (level) {
      case 1:
        return [
          Colors.yellow.withOpacity(0.5),
          Colors.orange.withOpacity(0.3),
          Colors.transparent,
        ];
      case 2:
        return [
          Colors.orange.withOpacity(0.6),
          Colors.deepOrange.withOpacity(0.4),
          Colors.transparent,
        ];
      case 3:
        return [
          Colors.red.withOpacity(0.7),
          Colors.purple.withOpacity(0.5),
          Colors.transparent,
        ];
      default:
        return [
          Colors.white.withOpacity(0.2),
          Colors.transparent,
          Colors.transparent,
        ];
    }
  }

  String _getFireEmoji(int level) {
    if (level >= 3) return '👿';
    if (level == 2) return '🔥';
    if (level == 1) return '⚡';
    return '✨';
  }
}

// --- LOGIC: CONTROLLER ---
class QuizEffectsController extends ChangeNotifier {
  final List<AudioPlayer> _activePlayers = [];

  int streak = 0;
  bool showStreakUI = false;
  bool showFire = false;
  bool showFailAnimation = false;
  int fireLevel = 0;

  /// Yeni bir player oluşturur
  AudioPlayer _createPlayer() {
    final p = AudioPlayer();

    // --- DÜZELTİLEN KISIM BURASI ---
    p.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          // HATA ÇÖZÜMÜ: 'mixWithOthers' kullanmak için 'playback' seçilmeli.
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
      ),
    );
    // ------------------------------

    _activePlayers.add(p);

    p.onPlayerComplete.listen((_) {
      _disposePlayer(p);
    });

    return p;
  }

  void _disposePlayer(AudioPlayer p) {
    p.dispose();
    _activePlayers.remove(p);
  }

  Future<void> onCorrect() async {
    streak++;
    showStreakUI = true;
    showFire = true;

    // Seviye
    if (streak >= 10)
      fireLevel = 3;
    else if (streak >= 5)
      fireLevel = 2;
    else if (streak >= 2)
      fireLevel = 1;
    else
      fireLevel = 0;

    notifyListeners();

    // Animasyonu kapatma zamanlayıcısı (Ses hatası olsa bile çalışması için try dışında tutuyoruz)
    // Sadece görüntü temizliği için timer başlat:
    _scheduleFireCleanup();

    // Sesleri Çal
    try {
      if (streak == 1) {
        await _playMulti([
          "Killstreak_SFX_Multikill_Point_First.ogg",
          "Killstreak_SFX_Multikill_Melody_First.ogg",
        ]);
      } else if (streak == 2) {
        await _playMulti([
          "Killstreak_SFX_Multikill_Point_Double.ogg",
          "Killstreak_SFX_Multikill_Melody_Double.ogg",
        ]);
      } else if (streak == 3) {
        await _playMulti([
          "Killstreak_SFX_Multikill_Point_Triple.ogg",
          "Killstreak_SFX_Multikill_Melody_Triple.ogg",
        ]);
      } else if (streak == 4) {
        await _playMulti([
          "Killstreak_SFX_Multikill_Point_Quadra.ogg",
          "Killstreak_SFX_Multikill_Melody_Quadra.ogg",
        ]);
      } else if (streak >= 5) {
        await _playMulti([
          "Killstreak_SFX_Multikill_Point_Penta.ogg",
          "Killstreak_SFX_Multikill_Melody_Penta.ogg",
        ]);
      }
    } catch (e) {
      debugPrint("Ses hatası (onCorrect): $e");
      // Hata olsa bile uygulama çökmesin
    }
  }

  void _scheduleFireCleanup() {
    // Eski timer varsa iptal etmek yerine basit delay kullanıyoruz,
    // UI her zaman son gelen emri dinler.
    Future.delayed(const Duration(milliseconds: 800), () {
      // Eğer kullanıcı çok hızlı basıyorsa ve hala streak devam ediyorsa hemen kapatma
      // Ama basitlik adına kapatıp tekrar açılması daha iyi feedback verir.
      showFire = false;
      // Streak UI bir süre daha kalsın istersek buraya if koyabiliriz ama şimdilik kapatalım
      notifyListeners();
    });
  }

  Future<void> onWrong() async {
    streak = 0;
    fireLevel = 0;
    showFire = false;
    showStreakUI = false;
    showFailAnimation = true;
    notifyListeners();

    // Cleanup Timer
    Future.delayed(const Duration(milliseconds: 800), () {
      showFailAnimation = false;
      notifyListeners();
    });

    try {
      await _playSingle("Killstreak_SFX_Assist.ogg");
    } catch (e) {
      debugPrint("Ses hatası (onWrong): $e");
    }
  }

  Future<void> _playSingle(String file) async {
    final p = _createPlayer();
    await p.play(AssetSource('audio/$file'));
  }

  Future<void> _playMulti(List<String> files) async {
    for (final f in files) {
      final p = _createPlayer();
      // await p.play(...) kullanmıyoruz, hepsi aynı anda başlasın
      p.play(AssetSource('audio/$f')).catchError((e) {
        debugPrint("Dosya oynatılamadı: $f -> $e");
      });
    }
  }

  @override
  void dispose() {
    for (var p in _activePlayers) {
      p.dispose();
    }
    _activePlayers.clear();
    super.dispose();
  }
}
