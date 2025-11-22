import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/vocabulary_word.dart';
import '../states/vocabulary_controller.dart';
import '../states/quiz_effects_controller.dart';

class VocabQuizPage extends ConsumerStatefulWidget {
  const VocabQuizPage({Key? key}) : super(key: key);

  @override
  ConsumerState<VocabQuizPage> createState() => _VocabQuizPageState();
}

class _VocabQuizPageState extends ConsumerState<VocabQuizPage> {
  VocabularyWord? current;
  List<String> options = [];
  bool locked = false;
  String? feedbackMessage;

  // *** YENİ: Quiz'e özel tam liste ***
  List<VocabularyWord> _quizPool = [];

  late final QuizEffectsController effects;

  @override
  void initState() {
    super.initState();
    effects = QuizEffectsController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Önce veritabanının açık olduğundan emin olalım
      ref.read(vocabularyControllerProvider.notifier).init().then((_) {
        _loadAllWordsAndStart(); // <--- DEĞİŞİKLİK BURADA
      });
    });
  }

  // Yeni Başlatma Fonksiyonu
  void _loadAllWordsAndStart() {
    final ctrl = ref.read(vocabularyControllerProvider.notifier);

    // Controller'dan sadece 10 taneyi değil, HEPSİNİ istiyoruz
    final allWords = ctrl.getQuizPool();

    setState(() {
      _quizPool = allWords; // Havuzu doldur
    });

    _nextQuestion();
  }

  void _nextQuestion() {
    // ARTIK 'ctrl.loaded' YERİNE '_quizPool' KULLANIYORUZ
    if (_quizPool.isEmpty) {
      setState(() {
        current = null;
        options = [];
      });
      return;
    }

    // Sıralama mantığı aynı, sadece kaynak değişti (_quizPool)
    final sorted = [..._quizPool]
      ..sort((a, b) {
        final t1 = a.lastReviewed;
        final t2 = b.lastReviewed;
        if (t1 == null && t2 != null) return -1;
        if (t1 != null && t2 == null) return 1;
        if (t1 == null && t2 == null) return 0;
        return t1!.compareTo(t2!);
      });

    final candidateCount = min(20, sorted.length);
    final candidates = sorted.take(candidateCount).toList();

    VocabularyWord pickWeighted() {
      // (Ağırlık hesaplama kodu aynen kalıyor...)
      double weight(VocabularyWord w) {
        final days = DateTime.now()
            .difference(w.lastReviewed ?? DateTime(2000))
            .inDays;
        return (days + 1).toDouble();
      }

      final total = candidates.fold<double>(0, (t, w) => t + weight(w));
      if (total <= 0) return candidates.first;

      double r = Random().nextDouble() * total;
      for (final w in candidates) {
        r -= weight(w);
        if (r <= 0) return w;
      }
      return candidates.last;
    }

    final correct = pickWeighted();

    // Yanlış şıkları seçerken de _quizPool kullanıyoruz
    final rnd = Random();
    final wrongs = <String>{};
    int safety = 0;
    while (wrongs.length < 3 &&
        wrongs.length < _quizPool.length - 1 &&
        safety < 100) {
      final candidate = _quizPool[rnd.nextInt(_quizPool.length)];
      if (candidate.turkish != correct.turkish) {
        wrongs.add(candidate.turkish);
      }
      safety++;
    }

    final opts = [correct.turkish, ...wrongs].toList()..shuffle();

    if (mounted) {
      setState(() {
        current = correct;
        options = opts;
        locked = false;
        feedbackMessage = null;
      });
    }
  }

  Future<void> _answer(String ans) async {
    if (locked) return;
    locked = true;

    final correct = current!.turkish;
    final good = ans == correct;

    setState(() {
      feedbackMessage = good ? 'Doğru!' : 'Yanlış\nDoğru: $correct';
    });

    if (good) {
      await effects.onCorrect();
    } else {
      await effects.onWrong();
    }

    // GÜNCELLEME MANTIĞI:
    // Doğru bildiğinde hem veritabanını hem de elimizdeki _quizPool'u güncellemeliyiz
    // ki bir sonraki soruda bu kelime en sona gitsin.
    if (good && current != null) {
      final ctrl = ref.read(vocabularyControllerProvider.notifier);
      final updated = current!.copyWith(lastReviewed: DateTime.now());

      // 1. Veritabanını güncelle (Index bulmaya gerek yok, repo anahtar kelime/id ile bulmalı ama senin yapında global index kullanıyorduk)
      // DİKKAT: Senin yapında updateAtListIndex listedeki sıraya göre çalışıyordu.
      // Ancak _quizPool karışık olduğu için Repository'de 'update' metodun muhtemelen index değil KEY veya ID beklemeli.
      // Eğer ID yoksa, kelimenin kendisini bulup değiştirmemiz lazım.

      // Geçici Çözüm (Senin mevcut yapına uygun):
      // DB'deki gerçek indexini bulmamız lazım.
      // Bu biraz maliyetli ama 100-500 kelime için sorun olmaz.
      final globalIndex = ctrl.getQuizPool().indexWhere(
        (w) => w.german == current!.german,
      );

      if (globalIndex != -1) {
        await ctrl.updateAtListIndex(globalIndex, updated);

        // 2. Yerel Quiz Havuzunu Güncelle (Önemli! Yoksa quiz bitene kadar eski tarihli kalır)
        final localIndex = _quizPool.indexWhere(
          (w) => w.german == current!.german,
        );
        if (localIndex != -1) {
          _quizPool[localIndex] = updated;
        }
      }
    }

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 700));
    _nextQuestion();
  }

  // ---------------------------------------------------------------------------
  // UI BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (current == null) {
      return const Center(
        child: Text('Kütüphanede kelime yok veya yükleniyor...'),
      );
    }

    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Almanca: ${current!.german}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  ...options.map(
                    (o) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: _getButtonColor(o),
                          ),
                          onPressed: () => _answer(o),
                          child: Text(
                            o,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    onPressed: locked ? null : _nextQuestion,
                    child: const Text('Atla / Geç'),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Eski Feedback Overlay (Basit metin)
        if (feedbackMessage != null)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: feedbackMessage != null ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: Colors.black.withOpacity(0.6),
                alignment: Alignment.center,
                child: Text(
                  feedbackMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    color: feedbackMessage!.startsWith('Doğru')
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        // *** YENİ EFEKT KATMANI (Ateş, Streak, Ses) ***
        QuizEffectsOverlay(controller: effects),
      ],
    );
  }

  // Buton rengini duruma göre değiştirme (Opsiyonel görsel iyileştirme)
  Color? _getButtonColor(String optionText) {
    if (!locked) return null; // Varsayılan renk
    if (current != null && optionText == current!.turkish) {
      return Colors.green; // Doğru cevap her zaman yeşil yanar
    }
    if (feedbackMessage != null &&
        !feedbackMessage!.startsWith('Doğru') &&
        optionText != current!.turkish) {
      // Yanlış basılanı belirtmek isterseniz burayı kullanabilirsiniz, şu an sade bırakıldı.
    }
    return null;
  }
}
