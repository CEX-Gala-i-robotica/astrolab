import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:astrolab/theme/app_theme.dart';
import '../models/lesson_models.dart';
import '../services/curriculum_repository.dart';
import '../services/progress_service.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/latex_mixed.dart';

class QuizAnalysisScreen extends StatefulWidget {
  final String title;
  final int moduleNumber;
  final int? chapterNumber;
  final int? lessonIndex;
  final String type;
  final List<QuizAttempt> attempts;
  final int percentage;
  final int correct;
  final int total;

  const QuizAnalysisScreen({
    super.key,
    required this.title,
    required this.moduleNumber,
    required this.chapterNumber,
    required this.lessonIndex,
    required this.type,
    required this.attempts,
    required this.percentage,
    required this.correct,
    required this.total,
  });

  @override
  State<QuizAnalysisScreen> createState() => _QuizAnalysisScreenState();
}

class _QuizAnalysisScreenState extends State<QuizAnalysisScreen> {
  bool _loading = true;
  List<QuizQuestion> _questions = const [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final module = await CurriculumRepository.loadModule(widget.moduleNumber);
      if (widget.type == 'module_final_quiz') {
        _questions = module.finalQuiz;
      } else {
        final chapter = module.chapters.firstWhere(
          (c) => c.number == widget.chapterNumber,
        );
        if (widget.type == 'lesson_exercise') {
          _questions = chapter.exercisesAfterLesson(widget.lessonIndex ?? 0);
        } else {
          _questions = chapter.quiz;
        }
      }
    } catch (_) {
      _questions = const [];
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 640;
    final passed = widget.percentage >= 75;
    final scoreColor = widget.percentage >= 75
        ? const Color(0xFF34D399)
        : widget.percentage >= 50
        ? const Color(0xFFFBBF24)
        : const Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const CosmicBackground(),
          SafeArea(
            child: Column(
              children: [
                _topBar(context, isMobile),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: EdgeInsets.fromLTRB(
                            isMobile ? 16 : 32,
                            16,
                            isMobile ? 16 : 32,
                            24,
                          ),
                          children: [
                            _summaryCard(scoreColor, passed),
                            const SizedBox(height: 16),
                            _analysisHeader(),
                            const SizedBox(height: 12),
                            ...widget.attempts.asMap().entries.map(
                              (entry) => _attemptCard(entry.key, entry.value),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF071520).withOpacity(0.90),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withOpacity(0.15),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(Color scoreColor, bool passed) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scoreColor.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(color: scoreColor.withOpacity(0.10), blurRadius: 32),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scoreColor.withOpacity(0.10),
                  border: Border.all(
                    color: scoreColor.withOpacity(0.55),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scoreColor.withOpacity(0.22),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.percentage}%',
                        style: GoogleFonts.exo2(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        '${widget.correct}/${widget.total}',
                        style: GoogleFonts.exo2(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: scoreColor.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passed ? 'Test promovat' : 'Test nepromovat',
                      style: GoogleFonts.exo2(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Analiza raspunsurilor tale pentru acest rezultat.',
                      style: GoogleFonts.exo2(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.62),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: widget.percentage.clamp(0, 100) / 100,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        color: scoreColor,
                        minHeight: 7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _analysisHeader() {
    return Row(
      children: [
        Icon(
          Icons.analytics_outlined,
          color: const Color(0xFF67E8F9).withOpacity(0.9),
          size: 22,
        ),
        const SizedBox(width: 10),
        Text(
          'Analiza pe intrebari',
          style: GoogleFonts.exo2(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _attemptCard(int index, QuizAttempt attempt) {
    final accent = attempt.isCorrect
        ? const Color(0xFF34D399)
        : attempt.isPartiallyCorrect
        ? const Color(0xFFFBBF24)
        : const Color(0xFFEF4444);
    final question =
        attempt.questionIndex >= 0 && attempt.questionIndex < _questions.length
        ? _questions[attempt.questionIndex]
        : null;
    final selected = _selectedAnswer(attempt, question);
    final correct = _correctAnswer(attempt, question);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                attempt.isCorrect
                    ? Icons.check_circle_rounded
                    : attempt.isPartiallyCorrect
                    ? Icons.error_rounded
                    : Icons.cancel_rounded,
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  attempt.isPartiallyCorrect
                      ? 'Intrebarea ${index + 1} - partial corect'
                      : 'Intrebarea ${index + 1}',
                  style: GoogleFonts.exo2(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _richText(
            attempt.question,
            GoogleFonts.exo2(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          _answerBlock(
            'Raspunsul tau:',
            selected,
            Colors.white.withOpacity(0.75),
          ),
          if (!attempt.isCorrect) ...[
            const SizedBox(height: 8),
            _answerBlock(
              attempt.isPartiallyCorrect
                  ? 'Explicatie si raspunsuri corecte:'
                  : 'Corect:',
              correct,
              attempt.isPartiallyCorrect
                  ? const Color(0xFFFDE68A)
                  : const Color(0xFF6EE7B7),
            ),
          ],
        ],
      ),
    );
  }

  Widget _answerBlock(String label, String source, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.exo2(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color.withOpacity(0.78),
          ),
        ),
        const SizedBox(height: 2),
        _richText(
          source.isEmpty ? '-' : source,
          GoogleFonts.exo2(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _richText(String source, TextStyle style) {
    return LatexMixedColumn(source: source, textStyle: style);
  }

  String _selectedAnswer(QuizAttempt attempt, QuizQuestion? question) {
    if (attempt.openAnswers.isNotEmpty) return attempt.openAnswers.join('\n');
    if (question != null &&
        attempt.selectedAnswer >= 0 &&
        attempt.selectedAnswer < question.options.length) {
      return question.options[attempt.selectedAnswer].text;
    }
    return attempt.selectedAnswer >= 0
        ? 'Optiunea ${attempt.selectedAnswer + 1}'
        : '-';
  }

  String _correctAnswer(QuizAttempt attempt, QuizQuestion? question) {
    if (question?.isOpen == true) {
      final q = question!;
      return [
        for (final field in q.answerFields)
          '${field.label}: ${field.expectsText ? field.correctText : field.correctValue}${field.unit.isEmpty ? '' : ' ${field.unit}'}',
        if (q.explanation.isNotEmpty) '',
        if (q.explanation.isNotEmpty) q.explanation,
      ].join('\n');
    }
    if (question != null &&
        attempt.correctAnswer >= 0 &&
        attempt.correctAnswer < question.options.length) {
      return question.options[attempt.correctAnswer].text;
    }
    return attempt.correctAnswer >= 0
        ? 'Optiunea ${attempt.correctAnswer + 1}'
        : '-';
  }
}
