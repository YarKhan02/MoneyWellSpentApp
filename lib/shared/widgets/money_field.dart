import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import 'app_card.dart';

/// Borderless large-type amount entry inside a card, prefixed with the book's
/// currency code. Shared by the expense form and the budget cap form.
class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    required this.currency,
    required this.label,
    this.textStyle,
    this.autofocus = false,
  });
  final TextEditingController controller;
  final String currency, label;
  final TextStyle? textStyle;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => AppCard(
    child: TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: textStyle ?? context.text.displaySmall,
      decoration: InputDecoration(
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        labelText: label,
        prefixText: '$currency ',
        prefixStyle: context.text.titleLarge?.copyWith(color: Brand.muted),
      ),
    ),
  );
}
