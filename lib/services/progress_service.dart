import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/lesson_models.dart';
import 'curriculum_repository.dart';

class ProgressService {
  static const String _progressKey = 'user_progress';
  static const int _firstModuleNumber = 1;

  static String _moduleFinalQuizKey(int moduleNumber) =>
      'module_${moduleNumber}_final_quiz';

  static String _lessonExerciseKey(
    int moduleNumber,
    int chapterNumber,
    int lessonIndex,
  ) =>
      'module_${moduleNumber}_chapter_${chapterNumber}_lesson_${lessonIndex}_exercise';

  // Salvează progresul pentru o lecție specifică
  static Future<void> markLessonComplete(
    int moduleNumber,
    int chapterNumber,
    int lessonIndex,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final progress = await getProgress();

    final key =
        'module_${moduleNumber}_chapter_${chapterNumber}_lesson_$lessonIndex';
    progress[key] = true;

    await prefs.setString(_progressKey, jsonEncode(progress));
  }

  // Salvează rezultatul quiz-ului
  static Future<void> saveQuizResult(
    int moduleNumber,
    int chapterNumber,
    int correctAnswers,
    int totalQuestions,
    List<QuizAttempt> attempts,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final progress = await getProgress();

    final key = 'module_${moduleNumber}_chapter_${chapterNumber}_quiz';
    final pct = totalQuestions == 0
        ? 0
        : (correctAnswers / totalQuestions * 100).round();
    progress[key] = {
      'completed': true,
      'correct': correctAnswers,
      'total': totalQuestions,
      'percentage': pct,
      'passed': pct >= 75,
      'timestamp': DateTime.now().toIso8601String(),
      'attempts': attempts.map((a) => a.toJson()).toList(),
    };

    await prefs.setString(_progressKey, jsonEncode(progress));
  }

  static Future<void> saveModuleFinalQuizResult(
    int moduleNumber,
    int correctAnswers,
    int totalQuestions,
    List<QuizAttempt> attempts,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final progress = await getProgress();

    final pct = totalQuestions == 0
        ? 0
        : (correctAnswers / totalQuestions * 100).round();
    progress[_moduleFinalQuizKey(moduleNumber)] = {
      'completed': true,
      'correct': correctAnswers,
      'total': totalQuestions,
      'percentage': pct,
      'passed': pct >= 75,
      'timestamp': DateTime.now().toIso8601String(),
      'attempts': attempts.map((a) => a.toJson()).toList(),
    };

    await prefs.setString(_progressKey, jsonEncode(progress));
  }

  static Future<void> saveLessonExerciseResult(
    int moduleNumber,
    int chapterNumber,
    int lessonIndex,
    int correctAnswers,
    int totalQuestions,
    List<QuizAttempt> attempts,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final progress = await getProgress();

    final pct = totalQuestions == 0
        ? 0
        : (correctAnswers / totalQuestions * 100).round();
    progress[_lessonExerciseKey(moduleNumber, chapterNumber, lessonIndex)] = {
      'completed': true,
      'correct': correctAnswers,
      'total': totalQuestions,
      'percentage': pct,
      'passed': pct >= 75,
      'timestamp': DateTime.now().toIso8601String(),
      'attempts': attempts.map((a) => a.toJson()).toList(),
    };

    await prefs.setString(_progressKey, jsonEncode(progress));
  }

  // Verifică dacă o lecție este completă
  static Future<bool> isLessonComplete(
    int moduleNumber,
    int chapterNumber,
    int lessonIndex,
  ) async {
    final progress = await getProgress();
    final key =
        'module_${moduleNumber}_chapter_${chapterNumber}_lesson_$lessonIndex';
    return progress[key] == true;
  }

  static Future<Map<String, dynamic>?> getLessonExerciseResult(
    int moduleNumber,
    int chapterNumber,
    int lessonIndex,
  ) async {
    final progress = await getProgress();
    final result =
        progress[_lessonExerciseKey(moduleNumber, chapterNumber, lessonIndex)];
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    return null;
  }

