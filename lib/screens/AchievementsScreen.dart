import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/lesson_models.dart';
import '../services/curriculum_repository.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cosmic_background.dart';

class AchievementsScreen extends StatefulWidget {
  final String uid;
  final String token;
  final String firstName;
  final String lastName;

  const AchievementsScreen({
    super.key,
    required this.uid,
    required this.token,
    required this.firstName,
    required this.lastName,
  });

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late Future<List<_DiplomaEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_DiplomaEntry>> _load() async {
    final progress = await ProgressService.getProgress();
    final modules = <Module>[];

    for (final moduleNumber in [1, 2]) {
      try {
        modules.add(await CurriculumRepository.loadModule(moduleNumber));
      } catch (_) {}
    }

    final fullName = '${widget.firstName} ${widget.lastName}'.trim();
    final studentName = fullName.isEmpty ? 'Elev AstroLab' : fullName;
    final diplomas = <_DiplomaEntry>[];

    for (final module in modules) {
      for (final chapter in module.chapters) {
        if (_isChapterStrictlyComplete(progress, module.number, chapter)) {
          diplomas.add(
            _DiplomaEntry(
              kind: _DiplomaKind.chapter,
              title: 'Capitolul ${chapter.number}',
              subtitle: chapter.title,
              completedTitle: 'Capitolul ${chapter.number}: ${chapter.title}',
              certificateTitle: chapter.title,
              templateAsset: 'diploma_capitol',
              name: studentName,
              moduleNumber: module.number,
              chapterNumber: chapter.number,
            ),
          );
        }
      }

      if (_isModuleStrictlyComplete(progress, module)) {
        diplomas.add(
          _DiplomaEntry(
            kind: _DiplomaKind.module,
            title: 'Modulul ${module.number}',
            subtitle: module.title,
            completedTitle: 'Modulul ${module.number}: ${module.title}',
            certificateTitle: module.title,
            templateAsset: 'diploma_modul',
            name: studentName,
            moduleNumber: module.number,
          ),
        );
      }
    }

    diplomas.sort((a, b) {
      if (a.kind != b.kind) return a.kind == _DiplomaKind.module ? -1 : 1;
      final moduleCompare = a.moduleNumber.compareTo(b.moduleNumber);
      if (moduleCompare != 0) return moduleCompare;
      return (a.chapterNumber ?? 0).compareTo(b.chapterNumber ?? 0);
    });

    return diplomas;
  }

  bool _isModuleStrictlyComplete(Map<String, dynamic> progress, Module module) {
    for (final chapter in module.chapters) {
      if (!_isChapterStrictlyComplete(progress, module.number, chapter)) {
        return false;
      }
    }

    if (module.finalQuiz.isEmpty) return true;
    return _isPassed(progress['module_${module.number}_final_quiz']);
  }

  bool _isChapterStrictlyComplete(
    Map<String, dynamic> progress,
    int moduleNumber,
    Chapter chapter,
  ) {
    for (var i = 0; i < chapter.content.length; i++) {
      if (progress['module_${moduleNumber}_chapter_${chapter.number}_lesson_$i'] !=
          true) {
        return false;
      }

      if (chapter.exercisesAfterLesson(i).isNotEmpty) {
        final exercise =
            progress['module_${moduleNumber}_chapter_${chapter.number}_lesson_${i}_exercise'];
        if (!_isPassed(exercise)) return false;
      }
    }

    if (chapter.quiz.isEmpty) return true;
    return _isPassed(
      progress['module_${moduleNumber}_chapter_${chapter.number}_quiz'],
    );
  }

  bool _isPassed(dynamic value) {
    if (value is! Map || value['completed'] != true) return false;
    final percentage = value['percentage'];
    if (percentage is num) return percentage >= 75;
    return value['passed'] == true;
  }

