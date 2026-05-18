import 'package:flutter_test/flutter_test.dart';
import 'package:astrolab/data/curriculum_parser.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parses minimal module JSON', () {
    const raw = '''
{
  "schemaVersion": 1,
  "number": 9,
  "title": "Test module",
  "chapters": [
    {
      "number": 1,
      "title": "Capitol",
      "lessons": ["**Titlu**\\n\\nText."],
      "quiz": [
        {
          "question": "Q?",
          "options": ["A", "B"],
          "correct_index": 1
        },
        {
          "question": "Q2?",
          "options": [
            { "label": "x", "text": "Unu" },
            { "label": "y", "text": "Doi" }
          ],
          "correct": 0
        }
      ]
    }
  ]
}
''';
    final m = CurriculumParser.parseModuleString(raw);
    expect(m.number, 9);
    expect(m.title, 'Test module');
    expect(m.chapters.length, 1);
    expect(m.chapters.first.content.length, 1);
    expect(m.chapters.first.quiz.length, 2);
    expect(m.chapters.first.quiz.first.correctOptionIndex, 1);
    expect(m.chapters.first.quiz.first.options[0].label, 'a');
    expect(m.chapters.first.quiz.last.options[0].label, 'x');
  });

  test('round-trip map matches key fields', () {
    const raw =
        '{"schemaVersion":1,"number":1,"title":"T","chapters":[{"number":1,"title":"C","lessons":["x"],"quiz":[{"question":"q","options":["o0","o1"],"correct_index":0}]}]}';
    final m = CurriculumParser.parseModuleString(raw);
    final map = CurriculumParser.moduleToJsonMap(m);
    final again = CurriculumParser.parseModuleMap(map);
    expect(again.title, m.title);
    expect(again.chapters.first.quiz.first.correctOptionIndex, 0);
  });

  test('module 2 asset declares module number 2', () async {
    final raw = await rootBundle.loadString('assets/curriculum/module_2.json');
    final m = CurriculumParser.parseModuleString(raw);
    expect(m.number, 2);
    expect(m.chapters, isNotEmpty);
  });

  test('module 2 asset keeps Romanian diacritics intact', () async {
    final raw = await rootBundle.loadString('assets/curriculum/module_2.json');
    expect(raw, isNot(contains('�')));
    expect(raw, isNot(contains('Ä')));
    expect(raw, isNot(contains('ĹŁ')));
    expect(raw, isNot(contains('Č™')));
    expect(raw, isNot(contains('â€')));
  });

  test(
    'module 2 has open lesson exercises in the right chapter positions',
    () async {
      final raw = await rootBundle.loadString(
        'assets/curriculum/module_2.json',
      );
      final m = CurriculumParser.parseModuleString(raw);
      final chapter1 = m.chapters.first;
      final chapter2 = m.chapters[1];
      final chapter3 = m.chapters[2];
      final chapter4 = m.chapters[3];
      final chapter5 = m.chapters[4];
      final exercises = chapter1.exercisesAfterLesson(0);
      final finalExercises = chapter1.exercisesAfterLesson(3);
      final coordinateExercises = chapter2.exercisesAfterLesson(3);
      final solarExercises = chapter3.exercisesAfterLesson(6);
      final orbitExercises = chapter4.exercisesAfterLesson(4);

      expect(exercises.length, 4);
      expect(exercises.first.isOpen, isTrue);
      expect(exercises.first.answerFields.length, 3);
      expect(finalExercises.length, 7);
      expect(finalExercises.last.answerFields.last.expectsText, isTrue);
      expect(chapter1.exercisesAfterLesson(4), isEmpty);
      expect(coordinateExercises.length, 2);
      expect(coordinateExercises.first.answerFields.length, 2);
      expect(solarExercises.length, 10);
      expect(solarExercises.first.answerFields.length, 10);
      expect(orbitExercises.length, 7);
      expect(orbitExercises.first.answerFields.length, 3);
      expect(chapter5.number, 5);
      expect(chapter5.content.length, 4);
      expect(chapter5.quiz.length, 15);
    },
  );

  test('module 1 final quiz asset parses', () async {
    final raw = await rootBundle.loadString(
      'assets/curriculum/module_1_final_quiz.json',
    );
    final quiz = CurriculumParser.parseQuizString(raw);
    expect(quiz.length, 50);
    expect(quiz.first.correctOptionIndex, 1);
  });
}