  static Future<bool> hasLessonExerciseAttempt(
    int moduleNumber,
    int chapterNumber,
    int lessonIndex,
  ) async {
    final result = await getLessonExerciseResult(
      moduleNumber,
      chapterNumber,
      lessonIndex,
    );
    return result != null && result['completed'] == true;
  }

  static Future<bool> isLessonExercisePassed(
    int moduleNumber,
    int chapterNumber,
    int lessonIndex,
  ) async {
    final result = await getLessonExerciseResult(
      moduleNumber,
      chapterNumber,
      lessonIndex,
    );
    if (result == null) return false;
    final p = result['percentage'];
    if (p is num) return p >= 75;
    return result['passed'] == true;
  }

  /// Quiz încercat (există rezultat salvat).
  static Future<bool> hasQuizAttempt(
    int moduleNumber,
    int chapterNumber,
  ) async {
    final progress = await getProgress();
    final key = 'module_${moduleNumber}_chapter_${chapterNumber}_quiz';
    return progress[key] != null && progress[key]['completed'] == true;
  }

  /// Quiz promovat (≥ 75%) — deblochează următorul capitol și bulina verde.
  static Future<bool> isQuizPassed(int moduleNumber, int chapterNumber) async {
    final r = await getQuizResult(moduleNumber, chapterNumber);
    if (r == null) return false;
    final p = r['percentage'];
    if (p is num) return p >= 75;
    return r['passed'] == true;
  }

  /// Alias pentru UI: „quiz finalizat cu succes”.
  static Future<bool> isQuizComplete(
    int moduleNumber,
    int chapterNumber,
  ) async {
    return isQuizPassed(moduleNumber, chapterNumber);
  }

