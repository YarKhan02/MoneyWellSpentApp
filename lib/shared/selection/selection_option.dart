/// One choice in a [showSelectionSheet] list.
///
/// [value] is the stored value and never changes when the label does, so a
/// user-facing rename cannot alter what is written to the database.
class SelectionOption<T> {
  const SelectionOption({
    required this.value,
    required this.label,
    this.description,
    this.leading,
  });

  final T value;
  final String label;

  /// Optional second line, e.g. what a setting affects.
  final String? description;

  /// Optional leading visual, such as a category icon or colour swatch.
  final SelectionLeading? leading;

  /// Text matched when the sheet shows a search field.
  String get searchText => '$label ${description ?? ''}'.toLowerCase();
}

/// A small visual shown before an option's label. Kept as data rather than a
/// widget so the sheet controls sizing and selected-state colouring.
sealed class SelectionLeading {
  const SelectionLeading();
}

/// A category-style icon, identified by the keys already stored on a row.
class IconLeading extends SelectionLeading {
  const IconLeading({required this.iconKey, required this.colorKey});
  final String iconKey, colorKey;
}

/// A filled colour swatch, for accent pickers.
class SwatchLeading extends SelectionLeading {
  const SwatchLeading(this.colorKey);
  final String colorKey;
}
