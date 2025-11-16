// life_assistant/lib/features/language_learning/presentation/pages/vocab_quiz_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/vocabulary_word.dart';
import '../states/vocabulary_controller.dart';

class VocabQuizPage extends ConsumerStatefulWidget {
  const VocabQuizPage({Key? key}) : super(key: key);

  @override
  ConsumerState<VocabQuizPage> createState() => _VocabQuizPageState();
}

class _VocabQuizPageState extends ConsumerState<VocabQuizPage> {
  VocabularyWord? current;
  List<String> options = [];

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

    final rnd = Random();
    final correct = pool[rnd.nextInt(pool.length)];
    final wrongs = <String>{};
    while (wrongs.length < 3 && wrongs.length < pool.length - 1) {
      final candidate = pool[rnd.nextInt(pool.length)];
      if (candidate.turkish != correct.turkish) wrongs.add(candidate.turkish);
    }
    final opts = [correct.turkish, ...wrongs].toList()..shuffle();
    setState(() {
      current = correct;
      options = opts;
    });
  }

  @override
  void initState() {
    super.initState();
    // If user hasn't opened library (and thus box not init), init to allow quiz
    // This triggers lazy open too.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(vocabularyControllerProvider.notifier)
          .init()
          .then((_) => _nextQuestion());
    });
  }

  void _answer(String ans) {
    final correct = current?.turkish;
    final good = ans == correct;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(good ? 'Doğru' : 'Yanlış - Doğru: $correct')),
    );
    // mark lastReviewed for the word
    if (good) {
      // update lastReviewed
      final ctrl = ref.read(vocabularyControllerProvider.notifier);
      final index = ctrl.loaded.indexWhere(
        (w) => w.german == current!.german && w.turkish == current!.turkish,
      );
      if (index != -1) {
        final updated = current!.copyWith(lastReviewed: DateTime.now());
        // update via repository: we didn't expose update by index in controller, call repo directly
        ref.read(vocabularyRepositoryProvider).update(index, updated);
        // refresh controller list
        ref.read(vocabularyControllerProvider.notifier).init();
      }
    }
    _nextQuestion();
  }

  @override
  Widget build(BuildContext context) {
    if (current == null) {
      return const Center(
        child: Text('Kütüphanede kelime yok veya yükleniyor'),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Almanca: ${current!.german}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ...options.map(
            (o) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton(
                onPressed: () => _answer(o),
                child: Text(o),
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(onPressed: _nextQuestion, child: const Text('Geç')),
        ],
      ),
    );
  }
}
