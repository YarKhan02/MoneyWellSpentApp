import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';

/// Two items side by side when they fit, stacked when they do not.
///
/// The decision comes from the actual constraints and the viewer's text
/// scale, not from a device breakpoint — a wide phone with 200% text stacks,
/// a narrow one at normal text does not.
class ResponsivePair extends StatelessWidget {
  const ResponsivePair({
    super.key,
    required this.first,
    required this.second,
    this.gap = Brand.md,
    this.minChildWidth = 148,
  });

  final Widget first, second;
  final double gap;

  /// Below this width per child, the pair stacks.
  final double minChildWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final fits =
          constraints.maxWidth >= minChildWidth * 2 + gap &&
          !context.stacksPairs;
      if (!fits) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            first,
            SizedBox(height: gap),
            second,
          ],
        );
      }
      // IntrinsicHeight so two cards of different content still match.
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: first),
            SizedBox(width: gap),
            Expanded(child: second),
          ],
        ),
      );
    },
  );
}
