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

  // Ses ve Efekt Kontrolcüsü
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
  // SORU SEÇME (Spaced Repetition Mantığı)
  // ---------------------------------------------------------------------------
  void _nextQuestion() {
    // 1. Havuzu Yükle
    final ctrl = ref.read(vocabularyControllerProvider.notifier);
    // NOT: ctrl.loaded getter'ının güncel listeyi verdiğinden emin olun.
    final pool = ctrl.loaded;

    if (pool.isEmpty) {
      setState(() {
        current = null;
        options = [];
      });
      return;
    }

    // 2. Sıralama: Hiç çözülmemişler (null) veya tarihi en eski olanlar başa gelir.
    // Tarihi "Bugün" olanlar (az önce çözdükleriniz) en sona gider.
    final sorted = [...pool]
      ..sort((a, b) {
        final t1 = a.lastReviewed;
        final t2 = b.lastReviewed;

        if (t1 == null && t2 != null) return -1; // t1 öncelikli
        if (t1 != null && t2 == null) return 1; // t2 öncelikli
        if (t1 == null && t2 == null) return 0;
        return t1!.compareTo(t2!); // Eskiden yeniye sırala
      });

    // İlk 20 aday arasından seçim yap (Aşırı tekrarı önlemek için havuz genişletildi)
    final candidateCount = min(20, sorted.length);
    final candidates = sorted.take(candidateCount).toList();

    // 3. Ağırlıklı Rastgele Seçim
    VocabularyWord pickWeighted() {
      double weight(VocabularyWord w) {
        // Eğer hiç çözülmediyse (null) çok yüksek ağırlık ver (9000+)
        // Çözüldüyse geçen gün sayısı kadar ağırlık ver.
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

    // Yanlış şıkları seç
    final rnd = Random();
    final wrongs = <String>{};
    // Sonsuz döngüye girmemesi için güvenlik limiti (100 deneme)
    int safety = 0;
    while (wrongs.length < 3 &&
        wrongs.length < pool.length - 1 &&
        safety < 100) {
      final candidate = pool[rnd.nextInt(pool.length)];
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

  // ---------------------------------------------------------------------------
  // CEVAP VE GÜNCELLEME
  // ---------------------------------------------------------------------------
  Future<void> _answer(String ans) async {
    if (locked) return;
    locked = true;

    final correct = current!.turkish;
    final good = ans == correct;

    setState(() {
      feedbackMessage = good ? 'Doğru!' : 'Yanlış\nDoğru: $correct';
    });

    // --- SES VE EFEKTLER ---
    if (good) {
      await effects.onCorrect();
    } else {
      await effects.onWrong();
    }

    // --- VERİTABANI GÜNCELLEMESİ (SORUNUN ÇÖZÜMÜ BURADA) ---
    if (good && current != null) {
      final ctrl = ref.read(vocabularyControllerProvider.notifier);

      // String karşılaştırmalarında .trim() ve lowercase kullanarak hata payını azaltıyoruz.
      final index = ctrl.loaded.indexWhere(
        (w) =>
            w.german.trim() == current!.german.trim() &&
            w.turkish.trim() == current!.turkish.trim(),
      );

      if (index != -1) {
        debugPrint(
          "✅ Kelime bulundu (Index: $index). Güncelleniyor: ${current!.german}",
        );

        final updated = current!.copyWith(lastReviewed: DateTime.now());

        // State ve DB güncellemesi
        await ctrl.updateAtListIndex(index, updated);
      } else {
        debugPrint(
          "⚠️ HATA: Kelime listede bulunamadı! Güncelleme yapılamadı. Aranan: ${current!.german}",
        );
        // Buraya düşüyorsa 'current' ile listedeki veri arasında fark vardır (boşluk, harf hatası vb).
      }
    }

    if (!mounted) return;

    // Kullanıcının geri bildirimi görmesi için bekleme
    await Future.delayed(const Duration(milliseconds: 700));

    // Bir sonraki soruya geç
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
