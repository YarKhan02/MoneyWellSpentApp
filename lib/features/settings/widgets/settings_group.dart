import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../shared/widgets/widgets.dart';

/// A titled group of settings rendered as one card.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.title,
    required this.children,
  });
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: Brand.sm, left: Brand.xs),
        child: Text(title, style: context.text.titleMedium),
      ),
      AppCard(child: Column(children: children)),
    ],
  );
}
