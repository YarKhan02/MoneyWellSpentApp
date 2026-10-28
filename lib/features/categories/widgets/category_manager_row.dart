import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../ledger/models.dart';

/// One category in the manage-categories list.
///
/// Archive and edit are offered for custom categories only — built-in ones
/// are permanent, so they carry no actions at all rather than disabled
/// buttons that invite a tap.
class CategoryManagerRow extends StatelessWidget {
  const CategoryManagerRow({
    super.key,
    required this.category,
    required this.onArchiveToggled,
    required this.onEdit,
  });
  final Category category;
  final VoidCallback onArchiveToggled, onEdit;

  String get _status => category.system
      ? 'Built-in'
      : category.archived
      ? 'Archived · kept in history'
      : 'Custom';

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: Brand.lg,
      vertical: Brand.sm,
    ),
    child: Row(
      children: [
        CategoryAvatar(
          iconKey: category.icon,
          colorKey: category.color,
          size: Brand.avatarSizeSmall,
        ),
        const SizedBox(width: Brand.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                category.name,
                style: context.text.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _status,
                style: context.text.labelMedium?.copyWith(color: Brand.muted),
              ),
            ],
          ),
        ),
        if (!category.system) ...[
          const SizedBox(width: Brand.sm),
          _RowAction(
            tooltip: category.archived
                ? 'Restore ${category.name}'
                : 'Archive ${category.name}',
            icon: category.archived
                ? Icons.unarchive_outlined
                : Icons.archive_outlined,
            onPressed: onArchiveToggled,
          ),
          _RowAction(
            tooltip: 'Edit ${category.name}',
            icon: Icons.edit_outlined,
            onPressed: onEdit,
          ),
        ],
      ],
    ),
  );
}

/// Visually small icon action that still fills a full touch target.
class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    iconSize: Brand.iconSize,
    constraints: const BoxConstraints.tightFor(
      width: Brand.minTouchTarget,
      height: Brand.minTouchTarget,
    ),
    padding: EdgeInsets.zero,
    icon: Icon(icon),
  );
}
