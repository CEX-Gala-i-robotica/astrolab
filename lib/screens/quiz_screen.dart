import 'dart:async' show unawaited;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:astrolab/theme/app_theme.dart';
import '../models/lesson_models.dart';
import '../services/placement_service.dart';
import '../services/progress_service.dart';
import '../utils/lesson_content_parser.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/latex_mixed.dart';
import '../widgets/lesson_table_widget.dart';

class QuizScreen extends StatefulWidget {
  final String chapterTitle;
  final List<QuizQuestion> questions;
  final int? moduleNumber;
  final int? chapterNumber;
  final int? finalQuizModuleNumber;
  final int? exerciseLessonIndex;
  final bool isInitialPlacementQuiz;
  final bool isSkipQuiz;

  const QuizScreen({
    super.key,
    required this.chapterTitle,
    required this.questions,
    this.moduleNumber,
    this.chapterNumber,
    this.finalQuizModuleNumber,
    this.exerciseLessonIndex,
    this.isInitialPlacementQuiz = false,
    this.isSkipQuiz = false,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  int? _selectedOption;
  bool? _openAnswerCorrect;
  double _openAnswerScoreFraction = 0;
  bool _answered = false;
  int _correctCount = 0;
  double _scorePoints = 0;
  bool _showResult = false;
  final List<QuizAttempt> _attempts = [];
  final Map<int, List<TextEditingController>> _openControllers = {};

  late AnimationController _feedbackController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _fadeAnim = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    for (final controllers in _openControllers.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    _feedbackController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  QuizQuestion get _currentQuestion => widget.questions[_currentIndex];
  bool get _isOpenQuestion => _currentQuestion.isOpen;
  bool get _isLessonExercise => widget.exerciseLessonIndex != null;
  bool get _requiresAcceleratedThreshold =>
      widget.isInitialPlacementQuiz || widget.isSkipQuiz;

  String get _screenTitle {
    if (widget.isInitialPlacementQuiz) {
      return 'Test ini\u021bial de evaluare a cuno\u0219tin\u021belor anterioare de astronomie \u0219i astrofizic\u0103';
    }
    if (widget.isSkipQuiz) return 'Evaluare accelerat\u0103';
    if (_isLessonExercise) return 'Exerci\u021bii aplicative';
    return 'Evaluare sumativ\u0103';
  }

  String get _resultTitle {
    if (widget.isInitialPlacementQuiz) return 'Rezultate test ini\u021bial';
    if (widget.isSkipQuiz) return 'Rezultate evaluare accelerat\u0103';
    if (_isLessonExercise) return 'Rezultate exerci\u021bii aplicative';
    return 'Rezultate evaluare sumativ\u0103';
  }

  String get _headerSubtitle {
    if (widget.isInitialPlacementQuiz) return 'Evaluare de plasament';
    if (widget.isSkipQuiz) return 'Evaluare pentru echivalarea capitolului';
    return widget.chapterTitle;
  }

  List<TextEditingController> _controllersForCurrentOpenQuestion() {
    return _openControllers.putIfAbsent(
      _currentIndex,
      () => List.generate(
        _currentQuestion.answerFields.length,
        (_) => TextEditingController(),
      ),
    );
  }

  void _selectOption(int index) {
    if (_answered) return;
    final isCorrect = index == _currentQuestion.correctOptionIndex;
    setState(() {
      _selectedOption = index;
      _answered = true;
      if (isCorrect) {
        _correctCount++;
        if (_isLessonExercise) {
          _scorePoints += 100 / widget.questions.length;
        }
      }
    });
    _feedbackController.forward();
  }

  num? _parseNumber(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return num.tryParse(normalized);
  }

  String _correctOpenAnswerSummary(QuizQuestion question) {
    return question.answerFields
        .map(
          (f) =>
              '${f.label}: ${_formatCorrectOpenAnswer(f)}${f.unit.isEmpty ? '' : ' ${f.unit}'}',
        )
        .join('\n');
  }

  String _formatCorrectOpenAnswer(AnswerField field) {
    final value = field.expectsText
        ? field.correctText
        : '${field.correctValue}';
    final display = value
        .replaceAll('\u03b8_0G', r'\theta_{0G}')
        .replaceAll('\u03b8_G', r'\theta_G')
        .replaceAll('\u03b8', r'\theta')
        .replaceAll('\u00b7', r'\cdot ');
    final looksLikeFormula =
        display.contains(r'\theta') ||
        display.contains('_') ||
        display.contains('TU');
    return looksLikeFormula ? '\$$display\$' : value;
  }

  bool _isAnswerFieldCorrect(AnswerField field, String rawValue) {
    if (field.expectsText) {
      final value = rawValue.trim().toLowerCase();
      final expected = field.correctText.trim().toLowerCase();
      return value == expected;
    }

    final value = _parseNumber(rawValue);
    final correctValue = field.correctValue;
    return value != null &&
        correctValue != null &&
        (value - correctValue).abs() <= field.tolerance;
  }

  void _submitOpenAnswer() {
    if (_answered) return;

    final controllers = _controllersForCurrentOpenQuestion();
    var correctFields = 0;
    for (var i = 0; i < _currentQuestion.answerFields.length; i++) {
      final field = _currentQuestion.answerFields[i];
      if (_isAnswerFieldCorrect(field, controllers[i].text)) {
        correctFields++;
      }
    }
    final totalFields = _currentQuestion.answerFields.length;
    final fraction = totalFields == 0 ? 0.0 : correctFields / totalFields;
    final allCorrect = fraction == 1;

    setState(() {
      _answered = true;
      _openAnswerCorrect = allCorrect;
      _openAnswerScoreFraction = fraction;
      if (allCorrect) _correctCount++;
      if (_isLessonExercise) {
        _scorePoints += fraction * (100 / widget.questions.length);
      }
    });
    _feedbackController.forward();
  }

  void _recordCurrentAttempt() {
    if (_currentQuestion.isOpen) {
      final answers = _controllersForCurrentOpenQuestion()
          .map((controller) => controller.text.trim())
          .toList();
      _attempts.add(
        QuizAttempt(
          questionIndex: _currentIndex,
          selectedAnswer: -1,
          correctAnswer: -1,
          isCorrect: _openAnswerCorrect ?? false,
          isPartiallyCorrect: !_isOpenQuestion
              ? false
              : _openAnswerScoreFraction > 0 && _openAnswerScoreFraction < 1,
          scoreFraction: _openAnswerScoreFraction,
          question: _currentQuestion.question,
          openAnswers: answers,
          feedback: _currentQuestion.explanation,
        ),
      );
      return;
    }

    if (_selectedOption == null) return;
    final isCorrect = _selectedOption == _currentQuestion.correctOptionIndex;
    _attempts.add(
      QuizAttempt(
        questionIndex: _currentIndex,
        selectedAnswer: _selectedOption!,
        correctAnswer: _currentQuestion.correctOptionIndex,
        isCorrect: isCorrect,
        scoreFraction: isCorrect ? 1 : 0,
        question: _currentQuestion.question,
      ),
    );
  }

  Future<void> _next() async {
    _recordCurrentAttempt();
    if (_currentIndex < widget.questions.length - 1) {
      _feedbackController.reset();
      _slideController.reset();
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _openAnswerCorrect = null;
        _openAnswerScoreFraction = 0;
        _answered = false;
      });
      _slideController.forward();
    } else {
      final finalMod = widget.finalQuizModuleNumber;
      if (finalMod != null) {
        await ProgressService.saveModuleFinalQuizResult(
          finalMod,
          _correctCount,
          widget.questions.length,
          List<QuizAttempt>.from(_attempts),
          isInitialPlacementQuiz: widget.isInitialPlacementQuiz,
        );
        if (widget.isInitialPlacementQuiz) {
          unawaited(
            PlacementService.applyInitialPlacement(
              moduleNumber: finalMod,
              correctAnswers: _correctCount,
              totalQuestions: widget.questions.length,
              attempts: List<QuizAttempt>.from(_attempts),
            ).catchError((_) {}),
          );
        }
      } else if (widget.moduleNumber != null &&
          widget.chapterNumber != null &&
          widget.exerciseLessonIndex != null) {
        await ProgressService.saveLessonExerciseResult(
          widget.moduleNumber!,
          widget.chapterNumber!,
          widget.exerciseLessonIndex!,
          _scorePoints.round(),
          100,
          List<QuizAttempt>.from(_attempts),
        );
      } else if (widget.moduleNumber != null && widget.chapterNumber != null) {
        await ProgressService.saveQuizResult(
          widget.moduleNumber!,
          widget.chapterNumber!,
          _correctCount,
          widget.questions.length,
          List<QuizAttempt>.from(_attempts),
          isSkipQuiz: widget.isSkipQuiz,
        );
      }
      setState(() => _showResult = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return _QuizCosmicShell(
        child: Column(
          children: [
            _QuizGlassHeader(
              title: _screenTitle,
              subtitle: _headerSubtitle,
              progress: 0,
              stepLabel: '\u2014',
              onClose: () => Navigator.pop(context),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    _isLessonExercise
                        ? 'Aceast\u0103 lec\u021bie nu are exerci\u021bii aplicative.'
                        : 'Acest capitol nu are \u00eentreb\u0103ri de quiz.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.exo2(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.55),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_showResult) {
      return _ResultScreen(
        chapterTitle: _headerSubtitle,
        questions: widget.questions,
        attempts: _attempts,
        correctCount: _isLessonExercise ? _scorePoints.round() : _correctCount,
        totalCount: _isLessonExercise ? 100 : widget.questions.length,
        isFinalModuleQuiz: widget.finalQuizModuleNumber != null,
        isLessonExercise: _isLessonExercise,
        isInitialPlacementQuiz: widget.isInitialPlacementQuiz,
        requiresAcceleratedThreshold: _requiresAcceleratedThreshold,
        title: _resultTitle,
        onRetry: () {
          for (final controllers in _openControllers.values) {
            for (final controller in controllers) {
              controller.dispose();
            }
          }
          setState(() {
            _currentIndex = 0;
            _selectedOption = null;
            _openAnswerCorrect = null;
            _openAnswerScoreFraction = 0;
            _answered = false;
            _correctCount = 0;
            _scorePoints = 0;
            _showResult = false;
            _attempts.clear();
            _openControllers.clear();
          });
          _feedbackController.reset();
          _slideController.reset();
          _slideController.forward();
        },
        onFinish: () => Navigator.pop(context),
      );
    }

    final progress = (_currentIndex + 1) / widget.questions.length;
    final isCorrect = _isOpenQuestion
        ? (_openAnswerCorrect ?? false)
        : _answered && _selectedOption == _currentQuestion.correctOptionIndex;

    return _QuizCosmicShell(
      child: Column(
        children: [
          _QuizGlassHeader(
            title: _screenTitle,
            subtitle: _headerSubtitle,
            progress: progress,
            stepLabel: '${_currentIndex + 1} / ${widget.questions.length}',
            onClose: () => Navigator.pop(context),
          ),
          Expanded(
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _GlassCard(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF8B5CF6,
                                ).withOpacity(0.18),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: const Color(
                                    0xFFC4B5FD,
                                  ).withOpacity(0.35),
                                ),
                              ),
                              child: Text(
                                '\u00ceNTREBAREA ${_currentIndex + 1}',
                                style: GoogleFonts.exo2(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: const Color(
                                    0xFFC4B5FD,
                                  ).withOpacity(0.95),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _QuizContentColumn(
                              source: _currentQuestion.question,
                              textAlign: TextAlign.center,
                              textStyle: GoogleFonts.exo2(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withOpacity(0.94),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_isOpenQuestion)
                        _OpenQuestionFields(
                          fields: _currentQuestion.answerFields,
                          controllers: _controllersForCurrentOpenQuestion(),
                          answered: _answered,
                          onSubmit: _submitOpenAnswer,
                        )
                      else
                        ...List.generate(_currentQuestion.options.length, (
                          index,
                        ) {
                          return _QuizOptionTile(
                            index: index,
                            option: _currentQuestion.options[index],
                            answered: _answered,
                            isSelected: _selectedOption == index,
                            isCorrectOption:
                                index == _currentQuestion.correctOptionIndex,
                            onTap: () => _selectOption(index),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _answered
                ? _FeedbackBar(
                    isCorrect: isCorrect,
                    isPartiallyCorrect:
                        _isOpenQuestion &&
                        _openAnswerScoreFraction > 0 &&
                        _openAnswerScoreFraction < 1,
                    correctAnswer: _isOpenQuestion
                        ? '${_correctOpenAnswerSummary(_currentQuestion)}\n\n${_currentQuestion.explanation}'
                        : _currentQuestion
                              .options[_currentQuestion.correctOptionIndex]
                              .text,
                    onContinue: _next,
                    isLast: _currentIndex == widget.questions.length - 1,
                  )
                : const SizedBox(height: 20),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Shell & chrome â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _QuizContentColumn extends StatelessWidget {
  final String source;
  final TextStyle textStyle;
  final TextAlign textAlign;

  const _QuizContentColumn({
    required this.source,
    required this.textStyle,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final blocks = _quizContentBlocks(source);
    final isMobile = MediaQuery.sizeOf(context).width < 640;
    final cross = textAlign == TextAlign.center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: cross,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          if (blocks[i].table != null)
            LessonTableWidget(table: blocks[i].table!, isMobile: isMobile)
          else
            LatexMixedColumn(
              source: blocks[i].text,
              textStyle: textStyle,
              textAlign: textAlign,
            ),
        ],
      ],
    );
  }
}

class _QuizContentBlock {
  final String text;
  final LessonTableData? table;

  const _QuizContentBlock.text(this.text) : table = null;
  const _QuizContentBlock.table(this.table) : text = '';
}

List<_QuizContentBlock> _quizContentBlocks(String source) {
  final blocks = <_QuizContentBlock>[];
  final pending = <String>[];
  final lines = source.split('\n');

  void flushText() {
    final text = pending.join('\n').trim();
    pending.clear();
    if (text.isNotEmpty) blocks.add(_QuizContentBlock.text(text));
  }

  var i = 0;
  while (i < lines.length) {
    final line = lines[i].trim();
    if (_isQuizTableRow(line) &&
        i + 1 < lines.length &&
        _isQuizTableSeparator(lines[i + 1].trim())) {
      flushText();
      final tableLines = <String>[line, lines[i + 1].trim()];
      i += 2;
      while (i < lines.length) {
        final row = lines[i].trim();
        if (row.isEmpty ||
            !_isQuizTableRow(row) ||
            _isQuizTableSeparator(row)) {
          break;
        }
        tableLines.add(row);
        i++;
      }
      final table = _parseQuizMarkdownTable(tableLines);
      if (table != null) blocks.add(_QuizContentBlock.table(table));
      continue;
    }

    pending.add(lines[i]);
    i++;
  }

  flushText();
  return blocks;
}

bool _isQuizTableRow(String line) =>
    line.startsWith('|') && line.endsWith('|') && line.length > 2;

bool _isQuizTableSeparator(String line) {
  if (!_isQuizTableRow(line)) return false;
  return RegExp(r'^\|[\s\-:|]+\|$').hasMatch(line);
}

List<String> _splitQuizTableCells(String line) {
  return line
      .split('|')
      .map((cell) => cell.trim())
      .where((cell) => cell.isNotEmpty)
      .toList();
}

LessonTableData? _parseQuizMarkdownTable(List<String> lines) {
  if (lines.isEmpty) return null;
  final headers = _splitQuizTableCells(lines.first);
  if (headers.isEmpty) return null;

  final rows = <List<String>>[];
  for (var i = 1; i < lines.length; i++) {
    if (_isQuizTableSeparator(lines[i])) continue;
    final cells = _splitQuizTableCells(lines[i]);
    if (cells.isEmpty) continue;
    while (cells.length < headers.length) {
      cells.add('');
    }
    rows.add(cells.take(headers.length).toList());
  }

  return LessonTableData(headers: headers, rows: rows);
}

class _QuizCosmicShell extends StatelessWidget {
  final Widget child;

  const _QuizCosmicShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020208),
      body: Stack(
        children: [
          const CosmicBackground(),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _QuizGlassHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;
  final String stepLabel;
  final VoidCallback onClose;

  const _QuizGlassHeader({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.stepLabel,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: onClose,
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withOpacity(0.88),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.exo2(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFC4B5FD).withOpacity(0.95),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.exo2(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      stepLabel,
                      style: GoogleFonts.exo2(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _GlowingProgressBar(value: progress),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowingProgressBar extends StatelessWidget {
  final double value;

  const _GlowingProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final fillW = (w * value.clamp(0.0, 1.0)).clamp(0.0, w);
        return SizedBox(
          height: 6,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              if (fillW > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: fillW,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22D3EE), Color(0xFF34D399)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF34D399).withOpacity(0.55),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.06),
                blurRadius: 20,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// â”€â”€â”€ Options â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _QuizOptionTile extends StatelessWidget {
  final int index;
  final QuizOption option;
  final bool answered;
  final bool isSelected;
  final bool isCorrectOption;
  final VoidCallback onTap;

  const _QuizOptionTile({
    required this.index,
    required this.option,
    required this.answered,
    required this.isSelected,
    required this.isCorrectOption,
    required this.onTap,
  });

  Color get _accent {
    if (!answered) {
      return isSelected
          ? const Color(0xFF67E8F9)
          : Colors.white.withOpacity(0.2);
    }
    if (isCorrectOption) return const Color(0xFF6EE7B7);
    if (isSelected && !isCorrectOption) return const Color(0xFFFCA5A5);
    return Colors.white.withOpacity(0.12);
  }

  Color get _fill {
    if (!answered) {
      return isSelected
          ? AppColors.primary.withOpacity(0.12)
          : Colors.white.withOpacity(0.04);
    }
    if (isCorrectOption) return const Color(0xFF34D399).withOpacity(0.12);
    if (isSelected && !isCorrectOption) {
      return const Color(0xFFEF4444).withOpacity(0.12);
    }
    return Colors.white.withOpacity(0.03);
  }

  @override
  Widget build(BuildContext context) {
    final showCorrectIcon = answered && isCorrectOption;
    final showWrongIcon = answered && isSelected && !isCorrectOption;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: answered ? null : onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _fill,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _accent,
                width: isSelected || (answered && isCorrectOption) ? 1.5 : 1,
              ),
              boxShadow: isSelected && !answered
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accent.withOpacity(0.12),
                    border: Border.all(color: _accent.withOpacity(0.55)),
                  ),
                  child: Center(
                    child: answered
                        ? (showCorrectIcon
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: _accent,
                                )
                              : showWrongIcon
                              ? Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: _accent,
                                )
                              : Text(
                                  option.label.toUpperCase(),
                                  style: GoogleFonts.exo2(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white.withOpacity(0.35),
                                  ),
                                ))
                        : Text(
                            option.label.toUpperCase(),
                            style: GoogleFonts.exo2(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? const Color(0xFF67E8F9)
                                  : Colors.white.withOpacity(0.5),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: LatexMixedColumn(
                    source: option.text,
                    textStyle: GoogleFonts.exo2(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: answered
                          ? (isCorrectOption
                                ? const Color(0xFF6EE7B7)
                                : (isSelected
                                      ? const Color(0xFFFCA5A5)
                                      : Colors.white.withOpacity(0.4)))
                          : (isSelected
                                ? Colors.white.withOpacity(0.92)
                                : Colors.white.withOpacity(0.68)),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenQuestionFields extends StatelessWidget {
  final List<AnswerField> fields;
  final List<TextEditingController> controllers;
  final bool answered;
  final VoidCallback onSubmit;

  const _OpenQuestionFields({
    required this.fields,
    required this.controllers,
    required this.answered,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...List.generate(fields.length, (index) {
            final field = fields[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == fields.length - 1 ? 0 : 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 7),
                    child: LatexMixedColumn(
                      source: field.label,
                      textStyle: GoogleFonts.exo2(
                        color: Colors.white.withOpacity(0.66),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                  TextField(
                    controller: controllers[index],
                    enabled: !answered,
                    keyboardType: field.expectsText
                        ? TextInputType.text
                        : const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.exo2(
                      color: Colors.white.withOpacity(0.92),
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'R\u0103spuns',
                      suffixText: field.unit,
                      hintStyle: GoogleFonts.exo2(
                        color: Colors.white.withOpacity(0.35),
                      ),
                      suffixStyle: GoogleFonts.exo2(
                        color: const Color(0xFF67E8F9).withOpacity(0.9),
                        fontWeight: FontWeight.w700,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.14),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF67E8F9)),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 18),
          _QuizGradientButton(
            label: answered
                ? 'R\u0103spuns verificat'
                : 'Verific\u0103 r\u0103spunsul',
            icon: answered ? Icons.check_rounded : Icons.task_alt_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF22D3EE)],
            ),
            onPressed: answered ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Feedback â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FeedbackBar extends StatelessWidget {
  final bool isCorrect;
  final bool isPartiallyCorrect;
  final String correctAnswer;
  final VoidCallback onContinue;
  final bool isLast;

  const _FeedbackBar({
    required this.isCorrect,
    this.isPartiallyCorrect = false,
    required this.correctAnswer,
    required this.onContinue,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isCorrect
        ? const Color(0xFF34D399)
        : isPartiallyCorrect
        ? const Color(0xFFFBBF24)
        : const Color(0xFFEF4444);
    final icon = isCorrect
        ? Icons.check_circle_rounded
        : isPartiallyCorrect
        ? Icons.error_rounded
        : Icons.cancel_rounded;
    final label = isCorrect
        ? 'Corect!'
        : isPartiallyCorrect
        ? 'R\u0103spuns par\u021bial corect'
        : 'Gre\u0219it';

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            MediaQuery.paddingOf(context).bottom + 20,
          ),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            border: Border(top: BorderSide(color: accent.withOpacity(0.35))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, color: accent, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.exo2(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isCorrect) ...[
                const SizedBox(height: 10),
                Text(
                  isPartiallyCorrect
                      ? 'Explica\u021bie \u0219i r\u0103spunsuri corecte:'
                      : 'R\u0103spuns corect:',
                  style: GoogleFonts.exo2(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accent.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                _QuizContentColumn(
                  source: correctAnswer,
                  textStyle: GoogleFonts.exo2(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _QuizGradientButton(
                label: isLast ? 'Vezi rezultatele' : 'Continu\u0103',
                icon: Icons.arrow_forward_rounded,
                gradient: LinearGradient(
                  colors: isCorrect
                      ? [const Color(0xFF059669), const Color(0xFF34D399)]
                      : isPartiallyCorrect
                      ? [const Color(0xFFD97706), const Color(0xFFFBBF24)]
                      : [const Color(0xFF7C3AED), const Color(0xFFA78BFA)],
                ),
                onPressed: onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizGradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onPressed;

  const _QuizGradientButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.exo2(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, size: 18, color: Colors.white.withOpacity(0.95)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _QuizOutlinedButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: Colors.white.withOpacity(0.28)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        label,
        style: GoogleFonts.exo2(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white.withOpacity(0.88),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Results â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ResultScreen extends StatefulWidget {
  final String chapterTitle;
  final List<QuizQuestion> questions;
  final List<QuizAttempt> attempts;
  final int correctCount;
  final int totalCount;
  final bool isFinalModuleQuiz;
  final bool isLessonExercise;
  final bool isInitialPlacementQuiz;
  final bool requiresAcceleratedThreshold;
  final String title;
  final VoidCallback onRetry;
  final VoidCallback onFinish;

  const _ResultScreen({
    required this.chapterTitle,
    required this.questions,
    required this.attempts,
    required this.correctCount,
    required this.totalCount,
    required this.isFinalModuleQuiz,
    required this.isLessonExercise,
    required this.isInitialPlacementQuiz,
    required this.requiresAcceleratedThreshold,
    required this.title,
    required this.onRetry,
    required this.onFinish,
  });

  @override
  State<_ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<_ResultScreen> {
  bool _analysisOpen = true;

  @override
  Widget build(BuildContext context) {
    final pct = widget.totalCount == 0
        ? 0.0
        : widget.correctCount / widget.totalCount;
    final pctInt = (pct * 100).round();
    final requiredPct = widget.requiresAcceleratedThreshold ? 0.90 : 0.75;
    final requiredPctInt = (requiredPct * 100).round();
    final isPerfect = widget.correctCount == widget.totalCount;
    final isPassed = pct >= requiredPct;

    final accentColor = isPerfect
        ? const Color(0xFFFFD700)
        : isPassed
        ? const Color(0xFF34D399)
        : const Color(0xFFEF4444);

    final passedTarget = widget.isFinalModuleQuiz
        ? 'urm\u0103torul modul'
        : widget.isLessonExercise
        ? 'lec\u021bia urm\u0103toare'
        : 'urm\u0103torul capitol';
    final message = isPerfect
        ? 'Perfect! Ai r\u0103spuns corect la toate!'
        : isPassed
        ? 'Felicit\u0103ri! Ai ob\u021binut cel pu\u021bin $requiredPctInt% \u0219i $passedTarget este deblocat.'
        : 'Ai nevoie de cel pu\u021bin $requiredPctInt% pentru a debloca $passedTarget. \u00cencearc\u0103 din nou!';

    return _QuizCosmicShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QuizGlassHeader(
            title: widget.title,
            subtitle: widget.chapterTitle,
            progress: 1,
            stepLabel: '$pctInt%',
            onClose: widget.onFinish,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                children: [
                  _GlassCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Icon(
                          isPerfect
                              ? Icons.emoji_events_rounded
                              : isPassed
                              ? Icons.star_rounded
                              : Icons.refresh_rounded,
                          size: 52,
                          color: accentColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.exo2(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.92),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor.withOpacity(0.1),
                            border: Border.all(
                              color: accentColor.withOpacity(0.55),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.25),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${widget.correctCount}/${widget.totalCount}',
                                  style: GoogleFonts.exo2(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: accentColor,
                                  ),
                                ),
                                Text(
                                  '$pctInt%',
                                  style: GoogleFonts.exo2(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Material(
                        color: Colors.white.withOpacity(0.05),
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: _analysisOpen,
                            onExpansionChanged: (v) =>
                                setState(() => _analysisOpen = v),
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 4,
                            ),
                            iconColor: const Color(0xFF67E8F9),
                            collapsedIconColor: Colors.white.withOpacity(0.5),
                            title: Row(
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  color: const Color(
                                    0xFF67E8F9,
                                  ).withOpacity(0.9),
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Analiz\u0103 pe \u00eentreb\u0103ri',
                                  style: GoogleFonts.exo2(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  0,
                                  14,
                                  14,
                                ),
                                child: Column(
                                  children: List.generate(
                                    widget.attempts.length,
                                    (i) => _AnalysisTile(
                                      index: i,
                                      attempt: widget.attempts[i],
                                      question:
                                          widget.attempts[i].questionIndex <
                                              widget.questions.length
                                          ? widget.questions[widget
                                                .attempts[i]
                                                .questionIndex]
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.paddingOf(context).bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _QuizGradientButton(
                  label: widget.isInitialPlacementQuiz
                      ? '\u00cencepe aventura AstroLab'
                      : isPassed
                      ? widget.isFinalModuleQuiz
                            ? '\u00cenapoi la modul'
                            : widget.isLessonExercise
                            ? '\u00cenapoi la lec\u021bie'
                            : '\u00cenapoi la capitol'
                      : '\u00cenapoi la capitol',
                  icon: Icons.check_rounded,
                  gradient: LinearGradient(
                    colors: isPassed
                        ? [const Color(0xFF059669), const Color(0xFF34D399)]
                        : [AppColors.primary, const Color(0xFF22D3EE)],
                  ),
                  onPressed: widget.onFinish,
                ),
                if (!widget.isInitialPlacementQuiz) ...[
                  const SizedBox(height: 10),
                  _QuizOutlinedButton(
                    label: 'Ref\u0103 quiz-ul',
                    onPressed: widget.onRetry,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisTile extends StatelessWidget {
  final int index;
  final QuizAttempt attempt;
  final QuizQuestion? question;

  const _AnalysisTile({
    required this.index,
    required this.attempt,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    final accent = attempt.isCorrect
        ? const Color(0xFF34D399)
        : attempt.isPartiallyCorrect
        ? const Color(0xFFFBBF24)
        : const Color(0xFFEF4444);
    final q = question;
    final isOpen = q?.isOpen ?? attempt.openAnswers.isNotEmpty;
    final sel = isOpen
        ? attempt.openAnswers.join('\n')
        : q != null &&
              attempt.selectedAnswer >= 0 &&
              attempt.selectedAnswer < q.options.length
        ? q.options[attempt.selectedAnswer].text
        : '\u2014';
    final ok = isOpen
        ? q != null
              ? [
                  for (final field in q.answerFields)
                    '${field.label}: ${field.expectsText ? field.correctText : field.correctValue}${field.unit.isEmpty ? '' : ' ${field.unit}'}',
                  if (q.explanation.isNotEmpty) '',
                  if (q.explanation.isNotEmpty) q.explanation,
                ].join('\n')
              : attempt.feedback
        : q != null &&
              attempt.correctAnswer >= 0 &&
              attempt.correctAnswer < q.options.length
        ? q.options[attempt.correctAnswer].text
        : '\u2014';

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
                      ? '\u00centrebarea ${index + 1} - par\u021bial corect'
                      : '\u00centrebarea ${index + 1}',
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
          _QuizContentColumn(
            source: attempt.question,
            textStyle: GoogleFonts.exo2(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'R\u0103spunsul t\u0103u:',
            style: GoogleFonts.exo2(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 2),
          _QuizContentColumn(
            source: sel,
            textStyle: GoogleFonts.exo2(
              fontSize: 13,
              color: Colors.white.withOpacity(0.75),
              height: 1.35,
            ),
          ),
          if (!attempt.isCorrect) ...[
            const SizedBox(height: 6),
            Text(
              attempt.isPartiallyCorrect
                  ? 'Explica\u021bie \u0219i r\u0103spunsuri corecte:'
                  : 'Corect:',
              style: GoogleFonts.exo2(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: attempt.isPartiallyCorrect
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFF6EE7B7),
              ),
            ),
            const SizedBox(height: 2),
            _QuizContentColumn(
              source: ok,
              textStyle: GoogleFonts.exo2(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: attempt.isPartiallyCorrect
                    ? const Color(0xFFFDE68A)
                    : const Color(0xFF6EE7B7),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
