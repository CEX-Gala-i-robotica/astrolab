import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';
import '../services/progress_service.dart';
import '../widgets/cosmic_background.dart';
import 'quiz_analysis_screen.dart';

enum _SortMode { recent, scoreDesc, scoreAsc }

class TestHistoryScreen extends StatefulWidget {
  const TestHistoryScreen({super.key});

  @override
  State<TestHistoryScreen> createState() => _TestHistoryScreenState();
}

class _HistoryEntry {
  final String title;
  final String subtitle;
  final int moduleNumber;
  final int? chapterNumber;
  final int? lessonIndex;
  final int percentage;
  final int correct;
  final int total;
  final DateTime timestamp;
  final bool passed;
  final List<QuizAttempt> attempts;
  final String type;

  const _HistoryEntry({
    required this.title,
    required this.subtitle,
    required this.moduleNumber,
    required this.chapterNumber,
    required this.lessonIndex,
    required this.percentage,
    required this.correct,
    required this.total,
    required this.timestamp,
    required this.passed,
    required this.attempts,
    required this.type,
  });
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  List<_HistoryEntry> _entries = [];
  bool _loading = true;
  _SortMode _sortMode = _SortMode.recent;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final progress = await ProgressService.getProgress();
    final entries = <_HistoryEntry>[];

    for (final item in progress.entries) {
      final key = item.key;
      final value = item.value;
      if (value is! Map) continue;
      if (value['completed'] != true) continue;
      if (value['equivalated'] == true) continue;

      final attempts = _parseAttempts(value['attempts']);
      if (attempts.isEmpty) continue;

      final timestamp = _parseDate(value['timestamp']);
      final percentage = (value['percentage'] as num?)?.round() ?? 0;
      final correct = (value['correct'] as num?)?.round() ?? 0;
      final total = (value['total'] as num?)?.round() ?? 0;
      final passed = value['passed'] == true;

      final chapterQuiz = RegExp(
        r'^module_(\d+)_chapter_(\d+)_quiz$',
      ).firstMatch(key);
      final moduleFinal = RegExp(r'^module_(\d+)_final_quiz$').firstMatch(key);
      final exercise = RegExp(
        r'^module_(\d+)_chapter_(\d+)_lesson_(\d+)_exercise$',
      ).firstMatch(key);

      if (chapterQuiz != null) {
        final moduleNumber = int.parse(chapterQuiz.group(1)!);
        final chapterNumber = int.parse(chapterQuiz.group(2)!);
        entries.add(
          _HistoryEntry(
            title: 'Quiz Capitol $chapterNumber',
            subtitle: 'Modulul $moduleNumber',
            moduleNumber: moduleNumber,
            chapterNumber: chapterNumber,
            lessonIndex: null,
            percentage: percentage,
            correct: correct,
            total: total,
            timestamp: timestamp,
            passed: passed,
            attempts: attempts,
            type: 'chapter_quiz',
          ),
        );
        continue;
      }

      if (moduleFinal != null) {
        final moduleNumber = int.parse(moduleFinal.group(1)!);
        entries.add(
          _HistoryEntry(
            title: 'Test Final Modul $moduleNumber',
            subtitle: 'Evaluare modul',
            moduleNumber: moduleNumber,
            chapterNumber: null,
            lessonIndex: null,
            percentage: percentage,
            correct: correct,
            total: total,
            timestamp: timestamp,
            passed: passed,
            attempts: attempts,
            type: 'module_final_quiz',
          ),
        );
        continue;
      }

      if (exercise != null) {
        final moduleNumber = int.parse(exercise.group(1)!);
        final chapterNumber = int.parse(exercise.group(2)!);
        final lessonIndex = int.parse(exercise.group(3)!);
        entries.add(
          _HistoryEntry(
            title: 'Exercitii Lectia ${lessonIndex + 1}',
            subtitle: 'Modul $moduleNumber, Capitol $chapterNumber',
            moduleNumber: moduleNumber,
            chapterNumber: chapterNumber,
            lessonIndex: lessonIndex,
            percentage: percentage,
            correct: correct,
            total: total,
            timestamp: timestamp,
            passed: passed,
            attempts: attempts,
            type: 'lesson_exercise',
          ),
        );
      }
    }

