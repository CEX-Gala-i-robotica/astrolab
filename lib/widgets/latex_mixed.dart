import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Segmente LaTeX **inline** (`$…$`, `\(…\)`).
enum _InKind { plain, inline }

class _InSeg {
  final _InKind kind;
  final String tex;
  _InSeg(this.kind, this.tex);
}

/// Bloc mare: text (cu inline) sau **display** (`$$…$$`, `\[…\]`).
enum _OutKind { textRun, display }

class _OutSeg {
  final _OutKind kind;
  final String value;
  _OutSeg(this.kind, this.value);
}

int _nextSingleDollar(String s, int from) {
  var j = from;
  while (j < s.length) {
    if (s.codeUnitAt(j) != 0x24) {
      j++;
      continue;
    }
    if (j + 1 < s.length && s.codeUnitAt(j + 1) == 0x24) {
      j += 2;
      continue;
    }
    return j;
  }
  return -1;
}

int _nextDisplayStart(String s, int from) {
  final a = s.indexOf(r'$$', from);
  final b = s.indexOf(r'\[', from);
  final cands = [a, b].where((x) => x >= from).toList();
  if (cands.isEmpty) return -1;
  return cands.reduce((x, y) => x < y ? x : y);
}

/// Împarte la `$$` și `\[ … \]` (formule pe rând).
List<_OutSeg> _splitDisplayOuter(String input) {
  final out = <_OutSeg>[];
  var i = 0;
  while (i < input.length) {
    if (i + 1 < input.length &&
        input.codeUnitAt(i) == 0x24 &&
        input.codeUnitAt(i + 1) == 0x24) {
      final end = input.indexOf(r'$$', i + 2);
      if (end != -1) {
        out.add(_OutSeg(_OutKind.display, input.substring(i + 2, end).trim()));
        i = end + 2;
        continue;
      }
    }
    if (input.startsWith(r'\[', i)) {
      final end = input.indexOf(r'\]', i + 2);
      if (end != -1) {
        out.add(_OutSeg(_OutKind.display, input.substring(i + 2, end).trim()));
        i = end + 2;
        continue;
      }
    }

    final next = _nextDisplayStart(input, i);
    if (next == -1) {
      out.add(_OutSeg(_OutKind.textRun, input.substring(i)));
      break;
    }
    if (next > i) {
      out.add(_OutSeg(_OutKind.textRun, input.substring(i, next)));
      i = next;
      continue;
    }
    out.add(_OutSeg(_OutKind.textRun, input[i]));
    i++;
  }
  return out;
}

/// În interiorul unui paragraf: `$…$`, `\(…\)`.
List<_InSeg> _splitInline(String input) {
  final out = <_InSeg>[];
  var i = 0;
  while (i < input.length) {
    if (input.startsWith(r'\(', i)) {
      final end = input.indexOf(r'\)', i + 2);
      if (end != -1) {
        out.add(_InSeg(_InKind.inline, input.substring(i + 2, end).trim()));
        i = end + 2;
        continue;
      }
    }
    if (input.codeUnitAt(i) == 0x24 &&
        (i + 1 >= input.length || input.codeUnitAt(i + 1) != 0x24)) {
      final end = input.indexOf(r'$', i + 1);
      if (end != -1) {
        out.add(_InSeg(_InKind.inline, input.substring(i + 1, end).trim()));
        i = end + 1;
        continue;
      }
    }

    int next = -1;
    final p1 = input.indexOf(r'\(', i);
    final p2 = _nextSingleDollar(input, i);
    if (p1 != -1 && p1 >= i) next = next == -1 ? p1 : (p1 < next ? p1 : next);
    if (p2 != -1 && p2 >= i) next = next == -1 ? p2 : (p2 < next ? p2 : next);

    if (next == -1) {
      out.add(_InSeg(_InKind.plain, input.substring(i)));
      break;
    }
    if (next > i) {
      out.add(_InSeg(_InKind.plain, input.substring(i, next)));
      i = next;
      continue;
    }
    out.add(_InSeg(_InKind.plain, input[i]));
    i++;
  }
  return out;
}

List<InlineSpan> _italicSpansList(String text, TextStyle base) {
  final spans = <InlineSpan>[];
  final regex = RegExp(r'\*(.*?)\*');
  var last = 0;
  for (final m in regex.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start)));
    }
    spans.add(
      TextSpan(
        text: m.group(1),
        style: base.merge(
          const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF334155)),
        ),
      ),
    );
    last = m.end;
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last)));
  }
  return spans.isEmpty ? [TextSpan(text: text)] : spans;
}

Widget _mathTex(
  String tex,
  MathStyle style,
  TextStyle textStyle, {
  bool scrollWide = false,
}) {
  final trimmed = tex.trim();
  if (trimmed.isEmpty) return const SizedBox.shrink();
  final math = Math.tex(
    trimmed,
    mathStyle: style,
    textStyle: textStyle,
    settings: const TexParserSettings(strict: Strict.ignore),
    onErrorFallback: (err) => Text(
      trimmed,
      style: textStyle.copyWith(
        color: const Color(0xFFB91C1C),
        fontSize: (textStyle.fontSize ?? 14) * 0.92,
      ),
    ),
  );
  if (scrollWide && style == MathStyle.display) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: math,
    );
  }
  return math;
}

/// Randare text + LaTeX: **display** `$$…$$`, `\[…\]`; **inline** `$…$`, `\(…\)`.
/// Păstrează `*italic*` în text.
class LatexMixedColumn extends StatelessWidget {
  final String source;
  final TextStyle textStyle;
  final TextAlign textAlign;
  final double inlineMathScale;

  const LatexMixedColumn({
    super.key,
    required this.source,
    required this.textStyle,
    this.textAlign = TextAlign.start,
    this.inlineMathScale = 0.96,
  });

  @override
  Widget build(BuildContext context) {
    final outer = _splitDisplayOuter(source);
    if (outer.isEmpty) return const SizedBox.shrink();

    final cross = textAlign == TextAlign.center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: cross,
      children: [
        for (var o = 0; o < outer.length; o++) ...[
          if (o > 0 && outer[o].kind == _OutKind.display) const SizedBox(height: 6),
          _buildOuter(outer[o]),
        ],
      ],
    );
  }

  Widget _buildOuter(_OutSeg seg) {
    if (seg.kind == _OutKind.textRun && seg.value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    if (seg.kind == _OutKind.display) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: _mathTex(
          seg.value,
          MathStyle.display,
          textStyle.copyWith(
            fontSize: (textStyle.fontSize ?? 16) * 1.1,
            color: textStyle.color,
          ),
          scrollWide: true,
        ),
      );
    }

    final inline = _splitInline(seg.value);
    final baseSize = textStyle.fontSize ?? 16;
    final mathStyle = textStyle.copyWith(
      fontSize: baseSize * 1.05,
      color: textStyle.color,
    );
    final spans = <InlineSpan>[];
    for (final part in inline) {
      if (part.kind == _InKind.plain && part.tex.isNotEmpty) {
        spans.addAll(_italicSpansList(part.tex, textStyle));
      } else if (part.kind == _InKind.inline && part.tex.isNotEmpty) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Transform.scale(
              scale: inlineMathScale,
              alignment: Alignment.bottomCenter,
              child: _mathTex(
                part.tex,
                MathStyle.text,
                mathStyle,
              ),
            ),
          ),
        );
      }
    }
    if (spans.isEmpty) return const SizedBox.shrink();
    return Text.rich(
      TextSpan(style: textStyle, children: spans),
      textAlign: textAlign,
    );
  }
}
