import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/lesson_content_parser.dart';
import 'latex_mixed.dart';

/// Tabel markdown (capitol lecție) — stil cosmic, scroll orizontal pe ecrane înguste.
class LessonTableWidget extends StatelessWidget {
  final LessonTableData table;
  final bool isMobile;

  const LessonTableWidget({
    super.key,
    required this.table,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final colCount = table.headers.length;
    if (colCount == 0) return const SizedBox.shrink();

    const minColW = 108.0;
    final tableMinWidth = colCount * minColW;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF67E8F9).withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22D3EE).withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: tableMinWidth),
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(minColW),
              border: TableBorder.symmetric(
                inside: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0891B2).withOpacity(0.45),
                        const Color(0xFF059669).withOpacity(0.35),
                      ],
                    ),
                  ),
                  children: [for (final h in table.headers) _headerCell(h)],
                ),
                for (var r = 0; r < table.rows.length; r++)
                  TableRow(
                    decoration: BoxDecoration(
                      color: r.isEven
                          ? Colors.white.withOpacity(0.03)
                          : Colors.white.withOpacity(0.07),
                    ),
                    children: [for (final c in table.rows[r]) _bodyCell(c)],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 12,
        vertical: isMobile ? 11 : 12,
      ),
      child: LatexMixedColumn(
        source: text,
        textStyle: GoogleFonts.exo2(
          fontSize: isMobile ? 11.5 : 12.5,
          fontWeight: FontWeight.w800,
          color: Colors.white.withOpacity(0.95),
          height: 1.25,
        ),
      ),
    );
  }

  Widget _bodyCell(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 12,
        vertical: isMobile ? 10 : 11,
      ),
      child: LatexMixedColumn(
        source: text,
        textStyle: GoogleFonts.exo2(
          fontSize: isMobile ? 11 : 12,
          fontWeight: FontWeight.w500,
          color: Colors.white.withOpacity(0.82),
          height: 1.3,
        ),
      ),
    );
  }
}
