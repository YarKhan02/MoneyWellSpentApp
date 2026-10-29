import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../core/design/tokens.dart';
import '../../../core/money/money.dart';
import '../../../shared/selection/selection.dart';

/// Book currency picker. Locked once any expense or budget exists, because
/// amounts are never converted or relabelled. When locked it stays a
/// readable value with the reason beside it, rather than a greyed-out
/// control that looks broken.
class CurrencyField extends StatelessWidget {
  const CurrencyField({
    super.key,
    required this.value,
    required this.locked,
    required this.enabled,
    required this.onChanged,
  });
  final String? value;
  final bool locked, enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SelectionField<String>(
    label: 'Book currency',
    value: value,
    enabled: enabled,
    locked: locked,
    helperText: locked
        ? 'Locked because this book already has expenses or budgets. Amounts are never converted.'
        : null,
    sheetTitle: 'Book currency',
    sheetDescription:
        'Every amount in this book is recorded in this currency. It locks once you add an expense or a budget.',
    options: [
      for (final code in Money.exponents.keys)
        SelectionOption(value: code, label: code),
    ],
    onChanged: onChanged,
  );
}

/// IANA timezone picker with type-ahead over the full tz database.
/// Every period boundary and displayed date derives from this.
class TimezoneField extends StatelessWidget {
  const TimezoneField({super.key, required this.controller});

  /// Holds the canonical value; the Autocomplete field keeps its own copy.
  final TextEditingController controller;

  static const _suggestionLimit = 30;

  @override
  Widget build(BuildContext context) => Autocomplete<String>(
    initialValue: TextEditingValue(text: controller.text),
    optionsBuilder: (value) => tz.timeZoneDatabase.locations.keys
        .where((zone) => zone.toLowerCase().contains(value.text.toLowerCase()))
        .take(_suggestionLimit),
    onSelected: (value) => controller.text = value,
    optionsViewBuilder: (context, onSelected, options) => Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(Brand.inputRadius),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          // Keeps the suggestion list inside the viewport on short screens.
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .3,
            maxWidth: Brand.contentMaxWidth,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: options.length,
            itemBuilder: (context, i) {
              final option = options.elementAt(i);
              return InkWell(
                onTap: () => onSelected(option),
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: Brand.minTouchTarget,
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Brand.lg,
                    vertical: Brand.sm,
                  ),
                  child: Text(option, style: context.text.bodyLarge),
                ),
              );
            },
          ),
        ),
      ),
    ),
    fieldViewBuilder: (context, field, focus, submit) {
      // The detected device timezone can arrive after the first build.
      if (field.text.isEmpty && controller.text.isNotEmpty) {
        field.text = controller.text;
      }
      return TextField(
        controller: field,
        focusNode: focus,
        onChanged: (value) => controller.text = value,
        decoration: const InputDecoration(
          labelText: 'Timezone (IANA)',
          hintText: 'Asia/Karachi',
        ),
      );
    },
  );
}

/// Which weekday weekly periods and weekly budgets start on.
class WeekStartField extends StatelessWidget {
  const WeekStartField({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  /// Indexed by `DateTime.monday`..`DateTime.sunday` (1–7).
  static const dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) => SelectionField<int>(
    label: 'Week starts on',
    value: value,
    enabled: enabled,
    sheetTitle: 'Week starts on',
    sheetDescription: 'Sets where weekly totals and the weekly budget begin.',
    options: [
      for (var i = 1; i <= dayNames.length; i++)
        SelectionOption(value: i, label: dayNames[i - 1]),
    ],
    onChanged: onChanged,
  );
}

/// Spacing between stacked preference fields inside a settings group.
const preferenceFieldGap = SizedBox(height: Brand.lg);
