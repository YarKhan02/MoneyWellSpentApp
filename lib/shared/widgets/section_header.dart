import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';

/// A row heading with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: context.text.titleLarge)),
      ?action,
    ],
  );
}
