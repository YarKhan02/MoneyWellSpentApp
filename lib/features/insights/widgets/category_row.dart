import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../ledger/category_share.dart';

/// One category's line in the insights breakdown: avatar, name, amount and
/// a share bar.
class CategoryRow extends StatelessWidget {
  const CategoryRow({super.key, required this.share, required this.chartColor});
  final CategoryShare share;
  final Color chartColor;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      CategoryAvatar(
        iconKey: share.category.icon,
        colorKey: share.category.color,
        size: Brand.avatarSizeSmall,
      ),
      const SizedBox(width: Brand.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    share.label,
                    style: context.text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: AmountText(
                    money: share.money,
                    style: context.text.bodyLarge,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Brand.sm),
            Row(
              children: [
                Expanded(
                  child: ProgressBar(
                    percent: share.fraction * 100,
                    color: chartColor,
                    track: context.tokens.track,
                    label: '${share.label} share',
                    height: 8,
                  ),
                ),
                const SizedBox(width: Brand.sm),
                Text(
                  share.percentLabel,
                  style: context.text.labelMedium?.copyWith(color: Brand.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}