    setState(() {
      _entries = entries;
      _applySorting();
      _loading = false;
    });
  }

  List<QuizAttempt> _parseAttempts(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((m) {
      return QuizAttempt(
        questionIndex: (m['questionIndex'] as num?)?.toInt() ?? 0,
        selectedAnswer: (m['selectedAnswer'] as num?)?.toInt() ?? -1,
        correctAnswer: (m['correctAnswer'] as num?)?.toInt() ?? -1,
        isCorrect: m['isCorrect'] == true,
        isPartiallyCorrect: m['isPartiallyCorrect'] == true,
        scoreFraction: (m['scoreFraction'] as num?)?.toDouble() ?? 0,
        question: m['question']?.toString() ?? '',
        openAnswers: m['openAnswers'] is List
            ? List<String>.from(m['openAnswers'])
            : const [],
        feedback: m['feedback']?.toString() ?? '',
      );
    }).toList();
  }

  DateTime _parseDate(dynamic raw) {
    if (raw is String) {
      return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _applySorting() {
    switch (_sortMode) {
      case _SortMode.recent:
        _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      case _SortMode.scoreDesc:
        _entries.sort((a, b) {
          final score = b.percentage.compareTo(a.percentage);
          return score == 0 ? b.timestamp.compareTo(a.timestamp) : score;
        });
      case _SortMode.scoreAsc:
        _entries.sort((a, b) {
          final score = a.percentage.compareTo(b.percentage);
          return score == 0 ? b.timestamp.compareTo(a.timestamp) : score;
        });
    }
  }

  void _setSort(_SortMode mode) {
    setState(() {
      _sortMode = mode;
      _applySorting();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 640;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const CosmicBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, isMobile),
                if (!_loading) _buildSortBar(),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _entries.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 32,
                            vertical: 16,
                          ),
                          itemCount: _entries.length,
                          itemBuilder: (context, index) =>
                              _buildEntry(context, _entries[index]),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isMobile) {
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
          const Text(
            'Istoric teste si exercitii',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF071520).withOpacity(0.60),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withOpacity(0.10),
            width: 0.5,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text(
              'Sortare:',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(width: 10),
            _sortChip('Recente', _SortMode.recent, Icons.access_time_rounded),
            const SizedBox(width: 8),
            _sortChip(
              'Scor desc',
              _SortMode.scoreDesc,
              Icons.trending_down_rounded,
            ),
            const SizedBox(width: 8),
            _sortChip(
              'Scor asc',
              _SortMode.scoreAsc,
              Icons.trending_up_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortChip(String label, _SortMode mode, IconData icon) {
    final selected = _sortMode == mode;
    return GestureDetector(
      onTap: () => _setSort(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.20)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary.withOpacity(0.60)
                : AppColors.primary.withOpacity(0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntry(BuildContext context, _HistoryEntry entry) {
    final color = entry.percentage >= 75
        ? Colors.greenAccent
        : entry.percentage >= 50
        ? Colors.orangeAccent
        : Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuizAnalysisScreen(
              title: entry.title,
              moduleNumber: entry.moduleNumber,
              chapterNumber: entry.chapterNumber,
              lessonIndex: entry.lessonIndex,
              type: entry.type,
              attempts: entry.attempts,
              percentage: entry.percentage,
              correct: entry.correct,
              total: entry.total,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF071520),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.16)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.12),
                  border: Border.all(
                    color: color.withOpacity(0.40),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${entry.percentage}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _badge(
                          entry.passed ? 'Promovat' : 'Nepromovat',
                          entry.passed ? Colors.greenAccent : Colors.redAccent,
                        ),
                        Text(
                          '${entry.correct}/${entry.total} corecte',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          _formatDate(entry.timestamp),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 52, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text(
            'Niciun test completat manual',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Testele echivalate automat nu apar aici.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    if (dt.millisecondsSinceEpoch == 0) return '';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}
