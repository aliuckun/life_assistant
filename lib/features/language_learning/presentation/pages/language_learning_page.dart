import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../states/vocabulary_controller.dart'; // Controller path
import '../states/vocabulary_import_helper.dart'; // Helper path

class LanguageLearningPage extends ConsumerWidget {
  const LanguageLearningPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dil Öğrenme")),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.library_books, color: Colors.blue),
            title: const Text("Kütüphane"),
            subtitle: const Text("Kelimelerini düzenle"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/language/library'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.school, color: Colors.green),
            title: const Text("Quiz Başlat"),
            subtitle: const Text("Kendini sına"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/language/quiz'),
          ),
          const Divider(),

          // --- YENİ CSV IMPORT BUTONU ---
          ListTile(
            leading: const Icon(Icons.upload_file, color: Colors.orange),
            title: const Text("Toplu Kelime Ekle (CSV)"),
            subtitle: const Text("Dosyadan içe aktar"),
            onTap: () async {
              // İşlemi başlat
              await _handleImport(context, ref);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    final helper = VocabularyImportHelper();

    try {
      // Yükleme göstergesi
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dosya seçiliyor...')));

      // Dosyayı seç ve parse et
      final newWords = await helper.pickAndParseCsv();

      if (newWords.isNotEmpty) {
        // Controller üzerinden kaydet
        await ref
            .read(vocabularyControllerProvider.notifier)
            .addAllWords(newWords);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${newWords.length} yeni kelime başarıyla eklendi!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dosya seçilmedi veya boş.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
