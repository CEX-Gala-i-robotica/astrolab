/// Parsare conținut lecție (markdown simplu din curriculum).

class LessonTableData {

  final List<String> headers;

  final List<List<String>> rows;



  const LessonTableData({

    required this.headers,

    required this.rows,

  });

}



class LessonStep {

  final bool isTitle;

  final bool isTable;

  final String text;

  final LessonTableData? table;



  const LessonStep({

    required this.isTitle,

    this.isTable = false,

    required this.text,

    this.table,

  });



  const LessonStep.title(String title)

      : isTitle = true,

        isTable = false,

        text = title,

        table = null;



  const LessonStep.body(String body)

      : isTitle = false,

        isTable = false,

        text = body,

        table = null;



  const LessonStep.table(LessonTableData data)

      : isTitle = false,

        isTable = true,

        text = '',

        table = data;

}



/// Titlul lecției = primul rând `**…**`.

String lessonTitleFromContent(String content) {

  for (final raw in content.split('\n')) {

    final line = raw.trim();

    if (line.startsWith('**') && line.endsWith('**')) {

      return line.replaceAll('**', '').trim();

    }

  }

  return '';

}



List<LessonStep> lessonStepsFromContent(String content) {

  final steps = <LessonStep>[];

  final lines = content.split('\n');

  var i = 0;



  while (i < lines.length) {

    final line = lines[i].trim();

    if (line.isEmpty) {

      i++;

      continue;

    }



    if (_isTableRow(line) &&

        i + 1 < lines.length &&

        _isTableSeparator(lines[i + 1].trim())) {

      final block = <String>[line, lines[i + 1].trim()];

      i += 2;

      while (i < lines.length) {

        final row = lines[i].trim();

        if (row.isEmpty || !_isTableRow(row) || _isTableSeparator(row)) break;

        block.add(row);

        i++;

      }

      final table = _parseMarkdownTable(block);

      if (table != null) {

        steps.add(LessonStep.table(table));

      }

      continue;

    }



    if (line.startsWith('**') && line.endsWith('**')) {

      steps.add(LessonStep.title(line.replaceAll('**', '').trim()));

      i++;

      continue;

    }

    if (line.startsWith('•') || line.startsWith('-')) {

      steps.add(LessonStep.body(line));

      i++;

      continue;

    }

    if (RegExp(r'^\d+\.\s').hasMatch(line)) {

      steps.add(LessonStep.body(line));

      i++;

      continue;

    }

    for (final s in _splitSentences(line)) {

      if (s.trim().isNotEmpty) {

        steps.add(LessonStep.body(s.trim()));

      }

    }

    i++;

  }

  return steps;

}



bool _isTableRow(String line) =>

    line.startsWith('|') && line.endsWith('|') && line.length > 2;



bool _isTableSeparator(String line) {

  if (!_isTableRow(line)) return false;

  return RegExp(r'^\|[\s\-:|]+\|$').hasMatch(line);

}



List<String> _splitTableCells(String line) {

  return line

      .split('|')

      .map((c) => c.trim())

      .where((c) => c.isNotEmpty)

      .toList();

}



LessonTableData? _parseMarkdownTable(List<String> lines) {

  if (lines.isEmpty) return null;

  final headers = _splitTableCells(lines.first);

  if (headers.isEmpty) return null;



  final rows = <List<String>>[];

  for (var j = 1; j < lines.length; j++) {

    if (_isTableSeparator(lines[j])) continue;

    final cells = _splitTableCells(lines[j]);

    if (cells.isEmpty) continue;

    while (cells.length < headers.length) {

      cells.add('');

    }

    rows.add(cells.take(headers.length).toList());

  }



  return LessonTableData(headers: headers, rows: rows);

}



List<String> _splitSentences(String text) {

  final out = <String>[];

  final re = RegExp(r'(?<=[.!?…])\s+');

  for (final chunk in text.split(re)) {

    final t = chunk.trim();

    if (t.isNotEmpty) out.add(t);

  }

  if (out.isEmpty && text.trim().isNotEmpty) out.add(text.trim());

  return out;

}



String stripLeadBullet(String s) {

  var t = s.trimLeft();

  if (t.startsWith('•')) t = t.substring(1).trimLeft();

  if (t.startsWith('-')) t = t.substring(1).trimLeft();

  return t;

}


