// life_assistant/lib/features/language_learning/presentation/pages/vocabulary_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../states/vocabulary_controller.dart';
import '../widgets/vocab_list_widget.dart';
import 'vocab_quiz_page.dart';

class VocabularyPage extends ConsumerStatefulWidget {
  const VocabularyPage({Key? key}) : super(key: key);

  @override
  ConsumerState<VocabularyPage> createState() => _VocabularyPageState();
}

class _VocabularyPageState extends ConsumerState<VocabularyPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Do not init repository here — we want lazy page-level init when user opens library tab.
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onLibraryOpened() {
    // initialize only when library tab is selected
    ref.read(vocabularyControllerProvider.notifier).init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dil Modülü'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (i) {
            if (i == 0) _onLibraryOpened();
          },
          tabs: const [
            Tab(text: 'Kütüphane'),
            Tab(text: 'Quiz'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Library
          VocabListWidget(),
          // Quiz
          VocabQuizPage(),
        ],
      ),
    );
  }
}
