import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/lesson_models.dart';
import '../services/progress_service.dart';
import '../widgets/chapter_path_widget.dart';
import '../widgets/cosmic_background.dart';
import 'lesson_screen.dart';
import 'quiz_screen.dart';

class ChapterScreen extends StatefulWidget {
  final Chapter chapter;
  final int moduleNumber;
  final String moduleName;

  const ChapterScreen({
    super.key,
    required this.chapter,
    required this.moduleNumber,
    required this.moduleName,
  });

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  int _pathEpoch = 0;

  Future<bool> _isChapterComplete() {
    return ProgressService.isChapterComplete(
      widget.moduleNumber,
      widget.chapter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020208),
      body: Stack(
        children: [
          const CosmicBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.16),
                          ),
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
                              child: Text(
                                'Capitolul ${widget.chapter.number}',
                                style: GoogleFonts.exo2(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.92),
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            FutureBuilder<bool>(
                              key: ValueKey('skip_$_pathEpoch'),
                              future: _isChapterComplete(),
                              builder: (context, snap) {
                                final complete = snap.data ?? false;
                                if (complete || widget.chapter.quiz.isEmpty) {
                                  return const SizedBox(width: 48);
                                }
                                return IconButton(
                                  tooltip: 'Sari capitolul prin quiz',
                                  icon: const Icon(
                                    Icons.fast_forward_rounded,
                                    color: Color(0xFF67E8F9),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (_) => QuizScreen(
                                              chapterTitle:
                                                  'Evaluare accelerat\u0103',
                                              questions: widget.chapter.quiz,
                                              moduleNumber: widget.moduleNumber,
                                              chapterNumber:
                                                  widget.chapter.number,
                                              isSkipQuiz: true,
                                            ),
                                          ),
                                        )
                                        .then((_) {
                                          if (mounted) {
                                            setState(() => _pathEpoch++);
                                          }
                                        });
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ChapterPathWidget(
                    key: ValueKey(_pathEpoch),
                    chapter: widget.chapter,
                    moduleNumber: widget.moduleNumber,
                    moduleName: widget.moduleName,
                    onLessonTap: (lessonIndex) {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => LessonScreen(
                                chapter: widget.chapter,
                                moduleName: widget.moduleName,
                                moduleNumber: widget.moduleNumber,
                                lessonIndex: lessonIndex,
                              ),
                            ),
                          )
                          .then((_) {
                            if (mounted) setState(() => _pathEpoch++);
                          });
                    },
                    onLessonExerciseTap: (lessonIndex) {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => QuizScreen(
                                chapterTitle:
                                    '${widget.moduleName} - ${widget.chapter.title}',
                                questions: widget.chapter.exercisesAfterLesson(
                                  lessonIndex,
                                ),
                                moduleNumber: widget.moduleNumber,
                                chapterNumber: widget.chapter.number,
                                exerciseLessonIndex: lessonIndex,
                              ),
                            ),
                          )
                          .then((_) {
                            if (mounted) setState(() => _pathEpoch++);
                          });
                    },
                    onQuizTap: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => QuizScreen(
                                chapterTitle:
                                    '${widget.moduleName} - ${widget.chapter.title}',
                                questions: widget.chapter.quiz,
                                moduleNumber: widget.moduleNumber,
                                chapterNumber: widget.chapter.number,
                              ),
                            ),
                          )
                          .then((_) {
                            if (mounted) setState(() => _pathEpoch++);
                          });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
