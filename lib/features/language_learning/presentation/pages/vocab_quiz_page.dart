// Buraya eksiksiz, entegre edilmiş tam çalışma sürümünüz gelecek.
// Kullanıcı .ogg desteklemek istiyor. Audioplayers .ogg çalabiliyor — mp3'e çevirmen gerekmez.
// Aşağıdaki kod VocabQuizPage + QuizEffectsController entegrasyonunun FINAL halidir.
// QuizEffectsController'ın kendisi ayrı dosyada kalmalı. Burada sadece Quiz Page güncellenmiş halini veriyorum.

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

  // *** EKLENDİ: EFFECTS CONTROLLER ***
  late final QuizEffectsController effects;

  @override
  void initState() {
    super.initState();
    effects = QuizEffectsController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vocabularyControllerProvider.notifier).init().then((_) {
        _nextQuestion();
      });
    });
  }

  @override
  void dispose() {
    effects.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // SORU SEÇME
  // ---------------------------------------------------------------------------
  void _nextQuestion() {
    final ctrl = ref.read(vocabularyControllerProvider.notifier);
    final pool = ctrl.loaded;

    if (pool.isEmpty) {
      setState(() {
        current = null;
        options = [];
      });
      return;
    }

    final sorted = [...pool]
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
      double weight(VocabularyWord w) {
        final days = DateTime.now()
            .difference(w.lastReviewed ?? DateTime(2000))
            .inDays;
        return days + 1;
      }

      final total = candidates.fold<double>(0, (t, w) => t + weight(w));
      double r = Random().nextDouble() * total;

      for (final w in candidates) {
        r -= weight(w);
        if (r <= 0) return w;
      }
      return candidates.last;
    }

    final correct = pickWeighted();

    final rnd = Random();
    final wrongs = <String>{};
    while (wrongs.length < 3 && wrongs.length < pool.length - 1) {
      final candidate = pool[rnd.nextInt(pool.length)];
      if (candidate.turkish != correct.turkish) wrongs.add(candidate.turkish);
    }

    final opts = [correct.turkish, ...wrongs].toList()..shuffle();

    setState(() {
      current = correct;
      options = opts;
      locked = false;
      feedbackMessage = null;
    });
  }

  // ---------------------------------------------------------------------------
  // CEVAP
  // ---------------------------------------------------------------------------
  Future<void> _answer(String ans) async {
    if (locked) return;
    locked = true;

    final correct = current!.turkish;
    final good = ans == correct;

    // Eski feedback sisteminiz hâlâ çalışıyor ama efekt overlay bunun üstüne gelecek.
    setState(() {
      feedbackMessage = good ? 'Doğru!' : 'Yanlış\nDoğru: $correct';
    });

    // *** DOĞRU/YANLIŞ EFFECTS ***
    if (good) {
      await effects.onCorrect();
    } else {
      await effects.onWrong();
    }

    // DB güncellemesi
    if (good) {
      final ctrl = ref.read(vocabularyControllerProvider.notifier);
      final index = ctrl.loaded.indexWhere(
        (w) => w.german == current!.german && w.turkish == current!.turkish,
      );
      if (index != -1) {
        final updated = current!.copyWith(lastReviewed: DateTime.now());
        await ref
            .read(vocabularyControllerProvider.notifier)
            .updateAtListIndex(index, updated);
      }
    }

    await Future.delayed(const Duration(milliseconds: 700));
    _nextQuestion();
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (current == null) {
      return const Center(
        child: Text('Kütüphanede kelime yok veya yükleniyor'),
      );
    }

    return Stack(
      children: [
        Center(
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
                        onPressed: () => _answer(o),
                        child: Text(o, textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: locked ? null : _nextQuestion,
                  child: const Text('Geç'),
                ),
              ],
            ),
          ),
        ),

        if (feedbackMessage != null)
          AnimatedOpacity(
            opacity: feedbackMessage != null ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              color: Colors.black.withOpacity(0.6),
              alignment: Alignment.center,
              child: Text(
                feedbackMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // *** EN ÜSTE EFFECTS OVERLAY ***
        QuizEffectsOverlay(controller: effects),
      ],
    );
  }
}
