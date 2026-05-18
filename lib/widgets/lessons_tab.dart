import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';
import '../models/lesson_models.dart';
import '../services/curriculum_repository.dart';
import '../services/progress_service.dart';
import '../screens/chapter_screen.dart';
import '../screens/quiz_screen.dart';

int _chapterExerciseCount(Chapter chapter) =>
    chapter.lessonExercises.values.fold(0, (sum, list) => sum + list.length);

int _moduleLessonCount(Module module) =>
    module.chapters.fold(0, (sum, chapter) => sum + chapter.content.length);

int _moduleChapterQuizCount(Module module) =>
    module.chapters.fold(0, (sum, chapter) => sum + chapter.quiz.length);

int _moduleExerciseCount(Module module) => module.chapters.fold(
  0,
  (sum, chapter) => sum + _chapterExerciseCount(chapter),
);

String _moduleStatsLabel(Module module) {
  final parts = <String>[
    '${module.chapters.length} capitole',
    '${_moduleLessonCount(module)} lecții',
    '${_moduleChapterQuizCount(module)} întrebări quiz',
  ];
  final exercises = _moduleExerciseCount(module);
  if (module.number == 2 && exercises > 0) {
    parts.add('$exercises exerciții aplicative');
  }
  return parts.join(' • ');
}

String _chapterStatsLabel(Module module, Chapter chapter) {
  final parts = <String>[
    '${chapter.content.length} lecții',
    '${chapter.quiz.length} întrebări quiz',
  ];
  final exercises = _chapterExerciseCount(chapter);
  if (module.number == 2 && exercises > 0) {
    parts.add('$exercises exerciții aplicative');
  }
  return parts.join(' • ');
}

class LessonsTab extends StatefulWidget {
  const LessonsTab({super.key});

  @override
  State<LessonsTab> createState() => _LessonsTabState();
}

class _LessonsTabState extends State<LessonsTab> {
  int _currentModuleNumber = 1;
  late Future<Module> _moduleFuture;
  int _moduleLockEpoch = 0;

  @override
  void initState() {
    super.initState();
    _moduleFuture = CurriculumRepository.loadModule(_currentModuleNumber);
  }

  void _changeModule(int moduleNumber) {
    if (moduleNumber == _currentModuleNumber) return;
    setState(() {
      _currentModuleNumber = moduleNumber;
      _moduleFuture = CurriculumRepository.loadModule(moduleNumber);
    });
  }

