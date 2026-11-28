import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

/// 轻量自绘折线图（零第三方依赖）。
/// 支持多条线、每条线自带 (x,y) 点、自动计算坐标范围、网格线、虚线样式。
class LineChart extends StatelessWidget {
  final List<LineSeries> series;
  final String yUnit;
  final double height;
  final double? xMin; // 固定 X 轴范围（如 0-36 月龄）
  final double? xMax;

  const LineChart({
    super.key,
    required this.series,
    this.yUnit = '',
    this.height = 220,
    this.xMin,
    this.xMax,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _LineChartPainter(
          series: series,
          unit: yUnit,
          xMin: xMin,
          xMax: xMax,
        ),
      ),
    );
  }
}

/// 一条折线：点列表 + 颜色 + 名称 + 是否虚线
class LineSeries {
  final List<ChartPoint> points;
  final Color color;
  final String label;
  final bool dashed;
  final double strokeWidth;

  const LineSeries({
    required this.points,
    required this.color,
    required this.label,
    this.dashed = false,
    this.strokeWidth = 2.5,
  });

  /// 便捷构造：等距 x（0,1,2...）的旧式数据
  factory LineSeries.fromValues({
    required List<double> values,
    required Color color,
    required String label,
    bool dashed = false,
    double strokeWidth = 2.5,
  }) {
    return LineSeries(
      points: [
        for (int i = 0; i < values.length; i++)
          ChartPoint(i.toDouble(), values[i]),
      ],
      color: color,
      label: label,
      dashed: dashed,
      strokeWidth: strokeWidth,
    );
  }
}

class ChartPoint {
  final double x;
  final double y;
  const ChartPoint(this.x, this.y);
}

class _LineChartPainter extends CustomPainter {
  final List<LineSeries> series;
  final String unit;
  final double? xMin;
  final double? xMax;

  _LineChartPainter({
    required this.series,
    required this.unit,
    this.xMin,
    this.xMax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;

    final left = 44.0;
    final right = 12.0;
    final top = 16.0;
    final bottom = 28.0;
    final chartW = size.width - left - right;
    final chartH = size.height - top - bottom;
    if (chartW <= 0 || chartH <= 0) return;

    final allPoints = series.expand((s) => s.points).toList();
    if (allPoints.isEmpty) return;

    double minY = allPoints.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    double maxY = allPoints.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    if (maxY - minY < 0.1) {
      minY -= 1;
      maxY += 1;
    }
    final padY = (maxY - minY) * 0.12;
    final yMin = minY - padY;
    final yMax = maxY + padY;

    double minX = xMin ?? allPoints.map((p) => p.x).reduce((a, b) => a < b ? a : b);
    double maxX = xMax ?? allPoints.map((p) => p.x).reduce((a, b) => a > b ? a : b);
    if (maxX - minX < 0.1) {
      maxX = minX + 1;
    }
    final padX = (maxX - minX) * 0.03;
    final xLo = xMin == null ? minX - padX : minX;
    final xHi = xMax == null ? maxX + padX : maxX;

    double xAt(double x) => left + chartW * (x - xLo) / (xHi - xLo);
    double yAt(double y) => top + chartH * (1 - (y - yMin) / (yMax - yMin));

    // 网格 + Y 轴刻度
    final gridPaint = Paint()
      ..color = const Color(0xFFE8E8E8)
      ..strokeWidth = 1;
    final textStyle = TextStyle(color: Colors.grey.shade600, fontSize: 10);
    const rows = 4;
    for (int i = 0; i <= rows; i++) {
      final y = top + chartH * i / rows;
      canvas.drawLine(Offset(left, y), Offset(left + chartW, y), gridPaint);
      final val = yMax - (yMax - yMin) * i / rows;
      _drawText(canvas, val.toStringAsFixed(val >= 100 ? 0 : 1), Offset(2, y - 6), textStyle);
    }

    // X 轴刻度
    _drawText(canvas, xLo.toStringAsFixed(0), Offset(left - 4, top + chartH + 8), textStyle);
    _drawText(canvas, xHi.toStringAsFixed(0), Offset(left + chartW - 16, top + chartH + 8), textStyle);

    // 画每条线
    for (final s in series) {
      if (s.points.isEmpty) continue;
      final pts = s.points
          .where((p) => p.x >= xLo && p.x <= xHi)
          .map((p) => Offset(xAt(p.x), yAt(p.y)))
          .toList();
      if (pts.isEmpty) continue;

      final linePaint = Paint()
        ..color = s.color
        ..strokeWidth = s.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (s.dashed) {
        for (int i = 0; i < pts.length - 1; i++) {
          _drawDashedSegment(canvas, pts[i], pts[i + 1], linePaint);
        }
      } else {
        if (pts.length == 1) {
          canvas.drawCircle(pts.first, 4, Paint()..color = s.color);
        } else {
          canvas.drawPoints(PointMode.polygon, pts, linePaint);
        }
        // 数据点
        for (final p in pts) {
          canvas.drawCircle(p, 3.5, Paint()..color = s.color);
          canvas.drawCircle(
            p,
            3.5,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
      }
    }

    if (unit.isNotEmpty) {
      _drawText(canvas, unit, Offset(left + 4, 2),
          TextStyle(color: Colors.grey.shade500, fontSize: 10));
    }
  }

  void _drawDashedSegment(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 6.0;
    const gap = 4.0;
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return;
    final ux = dx / len;
    final uy = dy / len;
    double pos = 0;
    while (pos < len) {
      final end = (pos + dash).clamp(0.0, len);
      canvas.drawLine(
        Offset(a.dx + ux * pos, a.dy + uy * pos),
        Offset(a.dx + ux * end, a.dy + uy * end),
        paint,
      );
      pos += dash + gap;
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.series != series ||
      oldDelegate.unit != unit ||
      oldDelegate.xMin != xMin ||
      oldDelegate.xMax != xMax;
}
