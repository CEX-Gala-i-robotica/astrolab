// Reformat / validate `assets/curriculum/module_1.json` (parse → canonical map → pretty JSON).
//
// Run from repo root:
//   dart run tool/export_curriculum_json.dart
//
import 'dart:convert';
import 'dart:io';

import 'package:astrolab/data/curriculum_parser.dart';

void main() {
  final file = File('assets/curriculum/module_1.json');
  if (!file.existsSync()) {
    // ignore: avoid_print
    stderr.writeln('Lipsește ${file.path}. Adaugă fișierul JSON înainte de a rula acest tool.');
    exitCode = 1;
    return;
  }

  final raw = file.readAsStringSync();
  final module = CurriculumParser.parseModuleString(raw);
  final map = CurriculumParser.moduleToJsonMap(module);
  file.writeAsStringSync(JsonEncoder.withIndent('  ').convert(map));
  // ignore: avoid_print
  print('Rescris ${file.absolute.path} (${file.lengthSync()} bytes)');
}
