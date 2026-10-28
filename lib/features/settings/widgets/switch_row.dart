import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';

/// Title, explanation and a switch — one toggleable preference.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.last = false,
  });
  final String title, subtitle;
  final bool value, last;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : Brand.md),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: context.text.titleMedium),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: context.text.bodyMedium?.copyWith(color: Brand.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: Brand.md),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: Brand.forest,
        ),
      ],
    ),
  );
}
