import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LanguageLearningPage extends StatelessWidget {
  const LanguageLearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dil Öğrenme")),
      body: Column(
        children: [
          ListTile(
            title: const Text("Kütüphane"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/language/library'),
          ),
          ListTile(
            title: const Text("Quiz Başlat"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/language/quiz'),
          ),
        ],
      ),
    );
  }
}
