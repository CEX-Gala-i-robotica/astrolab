// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astrolab/main.dart';

void main() {
  testWidgets('AstroLab home loads without layout overflow',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AstroLabApp());
    // Flush HeroSection's delayed fade start; repeating animations never fully settle.
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('ASTRO'), findsWidgets);
  });
}
