import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../shared/widgets/widgets.dart';

/// Plain-language statement of what the app does and does not do with data,
/// plus the open-source licence list.
class PrivacyCard extends StatelessWidget {
  const PrivacyCard({super.key});

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Privacy, by design', style: context.text.titleMedium),
        const SizedBox(height: Brand.sm),
        Text(
          'Your ledger stays on this device. No account, analytics or network service is used, and an export only goes where you send it. Uninstalling may remove your records — export first.',
          style: context.text.bodyMedium?.copyWith(color: Brand.muted),
        ),
        const SizedBox(height: Brand.sm),
        TextButton(
          onPressed: () => showLicensePage(
            context: context,
            applicationName: 'Money Well Spent',
          ),
          child: const Text('Open-source licenses'),
        ),
      ],
    ),
  );
}
