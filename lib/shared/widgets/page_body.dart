import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';

/// The standard scrolling page container: centred, width-capped, evenly
/// spaced, and always scrollable so no screen can overflow vertically.
///
/// It adds no allowance for the shell's docked bars. [Scaffold] already lays
/// the body out above `bottomNavigationBar`, so reserving space here as well
/// would leave a dead band at the end of every list.
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.gap = Brand.xl,
    this.controller,
  });

  final List<Widget> children;

  /// Vertical space between children.
  final double gap;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: Brand.contentMaxWidth),
      child: ListView.separated(
        controller: controller,
        primary: controller == null ? null : false,
        padding: const EdgeInsets.fromLTRB(
          Brand.screenPadding,
          Brand.md,
          Brand.screenPadding,
          Brand.xxl,
        ),
        itemCount: children.length,
        separatorBuilder: (_, _) => SizedBox(height: gap),
        itemBuilder: (_, i) => children[i],
      ),
    ),
  );
}
