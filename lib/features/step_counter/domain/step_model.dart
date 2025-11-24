// -----------------------------------------------------------------------------
// DOSYA: lib/features/step_counter/domain/step_model.dart
// KATMAN: Domain
// AÇIKLAMA: Hive Code Generation kullanan model.
// -----------------------------------------------------------------------------

import 'package:hive/hive.dart';

// Bu satır şu an IDE'de kırmızı yanabilir, build_runner çalışınca düzelir.
part 'step_model.g.dart';

@HiveType(typeId: 14) // Benzersiz Type ID (0 başka bir modeldeyse 1 ver)
class DailySteps extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final int steps;

  DailySteps({required this.date, required this.steps});
}
