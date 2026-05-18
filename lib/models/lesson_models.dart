class QuizQuestion {
  final String question;
  final List<QuizOption> options;
  final int correctOptionIndex;
  final String type;
  final List<AnswerField> answerFields;
  final String explanation;

  const QuizQuestion({
    required this.question,
    this.options = const [],
    this.correctOptionIndex = -1,
    this.type = 'choice',
    this.answerFields = const [],
    this.explanation = '',
  });

  bool get isOpen => type == 'open';
}

class QuizOption {
  final String label;
  final String text;

  const QuizOption({
    required this.label,
    required this.text,
  });
}

class AnswerField {
  final String label;
  final String unit;
  final num? correctValue;
  final String correctText;
  final num tolerance;

  const AnswerField({
    required this.label,
    required this.unit,
    this.correctValue,
    this.correctText = '',
    required this.tolerance,
  });

  bool get expectsText => correctText.isNotEmpty;
}

class Chapter {
  final int number;
  final String title;
  final List<String> content;
  final List<QuizQuestion> quiz;
  final Map<int, List<QuizQuestion>> lessonExercises;

  const Chapter({
    required this.number,
    required this.title,
    required this.content,
    required this.quiz,
    this.lessonExercises = const {},
  });

  List<QuizQuestion> exercisesAfterLesson(int lessonIndex) =>
      lessonExercises[lessonIndex] ?? const [];
}

class Module {
  final int number;
  final String title;
  final List<Chapter> chapters;
  final List<QuizQuestion> finalQuiz;

  const Module({
    required this.number,
    required this.title,
    required this.chapters,
    this.finalQuiz = const [],
  });
}
