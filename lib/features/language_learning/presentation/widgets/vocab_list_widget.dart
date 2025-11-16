// life_assistant/lib/features/language_learning/presentation/widgets/vocab_list_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/vocabulary_word.dart';
import '../states/vocabulary_controller.dart';

class VocabListWidget extends ConsumerStatefulWidget {
  const VocabListWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<VocabListWidget> createState() => _VocabListWidgetState();
}

class _VocabListWidgetState extends ConsumerState<VocabListWidget> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Do not call init here — parent page triggers init when tab selected.
  }

  void _onScroll() {
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels != 0) {
        // bottom
        ref.read(vocabularyControllerProvider.notifier).loadMore();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: _AddWordForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vocabularyControllerProvider);
    final ctrl = ref.read(vocabularyControllerProvider.notifier);
    final items = ctrl.loaded;

    if (state.isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError) {
      return Center(child: Text('Hata: ${state.error}'));
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddModal,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async => await ctrl.init(),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: items.length + (ctrl.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= items.length) {
              // loader tile
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final word = items[index];
            return Dismissible(
              key: ValueKey(word.german + word.turkish + index.toString()),
              direction: DismissDirection.startToEnd,
              onDismissed: (_) async {
                await ctrl.deleteAtListIndex(index);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Kelime silindi')));
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 16),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: ListTile(
                title: Text(word.german),
                subtitle: Text(word.turkish),
                trailing: Text(word.type.name),
                onTap: () {
                  // show detail / conjugations
                  showModalBottomSheet(
                    context: context,
                    builder: (_) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Almanca: ${word.german}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('Türkçe: ${word.turkish}'),
                            Text('Son tekrar: ${word.lastReviewed.toLocal()}'),
                            if (word.conjugations != null &&
                                word.conjugations!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Çekimler:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...word.conjugations!.entries.map(
                                (e) => Text('${e.key}: ${e.value}'),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AddWordForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddWordForm> createState() => _AddWordFormState();
}

class _AddWordFormState extends ConsumerState<_AddWordForm> {
  final _formKey = GlobalKey<FormState>();
  final _germanCtrl = TextEditingController();
  final _turkishCtrl = TextEditingController();
  VocabularyType _type = VocabularyType.noun;
  final _conjugationKeyCtrl = TextEditingController();
  final _conjugationValueCtrl = TextEditingController();
  final Map<String, String> _conj = {};

  @override
  void dispose() {
    _germanCtrl.dispose();
    _turkishCtrl.dispose();
    _conjugationKeyCtrl.dispose();
    _conjugationValueCtrl.dispose();
    super.dispose();
  }

  void _addConjugation() {
    final k = _conjugationKeyCtrl.text.trim();
    final v = _conjugationValueCtrl.text.trim();
    if (k.isEmpty || v.isEmpty) return;
    setState(() {
      _conj[k] = v;
      _conjugationKeyCtrl.clear();
      _conjugationValueCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final word = VocabularyWord(
      german: _germanCtrl.text.trim(),
      turkish: _turkishCtrl.text.trim(),
      lastReviewed: DateTime.now(),
      type: _type,
      conjugations: _conj.isEmpty ? null : Map.from(_conj),
    );
    await ref.read(vocabularyControllerProvider.notifier).addWord(word);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              'Kelime Ekle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _germanCtrl,
                    decoration: const InputDecoration(labelText: 'Almanca'),
                    validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
                  ),
                  TextFormField(
                    controller: _turkishCtrl,
                    decoration: const InputDecoration(labelText: 'Türkçe'),
                    validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
                  ),
                  DropdownButtonFormField<VocabularyType>(
                    value: _type,
                    items: VocabularyType.values
                        .map(
                          (t) =>
                              DropdownMenuItem(value: t, child: Text(t.name)),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _type = v ?? VocabularyType.noun),
                    decoration: const InputDecoration(labelText: 'Tür'),
                  ),
                  const SizedBox(height: 12),
                  if (_type == VocabularyType.verb) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _conjugationKeyCtrl,
                            decoration: const InputDecoration(
                              hintText: 'anahtar (örn: ich, present)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _conjugationValueCtrl,
                            decoration: const InputDecoration(
                              hintText: 'çekim',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addConjugation,
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: _conj.entries
                          .map((e) => Chip(label: Text('${e.key}: ${e.value}')))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _submit, child: const Text('Ekle')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
