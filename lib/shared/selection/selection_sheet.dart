import 'package:flutter/material.dart';
import '../../core/design/category_style.dart';
import '../../core/design/tokens.dart';
import '../widgets/category_avatar.dart';
import 'selection_option.dart';

/// Shows [options] in a rounded modal bottom sheet and returns the chosen
/// value, or null when dismissed without choosing.
///
/// This is the app's single selection pattern. It replaces Material's popup
/// menus, which open as large rectangles over the middle of the screen,
/// cover surrounding content and clip badly on short viewports.
///
/// The sheet scrolls its own list, respects safe areas and the keyboard,
/// never grows past most of the viewport, and closes on a single choice.
/// Dismissing changes nothing, so the caller keeps its previous selection.
Future<T?> showSelectionSheet<T>({
  required BuildContext context,
  required String title,
  required List<SelectionOption<T>> options,
  T? selected,
  String? description,

  /// Above this many options the sheet gains a search field.
  int searchThreshold = 12,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (sheetContext) => _SelectionSheet<T>(
    title: title,
    description: description,
    options: options,
    selected: selected,
    searchable: options.length > searchThreshold,
  ),
);

class _SelectionSheet<T> extends StatefulWidget {
  const _SelectionSheet({
    required this.title,
    required this.description,
    required this.options,
    required this.selected,
    required this.searchable,
  });

  final String title;
  final String? description;
  final List<SelectionOption<T>> options;
  final T? selected;
  final bool searchable;

  @override
  State<_SelectionSheet<T>> createState() => _SelectionSheetState<T>();
}

class _SelectionSheetState<T> extends State<_SelectionSheet<T>> {
  final _query = TextEditingController();
  late List<SelectionOption<T>> _visible = widget.options;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _filter(String text) {
    final needle = text.trim().toLowerCase();
    setState(
      () => _visible = needle.isEmpty
          ? widget.options
          : widget.options
                .where((o) => o.searchText.contains(needle))
                .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Never taller than most of the viewport, and shorter than that when the
    // option list is short — the sheet should not look empty.
    final maxHeight = MediaQuery.sizeOf(context).height * .75;
    return Padding(
      // Lifts the sheet above the keyboard when the search field has focus.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Brand.xl,
                0,
                Brand.xl,
                Brand.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: context.text.titleLarge,
                    // The sheet announces itself as a chooser.
                    semanticsLabel: '${widget.title}. Choose one option.',
                  ),
                  if (widget.description != null) ...[
                    const SizedBox(height: Brand.xs),
                    Text(
                      widget.description!,
                      style: context.text.bodyMedium?.copyWith(
                        color: Brand.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Brand.xl,
                  0,
                  Brand.xl,
                  Brand.md,
                ),
                child: TextField(
                  controller: _query,
                  onChanged: _filter,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    prefixIcon: Icon(Icons.search, size: Brand.iconSize),
                  ),
                ),
              ),
            Flexible(
              child: _visible.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.fromLTRB(
                        Brand.xl,
                        Brand.sm,
                        Brand.xl,
                        Brand.xxl,
                      ),
                      child: Text('No matching options.'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: Brand.sm),
                      itemCount: _visible.length,
                      itemBuilder: (context, i) => _OptionRow<T>(
                        option: _visible[i],
                        isSelected: _visible[i].value == widget.selected,
                        onTap: () => Navigator.pop(context, _visible[i].value),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final SelectionOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: isSelected,
    inMutuallyExclusiveGroup: true,
    button: true,
    child: InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: Brand.minTouchTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: Brand.xl,
          vertical: Brand.md,
        ),
        color: isSelected
            ? Brand.forest.withValues(alpha: .08)
            : Colors.transparent,
        child: Row(
          children: [
            if (option.leading != null) ...[
              _Leading(leading: option.leading!),
              const SizedBox(width: Brand.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option.label,
                    style: context.text.titleMedium?.copyWith(
                      color: isSelected ? Brand.forest : null,
                    ),
                  ),
                  if (option.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      option.description!,
                      style: context.text.bodyMedium?.copyWith(
                        color: Brand.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: Brand.sm),
              const Icon(Icons.check, color: Brand.forest, size: Brand.iconSize),
            ],
          ],
        ),
      ),
    ),
  );
}

class _Leading extends StatelessWidget {
  const _Leading({required this.leading});
  final SelectionLeading leading;

  @override
  Widget build(BuildContext context) => switch (leading) {
    IconLeading(:final iconKey, :final colorKey) => CategoryAvatar(
      iconKey: iconKey,
      colorKey: colorKey,
      size: Brand.avatarSizeSmall,
    ),
    SwatchLeading(:final colorKey) => ColorSwatchDot(colorKey: colorKey),
  };
}

/// Filled circle showing a category accent colour.
class ColorSwatchDot extends StatelessWidget {
  const ColorSwatchDot({super.key, required this.colorKey, this.size = 28});
  final String colorKey;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: categoryColor(colorKey),
      shape: BoxShape.circle,
      border: Border.all(color: context.tokens.cardBorder),
    ),
  );
}
