import 'package:astrolab/services/curriculum_repository.dart';
import 'package:astrolab/services/progress_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('modulul 2 este blocat pana cand modulul 1 este complet', () async {
    expect(await ProgressService.isModuleUnlocked(1), isTrue);
    expect(await ProgressService.isModuleUnlocked(2), isFalse);
  });

  test(
    'modulul 2 se deblocheaza dupa finalizarea completa a modulului 1',
    () async {
      await _completeModule(1);

      expect(await ProgressService.isModuleComplete(1), isTrue);
      expect(await ProgressService.isModuleUnlocked(2), isTrue);
      expect(await ProgressService.isChapterUnlocked(2, 1), isTrue);
    },
  );

  test('modulul 1 complet necesita promovarea testului final', () async {
    await _completeModuleChapters(1);

    expect(await ProgressService.areModuleChaptersComplete(1), isTrue);
    expect(await ProgressService.isModuleComplete(1), isFalse);
    expect(await ProgressService.isModuleUnlocked(2), isFalse);

    final module = await CurriculumRepository.loadModule(1);
    await ProgressService.saveModuleFinalQuizResult(
      1,
      module.finalQuiz.length,
      module.finalQuiz.length,
      const [],
    );

    expect(await ProgressService.isModuleComplete(1), isTrue);
    expect(await ProgressService.isModuleUnlocked(2), isTrue);
  });

  test('capitolele din modulul 2 se deblocheaza lectie cu lectie', () async {
    for (var lesson = 0; lesson < 5; lesson++) {
      await ProgressService.markLessonComplete(2, 1, lesson);
    }

    expect(await ProgressService.isChapterUnlocked(2, 2), isFalse);

    await _completeModule(1);

    expect(await ProgressService.isChapterUnlocked(2, 2), isFalse);

    final module2 = await CurriculumRepository.loadModule(2);
    final chapter = module2.chapters.first;
    for (final entry in chapter.lessonExercises.entries) {
      await ProgressService.saveLessonExerciseResult(
        2,
        chapter.number,
        entry.key,
        entry.value.length,
        entry.value.length,
        const [],
      );
    }
    await ProgressService.saveQuizResult(
      2,
      chapter.number,
      chapter.quiz.length,
      chapter.quiz.length,
      const [],
    );

    expect(await ProgressService.isChapterUnlocked(2, 2), isTrue);
  });

  test('exercitiile dupa lectia 1 din modulul 2 blocheaza progresul', () async {
    await _completeModule(1);
    final module = await CurriculumRepository.loadModule(2);
    final chapter = module.chapters.first;
    await ProgressService.markLessonComplete(2, 1, 0);

    expect(await ProgressService.isLessonComplete(2, 1, 0), isTrue);
    expect(await ProgressService.isChapterUnlocked(2, 2), isFalse);
    expect(await ProgressService.isChapterComplete(2, chapter), isFalse);

    await ProgressService.saveLessonExerciseResult(2, 1, 0, 3, 4, const []);
    expect(await ProgressService.isLessonExercisePassed(2, 1, 0), isTrue);
  });

  test('o lectie finalizata acorda 10 puncte o singura data', () async {
    await ProgressService.markLessonComplete(1, 1, 0);
    await ProgressService.markLessonComplete(1, 1, 0);

    final progress = await ProgressService.getProgress();
    expect(progress['leaderboardScore'], 10);
  });

  test(
    'skip-ul de capitol adauga scorul testului plus bonusul de skip',
    () async {
      final module = await CurriculumRepository.loadModule(1);
      final chapter = module.chapters.first;

      await ProgressService.saveQuizResult(
        module.number,
        chapter.number,
        chapter.quiz.length,
        chapter.quiz.length,
        const [],
        isSkipQuiz: true,
      );

      final progress = await ProgressService.getProgress();
      expect(
        progress['leaderboardScore'],
        100 + chapter.content.length * 20 + 50,
      );
    },
  );

  test(
    'echivalarea AI acorda punctaj pentru lectii si quiz-uri echivalate',
    () async {
      final module = await CurriculumRepository.loadModule(1);
      final firstChapter = module.chapters.first;
      final secondChapter = module.chapters[1];

      await ProgressService.equivalateThroughLesson(
        moduleNumber: module.number,
        chapterNumber: secondChapter.number,
        lessonIndex: 0,
        source: 'test_ai',
      );

      final progress = await ProgressService.getProgress();
      final expected =
          firstChapter.content.length * 10 +
          firstChapter.lessonExercises.length * 100 +
          (firstChapter.quiz.isEmpty ? 0 : 100) +
          10 +
          (secondChapter.exercisesAfterLesson(0).isEmpty ? 0 : 100);
      expect(progress['leaderboardScore'], expected);
    },
  );
}

Future<void> _completeModule(int moduleNumber) async {
  await _completeModuleChapters(moduleNumber);
  final module = await CurriculumRepository.loadModule(moduleNumber);

  if (module.finalQuiz.isNotEmpty) {
    await ProgressService.saveModuleFinalQuizResult(
      module.number,
      module.finalQuiz.length,
      module.finalQuiz.length,
      const [],
    );
  }
}

Future<void> _completeModuleChapters(int moduleNumber) async {
  final module = await CurriculumRepository.loadModule(moduleNumber);

  for (final chapter in module.chapters) {
    for (var lesson = 0; lesson < chapter.content.length; lesson++) {
      await ProgressService.markLessonComplete(
        module.number,
        chapter.number,
        lesson,
      );
      final exercises = chapter.exercisesAfterLesson(lesson);
      if (exercises.isNotEmpty) {
        await ProgressService.saveLessonExerciseResult(
          module.number,
          chapter.number,
          lesson,
          exercises.length,
          exercises.length,
          const [],
        );
      }
    }

    if (chapter.quiz.isNotEmpty) {
      await ProgressService.saveQuizResult(
        module.number,
        chapter.number,
        chapter.quiz.length,
        chapter.quiz.length,
        const [],
      );
    }
  }
}
