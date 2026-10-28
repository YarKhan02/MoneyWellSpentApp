import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/design/category_style.dart';
import '../../../core/design/tokens.dart';
import '../../../shared/errors.dart';
import '../../../shared/selection/selection_sheet.dart' show ColorSwatchDot;
import '../../ledger/models.dart';

/// Create or rename a custom category.
///
/// Presented as a keyboard-aware bottom sheet rather than a dialog: with the
/// keyboard open an AlertDialog squeezes its content until the icon grid and
/// the Save button are unreachable. Here the sheet is lifted by the keyboard
/// inset and its body scrolls, so the name field, any validation message and
/// the actions all stay reachable.
Future<void> showCategoryEditor(
  BuildContext context,
  WidgetRef ref, [
  Category? category,
]) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => _CategoryEditor(category: category, ref: ref),
);

class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({required this.category, required this.ref});
  final Category? category;
  final WidgetRef ref;

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  late final _name = TextEditingController(text: widget.category?.name);
  late String _icon = widget.category?.icon ?? '7';
  late String _color = widget.category?.color ?? 'forest';
  String? _error;
  bool _saving = false;

  bool get _isNew => widget.category == null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.ref
          .read(repositoryProvider)
          .saveCategory(
            id: widget.category?.id,
            name: _name.text,
            icon: _icon,
            color: _color,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = friendlyError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Brand.xl, 0, Brand.xl, Brand.md),
            child: Text(
              _isNew ? 'New category' : 'Edit category',
              style: context.text.titleLarge,
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: Brand.xl),
              children: [
                TextField(
                  controller: _name,
                  maxLength: 40,
                  autofocus: _isNew,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saving ? null : _save(),
                  decoration: const InputDecoration(
                    labelText: 'Category name',
                  ),
                ),
                const SizedBox(height: Brand.sm),
                Text('Icon', style: context.text.labelLarge),
                const SizedBox(height: Brand.sm),
                _IconGrid(
                  selected: _icon,
                  onSelected: (value) => setState(() => _icon = value),
                ),
                const SizedBox(height: Brand.xl),
                Text('Accent colour', style: context.text.labelLarge),
                const SizedBox(height: Brand.sm),
                _SwatchRow(
                  selected: _color,
                  onSelected: (value) => setState(() => _color = value),
                ),
                if (_error != null) ...[
                  const SizedBox(height: Brand.lg),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: TextStyle(color: context.scheme.error),
                    ),
                  ),
                ],
                const SizedBox(height: Brand.xl),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Brand.xl,
              0,
              Brand.xl,
              Brand.lg,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: Brand.md),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving…' : 'Save category'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Icon choices laid out with [Wrap], so the number of columns follows the
/// available width instead of a fixed grid count.
class _IconGrid extends StatelessWidget {
  const _IconGrid({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Brand.sm,
    runSpacing: Brand.sm,
    children: [
      for (var i = 0; i < categoryIcons.length; i++)
        _ChoiceTile(
          isSelected: selected == '$i',
          semanticLabel: categoryIconLabels[i],
          onTap: () => onSelected('$i'),
          child: Icon(categoryIcons[i], size: Brand.iconSize),
        ),
    ],
  );
}

/// Labeled colour swatches. The readable name is shown beside the swatch so
/// the choice does not depend on colour perception alone.
class _SwatchRow extends StatelessWidget {
  const _SwatchRow({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Brand.sm,
    runSpacing: Brand.sm,
    children: [
      for (final key in categoryColorKeys)
        _ChoiceTile(
          isSelected: selected == key,
          semanticLabel: categoryColorName(key),
          onTap: () => onSelected(key),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColorSwatchDot(colorKey: key, size: 20),
              const SizedBox(width: Brand.sm),
              Text(categoryColorName(key), style: context.text.labelLarge),
            ],
          ),
        ),
    ],
  );
}

/// Shared selectable tile: full-size touch target, visible selected state
/// expressed with a border and a check, not colour alone.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.isSelected,
    required this.semanticLabel,
    required this.onTap,
    required this.child,
  });

  final bool isSelected;
  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: semanticLabel,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: isSelected
            ? Brand.forest.withValues(alpha: .12)
            : t.neutralCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Brand.smallRadius),
          side: BorderSide(
            color: isSelected ? Brand.forest : t.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
              minWidth: Brand.minTouchTarget,
              minHeight: Brand.minTouchTarget,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: Brand.md),
            child: ExcludeSemantics(child: child),
          ),
        ),
      ),
    );
  }
}
