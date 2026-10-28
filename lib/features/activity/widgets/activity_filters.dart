import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../core/design/tokens.dart';
import '../../../core/time/period.dart';
import '../../../shared/selection/selection.dart';
import '../../ledger/formatting.dart';
import '../../ledger/models.dart';

/// Category and date-range filters for the activity list, plus a reset.
///
/// Both open the app's shared selection pattern rather than a dropdown
/// menu. They sit side by side when both fit and wrap onto their own lines
/// when the viewport is narrow or the text is large. An applied filter is
/// obvious at a glance, and the reset appears only when there is something
/// to reset.
///
/// Purely presentational — the screen owns the filter state.
class ActivityFilters extends StatelessWidget {
  const ActivityFilters({
    super.key,
    required this.profile,
    required this.categories,
    required this.category,
    required this.start,
    required this.end,
    required this.onCategoryChanged,
    required this.onRangeChanged,
    required this.onCleared,
  });

  final Profile profile;
  final List<Category> categories;
  final String? category;
  final DateTime? start, end;
  final ValueChanged<String?> onCategoryChanged;
  final void Function(DateTime start, DateTime end) onRangeChanged;
  final VoidCallback onCleared;

  bool get _filtered => start != null || category != null;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Brand.md,
    runSpacing: Brand.md,
    children: [
      _FilterChipButton(
        icon: Icons.sell_outlined,
        label: _categoryLabel,
        active: category != null,
        onTap: () => _pickCategory(context),
      ),
      _FilterChipButton(
        icon: Icons.date_range_outlined,
        label: start == null
            ? 'All dates'
            : profile.formatRange(CalendarRange(start!, end!)),
        active: start != null,
        onTap: () => _pickRange(context),
      ),
      if (_filtered)
        TextButton.icon(
          onPressed: onCleared,
          icon: const Icon(Icons.close, size: Brand.smallIconSize),
          label: const Text('Clear filters'),
        ),
    ],
  );

  String get _categoryLabel => category == null
      ? 'All categories'
      : categories.where((c) => c.id == category).firstOrNull?.name ??
            'All categories';

  Future<void> _pickCategory(BuildContext context) async {
    const allValue = '';
    final chosen = await showSelectionSheet<String>(
      context: context,
      title: 'Filter by category',
      selected: category ?? allValue,
      options: [
        const SelectionOption(value: allValue, label: 'All categories'),
        for (final c in categories)
          SelectionOption(
            value: c.id,
            label: c.name,
            description: c.archived ? 'Archived' : null,
            leading: IconLeading(iconKey: c.icon, colorKey: c.color),
          ),
      ],
    );
    if (chosen != null) onCategoryChanged(chosen == allValue ? null : chosen);
  }

  /// Converts the picked local days into a half-open UTC window
  /// `[start of first day, start of day after last)`.
  Future<void> _pickRange(BuildContext context) async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: DateTime(2200),
    );
    if (selected == null) return;
    final loc = tz.getLocation(profile.timezone);
    onRangeChanged(
      tz.TZDateTime(
        loc,
        selected.start.year,
        selected.start.month,
        selected.start.day,
      ).toUtc(),
      tz.TZDateTime(
        loc,
        selected.end.year,
        selected.end.month,
        selected.end.day + 1,
      ).toUtc(),
    );
  }
}

/// Compact, pill-shaped filter trigger. Shows an obvious active state so it
/// is clear at a glance that the list below is filtered.
class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      selected: active,
      child: Material(
        color: active ? Brand.forest.withValues(alpha: .12) : t.neutralCard,
        shape: StadiumBorder(
          side: BorderSide(color: active ? Brand.forest : t.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: Brand.minTouchTarget,
              maxWidth: 260,
            ),
            padding: const EdgeInsets.symmetric(horizontal: Brand.lg),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: Brand.smallIconSize,
                  color: active ? Brand.forest : Brand.muted,
                ),
                const SizedBox(width: Brand.sm),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelLarge?.copyWith(
                      color: active ? Brand.forest : context.scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: Brand.xs),
                Icon(
                  Icons.expand_more,
                  size: Brand.smallIconSize,
                  color: Brand.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
