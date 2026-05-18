import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:astrolab/theme/app_theme.dart';
import '../models/lesson_models.dart';
import '../services/progress_service.dart';
import '../utils/lesson_content_parser.dart';

class ChapterPathWidget extends StatefulWidget {
  final Chapter chapter;
  final int moduleNumber;
  final String moduleName;
  final void Function(int lessonIndex) onLessonTap;
  final void Function(int lessonIndex) onLessonExerciseTap;
  final VoidCallback onQuizTap;

  const ChapterPathWidget({
    super.key,
    required this.chapter,
    required this.moduleNumber,
    required this.moduleName,
    required this.onLessonTap,
    required this.onLessonExerciseTap,
    required this.onQuizTap,
  });

  @override
  State<ChapterPathWidget> createState() => _ChapterPathWidgetState();
}

class _ChapterPathWidgetState extends State<ChapterPathWidget>
    with SingleTickerProviderStateMixin {
  /// Amplitudine zigzag — mai mică = mai mult spațiu pentru etichete la margini.
  static const double _pathAmpRatio = 0.125;

  Map<int, bool> _lessonCompletion = {};
  Map<int, bool> _exercisePassed = {};
  Map<int, bool> _exerciseAttempted = {};
  Map<int, Map<String, dynamic>?> _exerciseResults = {};
  bool _quizPassed = false;
  bool _quizAttempted = false;
  Map<String, dynamic>? _quizResult;

  late final AnimationController _pathTrace;

  bool get _hasQuiz => widget.chapter.quiz.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _pathTrace = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _loadProgress();
  }

  @override
  void dispose() {
    _pathTrace.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final lessonCompletion = <int, bool>{};

    for (int i = 0; i < widget.chapter.content.length; i++) {
      lessonCompletion[i] = await ProgressService.isLessonComplete(
        widget.moduleNumber,
        widget.chapter.number,
        i,
      );
    }
    final exercisePassed = <int, bool>{};
    final exerciseAttempted = <int, bool>{};
    final exerciseResults = <int, Map<String, dynamic>?>{};
    for (final lessonIndex in widget.chapter.lessonExercises.keys) {
      exercisePassed[lessonIndex] =
          await ProgressService.isLessonExercisePassed(
            widget.moduleNumber,
            widget.chapter.number,
            lessonIndex,
          );
      exerciseAttempted[lessonIndex] =
          await ProgressService.hasLessonExerciseAttempt(
            widget.moduleNumber,
            widget.chapter.number,
            lessonIndex,
          );
      exerciseResults[lessonIndex] =
          await ProgressService.getLessonExerciseResult(
            widget.moduleNumber,
            widget.chapter.number,
            lessonIndex,
          );
    }

    final passed =
        !_hasQuiz ||
        await ProgressService.isQuizPassed(
          widget.moduleNumber,
          widget.chapter.number,
        );
    final attempted = await ProgressService.hasQuizAttempt(
      widget.moduleNumber,
      widget.chapter.number,
    );
    final quizResult = await ProgressService.getQuizResult(
      widget.moduleNumber,
      widget.chapter.number,
    );

    if (mounted) {
      setState(() {
        _lessonCompletion = lessonCompletion;
        _exercisePassed = exercisePassed;
        _exerciseAttempted = exerciseAttempted;
        _exerciseResults = exerciseResults;
        _quizPassed = passed;
        _quizAttempted = attempted;
        _quizResult = quizResult;
      });
    }
  }

  bool _isLessonUnlocked(int index) {
    if (index == 0) return true;
    final previousLesson = index - 1;
    final previousLessonDone = _lessonCompletion[previousLesson] ?? false;
    if (!previousLessonDone) return false;
    if (widget.chapter.exercisesAfterLesson(previousLesson).isNotEmpty) {
      return _exercisePassed[previousLesson] ?? false;
    }
    return true;
  }

  bool _isExerciseUnlocked(int lessonIndex) {
    return _lessonCompletion[lessonIndex] ?? false;
  }

  bool _isQuizUnlocked() {
    for (int i = 0; i < widget.chapter.content.length; i++) {
      if (!(_lessonCompletion[i] ?? false)) return false;
      if (widget.chapter.exercisesAfterLesson(i).isNotEmpty &&
          !(_exercisePassed[i] ?? false)) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;
    final pathStep = isMobile ? 148.0 : 158.0;
    final topPad = isMobile ? 14.0 : 18.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              _buildGlassHeader(isMobile),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                  final trackW = constraints.maxWidth;
                  final pathH = _pathHeight(isMobile, pathStep, topPad);
                  return SizedBox(
                    width: trackW,
                    height: pathH,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedBuilder(
                          animation: _pathTrace,
                          builder: (context, _) {
                            return CustomPaint(
                              size: Size(trackW, pathH),
                              painter: _SpatialPathPainter(
                                nodeCompletion: _pathNodeCompletion(),
                                step: pathStep,
                                top: topPad,
                                traceT: _pathTrace.value,
                              ),
                            );
                          },
                        ),
                        ..._buildPositionedNodes(
                          trackW,
                          isMobile,
                          pathStep,
                          topPad,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  double _pathHeight(bool isMobile, double pathStep, double topPad) {
    final n = widget.chapter.content.length;
    final exerciseRows = widget.chapter.lessonExercises.length;
    final rows = n + exerciseRows + (_hasQuiz ? 1 : 0);
    return topPad + rows * pathStep + (isMobile ? 56 : 64);
  }

  List<bool> _pathNodeCompletion() {
    final nodes = <bool>[];
    for (int i = 0; i < widget.chapter.content.length; i++) {
      nodes.add(_lessonCompletion[i] ?? false);
      if (widget.chapter.exercisesAfterLesson(i).isNotEmpty) {
        nodes.add(_exercisePassed[i] ?? false);
      }
    }
    if (_hasQuiz) nodes.add(_quizPassed);
    return nodes;
  }

  List<Widget> _buildPositionedNodes(
    double trackW,
    bool isMobile,
    double pathStep,
    double topPad,
  ) {
    final nodes = <Widget>[];
    final bubbleR = isMobile ? 35.0 : 40.0;
    const labelGap = 12.0;
    final bubbleD = bubbleR * 2;

    void addNode({
      required double centerX,
      required double centerY,
      required double nodeR,
      required bool bubbleOnLeft,
      required Widget bubble,
      required _PathNodeLabel label,
    }) {
      final bubbleLeft = centerX - nodeR;
      final rowTop = centerY - nodeR;

      nodes.add(
        Positioned(
          left: bubbleLeft,
          top: rowTop,
          width: bubbleD,
          height: bubbleD,
          child: bubble,
        ),
      );

      // Etichetă la marginea exterioară; text aliniat spre bulină.
      if (bubbleOnLeft) {
        final labelW = bubbleLeft - labelGap - 8;
        nodes.add(
          Positioned(left: 8, width: labelW, top: rowTop, child: label),
        );
      } else {
        final labelLeft = bubbleLeft + bubbleD + labelGap;
        final labelW = trackW - labelLeft - 8;
        nodes.add(
          Positioned(left: labelLeft, width: labelW, top: rowTop, child: label),
        );
      }
    }

    var visualIndex = 0;
    for (int i = 0; i < widget.chapter.content.length; i++) {
      final x = _nodeCenterX(trackW, visualIndex);
      final y = topPad + visualIndex * pathStep;
      final done = _lessonCompletion[i] ?? false;
      final unlocked = _isLessonUnlocked(i);
      final next = !done && unlocked;
      final title = lessonTitleFromContent(widget.chapter.content[i]);
      final bubbleOnLeft = visualIndex.isEven;

      addNode(
        centerX: x,
        centerY: y,
        nodeR: bubbleR,
        bubbleOnLeft: bubbleOnLeft,
        bubble: _NeonLessonNode(
          isMobile: isMobile,
          isCompleted: done,
          isUnlocked: unlocked,
          onTap: () => widget.onLessonTap(i),
        ),
        label: _PathNodeLabel(
          lessonNumber: i + 1,
          title: title,
          isMobile: isMobile,
          isCompleted: done,
          isUnlocked: unlocked,
          isNext: next,
          alignRight: bubbleOnLeft,
        ),
      );
      visualIndex++;

      final exercises = widget.chapter.exercisesAfterLesson(i);
      if (exercises.isNotEmpty) {
        final exX = _nodeCenterX(trackW, visualIndex);
        final exY = topPad + visualIndex * pathStep;
        final exPassed = _exercisePassed[i] ?? false;
        final exAttempted = _exerciseAttempted[i] ?? false;
        final exPct = ((_exerciseResults[i]?['percentage'] ?? 0) as num)
            .round();
        final exUnlocked = _isExerciseUnlocked(i);
        final exOnLeft = visualIndex.isEven;

        addNode(
          centerX: exX,
          centerY: exY,
          nodeR: bubbleR + 6,
          bubbleOnLeft: exOnLeft,
          bubble: _NeonQuizNode(
            isMobile: isMobile,
            isUnlocked: exUnlocked,
            passed: exPassed,
            attempted: exAttempted,
            percentage: exPct,
            onTap: () => widget.onLessonExerciseTap(i),
          ),
          label: _PathNodeLabel(
            lessonNumber: null,
            title: 'Exerciții aplicate',
            isMobile: isMobile,
            isCompleted: exPassed,
            isUnlocked: exUnlocked,
            isNext: !exPassed && exUnlocked,
            accentQuiz: true,
            alignRight: exOnLeft,
          ),
        );
        visualIndex++;
      }
    }

    final qi = visualIndex;
    final qx = _nodeCenterX(trackW, qi);
    final qy = topPad + qi * pathStep;
    final pct = ((_quizResult?['percentage'] ?? 0) as num).round();
    if (_hasQuiz) {
      final quizR = bubbleR + 6;
      addNode(
        centerX: qx,
        centerY: qy,
        nodeR: quizR,
        bubbleOnLeft: qi.isEven,
        bubble: _NeonQuizNode(
          isMobile: isMobile,
          isUnlocked: _isQuizUnlocked(),
          passed: _quizPassed,
          attempted: _quizAttempted,
          percentage: pct,
          onTap: widget.onQuizTap,
        ),
        label: _PathNodeLabel(
          lessonNumber: null,
          title: 'Quiz final',
          isMobile: isMobile,
          isCompleted: _quizPassed,
          isUnlocked: _isQuizUnlocked(),
          isNext: !_quizPassed && _isQuizUnlocked(),
          accentQuiz: true,
          alignRight: qi.isEven,
        ),
      );
    }

    return nodes;
  }

  double _nodeCenterX(double trackW, int index) {
    final amp = trackW * _pathAmpRatio;
    final mid = trackW / 2;
    return mid + (index.isEven ? -amp : amp);
  }

  Widget _buildGlassHeader(bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.08),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                widget.moduleName,
                style: GoogleFonts.exo2(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.55),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.chapter.title,
                style: GoogleFonts.exo2(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withOpacity(0.95),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildGlowingProgressBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlowingProgressBar() {
    final total = widget.chapter.content.length + (_hasQuiz ? 1 : 0);
    int completed = _lessonCompletion.values.where((v) => v).length;
    final exerciseTotal = widget.chapter.lessonExercises.length;
    final exerciseCompleted = _exercisePassed.values.where((v) => v).length;
    completed += exerciseCompleted;
    if (_hasQuiz && _quizPassed) completed++;
    final effectiveTotal = total + exerciseTotal;

    final progress = effectiveTotal == 0 ? 0.0 : completed / effectiveTotal;

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final fillW = (w * progress).clamp(0.0, w);
            return SizedBox(
              height: 6,
              width: w,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
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
                              color: const Color(0xFF34D399).withOpacity(0.65),
                              blurRadius: 10,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (fillW > 8)
                    Positioned(
                      left: fillW - 6,
                      top: -3,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.95),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: const Color(0xFF6EE7B7).withOpacity(0.8),
                              blurRadius: 14,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Text(
          '$completed / $effectiveTotal completate',
          style: GoogleFonts.exo2(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

class _PathNodeLabel extends StatelessWidget {
  final int? lessonNumber;
  final String title;
  final bool isMobile;
  final bool isCompleted;
  final bool isUnlocked;
  final bool isNext;
  final bool accentQuiz;

  /// true = text aliniat la dreapta (spre bulina din dreapta zonei).
  final bool alignRight;

  const _PathNodeLabel({
    required this.lessonNumber,
    required this.title,
    required this.isMobile,
    required this.isCompleted,
    required this.isUnlocked,
    required this.isNext,
    this.accentQuiz = false,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    Color subtitleColor;
    if (isCompleted) {
      subtitleColor = const Color(0xFF6EE7A0);
    } else if (accentQuiz && isUnlocked) {
      subtitleColor = const Color(0xFFC4B5FD);
    } else if (isUnlocked) {
      subtitleColor = Colors.white.withOpacity(0.82);
    } else {
      subtitleColor = Colors.white.withOpacity(0.28);
    }

    final titleStyle = GoogleFonts.exo2(
      fontSize: isMobile ? 14 : 15,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: isUnlocked
          ? Colors.white.withOpacity(0.92)
          : Colors.white.withOpacity(0.35),
    );

    final lessonStyle = GoogleFonts.exo2(
      fontSize: isMobile ? 11 : 12,
      fontWeight: isNext ? FontWeight.w800 : FontWeight.w700,
      color: subtitleColor,
      letterSpacing: 0.2,
    );

    final cross = alignRight
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final textAlign = alignRight ? TextAlign.right : TextAlign.left;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: cross,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lessonNumber != null)
            Text(
              'Lecția $lessonNumber',
              maxLines: 1,
              textAlign: textAlign,
              style: lessonStyle,
            ),
          if (title.isNotEmpty) ...[
            if (lessonNumber != null) const SizedBox(height: 4),
            Text(
              title,
              maxLines: 4,
              softWrap: true,
              textAlign: textAlign,
              style: titleStyle,
            ),
          ],
        ],
      ),
    );
  }
}

/// Traseu spațial: segmente cu gradient + „trace” animat deasupra.
class _SpatialPathPainter extends CustomPainter {
  final List<bool> nodeCompletion;
  final double step;
  final double top;
  final double traceT;

  _SpatialPathPainter({
    required this.nodeCompletion,
    required this.step,
    required this.top,
    required this.traceT,
  });

  double _cx(double w, int i) {
    final amp = w * _ChapterPathWidgetState._pathAmpRatio;
    final mid = w / 2;
    return mid + (i.isEven ? -amp : amp);
  }

  Color _muted() => const Color(0xFF6366F1).withOpacity(0.22);

  Color _nodeTrail(int nodeIndex) {
    if (nodeIndex < 0 || nodeIndex >= nodeCompletion.length) return _muted();
    return nodeCompletion[nodeIndex] ? const Color(0xFF34D399) : _muted();
  }

  Path _curvePath(double x0, double y0, double x1, double y1) {
    final path = Path()..moveTo(x0, y0);
    final mx = (x0 + x1) / 2;
    path.quadraticBezierTo(mx, y0 + (y1 - y0) * 0.55, x1, y1);
    return path;
  }

  Paint _segmentPaint(
    double x0,
    double y0,
    double x1,
    double y1,
    Color c0,
    Color c1,
  ) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          c0.withOpacity(0.95),
          Color.lerp(c0, c1, 0.5)!,
          c1.withOpacity(0.95),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromPoints(Offset(x0, y0), Offset(x1, y1)));
  }

  void _drawTraceHead(Canvas canvas, Path path, double phase, Color glow) {
    for (final metric in path.computeMetrics()) {
      final len = metric.length;
      if (len < 1) return;
      final head = (phase * 1.15) % 1.0 * len;
      const tail = 48.0;
      final start = (head - tail).clamp(0.0, len);
      final end = head.clamp(0.0, len);
      if (end <= start) return;
      final glowPath = metric.extractPath(start, end);
      canvas.drawPath(
        glowPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..color = glow.withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawPath(
        glowPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withOpacity(0.88),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final n = nodeCompletion.length;

    Offset p(int i) => Offset(_cx(w, i), top + i * step);

    void drawSegment(Offset a, Offset b, Color ca, Color cb, int segIndex) {
      final path = _curvePath(a.dx, a.dy, b.dx, b.dy);
      canvas.drawPath(path, _segmentPaint(a.dx, a.dy, b.dx, b.dy, ca, cb));
      final phase = (traceT + segIndex * 0.09) % 1.0;
      _drawTraceHead(canvas, path, phase, Color.lerp(ca, cb, 0.5)!);
    }

    if (n > 0) {
      final entry = Offset(_cx(w, 0), top - 26);
      drawSegment(entry, p(0), _muted(), _nodeTrail(0), 0);

      for (int i = 0; i < n - 1; i++) {
        drawSegment(p(i), p(i + 1), _nodeTrail(i), _nodeTrail(i + 1), i + 1);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SpatialPathPainter oldDelegate) {
    return oldDelegate.nodeCompletion != nodeCompletion ||
        oldDelegate.step != step ||
        oldDelegate.top != top ||
        oldDelegate.traceT != traceT;
  }
}

class _NeonLessonNode extends StatelessWidget {
  final bool isMobile;
  final bool isCompleted;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _NeonLessonNode({
    required this.isMobile,
    required this.isCompleted,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNext = !isCompleted && isUnlocked;
    final r = isMobile ? 35.0 : 40.0;

    final List<BoxShadow> glow;
    final BoxDecoration deco;

    if (isCompleted) {
      glow = [
        BoxShadow(
          color: const Color(0xFF34D399).withOpacity(0.75),
          blurRadius: 22,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: const Color(0xFF22D3EE).withOpacity(0.35),
          blurRadius: 14,
          spreadRadius: 0,
        ),
      ];
      deco = BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
          stops: [0.0, 0.45, 1.0],
        ),
        border: Border.all(
          color: const Color(0xFF6EE7B7).withOpacity(0.95),
          width: 2,
        ),
        boxShadow: glow,
      );
    } else if (isNext) {
      glow = [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.65),
          blurRadius: 26,
          spreadRadius: 2,
        ),
      ];
      deco = BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.75),
            const Color(0xFF22D3EE),
          ],
        ),
        border: Border.all(color: const Color(0xFF67E8F9), width: 2.5),
        boxShadow: glow,
      );
    } else {
      glow = [];
      deco = BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0D1118).withOpacity(0.92),
        border: Border.all(
          color: isUnlocked
              ? AppColors.primary.withOpacity(0.35)
              : Colors.white.withOpacity(0.12),
          width: 2,
        ),
        boxShadow: glow,
      );
    }

    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        width: r * 2,
        height: r * 2,
        decoration: deco,
        child: Stack(
          children: [
            Center(
              child: isCompleted
                  ? Icon(
                      Icons.check_rounded,
                      color: Colors.white.withOpacity(0.95),
                      size: 30,
                    )
                  : Icon(
                      isUnlocked ? Icons.star_rounded : Icons.lock_rounded,
                      color: isUnlocked
                          ? Colors.white.withOpacity(0.95)
                          : Colors.white.withOpacity(0.25),
                      size: 26,
                    ),
            ),
            if (!isUnlocked)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.42),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NeonQuizNode extends StatelessWidget {
  final bool isMobile;
  final bool isUnlocked;
  final bool passed;
  final bool attempted;
  final int percentage;
  final VoidCallback onTap;

  const _NeonQuizNode({
    required this.isMobile,
    required this.isUnlocked,
    required this.passed,
    required this.attempted,
    required this.percentage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNext = !passed && isUnlocked;
    final r = isMobile ? 41.0 : 46.0;

    late final BoxDecoration deco;
    if (passed) {
      deco = BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF059669), Color(0xFF34D399)],
        ),
        border: Border.all(color: const Color(0xFF6EE7B7), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF34D399).withOpacity(0.7),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      );
    } else if (attempted && !passed) {
      deco = BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF3F1F1F),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.55),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.25),
            blurRadius: 16,
          ),
        ],
      );
    } else if (isNext) {
      deco = BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
        ),
        border: Border.all(color: const Color(0xFFC4B5FD), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.65),
            blurRadius: 26,
            spreadRadius: 2,
          ),
        ],
      );
    } else {
      deco = BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0D1118).withOpacity(0.92),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 2),
      );
    }

    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        width: r * 2,
        height: r * 2,
        decoration: deco,
        child: Stack(
          children: [
            Center(
              child: passed
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white.withOpacity(0.95),
                          size: 28,
                        ),
                        Text(
                          '$percentage%',
                          style: GoogleFonts.exo2(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : attempted
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          color: Colors.white.withOpacity(0.75),
                          size: 26,
                        ),
                        Text(
                          '$percentage%',
                          style: GoogleFonts.exo2(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    )
                  : Icon(
                      isUnlocked ? Icons.quiz_rounded : Icons.lock_rounded,
                      color: isUnlocked
                          ? Colors.white.withOpacity(0.95)
                          : Colors.white.withOpacity(0.25),
                      size: 32,
                    ),
            ),
            if (!isUnlocked)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.38),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
