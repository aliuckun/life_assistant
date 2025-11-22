import 'dart:convert'; // UTF-8 ve Latin1 için gerekli
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
        return [];
      }

      String csvString;

      // 2. Dosyayı Akıllıca Oku (Encoding Fix)
      if (kIsWeb) {
        final bytes = result.files.single.bytes;
        if (bytes == null) return [];
        csvString = utf8.decode(bytes, allowMalformed: true);
      } else {
        final path = result.files.single.path;
        if (path == null) return [];
        final file = File(path);

        // Önce byte (sayısal veri) olarak oku
        final bytes = await file.readAsBytes();

        try {
          // Önce standart UTF-8 dene
          csvString = utf8.decode(bytes);
        } catch (e) {
          debugPrint("UTF-8 başarısız, Windows-1252/Latin1 deneniyor...");
          // Hata verirse Latin1 (Windows ANSI) dene.
          // Almanca karakterleri (ü,ö,ä) bu kurtarır.
          csvString = latin1.decode(bytes);
        }
      }

      // 3. CSV Parse İşlemi
      List<List<dynamic>> rows = const CsvToListConverter().convert(
        csvString,
        fieldDelimiter: ',',
        eol: '\n',
      );

      List<VocabularyWord> newWords = [];

      for (var row in rows) {
        if (row.isEmpty) continue;
        if (row.length < 2) continue;

        final german = row[0].toString().trim();
        final turkish = row[1].toString().trim();

        // Başlık satırını atla
        if (german.toLowerCase().contains('german') ||
            german.toLowerCase() == 'almanca')
          continue;

        // Tür belirleme
        VocabularyType type = VocabularyType.noun;
        if (row.length > 2) {
          final typeStr = row[2].toString().trim().toLowerCase();
          if (typeStr.contains('verb') || typeStr.contains('fiil')) {
            type = VocabularyType.verb;
          } else if (typeStr.contains('adj') || typeStr.contains('sıfat')) {
            type = VocabularyType.adjective;
          }
        }

        newWords.add(
          VocabularyWord(
            german: german,
            turkish: turkish,
            lastReviewed: DateTime(
              2000,
            ), // Çözüm: Çok eski bir tarih veriyoruz, // Hiç çözülmemiş olarak işaretle
            type: type,
            conjugations: null,
          ),
        );
      }

      return newWords;
    } catch (e) {
      debugPrint("CSV Import Hatası: $e");
      rethrow;
    }
  }
}
