import 'package:flutter/material.dart';

/// Rounded progress bar with accessible semantics.
///
/// Takes a raw [percent] which may exceed 100 — an over-budget period is a
/// real state and the caller should not have to pre-clamp it. The bar fills
/// to at most 100%, and the spoken value is clamped too: Flutter asserts
/// that a percentage announced to assistive technology is between 0% and
/// 100%, and "150%" crashes the semantics tree.
///
/// The true, unclamped figure belongs in visible text beside the bar.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.percent,
    required this.color,
    required this.track,
    required this.label,
    this.height = 6,
  });

  /// 0–100 under normal conditions; may be greater when over budget.
  final double percent;
  final double height;
  final Color color, track;

  /// What is being measured, e.g. "Weekly budget used".
  final String label;

  double get _fraction => (percent / 100).clamp(0, 1).toDouble();
  String get _spokenValue => '${percent.clamp(0, 100).round()}%';

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(999),
    child: LinearProgressIndicator(
      value: _fraction,
      minHeight: height,
      color: color,
      backgroundColor: track,
      semanticsLabel: label,
      semanticsValue: _spokenValue,
    ),
  );
}
