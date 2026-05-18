import 'dart:convert';

import '../models/lesson_models.dart';

/// Parses curriculum JSON into [Module].
///
/// ## Schema (schemaVersion 1)
///
/// ```json
/// {
///   "schemaVersion": 1,
///   "number": 1,
///   "title": "Module title",
///   "chapters": [
///     {
///       "number": 1,
///       "title": "Chapter title",
///       "lessons": ["markdown lesson 1", "lesson 2"],
///       "quiz": [
///         {
///           "question": "…?",
///           "options": [
///             { "label": "a", "text": "…" },
///             "short option as plain string"
///           ],
///           "correct_index": 0
///         }
///       ]
///     }
///   ]
/// }
/// ```
///
/// - Chapter body: use **`lessons`** or **`content`** (array of strings).
/// - Each quiz option: object `{ "label", "text" }` or a **string** (labels auto `a`,`b`,`c`,…).
/// - Correct answer: **`correct_index`** (0-based) or **`correct`** (same).
///
/// În stringurile din `lessons` / `content` poți folosi LaTeX:
/// **`$…$`** / **`\(…\)`** inline, **`$$…$$`** / **`\[…\]`** display (randat în app).
class CurriculumParser {
  CurriculumParser._();

  static Module parseModuleString(String json) {
    final dynamic decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw CurriculumParseException('Root JSON must be an object');
    }
    return parseModuleMap(decoded);
  }

  static Module parseModuleMap(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    if (version != null && version is! int) {
      throw CurriculumParseException('schemaVersion must be an int');
    }

    final number = _reqInt(json, 'number');
    final title = _reqString(json, 'title');
    final chaptersRaw = json['chapters'];
    if (chaptersRaw is! List || chaptersRaw.isEmpty) {
      throw CurriculumParseException('chapters must be a non-empty array');
    }

    final chapters = <Chapter>[];
    for (var i = 0; i < chaptersRaw.length; i++) {
      final item = chaptersRaw[i];
      if (item is! Map<String, dynamic>) {
        throw CurriculumParseException('chapters[$i] must be an object');
      }
      chapters.add(_parseChapter(item, i));
    }

    final finalQuiz = _parseQuizList(json['quiz'], 'module final quiz');

    return Module(
      number: number,
      title: title,
      chapters: chapters,
      finalQuiz: finalQuiz,
    );
  }

  static Chapter _parseChapter(Map<String, dynamic> json, int index) {
    final number = _reqInt(json, 'number');
    final title = _reqString(json, 'title');
    final lessons = json['lessons'] ?? json['content'];
    if (lessons is! List || lessons.isEmpty) {
      throw CurriculumParseException(
        'Chapter $index: need non-empty "lessons" or "content" array',
      );
    }
    final content = <String>[];
    for (var j = 0; j < lessons.length; j++) {
      final s = lessons[j];
      if (s is! String) {
        throw CurriculumParseException(
          'Chapter $index lessons[$j] must be a string',
        );
      }
      content.add(s);
    }

    final quiz = _parseQuizList(json['quiz'], 'Chapter $index quiz');
    final lessonExercises = _parseLessonExercises(
      json['lesson_exercises'],
      'Chapter $index lesson_exercises',
    );

    return Chapter(
      number: number,
      title: title,
      content: content,
      quiz: quiz,
      lessonExercises: lessonExercises,
    );
  }

  static Map<int, List<QuizQuestion>> _parseLessonExercises(
    dynamic raw,
    String context,
  ) {
    if (raw == null) return const {};
    if (raw is! List) {
      throw CurriculumParseException('$context must be an array');
    }

    final result = <int, List<QuizQuestion>>{};
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is! Map) {
        throw CurriculumParseException('$context[$i] must be an object');
      }
      final map = Map<String, dynamic>.from(item);
      final afterLesson = _reqInt(map, 'after_lesson');
      result[afterLesson] = _parseQuizList(
        map['quiz'],
        '$context[$i].quiz',
      );
    }
    return result;
  }

  static List<QuizQuestion> parseQuizString(String json) {
    final dynamic decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw CurriculumParseException('Root JSON must be an object');
    }

    return _parseQuizList(decoded['quiz'], 'module final quiz');
  }

  static List<QuizQuestion> _parseQuizList(dynamic quizRaw, String context) {
    if (quizRaw == null) return const [];
    if (quizRaw is! List) {
      throw CurriculumParseException('$context: "quiz" must be an array');
    }

    final quiz = <QuizQuestion>[];
    for (var q = 0; q < quizRaw.length; q++) {
      final qMap = quizRaw[q];
      if (qMap is! Map) {
        throw CurriculumParseException('$context[$q] must be an object');
      }
      quiz.add(_parseQuestion(Map<String, dynamic>.from(qMap), context, q));
    }
    return quiz;
  }

  static QuizQuestion _parseQuestion(
    Map<String, dynamic> json,
    String context,
    int qIndex,
  ) {
    final type = json['type'] is String ? json['type'] as String : 'choice';
    final question = _reqString(json, 'question');
    if (type == 'open') {
      final fieldsRaw = json['answer_fields'];
      if (fieldsRaw is! List || fieldsRaw.isEmpty) {
        throw CurriculumParseException(
          '$context[$qIndex]: open question needs answer_fields',
        );
      }
      final fields = <AnswerField>[];
      for (var f = 0; f < fieldsRaw.length; f++) {
        final rawField = fieldsRaw[f];
        if (rawField is! Map) {
          throw CurriculumParseException(
            '$context[$qIndex] answer_fields[$f] must be an object',
          );
        }
        final field = Map<String, dynamic>.from(rawField);
        fields.add(
          AnswerField(
            label: _reqString(field, 'label'),
            unit: field['unit'] is String ? field['unit'] as String : '',
            correctValue: field['correct_value'] is num
                ? field['correct_value'] as num
                : null,
            correctText: field['correct_value'] is String
                ? field['correct_value'] as String
                : '',
            tolerance: _reqNum(field, 'tolerance'),
          ),
        );
      }

      return QuizQuestion(
        question: question,
        type: type,
        answerFields: fields,
        explanation: json['explanation'] is String
            ? json['explanation'] as String
            : '',
      );
    }

    final optionsRaw = json['options'];
    if (optionsRaw is! List || optionsRaw.length < 2) {
      throw CurriculumParseException(
        '$context[$qIndex]: need at least 2 options',
      );
    }

    final labels = 'abcdefghijklmnopqrstuvwxyz';
    final options = <QuizOption>[];
    for (var o = 0; o < optionsRaw.length; o++) {
      final entry = optionsRaw[o];
      if (entry is String) {
        final label = o < labels.length ? labels[o] : '$o';
        options.add(QuizOption(label: label, text: entry));
      } else if (entry is Map) {
        final optionMap = Map<String, dynamic>.from(entry);
        final text = _reqString(optionMap, 'text');
        final label = optionMap['label'] is String
            ? (optionMap['label'] as String)
            : (o < labels.length ? labels[o] : '$o');
        options.add(QuizOption(label: label, text: text));
      } else {
        throw CurriculumParseException(
          '$context[$qIndex] options[$o] must be string or object',
        );
      }
    }

    final correctRaw =
        json['correct_index'] ?? json['correct'] ?? json['correctOptionIndex'];
    if (correctRaw is! int) {
      throw CurriculumParseException(
        '$context[$qIndex]: need int correct_index (or correct)',
      );
    }
    if (correctRaw < 0 || correctRaw >= options.length) {
      throw CurriculumParseException(
        '$context[$qIndex]: correct_index out of range',
      );
    }

    return QuizQuestion(
      question: question,
      options: options,
      correctOptionIndex: correctRaw,
    );
  }

  static int _reqInt(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    throw CurriculumParseException('Missing or invalid int "$key"');
  }

  static num _reqNum(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v is num) return v;
    throw CurriculumParseException('Missing or invalid number "$key"');
  }

  static String _reqString(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v is String && v.isNotEmpty) return v;
    throw CurriculumParseException('Missing or invalid string "$key"');
  }

  /// For tooling: export current in-memory [Module] to JSON-serializable map.
  static Map<String, dynamic> moduleToJsonMap(Module module) => {
        'schemaVersion': 1,
        'number': module.number,
        'title': module.title,
        'quiz': module.finalQuiz
            .map(_questionToJsonMap)
            .toList(),
        'chapters': module.chapters
            .map(
              (c) => {
                'number': c.number,
                'title': c.title,
                'lessons': c.content,
                'lesson_exercises': c.lessonExercises.entries
                    .map(
                      (entry) => {
                        'after_lesson': entry.key,
                        'quiz': entry.value.map(_questionToJsonMap).toList(),
                      },
                    )
                    .toList(),
                'quiz': c.quiz
                    .map(_questionToJsonMap)
                    .toList(),
              },
            )
            .toList(),
      };

  static Map<String, dynamic> _questionToJsonMap(QuizQuestion q) {
    if (q.isOpen) {
      return {
        'type': 'open',
        'question': q.question,
        'answer_fields': q.answerFields
            .map(
              (f) => {
                'label': f.label,
                'unit': f.unit,
                'correct_value': f.expectsText ? f.correctText : f.correctValue,
                'tolerance': f.tolerance,
              },
            )
            .toList(),
        'explanation': q.explanation,
      };
    }

    return {
      'question': q.question,
      'options': q.options.map((o) => {'label': o.label, 'text': o.text}).toList(),
      'correct_index': q.correctOptionIndex,
    };
  }
}

class CurriculumParseException implements Exception {
  final String message;
  CurriculumParseException(this.message);

  @override
  String toString() => 'CurriculumParseException: $message';
}
