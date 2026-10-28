import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import 'app_card.dart';

/// One card holding a list of rows separated by hairline dividers.
///
/// Replaces stacks of individually shadowed cards: a list reads as a single
/// surface, and only the rows inside it need to be scanned.
///
/// Rows supply their own padding so that any ink response fills the full
/// width of the surface; this widget only insets the dividers to match.
class ListSurface extends StatelessWidget {
  const ListSurface({
    super.key,
    required this.children,
    this.dividerIndent = Brand.lg,
  });

  final List<Widget> children;
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: dividerIndent,
                endIndent: dividerIndent,
                color: context.tokens.divider,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}
