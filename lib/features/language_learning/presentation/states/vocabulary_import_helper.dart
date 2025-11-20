import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // for debugPrint
import '../../domain/vocabulary_word.dart';

class VocabularyImportHelper {
  /// Kullanıcıdan CSV dosyası seçmesini ister ve parse edilmiş listeyi döner.
  Future<List<VocabularyWord>> pickAndParseCsv() async {
    try {
      // 1. Dosya Seçiciyi Aç
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result == null) {
        // Kullanıcı iptal etti
        return [];
      }

      // 2. Dosyayı Oku
      String csvString;
      if (kIsWeb) {
        // Web için (byte array'den stringe)
        final bytes = result.files.single.bytes;
        if (bytes == null) return [];
        csvString = utf8.decode(bytes);
      } else {
        // Mobil için (path üzerinden)
        final path = result.files.single.path;
        if (path == null) return [];
        final file = File(path);
        csvString = await file.readAsString();
      }

      // 3. CSV Parse İşlemi (Satır satır ayır)
      // List<List<dynamic>> döner -> [[German, Turkish, Type], [Hund, Köpek, noun], ...]
      List<List<dynamic>> rows = const CsvToListConverter().convert(
        csvString,
        fieldDelimiter:
            ',', // Excel genelde noktalı virgül (;) de kullanabilir, buraya dikkat.
        eol: '\n',
      );

      List<VocabularyWord> newWords = [];

      // Başlık satırı (Header) varsa atlamak için i=1 yapabilirsin.
      // Biz güvenli olsun diye döngüde kontrol edelim.
      for (var row in rows) {
        if (row.isEmpty) continue;
        if (row.length < 2) continue; // En az Almanca ve Türkçe olmalı

        final german = row[0].toString().trim();
        final turkish = row[1].toString().trim();

        // Header satırı geldiyse atla
        if (german.toLowerCase() == 'german' ||
            german.toLowerCase() == 'almanca')
          continue;

        // Tür belirleme (Varsayılan: Noun)
        VocabularyType type = VocabularyType.noun;
        if (row.length > 2) {
          final typeStr = row[2].toString().trim().toLowerCase();
          if (typeStr.contains('verb') || typeStr.contains('fiil')) {
            type = VocabularyType.verb;
          } else if (typeStr.contains('adj') || typeStr.contains('sıfat')) {
            type = VocabularyType.adjective;
          }
        }

        // Yeni kelimeyi oluştur
        newWords.add(
          VocabularyWord(
            german: german,
            turkish: turkish,
            // lastReviewed'u çok eski bir tarih yapıyoruz ki Quiz algoritması hemen sorsun.
            lastReviewed: DateTime(2000),
            type: type,
            conjugations:
                null, // CSV'den karmaşık yapı çekmek zordur, şimdilik null
          ),
        );
      }

      return newWords;
    } catch (e) {
      debugPrint("CSV Import Hatası: $e");
      rethrow; // Hatayı UI'da göstermek için fırlat
    }
  }
}
