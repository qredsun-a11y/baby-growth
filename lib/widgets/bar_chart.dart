import 'package:flutter/material.dart';

/// 轻量自绘柱状图（零第三方依赖）。
/// 每根柱子一个标签 + 数值，可设参考线（推荐量）。
class BarChart extends StatelessWidget {
  final List<BarItem> items;
  final double height;
  final double? referenceValue; // 参考线（如推荐量）

  const BarChart({
    super.key,
    required this.items,
    this.height = 200,
    this.referenceValue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _BarChartPainter(items: items, referenceValue: referenceValue),
      ),
    );
  }
}

class BarItem {
  final String label;
  final double value;
  final Color color;

  const BarItem({required this.label, required this.value, required this.color});
}

class _BarChartPainter extends CustomPainter {
  final List<BarItem> items;
  final double? referenceValue;

  _BarChartPainter({required this.items, required this.referenceValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;
    final left = 36.0;
    final right = 8.0;
    final top = 12.0;
    final bottom = 30.0;
    final chartW = size.width - left - right;
    final chartH = size.height - top - bottom;
    if (chartW <= 0 || chartH <= 0) return;

    double maxV = items.map((i) => i.value).reduce((a, b) => a > b ? a : b);
    if (referenceValue != null && referenceValue! > maxV) maxV = referenceValue!;
    if (maxV <= 0) maxV = 1;
    maxV *= 1.15;

    final yAt = (double v) => top + chartH * (1 - v / maxV);

    // 参考线
    if (referenceValue != null && referenceValue! > 0) {
      final ry = yAt(referenceValue!);
      final rp = Paint()
        ..color = Colors.orange.shade400
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      for (double x = left; x < left + chartW; x += 10) {
        canvas.drawLine(Offset(x, ry), Offset(x + 6, ry), rp);
      }
      _text(canvas, '推荐', Offset(2, ry - 5), TextStyle(color: Colors.orange.shade700, fontSize: 9));
    }

    final slot = chartW / items.length;
    final barW = slot * 0.62;
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final cx = left + slot * i + slot / 2;
      final y = yAt(item.value);
      final rect = Rect.fromLTRB(cx - barW / 2, y, cx + barW / 2, top + chartH);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = item.color,
      );
      // 数值
      _text(
        canvas,
        item.value.toStringAsFixed(item.value >= 100 ? 0 : 1),
        Offset(cx - 14, y - 14),
        TextStyle(color: Colors.grey.shade700, fontSize: 9),
      );
      // 标签
      _text(
        canvas,
        item.label,
        Offset(cx - (item.label.length * 5), top + chartH + 8),
        TextStyle(color: Colors.grey.shade700, fontSize: 10),
      );
    }
  }

  void _text(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) =>
      old.items != items || old.referenceValue != referenceValue;
}
