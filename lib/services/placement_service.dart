import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/lesson_models.dart';
import 'curriculum_repository.dart';
import 'progress_service.dart';

class PlacementService {
  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY'
  );

  static Future<void> applyInitialPlacement({
    required int moduleNumber,
    required int correctAnswers,
    required int totalQuestions,
    required List<QuizAttempt> attempts,
  }) async {
    final pct = totalQuestions == 0
        ? 0
        : (correctAnswers / totalQuestions * 100).round();

    if (moduleNumber == 1) {
      if (pct >= 90) {
        await ProgressService.equivalateEntireModule(
          moduleNumber: 1,
          source: 'initial_module_1',
        );
        return;
      }

      final decision = await _askGeminiForModule1Placement(
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
        attempts: attempts,
      );
      await ProgressService.equivalateThroughLesson(
        moduleNumber: 1,
        chapterNumber: decision.chapterNumber,
        lessonIndex: decision.lessonIndex,
        source: 'initial_module_1_ai',
      );
      return;
    }

    if (moduleNumber == 2 && pct == 100) {
      await ProgressService.equivalateEntireModule(
        moduleNumber: 1,
        source: 'initial_module_2_perfect',
      );
      await ProgressService.equivalateEntireModule(
        moduleNumber: 2,
        source: 'initial_module_2_perfect',
      );
    }
  }

  static Future<_PlacementDecision> _askGeminiForModule1Placement({
    required int correctAnswers,
    required int totalQuestions,
    required List<QuizAttempt> attempts,
  }) async {
    try {
      final module = await CurriculumRepository.loadModule(1);
      final prompt = _buildPrompt(
        module: module,
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
        attempts: attempts,
      );

      final res = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0,
            'responseMimeType': 'application/json',
          },
        }),
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        return _fallbackDecision(correctAnswers, totalQuestions);
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final text =
          data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        return _fallbackDecision(correctAnswers, totalQuestions);
      }

      final decoded = jsonDecode(text) as Map<String, dynamic>;
      return _boundedDecision(
        module,
        _PlacementDecision(
          chapterNumber: (decoded['chapterNumber'] as num?)?.round() ?? 1,
          lessonIndex: (decoded['lessonIndex'] as num?)?.round() ?? 0,
        ),
      );
    } catch (_) {
      return _fallbackDecision(correctAnswers, totalQuestions);
    }
  }

  static String _buildPrompt({
    required Module module,
    required int correctAnswers,
    required int totalQuestions,
    required List<QuizAttempt> attempts,
  }) {
    final curriculum = {
      'moduleNumber': module.number,
      'title': module.title,
      'chapters': [
        for (final chapter in module.chapters)
          {
            'chapterNumber': chapter.number,
            'title': chapter.title,
            'lessons': [
              for (var i = 0; i < chapter.content.length; i++)
                {
                  'lessonIndex': i,
                  'title': _lessonTitle(chapter.content[i], i),
                  'content': chapter.content[i],
                },
            ],
          },
      ],
    };

    final results = {
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'percentage': totalQuestions == 0
          ? 0
          : (correctAnswers / totalQuestions * 100).round(),
      'attempts': attempts.map((a) => a.toJson()).toList(),
    };

    return '''
Esti un evaluator pentru platforma AstroLab.
Trebuie sa decizi pana la ce lectie din Modulul 1 poate fi echivalat progresul elevului pe baza testului initial.

Reguli:
- Raspunde doar JSON valid.
- Format exact: {"chapterNumber":1,"lessonIndex":0,"reason":"scurt"}
- chapterNumber este numarul capitolului din curriculum.
- lessonIndex este index 0-based in capitol.
- Alege ultima lectie pe care elevul pare sa o stapaneasca.
- Fii conservator daca raspunsurile gresite indica lacune.
- Nu echivala dincolo de curriculumul primit.

Rezultate test initial:
${jsonEncode(results)}

Curriculum Modulul 1:
${jsonEncode(curriculum)}
''';
  }

  static String _lessonTitle(String content, int index) {
    final firstLine = content
        .split('\n')
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    if (firstLine.isEmpty) return 'Lectia ${index + 1}';
    return firstLine.replaceFirst(RegExp(r'^#+\s*'), '');
  }

  static Future<_PlacementDecision> _fallbackDecision(
    int correctAnswers,
    int totalQuestions,
  ) async {
    final module = await CurriculumRepository.loadModule(1);
    final pct = totalQuestions == 0 ? 0.0 : correctAnswers / totalQuestions;
    final lessonSlots = <_PlacementDecision>[];
    for (final chapter in module.chapters) {
      for (var i = 0; i < chapter.content.length; i++) {
        lessonSlots.add(
          _PlacementDecision(chapterNumber: chapter.number, lessonIndex: i),
        );
      }
    }
    if (lessonSlots.isEmpty) {
      return const _PlacementDecision(chapterNumber: 1, lessonIndex: 0);
    }
    final index = (pct * (lessonSlots.length - 1))
        .floor()
        .clamp(0, lessonSlots.length - 1)
        .toInt();
    return lessonSlots[index];
  }

  static _PlacementDecision _boundedDecision(
    Module module,
    _PlacementDecision decision,
  ) {
    final chapter = module.chapters.firstWhere(
      (c) => c.number == decision.chapterNumber,
      orElse: () => module.chapters.first,
    );
    final maxLesson = chapter.content.isEmpty ? 0 : chapter.content.length - 1;
    return _PlacementDecision(
      chapterNumber: chapter.number,
      lessonIndex: decision.lessonIndex.clamp(0, maxLesson).toInt(),
    );
  }
}

class _PlacementDecision {
  final int chapterNumber;
  final int lessonIndex;

  const _PlacementDecision({
    required this.chapterNumber,
    required this.lessonIndex,
  });
}
