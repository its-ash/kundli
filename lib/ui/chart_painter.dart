import 'package:flutter/material.dart';

import '../engine/engine.dart';

/// Draws a birth chart as a North Indian diamond (houses fixed, signs move)
/// or a South Indian grid (signs fixed, houses move).
class ChartPainter extends CustomPainter {
  ChartPainter({
    required this.chart,
    required this.south,
    required this.line,
    required this.sign,
    required this.planet,
    required this.accent,
    required this.fill,
  });

  final BirthChart chart;
  final bool south;
  final Color line, sign, planet, accent, fill;

  /// Planet labels per rashi index; the Lagna adds "Asc".
  List<List<String>> _byRashi() {
    final r = List.generate(12, (_) => <String>[]);
    r[chart.lagna.rashi].add('Asc');
    for (final p in chart.grahas) {
      r[p.rashi].add('${p.graha!.abbr}${p.retro && p.graha! != Graha.rahu && p.graha! != Graha.ketu ? '*' : ''}');
    }
    return r;
  }

  void _label(Canvas canvas, Offset center, int rashi, List<String> items, double unit) {
    final signPainter = TextPainter(
      text: TextSpan(text: '${rashi + 1}', style: TextStyle(color: sign, fontSize: unit * 0.075, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    final tp = TextPainter(
      text: TextSpan(
        children: [
          for (var i = 0; i < items.length; i++)
            TextSpan(
              text: i == 0 ? items[i] : '  ${items[i]}',
              style: TextStyle(
                color: items[i] == 'Asc' ? accent : planet,
                fontSize: unit * 0.068,
                fontWeight: items[i] == 'Asc' ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: unit * 0.22);
    final total = signPainter.height + (items.isEmpty ? 0 : tp.height + 2);
    final top = center.dy - total / 2;
    signPainter.paint(canvas, Offset(center.dx - signPainter.width / 2, top));
    if (items.isNotEmpty) tp.paint(canvas, Offset(center.dx - tp.width / 2, top + signPainter.height + 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final byRashi = _byRashi();
    final rect = Rect.fromLTWH(0, 0, s, s);
    canvas.drawRect(rect, Paint()..color = fill);
    canvas.drawRect(rect, stroke);

    if (south) {
      // Rows of signs from the top-left, clockwise from Meena.
      const grid = [
        [11, 0, 1, 2],
        [10, -1, -1, 3],
        [9, -1, -1, 4],
        [8, 7, 6, 5],
      ];
      final c = s / 4;
      for (var i = 1; i < 4; i++) {
        final a = Offset(i * c, 0), b = Offset(i * c, s);
        final a2 = Offset(0, i * c), b2 = Offset(s, i * c);
        if (i == 2) {
          canvas.drawLine(Offset(i * c, 0), Offset(i * c, c), stroke);
          canvas.drawLine(Offset(i * c, 3 * c), Offset(i * c, s), stroke);
          canvas.drawLine(Offset(0, i * c), Offset(c, i * c), stroke);
          canvas.drawLine(Offset(3 * c, i * c), Offset(s, i * c), stroke);
        } else {
          canvas.drawLine(a, b, stroke);
          canvas.drawLine(a2, b2, stroke);
        }
      }
      for (var row = 0; row < 4; row++) {
        for (var col = 0; col < 4; col++) {
          final r = grid[row][col];
          if (r < 0) continue;
          final cell = Rect.fromLTWH(col * c, row * c, c, c);
          if (r == chart.lagna.rashi) {
            canvas.drawLine(cell.topLeft, cell.topLeft + Offset(c * 0.22, 0), Paint()..color = accent..strokeWidth = 3);
            canvas.drawLine(cell.topLeft, cell.topLeft + Offset(0, c * 0.22), Paint()..color = accent..strokeWidth = 3);
          }
          _label(canvas, cell.center, r, byRashi[r], s);
        }
      }
      return;
    }

    // North Indian: two diagonals and the inner diamond.
    final t = Offset(s / 2, 0), r = Offset(s, s / 2), b = Offset(s / 2, s), l = Offset(0, s / 2);
    canvas.drawLine(Offset.zero, Offset(s, s), stroke);
    canvas.drawLine(Offset(s, 0), Offset(0, s), stroke);
    canvas.drawPath(
      Path()
        ..moveTo(t.dx, t.dy)
        ..lineTo(r.dx, r.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(l.dx, l.dy)
        ..close(),
      stroke,
    );
    final centers = <Offset>[
      Offset(s / 2, s / 4), // 1
      Offset(s / 4, s / 8), // 2
      Offset(s / 8, s / 4), // 3
      Offset(s / 4, s / 2), // 4
      Offset(s / 8, 3 * s / 4), // 5
      Offset(s / 4, 7 * s / 8), // 6
      Offset(s / 2, 3 * s / 4), // 7
      Offset(3 * s / 4, 7 * s / 8), // 8
      Offset(7 * s / 8, 3 * s / 4), // 9
      Offset(3 * s / 4, s / 2), // 10
      Offset(7 * s / 8, s / 4), // 11
      Offset(3 * s / 4, s / 8), // 12
    ];
    for (var h = 0; h < 12; h++) {
      final rashi = (chart.lagna.rashi + h) % 12;
      _label(canvas, centers[h], rashi, byRashi[rashi], s);
    }
  }

  @override
  bool shouldRepaint(ChartPainter old) =>
      old.chart != chart || old.south != south || old.line != line || old.planet != planet || old.fill != fill;
}
