import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import '../../core/money/money.dart';
import '../../core/money/money_display.dart';

/// A money amount, with the currency code set in a smaller, quieter style
/// than the figure itself.
///
/// The two parts share one paragraph, so a long amount wraps onto a second
/// line instead of being shrunk or truncated. Financial values are never
/// scaled down to fit — the layout gives way, not the number.
class AmountText extends StatelessWidget {
  const AmountText({
    super.key,
    required this.money,
    this.style,
    this.color,
    this.currencyColor,
    this.textAlign,
    this.maxLines,
  });

  final Money money;
  final TextStyle? style;
  final Color? color, currencyColor;
  final TextAlign? textAlign;

  /// Left null so the amount may wrap. Set it only where a row is known to
  /// have room, and never alongside an ellipsis.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final base = (style ?? context.text.titleMedium ?? const TextStyle())
        .copyWith(color: color);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${money.currency} ',
            style: base.copyWith(
              // Noticeably lighter and smaller than the figure, so the eye
              // lands on the number first.
              fontSize: (base.fontSize ?? 16) * .62,
              fontWeight: FontWeight.w600,
              color: currencyColor ?? base.color?.withValues(alpha: .72),
            ),
          ),
          TextSpan(text: money.groupedDecimal),
        ],
      ),
      style: base,
      textAlign: textAlign,
      maxLines: maxLines,
      softWrap: true,
    );
  }
}
