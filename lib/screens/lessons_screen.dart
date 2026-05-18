import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';
import '../models/lesson_models.dart';
import '../services/curriculum_repository.dart';
import '../services/progress_service.dart';
import 'chapter_screen.dart';

int _chapterExerciseCount(Chapter chapter) =>
    chapter.lessonExercises.values.fold(0, (sum, list) => sum + list.length);

class LessonsScreen extends StatefulWidget {
  final int moduleNumber;

  const LessonsScreen({super.key, required this.moduleNumber});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  late final Future<Module> _moduleFuture = CurriculumRepository.loadModule(
    widget.moduleNumber,
  );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;

    return FutureBuilder<bool>(
      future: ProgressService.isModuleUnlocked(widget.moduleNumber),
      builder: (context, snapshot) {
        final unlocked = widget.moduleNumber == 1 || (snapshot.data ?? false);
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (!unlocked) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Finalizează Modulul 1 pentru a debloca Modulul ${widget.moduleNumber}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return FutureBuilder<Module>(
          future: _moduleFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Eroare curriculum: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            final module = snapshot.data!;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 32,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Module Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.20),
                          AppColors.primary.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.18),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.60),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${module.number}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Modulul ${module.number}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                module.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'CAPITOLE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...module.chapters.map(
                    (chapter) => _ChapterCardAsync(
                      chapter: chapter,
                      moduleNumber: module.number,
                      moduleTitle: module.title,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ChapterCardAsync extends StatelessWidget {
  final Chapter chapter;
  final int moduleNumber;
  final String moduleTitle;

  const _ChapterCardAsync({
    required this.chapter,
    required this.moduleNumber,
    required this.moduleTitle,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: ProgressService.isChapterUnlocked(moduleNumber, chapter.number),
      builder: (context, snap) {
        final isUnlocked = snap.connectionState != ConnectionState.done
            ? chapter.number == 1
            : (snap.data ?? (chapter.number == 1));
        return _ChapterCard(
          chapter: chapter,
          isUnlocked: isUnlocked,
          moduleNumber: moduleNumber,
          moduleTitle: moduleTitle,
        );
      },
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final Chapter chapter;
  final bool isUnlocked;
  final int moduleNumber;
  final String moduleTitle;

  const _ChapterCard({
    required this.chapter,
    required this.isUnlocked,
    required this.moduleNumber,
    required this.moduleTitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUnlocked
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChapterScreen(
                  chapter: chapter,
                  moduleNumber: moduleNumber,
                  moduleName: moduleTitle,
                ),
              ),
            )
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF071520),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnlocked
                ? AppColors.primary.withOpacity(0.30)
                : AppColors.textMuted.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Chapter number badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.textMuted.withOpacity(0.08),
                border: Border.all(
                  color: isUnlocked
                      ? AppColors.primary.withOpacity(0.50)
                      : AppColors.textMuted.withOpacity(0.20),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: isUnlocked
                    ? Text(
                        '${chapter.number}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(
                        Icons.lock_rounded,
                        size: 18,
                        color: AppColors.textMuted.withOpacity(0.40),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Capitolul ${chapter.number}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isUnlocked
                          ? AppColors.primary.withOpacity(0.80)
                          : AppColors.textMuted.withOpacity(0.40),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chapter.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isUnlocked
                          ? AppColors.textPrimary
                          : AppColors.textMuted.withOpacity(0.40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      _tag(
                        Icons.book_rounded,
                        '${chapter.content.length} lecții',
                        isUnlocked,
                      ),
                      _tag(
                        Icons.quiz_rounded,
                        '${chapter.quiz.length} întrebări quiz',
                        isUnlocked,
                      ),
                      if (moduleNumber == 2 &&
                          _chapterExerciseCount(chapter) > 0)
                        _tag(
                          Icons.task_alt_rounded,
                          '${_chapterExerciseCount(chapter)} exerciții aplicative',
                          isUnlocked,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (isUnlocked)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String text, bool active) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: active
              ? AppColors.textMuted
              : AppColors.textMuted.withOpacity(0.30),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: active
                ? AppColors.textMuted
                : AppColors.textMuted.withOpacity(0.30),
          ),
        ),
      ],
    );
  }
}
