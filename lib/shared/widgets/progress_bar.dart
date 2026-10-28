import 'package:flutter/material.dart';

/// Rounded progress bar with accessible semantics.
/// [label] names what is being measured; [value] is the spoken percentage.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.fraction,
    required this.color,
    required this.track,
    required this.label,
    required this.value,
    this.height = 6,
  });
  final double fraction, height;
  final Color color, track;
  final String label, value;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(999),
    child: LinearProgressIndicator(
      value: fraction,
      minHeight: height,
      color: color,
      backgroundColor: track,
      semanticsLabel: label,
      semanticsValue: value,
    ),
  );
}