  void _refreshLocks() {
    if (mounted) setState(() => _moduleLockEpoch++);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;

    return Column(
      children: [
        // Module selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildModuleChip(1, 'Modulul 1'),
              const SizedBox(width: 12),
              _buildModuleChip(2, 'Modulul 2'),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<Module>(
            future: _moduleFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Nu s-a putut încărca curriculumul.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }
              final module = snapshot.data!;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 48,
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [_buildModuleCard(module, isMobile, context)],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModuleChip(int moduleNumber, String label) {
    final isSelected = _currentModuleNumber == moduleNumber;
    return FutureBuilder<bool>(
      key: ValueKey('module_lock_${moduleNumber}_$_moduleLockEpoch'),
      future: ProgressService.isModuleUnlocked(moduleNumber),
      builder: (context, snap) {
        final unlocked = snap.connectionState != ConnectionState.done
            ? moduleNumber == 1
            : (snap.data ?? moduleNumber == 1);
        return Tooltip(
          message: unlocked
              ? label
              : 'Finalizează Modulul 1 pentru a debloca Modulul 2',
          child: InkWell(
            onTap: unlocked ? () => _changeModule(moduleNumber) : null,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : unlocked
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.textMuted.withOpacity(0.08),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : unlocked
                      ? AppColors.primary.withOpacity(0.3)
                      : AppColors.textMuted.withOpacity(0.18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!unlocked) ...[
                    Icon(
                      Icons.lock_rounded,
                      size: 15,
                      color: AppColors.textMuted.withOpacity(0.55),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : unlocked
                          ? AppColors.primary
                          : AppColors.textMuted.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModuleCard(Module module, bool isMobile, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: const Color(0xFF071520).withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.10),
            blurRadius: 32,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text(
                  'Modulul ${module.number}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            module.title,
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _moduleStatsLabel(module),
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          ...module.chapters.map(
            (chapter) => _ChapterUnlockTile(
              chapter: chapter,
              module: module,
              isMobile: isMobile,
              onProgressChanged: _refreshLocks,
            ),
          ),
          if (module.finalQuiz.isNotEmpty)
            _ModuleFinalQuizTile(
              module: module,
              isMobile: isMobile,
              onProgressChanged: _refreshLocks,
            ),
        ],
      ),
    );
  }
}

class _ModuleFinalQuizTile extends StatelessWidget {
  final Module module;
  final bool isMobile;
  final VoidCallback onProgressChanged;

  const _ModuleFinalQuizTile({
    required this.module,
    required this.isMobile,
    required this.onProgressChanged,
  });

  Future<_ModuleFinalQuizStatus> _loadStatus() async {
    final chaptersComplete = await ProgressService.areModuleChaptersComplete(
      module.number,
    );
    final passed = await ProgressService.isModuleFinalQuizPassed(module.number);
    final result = await ProgressService.getModuleFinalQuizResult(
      module.number,
    );

    return _ModuleFinalQuizStatus(
      chaptersComplete: chaptersComplete,
      passed: passed,
      percentage: ((result?['percentage'] ?? 0) as num).round(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ModuleFinalQuizStatus>(
      future: _loadStatus(),
      builder: (context, snap) {
        final status = snap.data;
        final unlocked = status?.chaptersComplete ?? false;
        final passed = status?.passed ?? false;
        final pct = status?.percentage ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: passed
                ? const Color(0xFF34D399).withOpacity(0.08)
                : AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: passed
                  ? const Color(0xFF34D399).withOpacity(0.35)
                  : unlocked
                  ? AppColors.primary.withOpacity(0.25)
                  : AppColors.textMuted.withOpacity(0.12),
            ),
          ),
          child: InkWell(
            onTap: unlocked
                ? () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => QuizScreen(
                              chapterTitle:
                                  'Modulul ${module.number} - Test final',
                              questions: module.finalQuiz,
                              finalQuizModuleNumber: module.number,
                            ),
                          ),
                        )
                        .then((_) => onProgressChanged());
                  }
                : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Row(
                children: [
                  Container(
                    width: isMobile ? 48 : 56,
                    height: isMobile ? 48 : 56,
                    decoration: BoxDecoration(
                      color: passed
                          ? const Color(0xFF34D399).withOpacity(0.15)
                          : unlocked
                          ? AppColors.primary.withOpacity(0.15)
                          : AppColors.textMuted.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: passed
                            ? const Color(0xFF34D399).withOpacity(0.55)
                            : unlocked
                            ? AppColors.primary.withOpacity(0.3)
                            : AppColors.textMuted.withOpacity(0.15),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        passed
                            ? Icons.verified_rounded
                            : unlocked
                            ? Icons.workspace_premium_rounded
                            : Icons.lock_rounded,
                        color: passed
                            ? const Color(0xFF34D399)
                            : unlocked
                            ? AppColors.primary
                            : AppColors.textMuted.withOpacity(0.45),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test final Modulul ${module.number}',
                          style: TextStyle(
                            fontSize: isMobile ? 15 : 16,
                            fontWeight: FontWeight.w800,
                            color: unlocked
                                ? AppColors.textPrimary
                                : AppColors.textMuted.withOpacity(0.45),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          passed
                              ? module.number == 1
                                    ? 'Promovat cu $pct% • Modulul 2 este deblocat'
                                    : 'Promovat cu $pct%'
                              : unlocked
                              ? '${module.finalQuiz.length} întrebări • ai nevoie de cel puțin 75%'
                              : 'Finalizează toate capitolele modulului ${module.number}.',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            color: unlocked
                                ? AppColors.textMuted
                                : AppColors.textMuted.withOpacity(0.40),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unlocked)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: passed
                          ? const Color(0xFF34D399)
                          : AppColors.primary,
                      size: isMobile ? 16 : 18,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModuleFinalQuizStatus {
  final bool chaptersComplete;
  final bool passed;
  final int percentage;

  const _ModuleFinalQuizStatus({
    required this.chaptersComplete,
    required this.passed,
    required this.percentage,
  });
}

class _ChapterUnlockTile extends StatelessWidget {
  final Chapter chapter;
  final Module module;
  final bool isMobile;
  final VoidCallback onProgressChanged;

  const _ChapterUnlockTile({
    required this.chapter,
    required this.module,
    required this.isMobile,
    required this.onProgressChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: ProgressService.isChapterUnlocked(module.number, chapter.number),
      builder: (context, snap) {
        final unlocked = snap.connectionState != ConnectionState.done
            ? chapter.number == 1
            : (snap.data ?? (chapter.number == 1));
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unlocked
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.textMuted.withOpacity(0.12),
            ),
          ),
          child: InkWell(
            onTap: unlocked
                ? () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => ChapterScreen(
                              chapter: chapter,
                              moduleNumber: module.number,
                              moduleName: module.title,
                            ),
                          ),
                        )
                        .then((_) => onProgressChanged());
                  }
                : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Row(
                children: [
                  Container(
                    width: isMobile ? 48 : 56,
                    height: isMobile ? 48 : 56,
                    decoration: BoxDecoration(
                      color: unlocked
                          ? AppColors.primary.withOpacity(0.15)
                          : AppColors.textMuted.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: unlocked
                            ? AppColors.primary.withOpacity(0.3)
                            : AppColors.textMuted.withOpacity(0.15),
                      ),
                    ),
                    child: Center(
                      child: unlocked
                          ? Text(
                              '${chapter.number}',
                              style: TextStyle(
                                fontSize: isMobile ? 20 : 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            )
                          : Icon(
                              Icons.lock_rounded,
                              color: AppColors.textMuted.withOpacity(0.45),
                              size: 22,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.title,
                          style: TextStyle(
                            fontSize: isMobile ? 15 : 16,
                            fontWeight: FontWeight.w700,
                            color: unlocked
                                ? AppColors.textPrimary
                                : AppColors.textMuted.withOpacity(0.45),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          unlocked
                              ? _chapterStatsLabel(module, chapter)
                              : 'Finalizează capitolul anterior pentru deblocare',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            color: unlocked
                                ? AppColors.textMuted
                                : AppColors.textMuted.withOpacity(0.40),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unlocked)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.primary,
                      size: isMobile ? 16 : 18,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
