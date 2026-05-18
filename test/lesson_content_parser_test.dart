import 'package:flutter_test/flutter_test.dart';
import 'package:astrolab/utils/lesson_content_parser.dart';

void main() {
  test('parses markdown table as single step', () {
    const content = '''
**Titlu**

Intro text.

| Col A | Col B |
|-------|-------|
| one | two |
| three | four |
''';

    final steps = lessonStepsFromContent(content);
    expect(steps.any((s) => s.isTable), isTrue);
    final tableStep = steps.firstWhere((s) => s.isTable);
    expect(tableStep.table!.headers, ['Col A', 'Col B']);
    expect(tableStep.table!.rows.length, 2);
    expect(tableStep.table!.rows.first, ['one', 'two']);
  });

  test('parses meteor showers table headers', () {
    const block = '''
| Denumire | Perioada | Radiant |
|----------|----------|---------|
| Perseide | august | Perseus |
''';
    final steps = lessonStepsFromContent(block);
    expect(steps.length, 1);
    expect(steps.first.table!.headers.first, 'Denumire');
    expect(steps.first.table!.rows.first.first, 'Perseide');
  });
}
