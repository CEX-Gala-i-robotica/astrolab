import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/lesson_models.dart';
import 'curriculum_repository.dart';

class ProgressService {
  static const String _progressKey = 'user_progress';
  static const String _dbUrl = String.fromEnvironment('FIREBASE_DB_URL');
  static const int _firstModuleNumber = 1;
  static const String _scoreKey = 'leaderboardScore';
  static const String _scoreEventsKey = 'scoreEvents';
  static String? _uid;
  static String? _token;

  static String get _activeProgressKey {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return _progressKey;
    return '${_progressKey}_$uid';
  }

  static String _moduleFinalQuizKey(int moduleNumber) =>
      'module_${moduleNumber}_final_quiz';

  static String _lessonExerciseKey(
    int moduleNumber,
    int chapterNumber,
    int lessonIndex,
  ) =>
      'module_${moduleNumber}_chapter_${chapterNumber}_lesson_${lessonIndex}_exercise';

  static String _chapterSkipKey(int moduleNumber, int chapterNumber) =>
      'module_${moduleNumber}_chapter_${chapterNumber}_skipped';

  static Future<void> configureRemote({
    required String uid,
    required String token,
  }) async {
    _uid = uid;
    _token = token;
    await _loadAccountProgress();
  }

  static void clearRemoteSession() {
    _uid = null;
    _token = null;
  }

  // Salvează progresul pentru o lecție specifică
  static Future<void> markLessonComplete(
    int moduleNumber,
    int chapterNumber,
    int lessonIndex,
  ) async {
    final progress = await getProgress();

    final key =
        'module_${moduleNumber}_chapter_${chapterNumber}_lesson_$lessonIndex';
    final alreadyComplete = progress[key] == true;
    progress[key] = true;
    if (!alreadyComplete) {
      _applyScoreEvent(
        progress,
        'lesson:$moduleNumber:$chapterNumber:$lessonIndex',
        10,
        'Lectie finalizata',
      );
    }

    await _saveProgress(progress);
    await saveCurrentStudy(
      moduleNumber: moduleNumber,
      chapterNumber: chapterNumber,
      lessonIndex: lessonIndex,
      type: 'lesson',
    );
  }

  // Salvează rezultatul quiz-ului
  static Future<void> saveQuizResult(
    int moduleNumber,
    int chapterNumber,
    int correctAnswers,
    int totalQuestions,
    List<QuizAttempt> attempts, {
    bool isSkipQuiz = false,
  }) async {
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

    var scorePoints = pct;
    if (isSkipQuiz && pct >= 90) {
      scorePoints += await _chapterSkipBonus(moduleNumber, chapterNumber);
    }
    _applyScoreEvent(
      progress,
      'chapter_quiz:$moduleNumber:$chapterNumber',
      scorePoints,
      isSkipQuiz ? 'Skip capitol prin evaluare' : 'Test final capitol',
    );

    if (pct >= 90) {
      await _completeChapterInProgress(
        progress,
        moduleNumber,
        chapterNumber,
        preserveChapterQuizResult: true,
        awardEquivalatedScore: !isSkipQuiz,
      );
    }

    await _saveProgress(progress);
    await saveCurrentStudy(
      moduleNumber: moduleNumber,
      chapterNumber: chapterNumber,
      type: 'chapter_quiz',
      percentage: pct,
    );
  }

  static Future<void> saveModuleFinalQuizResult(
    int moduleNumber,
    int correctAnswers,
    int totalQuestions,
    List<QuizAttempt> attempts, {
    bool isInitialPlacementQuiz = false,
  }) async {
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

    _applyScoreEvent(
      progress,
      'module_final_quiz:$moduleNumber',
      pct,
      'Test final modul',
    );
    if (isInitialPlacementQuiz) {
      await _applyInitialPlacementSkipScore(
        progress,
        moduleNumber,
        correctAnswers,
        totalQuestions,
      );
    }

    await _saveProgress(progress);
    await saveCurrentStudy(
      moduleNumber: moduleNumber,
      type: 'module_final_quiz',
      percentage: pct,
    );
  }