  // Obține scorul quiz-ului
  static Future<Map<String, dynamic>?> getQuizResult(
    int moduleNumber,
    int chapterNumber,
  ) async {
    final progress = await getProgress();
    final key = 'module_${moduleNumber}_chapter_${chapterNumber}_quiz';
    final result = progress[key];
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getModuleFinalQuizResult(
    int moduleNumber,
  ) async {
    final progress = await getProgress();
    final result = progress[_moduleFinalQuizKey(moduleNumber)];
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    return null;
  }

  static Future<bool> hasModuleFinalQuizAttempt(int moduleNumber) async {
    final result = await getModuleFinalQuizResult(moduleNumber);
    return result != null && result['completed'] == true;
  }

  static Future<bool> isModuleFinalQuizPassed(int moduleNumber) async {
    final result = await getModuleFinalQuizResult(moduleNumber);
    if (result == null) return false;
    final p = result['percentage'];
    if (p is num) return p >= 75;
    return result['passed'] == true;
  }

  // Calculează progresul pentru un capitol
  static Future<double> getChapterProgress(
    int moduleNumber,
    int chapterNumber,
    int totalLessons,
  ) async {
    int completed = 0;

    // Verifică lecțiile
    for (int i = 0; i < totalLessons; i++) {
      if (await isLessonComplete(moduleNumber, chapterNumber, i)) {
        completed++;
      }
    }

    if (await isQuizPassed(moduleNumber, chapterNumber)) {
      completed++;
    }

    return completed / (totalLessons + 1);
  }

  static Future<bool> isModuleUnlocked(int moduleNumber) async {
    if (moduleNumber <= _firstModuleNumber) return true;
    return isModuleComplete(moduleNumber - 1);
  }

  static Future<bool> isModuleComplete(int moduleNumber) async {
    final module = await CurriculumRepository.loadModule(moduleNumber);

    for (final chapter in module.chapters) {
      if (!await isChapterComplete(module.number, chapter)) {
        return false;
      }
    }

    if (module.finalQuiz.isNotEmpty) {
      return isModuleFinalQuizPassed(module.number);
    }

    return true;
  }

  static Future<bool> areModuleChaptersComplete(int moduleNumber) async {
    final module = await CurriculumRepository.loadModule(moduleNumber);

    for (final chapter in module.chapters) {
      if (!await isChapterComplete(module.number, chapter)) {
        return false;
      }
    }

    return true;
  }

  static Future<bool> isChapterComplete(
    int moduleNumber,
    Chapter chapter,
  ) async {
    for (var i = 0; i < chapter.content.length; i++) {
      if (!await isLessonComplete(moduleNumber, chapter.number, i)) {
        return false;
      }
      if (chapter.exercisesAfterLesson(i).isNotEmpty &&
          !await isLessonExercisePassed(moduleNumber, chapter.number, i)) {
        return false;
      }
    }

    if (chapter.quiz.isEmpty) return true;
    return isQuizPassed(moduleNumber, chapter.number);
  }

  // Verifică dacă un capitol este deblocat
  static Future<bool> isChapterUnlocked(
    int moduleNumber,
    int chapterNumber,
  ) async {
    if (!await isModuleUnlocked(moduleNumber)) return false;
    if (chapterNumber == 1) return true;

    try {
      final module = await CurriculumRepository.loadModule(moduleNumber);
      Chapter? prev;
      for (final c in module.chapters) {
        if (c.number == chapterNumber - 1) {
          prev = c;
          break;
        }
      }
      if (prev != null) return isChapterComplete(moduleNumber, prev);
    } catch (_) {
      // fără curriculum încărcat: folosește logica veche
    }

    final previousQuizResult = await getQuizResult(
      moduleNumber,
      chapterNumber - 1,
    );
    if (previousQuizResult == null) return false;

    final percentage = previousQuizResult['percentage'] ?? 0;
    return percentage >= 75;
  }

  // Obține tot progresul
  static Future<Map<String, dynamic>> getProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final String? progressJson = prefs.getString(_progressKey);

    if (progressJson == null) return {};

    try {
      final decoded = jsonDecode(progressJson);
      return Map<String, dynamic>.from(decoded);
    } catch (e) {
      return {};
    }
  }

  // Resetează tot progresul (pentru debugging)
  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_progressKey);
  }
}

class QuizAttempt {
  final int questionIndex;
  final int selectedAnswer;
  final int correctAnswer;
  final bool isCorrect;
  final bool isPartiallyCorrect;
  final double scoreFraction;
  final String question;
  final List<String> openAnswers;
  final String feedback;

  QuizAttempt({
    required this.questionIndex,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    this.isPartiallyCorrect = false,
    this.scoreFraction = 0,
    required this.question,
    this.openAnswers = const [],
    this.feedback = '',
  });

  Map<String, dynamic> toJson() => {
    'questionIndex': questionIndex,
    'selectedAnswer': selectedAnswer,
    'correctAnswer': correctAnswer,
    'isCorrect': isCorrect,
    'isPartiallyCorrect': isPartiallyCorrect,
    'scoreFraction': scoreFraction,
    'question': question,
    'openAnswers': openAnswers,
    'feedback': feedback,
  };

  factory QuizAttempt.fromJson(Map<String, dynamic> json) => QuizAttempt(
    questionIndex: json['questionIndex'],
    selectedAnswer: json['selectedAnswer'],
    correctAnswer: json['correctAnswer'],
    isCorrect: json['isCorrect'],
    isPartiallyCorrect: json['isPartiallyCorrect'] == true,
    scoreFraction: json['scoreFraction'] is num
        ? (json['scoreFraction'] as num).toDouble()
        : 0,
    question: json['question'],
    openAnswers: json['openAnswers'] is List
        ? List<String>.from(json['openAnswers'])
        : const [],
    feedback: json['feedback'] is String ? json['feedback'] as String : '',
  );
}
