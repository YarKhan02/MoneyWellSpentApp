import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';

/// Compact page title with an optional secondary line and trailing action,
/// all on one row. Replaces a separate app bar on the shell's four tabs, so
/// each screen starts with content rather than 52 logical pixels of chrome.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;

  /// One short line. Keep it out of everyday dashboards.
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: context.text.headlineMedium),
            if (subtitle != null) ...[
              const SizedBox(height: Brand.xs),
              Text(
                subtitle!,
                style: context.text.bodyMedium?.copyWith(color: Brand.muted),
              ),
            ],
          ],
        ),
      ),
      if (action != null) ...[const SizedBox(width: Brand.sm), action!],
    ],
  );
}
