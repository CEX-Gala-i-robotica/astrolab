import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:astrolab/theme/app_theme.dart';
import '../models/lesson_models.dart';
import '../services/progress_service.dart';
import '../utils/lesson_content_parser.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/latex_mixed.dart';
import '../widgets/lesson_table_widget.dart';

const _kSentenceIcons = <IconData>[
  Icons.brightness_2_rounded,
  Icons.dark_mode_rounded,
  Icons.nightlight_round,
  Icons.brightness_medium_rounded,
  Icons.wb_twilight_rounded,
  Icons.nights_stay_rounded,
];

/// O lecție parcursă pas cu pas (Înapoi / Înainte), finalizare după toți pașii.
class LessonScreen extends StatefulWidget {
  final Chapter chapter;
  final String moduleName;
  final int moduleNumber;
  final int lessonIndex;

  const LessonScreen({
    super.key,
    required this.chapter,
    required this.moduleName,
    required this.moduleNumber,
    required this.lessonIndex,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  bool _completedHere = false;
  bool _loaded = false;
  bool _wasAlreadyComplete = false;

  /// Ultimul pas vizibil în listă (0.._stepIndex inclusive).
  int _stepIndex = 0;
  int _highestStep = 0;
  int? _exitingStepIndex;
  bool _exitAnimating = false;

  final _scrollController = ScrollController();

  late final List<LessonStep> _steps;
  late final String _lessonTitle;

  @override
  void initState() {
    super.initState();
    final raw = _rawLesson;
    _steps = lessonStepsFromContent(raw);
    _lessonTitle = lessonTitleFromContent(raw);
    ProgressService.saveCurrentStudy(
      moduleNumber: widget.moduleNumber,
      chapterNumber: widget.chapter.number,
      lessonIndex: widget.lessonIndex,
      type: 'lesson',
    );
    _loadCompletion();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCompletion() async {
    final done = await ProgressService.isLessonComplete(
      widget.moduleNumber,
      widget.chapter.number,
      widget.lessonIndex,
    );
    if (!mounted) return;
    setState(() {
      _wasAlreadyComplete = done;
      _loaded = true;
      if (done && _steps.isNotEmpty) {
        _stepIndex = _steps.length - 1;
        _highestStep = _steps.length - 1;
      }
    });
  }

  String get _rawLesson {
    final len = widget.chapter.content.length;
    if (len == 0) return '';
    final i = widget.lessonIndex.clamp(0, len - 1);
    return widget.chapter.content[i];
  }

  bool get _isDone => _wasAlreadyComplete || _completedHere;

  bool get _allStepsSeen => _steps.isEmpty || _highestStep >= _steps.length - 1;

  bool get _onFirstStep => _stepIndex <= 0;

  bool get _onLastStep => _steps.isEmpty || _stepIndex >= _steps.length - 1;

  bool get _canFinish => _allStepsSeen && _onLastStep && !_isDone;

  Future<void> _markComplete() async {
    await ProgressService.markLessonComplete(
      widget.moduleNumber,
      widget.chapter.number,
      widget.lessonIndex,
    );
    if (mounted) {
      setState(() {
        _completedHere = true;
        _wasAlreadyComplete = true;
      });
    }
  }

  Future<void> _goBack() async {
    if (_exitAnimating) return;
    if (_onFirstStep) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _exitingStepIndex = _stepIndex;
      _exitAnimating = true;
    });
  }

  void _onStepExitComplete() {
    if (!mounted || _exitingStepIndex == null) return;
    final newIndex = _stepIndex - 1;
    setState(() {
      _stepIndex = newIndex;
      _exitingStepIndex = null;
      _exitAnimating = false;
    });
  }

  void _goForward() {
    if (_exitAnimating || _onLastStep) return;
    final next = _stepIndex + 1;
    setState(() {
      _stepIndex = next;
      if (next > _highestStep) _highestStep = next;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  int _sentenceIconIndexFor(int stepIndex) {
    var n = 0;
    for (var i = 0; i <= stepIndex && i < _steps.length; i++) {
      final s = _steps[i];
      if (!s.isTitle && !s.isTable) n++;
    }
    return n > 0 ? n - 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;

    final bodyStyle = GoogleFonts.exo2(
      fontSize: isMobile ? 15 : 16,
      color: Colors.white.withOpacity(0.70),
      height: 1.5,
      fontWeight: FontWeight.w500,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF020208),
      body: Stack(
        children: [
          const CosmicBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildGlassAppBar(isMobile),
                if (_loaded && _steps.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _buildStepIndicator(isMobile),
                  ),
                Expanded(
                  child: !_loaded
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary.withOpacity(0.9),
                          ),
                        )
                      : _steps.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'Nu există conținut pentru această lecție.',
                              style: GoogleFonts.exo2(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 15,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                          itemCount: _stepIndex + 1,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, i) {
                            final exiting =
                                _exitingStepIndex != null &&
                                i == _exitingStepIndex;
                            return _RevealLessonCard(
                              key: ValueKey('step_$i'),
                              slideFromLeft: i.isEven,
                              playExit: exiting,
                              onExitComplete: exiting
                                  ? _onStepExitComplete
                                  : null,
                              child: _ImmersiveLessonCard(
                                step: _steps[i],
                                isMobile: isMobile,
                                sentenceIconIndex: _steps[i].isTitle
                                    ? null
                                    : _sentenceIconIndexFor(i),
                                bodyTextStyle: bodyStyle,
                              ),
                            );
                          },
                        ),
                ),
                _buildGlassBottomBar(isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(bool isMobile) {
    final total = _steps.length;
    final current = _stepIndex + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : current / total,
            minHeight: 5,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF34D399)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pasul $current din $total',
          textAlign: TextAlign.center,
          style: GoogleFonts.exo2(
            fontSize: isMobile ? 11 : 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassAppBar(bool isMobile) {
    final displayTitle = _lessonTitle.isNotEmpty
        ? _lessonTitle
        : 'Lecția ${widget.lessonIndex + 1}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.moduleName,
                        style: GoogleFonts.exo2(
                          fontSize: isMobile ? 10 : 11,
                          color: Colors.white.withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Capitolul ${widget.chapter.number}: ${widget.chapter.title}',
                        style: GoogleFonts.exo2(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.white.withOpacity(0.75),
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Lecția ${widget.lessonIndex + 1} · $displayTitle',
                        style: GoogleFonts.exo2(
                          fontSize: isMobile ? 14 : 16,
                          color: const Color(0xFF67E8F9).withOpacity(0.95),
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBottomBar(bool isMobile) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.12)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _lessonNavButton(
                      label: _onFirstStep ? 'Ieșire' : 'Înapoi',
                      icon: _onFirstStep
                          ? Icons.close_rounded
                          : Icons.arrow_back_rounded,
                      onPressed: (_steps.isEmpty || _exitAnimating)
                          ? null
                          : _goBack,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: _buildSecondaryAction()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle get _navButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: Colors.white.withOpacity(0.85),
    disabledForegroundColor: Colors.white.withOpacity(0.35),
    side: BorderSide(color: Colors.white.withOpacity(0.28)),
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    minimumSize: const Size(0, 48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  );

  Widget _lessonNavButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: GoogleFonts.exo2(fontWeight: FontWeight.w600)),
      style: _navButtonStyle,
    );
  }

  Widget _lessonFinishButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final enabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: enabled
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF059669),
                      Color(0xFF10B981),
                      Color(0xFF84CC16),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  )
                : LinearGradient(
                    colors: [
                      const Color(0xFF059669).withOpacity(0.35),
                      const Color(0xFF84CC16).withOpacity(0.25),
                    ],
                  ),
            border: Border.all(
              color: enabled
                  ? const Color(0xFF6EE7B7).withOpacity(0.55)
                  : Colors.white.withOpacity(0.15),
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF34D399).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: Colors.white.withOpacity(enabled ? 0.95 : 0.4),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.exo2(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(enabled ? 0.96 : 0.4),
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

  Widget _buildSecondaryAction() {
    if (_onLastStep && _isDone) {
      return _lessonFinishButton(
        label: 'Lecție finalizată',
        icon: Icons.check_rounded,
        onPressed: _exitAnimating ? null : () => Navigator.of(context).pop(),
      );
    }
    if (_onLastStep && _canFinish) {
      return _lessonFinishButton(
        label: 'Finalizează lecția',
        icon: Icons.task_alt_rounded,
        onPressed: _exitAnimating
            ? null
            : () async {
                await _markComplete();
                if (!mounted) return;
                Navigator.of(context).pop();
              },
      );
    }
    return _lessonNavButton(
      label: 'Înainte',
      icon: Icons.arrow_forward_rounded,
      onPressed: (_onLastStep || _exitAnimating) ? null : _goForward,
    );
  }
}

/// Intrare / ieșire alternantă stânga–dreapta + fade.
class _RevealLessonCard extends StatefulWidget {
  final Widget child;
  final bool slideFromLeft;
  final bool playExit;
  final VoidCallback? onExitComplete;

  const _RevealLessonCard({
    super.key,
    required this.child,
    required this.slideFromLeft,
    this.playExit = false,
    this.onExitComplete,
  });

  @override
  State<_RevealLessonCard> createState() => _RevealLessonCardState();
}

class _RevealLessonCardState extends State<_RevealLessonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final double _dx;

  @override
  void initState() {
    super.initState();
    _dx = widget.slideFromLeft ? -0.38 : 0.38;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
      reverseDuration: const Duration(milliseconds: 380),
    );
    _slide = Tween<Offset>(begin: Offset(_dx, 0.04), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.9, curve: Curves.easeOut),
        reverseCurve: const Interval(0.1, 1.0, curve: Curves.easeIn),
      ),
    );
    if (widget.playExit) {
      _ctrl.value = 1.0;
      _runExit();
    } else {
      _ctrl.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _RevealLessonCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playExit && !oldWidget.playExit) {
      _runExit();
    }
  }

  Future<void> _runExit() async {
    await _ctrl.reverse();
    widget.onExitComplete?.call();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      ),
    );
  }
}

