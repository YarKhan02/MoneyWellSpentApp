import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';

/// Small translucent label chip, used on hero surfaces.
class Pill extends StatelessWidget {
  const Pill({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Brand.md, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: context.text.labelMedium?.copyWith(color: Brand.hay),
    ),
  );
}
