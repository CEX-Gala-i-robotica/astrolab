import 'package:flutter/services.dart' show rootBundle;

import '../data/curriculum_parser.dart';
import '../models/lesson_models.dart';

/// Loads [Module] from `assets/curriculum/module_{n}.json`.
///
/// Nu folosește cache persistent: după ce modifici JSON-ul, un **restart complet**
/// al aplicației (`Stop` apoi `Run`) încarcă noul conținut (assetele nu se
/// reîmpachetează mereu la hot reload).
class CurriculumRepository {
  CurriculumRepository._();

  static Future<Module> loadModule(int moduleNumber) async {
    final path = 'assets/curriculum/module_$moduleNumber.json';
    final raw = await rootBundle.loadString(path);
    final module = CurriculumParser.parseModuleString(raw);

    if (module.finalQuiz.isNotEmpty) return module;

    try {
      final quizRaw = await rootBundle.loadString(
        'assets/curriculum/module_${module.number}_final_quiz.json',
      );
      return Module(
        number: module.number,
        title: module.title,
        chapters: module.chapters,
        finalQuiz: CurriculumParser.parseQuizString(quizRaw),
      );
    } catch (_) {
      return module;
    }
  }
}
