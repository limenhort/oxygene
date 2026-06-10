import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'pipe_logic.dart';

class PipeDrawler extends StatelessWidget {
  final String genome;
  final int activeKnot;

  final bool fit;

  final bool hideRoot;

  final double leafScale;

  const PipeDrawler({
    super.key,
    required this.genome,
    required this.activeKnot,
    this.fit = false,
    this.hideRoot = false,
    this.leafScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final knots = genome.split(',').where((k) => k.isNotEmpty).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return CustomPaint(
          size: size,
          isComplex: true,
          willChange: false,
          painter: PipeDrawlerPainter(
            knots: knots,
            selected: activeKnot,
            fit: fit,
            hideRoot: hideRoot,
            leafScale: leafScale,
          ),
        );
      },
    );
  }
}

class _Seg {
  final Offset? from;
  final Offset to;
  final bool isKnot;
  final bool selected;
  final String token;
  _Seg(this.from, this.to, this.isKnot, this.selected, this.token);
}

class PipeDrawlerPainter extends CustomPainter {
  final List<String> knots;
  final int selected;
  final bool fit;
  final bool hideRoot;

  /// множитель радиуса точек-листьев (кончиков). 1.0 — штатный размер.
  final double leafScale;

  PipeDrawlerPainter({
    required this.knots,
    required this.selected,
    this.fit = false,
    this.hideRoot = false,
    this.leafScale = 1.0,
  });

  final Paint flowerPaint = Paint()
    ..color = Colors.blueAccent
    ..strokeWidth = 5
    ..style = PaintingStyle.fill;

  final Paint flowerRedPaint = Paint()
    ..color = Colors.red
    ..strokeWidth = 5
    ..style = PaintingStyle.fill;

  final Paint flowerYellowPaint = Paint()
    ..color = Colors.yellow
    ..strokeWidth = 5
    ..style = PaintingStyle.fill;

  final Paint flowerBlackPaint = Paint()
    ..color = Colors.black
    ..strokeWidth = 5
    ..style = PaintingStyle.fill;

  final Paint flowerWhitePaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 5
    ..style = PaintingStyle.fill;

  final Paint tapPaint = Paint()
    ..color = Colors.purpleAccent
    ..strokeWidth = 5
    ..style = PaintingStyle.fill;

  final Paint knotPaint = Paint()
    ..color = Colors.teal
    ..strokeWidth = 5
    ..style = PaintingStyle.fill;

  final Paint hvostPaint = Paint()
    ..color = Colors.grey
    ..strokeWidth = 1;

  List<_Seg> _segments(Size size) {
    final logic = PipeLogic();
    final segs = <_Seg>[];
    try {
      for (int i = 0; i < knots.length; i++) {
        final knot = knots[i];
        final isKnot = logic.isKnot(knot);
        if (isKnot) {
          logic.addKnot(knot);
        } else {
          logic.addList(knot);
        }
        segs.add(_Seg(
          logic.ancestorOffset(size),
          logic.currentOffset(size),
          isKnot,
          i == selected,
          knot,
        ));
      }
    } catch (_) {}
    return segs;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 333.0;
    hvostPaint.strokeWidth = scale;

    var segs = _segments(size);
    if (segs.isEmpty) return;

    if (hideRoot && segs.length > 1) {
      final rest = segs.sublist(1);
      rest[0] = _Seg(
          null, rest[0].to, rest[0].isKnot, rest[0].selected, rest[0].token);
      segs = rest;
    }

    Offset Function(Offset) map = (p) => p;
    if (fit) {
      double minX = double.infinity, minY = double.infinity;
      double maxX = -double.infinity, maxY = -double.infinity;
      void acc(Offset o) {
        minX = math.min(minX, o.dx);
        minY = math.min(minY, o.dy);
        maxX = math.max(maxX, o.dx);
        maxY = math.max(maxY, o.dy);
      }

      for (final s in segs) {
        acc(s.to);
        if (s.from != null) acc(s.from!);
      }

      const pad = 6.0;
      final bw = math.max(maxX - minX, 1.0);
      final bh = math.max(maxY - minY, 1.0);
      final availW = math.max(size.width - 2 * pad, 1.0);
      final availH = math.max(size.height - 2 * pad, 1.0);
      final s = math.min(availW / bw, availH / bh);
      final offX = pad + (availW - bw * s) / 2 - minX * s;
      final offY = pad + (availH - bh * s) / 2 - minY * s;
      map = (p) => Offset(p.dx * s + offX, p.dy * s + offY);
    }

    for (final seg in segs) {
      final to = map(seg.to);
      if (seg.from != null) {
        canvas.drawLine(map(seg.from!), to, hvostPaint);
      }
      final isLeaf = !seg.isKnot;
      final isRedLeaf = isLeaf && seg.token.endsWith('*b');
      final isYellowLeaf = isLeaf && seg.token.endsWith('*c');
      final isBlackLeaf = isLeaf && seg.token.endsWith('*d');
      final isWhiteLeaf = isLeaf && seg.token.endsWith('*w');
      final leafPaint = isRedLeaf
          ? flowerRedPaint
          : isYellowLeaf
              ? flowerYellowPaint
              : isBlackLeaf
                  ? flowerBlackPaint
                  : isWhiteLeaf
                      ? flowerWhitePaint
                      : flowerPaint;
      final paint =
          seg.selected ? tapPaint : (seg.isKnot ? knotPaint : leafPaint);
      final radius =
          (seg.selected ? 3.0 : (seg.isKnot ? 1.5 : 2.0 * leafScale)) * scale;
      canvas.drawCircle(to, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PipeDrawlerPainter old) {
    return old.selected != selected ||
        old.fit != fit ||
        old.hideRoot != hideRoot ||
        old.leafScale != leafScale ||
        old.knots.join(',') != knots.join(',');
  }
}
