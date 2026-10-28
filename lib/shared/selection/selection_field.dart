import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import 'selection_option.dart';
import 'selection_sheet.dart';

/// A field that looks like a text input but opens [showSelectionSheet].
///
/// Using [InputDecorator] keeps it visually identical to the real inputs
/// beside it — the same border, label behaviour, helper text and error
/// colours — while behaving as a button for assistive technology.
class SelectionField<T> extends StatelessWidget {
  const SelectionField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.sheetTitle,
    this.sheetDescription,
    this.helperText,
    this.enabled = true,
    this.locked = false,
    this.placeholder = 'Choose…',
  });

  final String label;
  final T? value;
  final List<SelectionOption<T>> options;
  final ValueChanged<T> onChanged;

  /// Defaults to [label].
  final String? sheetTitle, sheetDescription, helperText;

  final bool enabled;

  /// Shows a padlock and blocks opening, for values the rules freeze.
  /// Prefer this over simply disabling, so the reason stays visible.
  final bool locked;

  final String placeholder;

  SelectionOption<T>? get _current =>
      options.where((o) => o.value == value).firstOrNull;

  bool get _interactive => enabled && !locked;

  Future<void> _open(BuildContext context) async {
    final chosen = await showSelectionSheet<T>(
      context: context,
      title: sheetTitle ?? label,
      description: sheetDescription,
      options: options,
      selected: value,
    );
    // Null means dismissed; the previous selection stands.
    if (chosen != null) onChanged(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    return Semantics(
      button: _interactive,
      enabled: _interactive,
      label: label,
      value: current?.label ?? placeholder,
      child: InkWell(
        onTap: _interactive ? () => _open(context) : null,
        borderRadius: BorderRadius.circular(Brand.inputRadius),
        child: InputDecorator(
          isEmpty: current == null,
          decoration: InputDecoration(
            labelText: label,
            helperText: helperText,
            helperMaxLines: 3,
            enabled: _interactive,
            suffixIcon: Icon(
              locked ? Icons.lock_outline : Icons.expand_more,
              size: Brand.iconSize,
              color: locked ? Brand.muted : null,
            ),
          ),
          child: Text(
            current?.label ?? placeholder,
            style: context.text.bodyLarge?.copyWith(
              color: current == null ? Brand.muted : null,
            ),
          ),
        ),
      ),
    );
  }
}
