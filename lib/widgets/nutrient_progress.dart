import 'package:flutter/material.dart';

import '../theme.dart';

/// 单个营养素的进度条：标签 + 数值 + 达成率进度。
/// 颜色随达成率变化：偏低橙、达标绿、偏高红。
class NutrientProgress extends StatelessWidget {
  final String label;
  final double value;
  final double target;
  final String unit;
  /// 点击营养名称的回调（用于查看食物来源）；不传则名称不可点
  final VoidCallback? onLabelTap;

  const NutrientProgress({
    super.key,
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
    this.onLabelTap,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = target > 0 ? value / target : 0.0;
    final color = ratio < 0.6
        ? AppTheme.low
        : ratio > 1.3
            ? AppTheme.high
            : AppTheme.good;
    final capped = ratio.clamp(0.0, 1.0);
    // 超过 100% 时算出超出百分比，用于数值行的小标记
    final overPercent = ratio > 1.0 ? ((ratio - 1.0) * 100).round() : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            onLabelTap == null
                ? Text(label, style: const TextStyle(fontWeight: FontWeight.w600))
                : InkWell(
                    onTap: onLabelTap,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryDark,
                              decoration: TextDecoration.underline,
                              decorationStyle: TextDecorationStyle.dotted,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(Icons.info_outline, size: 13, color: AppTheme.primaryDark),
                        ],
                      ),
                    ),
                  ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${value.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} $unit',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const TextSpan(
                    text: '  全天目标',
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  if (overPercent != null)
                    TextSpan(
                      text: '  超出$overPercent%',
                      style: const TextStyle(color: AppTheme.high, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: capped,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            color: color,
          ),
        ),
      ],
    );
  }
}