  static Future<void> saveLessonExerciseResult(
    int moduleNumber,
    int chapterNumber,
    int lessonIndex,
    int correctAnswers,
    int totalQuestions,
    List<QuizAttempt> attempts,
  ) async {
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

    _applyScoreEvent(
      progress,
      'lesson_exercise:$moduleNumber:$chapterNumber:$lessonIndex',
      pct,
      'Exercitii aplicative',
    );

    await _saveProgress(progress);
    await saveCurrentStudy(
      moduleNumber: moduleNumber,
      chapterNumber: chapterNumber,
      lessonIndex: lessonIndex,
      type: 'lesson_exercise',
      percentage: pct,
    );
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
    if (await isChapterSkipped(moduleNumber, chapter.number)) return true;

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

  static Future<bool> isChapterSkipped(
    int moduleNumber,
    int chapterNumber,
  ) async {
    final progress = await getProgress();
    return progress[_chapterSkipKey(moduleNumber, chapterNumber)] == true;
  }

  static Future<void> saveCurrentStudy({
    required int moduleNumber,
    int? chapterNumber,
    int? lessonIndex,
    required String type,
    int? percentage,
  }) async {
    final data = <String, dynamic>{
      'moduleNumber': moduleNumber,
      'type': type,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (chapterNumber != null) data['chapterNumber'] = chapterNumber;
    if (lessonIndex != null) data['lessonIndex'] = lessonIndex;
    if (percentage != null) data['percentage'] = percentage;

    final progress = await getProgress();
    progress['currentStudy'] = data;
    await _saveProgress(progress);
  }

  static Future<void> equivalateThroughLesson({
    required int moduleNumber,
    required int chapterNumber,
    required int lessonIndex,
    String source = 'placement',
  }) async {
    final progress = await getProgress();
    final module = await CurriculumRepository.loadModule(moduleNumber);

    for (final chapter in module.chapters) {
      if (chapter.number < chapterNumber) {
        await _completeChapterInProgress(
          progress,
          moduleNumber,
          chapter.number,
        );
        continue;
      }

      if (chapter.number == chapterNumber) {
        final maxLesson = lessonIndex
            .clamp(0, chapter.content.length - 1)
            .toInt();
        for (var i = 0; i <= maxLesson; i++) {
          _setLessonEquivalated(progress, moduleNumber, chapter.number, i);
          if (chapter.exercisesAfterLesson(i).isNotEmpty) {
            _setLessonExercisePerfect(
              progress,
              moduleNumber,
              chapter.number,
              i,
            );
          }
        }
        if (maxLesson >= chapter.content.length - 1 &&
            chapter.quiz.isNotEmpty) {
          _setChapterQuizPerfect(
            progress,
            moduleNumber,
            chapter.number,
            chapter,
          );
        }
        break;
      }
    }

    progress['lastEquivalence'] = {
      'source': source,
      'moduleNumber': moduleNumber,
      'chapterNumber': chapterNumber,
      'lessonIndex': lessonIndex,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _saveProgress(progress);
  }

  static Future<void> equivalateEntireModule({
    required int moduleNumber,
    String source = 'placement',
    bool includeFinalQuiz = true,
    bool preserveExistingModuleFinalQuiz = true,
  }) async {
    final progress = await getProgress();
    final module = await CurriculumRepository.loadModule(moduleNumber);

    for (final chapter in module.chapters) {
      await _completeChapterInProgress(progress, moduleNumber, chapter.number);
    }

    if (includeFinalQuiz &&
        module.finalQuiz.isNotEmpty &&
        !(preserveExistingModuleFinalQuiz &&
            progress[_moduleFinalQuizKey(moduleNumber)] != null)) {
      _setModuleFinalQuizPerfect(
        progress,
        moduleNumber,
        module.finalQuiz.length,
      );
    }

    progress['lastEquivalence'] = {
      'source': source,
      'moduleNumber': moduleNumber,
      'entireModule': true,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _saveProgress(progress);
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
    final String? progressJson = prefs.getString(_activeProgressKey);

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
    await prefs.remove(_activeProgressKey);
    await _syncRemoteProgress({});
    await _syncLeaderboardScore({});
  }

  static Future<void> _saveProgress(Map<String, dynamic> progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeProgressKey, jsonEncode(progress));
    await _syncRemoteProgress(progress);
    await _syncLeaderboardScore(progress);
  }

  static void _applyScoreEvent(
    Map<String, dynamic> progress,
    String eventKey,
    int points,
    String description,
  ) {
    if (points <= 0) return;

    final events = progress[_scoreEventsKey] is Map
        ? Map<String, dynamic>.from(progress[_scoreEventsKey] as Map)
        : <String, dynamic>{};
    final previous = events[eventKey];
    final previousPoints = previous is Map && previous['points'] is num
        ? (previous['points'] as num).round()
        : 0;
    if (points <= previousPoints) return;

    final currentScore = progress[_scoreKey] is num
        ? (progress[_scoreKey] as num).round()
        : 0;
    progress[_scoreKey] = currentScore + (points - previousPoints);
    events[eventKey] = {
      'points': points,
      'description': description,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    progress[_scoreEventsKey] = events;
  }

  static Future<int> _chapterSkipBonus(
    int moduleNumber,
    int chapterNumber,
  ) async {
    try {
      final module = await CurriculumRepository.loadModule(moduleNumber);
      final chapter = module.chapters.firstWhere(
        (c) => c.number == chapterNumber,
      );
      return chapter.content.length * 20 + 50;
    } catch (_) {
      return 50;
    }
  }

  static Future<void> _applyInitialPlacementSkipScore(
    Map<String, dynamic> progress,
    int moduleNumber,
    int correctAnswers,
    int totalQuestions,
  ) async {
    final pct = totalQuestions == 0
        ? 0
        : (correctAnswers / totalQuestions * 100).round();

    if (moduleNumber == 1 && pct >= 90) {
      _applyScoreEvent(
        progress,
        'module_skip:1',
        await _moduleSkipBonus(1),
        'Skip modul prin test initial',
      );
      return;
    }

    if (moduleNumber == 2 && pct == 100) {
      _applyScoreEvent(
        progress,
        'module_skip:1',
        await _moduleSkipBonus(1),
        'Skip modul prin test initial',
      );
      _applyScoreEvent(
        progress,
        'module_skip:2',
        await _moduleSkipBonus(2),
        'Skip modul prin test initial',
      );
    }
  }

  static Future<int> _moduleSkipBonus(int moduleNumber) async {
    try {
      final module = await CurriculumRepository.loadModule(moduleNumber);
      final lessonCount = module.chapters.fold<int>(
        0,
        (sum, chapter) => sum + chapter.content.length,
      );
      return lessonCount * 20 + 50;
    } catch (_) {
      return 50;
    }
  }

  static Future<void> _replaceLocalProgress(
    Map<String, dynamic> progress,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeProgressKey, jsonEncode(progress));
  }

  static Future<void> _loadAccountProgress() async {
    if (_uid == null || _token == null || _dbUrl.isEmpty) return;

    try {
      final res = await http.get(
        Uri.parse('$_dbUrl/$_uid/progress.json?auth=$_token'),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) return;
      final body = res.body.trim();
      if (body.isEmpty || body == 'null') {
        final localProgress = await getProgress();
        await _syncRemoteProgress(localProgress);
        await _syncLeaderboardScore(localProgress);
        return;
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map) return;
      final remoteProgress = Map<String, dynamic>.from(decoded);
      await _replaceLocalProgress(remoteProgress);
      await _syncLeaderboardScore(remoteProgress);
    } catch (_) {}
  }

  static Future<void> _syncRemoteProgress(Map<String, dynamic> progress) async {
    if (_uid == null || _token == null || _dbUrl.isEmpty) return;

    try {
      await http.put(
        Uri.parse('$_dbUrl/$_uid/progress.json?auth=$_token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(progress),
      );
    } catch (_) {}
  }

  static Future<void> _syncLeaderboardScore(
    Map<String, dynamic> progress,
  ) async {
    if (_uid == null || _token == null || _dbUrl.isEmpty) return;

    try {
      final score = progress[_scoreKey] is num
          ? (progress[_scoreKey] as num).round()
          : 0;
      await http.put(
        Uri.parse('$_dbUrl/leaderboard/$_uid.json?auth=$_token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': _uid,
          'score': score,
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  static Future<void> _completeChapterInProgress(
    Map<String, dynamic> progress,
    int moduleNumber,
    int chapterNumber, {
    bool preserveChapterQuizResult = false,
    bool awardEquivalatedScore = true,
  }) async {
    progress[_chapterSkipKey(moduleNumber, chapterNumber)] = true;

    try {
      final module = await CurriculumRepository.loadModule(moduleNumber);
      final chapter = module.chapters.firstWhere(
        (c) => c.number == chapterNumber,
      );
      for (var i = 0; i < chapter.content.length; i++) {
        if (awardEquivalatedScore) {
          _setLessonEquivalated(progress, moduleNumber, chapterNumber, i);
        } else {
          progress['module_${moduleNumber}_chapter_${chapterNumber}_lesson_$i'] =
              true;
        }
        if (chapter.exercisesAfterLesson(i).isNotEmpty) {
          _setLessonExercisePerfect(
            progress,
            moduleNumber,
            chapterNumber,
            i,
            awardScore: awardEquivalatedScore,
          );
        }
      }
      if (chapter.quiz.isNotEmpty &&
          !(preserveChapterQuizResult &&
              progress['module_${moduleNumber}_chapter_${chapterNumber}_quiz'] !=
                  null)) {
        _setChapterQuizPerfect(
          progress,
          moduleNumber,
          chapterNumber,
          chapter,
          awardScore: awardEquivalatedScore,
        );
      }
    } catch (_) {}
  }

  static void _setChapterQuizPerfect(
    Map<String, dynamic> progress,
    int moduleNumber,
    int chapterNumber,
    Chapter chapter, {
    bool awardScore = true,
  }) {
    progress['module_${moduleNumber}_chapter_${chapterNumber}_quiz'] = {
      'completed': true,
      'correct': chapter.quiz.length,
      'total': chapter.quiz.length,
      'percentage': 100,
      'passed': true,
      'equivalated': true,
      'timestamp': DateTime.now().toIso8601String(),
      'attempts': const [],
    };
    if (awardScore) {
      _applyScoreEvent(
        progress,
        'chapter_quiz:$moduleNumber:$chapterNumber',
        100,
        'Quiz capitol echivalat',
      );
    }
  }

  static void _setLessonEquivalated(
    Map<String, dynamic> progress,
    int moduleNumber,
    int chapterNumber,
    int lessonIndex,
  ) {
    progress['module_${moduleNumber}_chapter_${chapterNumber}_lesson_$lessonIndex'] =
        true;
    _applyScoreEvent(
      progress,
      'lesson:$moduleNumber:$chapterNumber:$lessonIndex',
      10,
      'Lectie echivalata',
    );
  }

  static void _setLessonExercisePerfect(
    Map<String, dynamic> progress,
    int moduleNumber,
    int chapterNumber,
    int lessonIndex, {
    bool awardScore = true,
  }) {
    progress[_lessonExerciseKey(moduleNumber, chapterNumber, lessonIndex)] = {
      'completed': true,
      'correct': 100,
      'total': 100,
      'percentage': 100,
      'passed': true,
      'equivalated': true,
      'timestamp': DateTime.now().toIso8601String(),
      'attempts': const [],
    };
    if (awardScore) {
      _applyScoreEvent(
        progress,
        'lesson_exercise:$moduleNumber:$chapterNumber:$lessonIndex',
        100,
        'Exercitii aplicative echivalate',
      );
    }
  }

  static void _setModuleFinalQuizPerfect(
    Map<String, dynamic> progress,
    int moduleNumber,
    int questionCount,
  ) {
    progress[_moduleFinalQuizKey(moduleNumber)] = {
      'completed': true,
      'correct': questionCount,
      'total': questionCount,
      'percentage': 100,
      'passed': true,
      'equivalated': true,
      'timestamp': DateTime.now().toIso8601String(),
      'attempts': const [],
    };
    _applyScoreEvent(
      progress,
      'module_final_quiz:$moduleNumber',
      100,
      'Test final modul echivalat',
    );
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
