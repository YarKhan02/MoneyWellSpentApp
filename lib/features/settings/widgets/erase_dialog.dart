import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';

/// Confirmation word the person must type to erase their book.
const eraseConfirmation = 'ERASE';

/// Asks the person to type [eraseConfirmation] before wiping local data.
/// Returns the text they typed, or null if they cancelled.
Future<String?> showEraseDialog(BuildContext context) async {
  final input = TextEditingController();
  final accepted = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Erase this local book?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'This permanently erases all expenses, budgets, custom categories and preferences. Export first. Type ERASE to continue.',
          ),
          const SizedBox(height: Brand.lg),
          TextField(
            controller: input,
            decoration: const InputDecoration(labelText: 'Type ERASE'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(c, input.text == eraseConfirmation),
          child: const Text('Erase local data'),
        ),
      ],
    ),
  );
  final typed = input.text;
  // Dispose after the dialog's closing transition releases its text field.
  Future<void>.delayed(const Duration(seconds: 1), input.dispose);
  return accepted == true ? typed : null;
}