  Future<void> _generateDiploma(_DiplomaEntry entry) async {
    final pdf = pw.Document();
    final imageData = await rootBundle.load(
      'assets/certificates/${entry.templateAsset}.png',
    );
    final bgImage = pw.MemoryImage(imageData.buffer.asUint8List());

    const pageW = 842.0;
    const pageH = 595.0;
    final nameFontSize = _fitFont(entry.name, base: 42, min: 30, maxChars: 26);
    final titleFontSize = _fitFont(
      entry.certificateTitle,
      base: entry.kind == _DiplomaKind.chapter ? 14 : 16,
      min: 9,
      maxChars: 44,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Stack(
          children: [
            pw.Positioned.fill(child: pw.Image(bgImage, fit: pw.BoxFit.fill)),
            pw.Positioned(
              left: pageW * 0.14,
              right: pageW * 0.23,
              top: pageH * 0.395,
              child: pw.Center(
                child: pw.Text(
                  entry.name,
                  maxLines: 1,
                  style: pw.TextStyle(
                    fontSize: nameFontSize,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#2D0A4E'),
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
            pw.Positioned(
              left: pageW * 0.47,
              right: pageW * 0.08,
              top: pageH * 0.565,
              child: pw.Center(
                child: pw.Text(
                  entry.certificateTitle,
                  maxLines: 2,
                  style: pw.TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#2D0A4E'),
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final bytes = await pdf.save();
    if (!kIsWeb) {
      try {
        final printers = await Printing.listPrinters();
        final printer = printers.cast<Printer?>().firstWhere(
          (printer) =>
              printer?.name.toLowerCase().contains('microsoft print to pdf') ??
              false,
          orElse: () => null,
        );
        if (printer != null) {
          await Printing.directPrintPdf(
            printer: printer,
            name: '${entry.title} - ${entry.name}.pdf',
            format: PdfPageFormat.a4.landscape,
            onLayout: (_) async => bytes,
          );
          return;
        }
      } catch (_) {}
    }

    await Printing.layoutPdf(
      name: '${entry.title} - ${entry.name}.pdf',
      format: PdfPageFormat.a4.landscape,
      onLayout: (_) async => bytes,
    );
  }

  double _fitFont(
    String text, {
    required double base,
    required double min,
    required int maxChars,
  }) {
    if (text.length <= maxChars) return base;
    final ratio = maxChars / text.length;
    return (base * ratio).clamp(min, base).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width < 640 ? 18.0 : 32.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const CosmicBackground(),
          SafeArea(
            child: FutureBuilder<List<_DiplomaEntry>>(
              future: _future,
              builder: (context, snapshot) {
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _topBar(context)),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 34),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1040),
                            child: _content(snapshot),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(AsyncSnapshot<List<_DiplomaEntry>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Padding(
        padding: EdgeInsets.only(top: 120),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (snapshot.hasError || !snapshot.hasData) {
      return _emptyState(
        icon: Icons.error_outline_rounded,
        title: 'Nu am putut încărca realizările',
        message: 'Încearcă din nou peste câteva momente.',
      );
    }

    final diplomas = snapshot.data!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _hero(diplomas.length),
        const SizedBox(height: 18),
        if (diplomas.isEmpty)
          _emptyState(
            icon: Icons.workspace_premium_outlined,
            title: 'Încă nu ai diplome',
            message:
                'Finalizează complet un capitol sau un modul: lecții, exerciții aplicative și quiz-uri.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 860 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: diplomas.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: columns == 2 ? 1.78 : 1.62,
                ),
                itemBuilder: (_, index) => _diplomaCard(diplomas[index]),
              );
            },
          ),
      ],
    );
  }

  Widget _topBar(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Realizări',
          style: GoogleFonts.orbitron(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _hero(int count) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: AppColors.cardGradient,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.primary.withOpacity(0.22)),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.08),
          blurRadius: 34,
          offset: const Offset(0, 18),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.14),
            border: Border.all(color: AppColors.primary.withOpacity(0.35)),
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: AppColors.primary,
            size: 30,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Diplome AstroLab',
                style: GoogleFonts.orbitron(
                  color: AppColors.textPrimary,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                count == 0
                    ? 'Diplomele apar doar pentru capitole și module finalizate complet.'
                    : '$count ${count == 1 ? 'diplomă obținută' : 'diplome obținute'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _diplomaCard(_DiplomaEntry entry) {
    final isModule = entry.kind == _DiplomaKind.module;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isModule ? Colors.amberAccent : AppColors.primary)
              .withOpacity(0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isModule ? Colors.amberAccent : AppColors.primary)
                      .withOpacity(0.13),
                ),
                child: Icon(
                  isModule
                      ? Icons.military_tech_rounded
                      : Icons.emoji_events_rounded,
                  color: isModule ? Colors.amberAccent : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isModule ? 'Diplomă de modul' : 'Diplomă de capitol',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            entry.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _generateDiploma(entry),
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Descarcă'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: AppColors.surface.withOpacity(0.92),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.primary.withOpacity(0.16)),
    ),
    child: Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 42),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

enum _DiplomaKind { module, chapter }

class _DiplomaEntry {
  final _DiplomaKind kind;
  final String title;
  final String subtitle;
  final String completedTitle;
  final String certificateTitle;
  final String templateAsset;
  final String name;
  final int moduleNumber;
  final int? chapterNumber;

  const _DiplomaEntry({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.completedTitle,
    required this.certificateTitle,
    required this.templateAsset,
    required this.name,
    required this.moduleNumber,
    this.chapterNumber,
  });
}
