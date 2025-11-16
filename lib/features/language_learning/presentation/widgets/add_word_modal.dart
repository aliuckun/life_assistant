// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../domain/vocabulary_word.dart';
// import '../states/vocabulary_controller.dart';

// void showAddWordModal(BuildContext context, WidgetRef ref) {
//   final german = TextEditingController();
//   final turkish = TextEditingController();
//   final conjugation = TextEditingController();
//   String type = 'noun';

//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     builder: (_) {
//       return Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: german,
//               decoration: const InputDecoration(labelText: "Almanca"),
//             ),
//             TextField(
//               controller: turkish,
//               decoration: const InputDecoration(labelText: "Türkçe"),
//             ),
//             DropdownButtonFormField(
//               value: type,
//               items: const [
//                 DropdownMenuItem(value: 'noun', child: Text("İsim")),
//                 DropdownMenuItem(value: 'verb', child: Text("Fiil")),
//                 DropdownMenuItem(value: 'adj', child: Text("Sıfat")),
//               ],
//               onChanged: (v) => type = v!,
//             ),
//             if (type == 'verb')
//               TextField(
//                 controller: conjugation,
//                 decoration: const InputDecoration(labelText: "Fiil Çekimi"),
//               ),

//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () {
//                 final word = VocabularyWord(
//                   german: german.text,
//                   turkish: turkish.text,
//                   type: type,
//                   lastReviewed: DateTime.now(),
//                   conjugation: type == 'verb' ? conjugation.text : null,
//                 );

//                 ref.read(vocabularyProvider.notifier).addWord(word);
//                 Navigator.pop(context);
//               },
//               child: const Text("Ekle"),
//             ),
//           ],
//         ),
//       );
//     },
//   );
// }