class _ImmersiveLessonCard extends StatelessWidget {
  final LessonStep step;
  final bool isMobile;
  final int? sentenceIconIndex;
  final TextStyle bodyTextStyle;

  const _ImmersiveLessonCard({
    super.key,
    required this.step,
    required this.isMobile,
    required this.sentenceIconIndex,
    required this.bodyTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (step.isTable && step.table != null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 14,
          vertical: isMobile ? 14 : 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: LessonTableWidget(table: step.table!, isMobile: isMobile),
      );
    }

    if (step.isTitle) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 18 : 20,
          vertical: isMobile ? 16 : 18,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF67E8F9).withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22D3EE).withOpacity(0.12),
              blurRadius: 20,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: const Color(0xFF67E8F9).withOpacity(0.95),
              size: isMobile ? 22 : 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LatexMixedColumn(
                source: step.text,
                textStyle: GoogleFonts.exo2(
                  fontSize: isMobile ? 17 : 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withOpacity(0.92),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final icon = sentenceIconIndex == null
        ? Icons.circle_outlined
        : _kSentenceIcons[sentenceIconIndex! % _kSentenceIcons.length];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 18,
        vertical: isMobile ? 16 : 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: isMobile ? 22 : 24,
              color: const Color(0xFFC4B5FD).withOpacity(0.9),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: LatexMixedColumn(
              source: stripLeadBullet(step.text),
              textStyle: bodyTextStyle,
            ),
          ),
        ],
      ),
    );
  }
}
