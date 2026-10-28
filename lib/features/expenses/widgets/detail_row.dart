import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';

/// Label / value pair in the expense detail card.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.last = false,
  });
  final String label, value;
  final bool last;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : Brand.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: context.text.bodyMedium?.copyWith(color: Brand.muted),
          ),
        ),
        Expanded(child: Text(value, style: context.text.bodyLarge)),
      ],
    ),
  );
}
