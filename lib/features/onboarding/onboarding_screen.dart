import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import '../../shared/widgets/widgets.dart';
import '../ledger/models.dart';
import '../settings/settings_screen.dart';
import 'widgets/feature_row.dart';

/// First run: a welcome page, then the preferences needed to open a book.
///
/// There is no account step — the book exists the moment preferences are
/// saved, and nothing leaves the device.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.data});
  final LedgerSnapshot data;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool showSetup = false;

  @override
  Widget build(BuildContext context) => showSetup
      ? SettingsScreen(data: widget.data, onboarding: true)
      : _Welcome(onContinue: () => setState(() => showSetup = true));
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: PageBody(
        children: [
          const SizedBox(height: Brand.xxl),
          Image.asset(
            'assets/07_stacked_logo_transparent.png',
            height: 160,
            semanticLabel: 'Money Well Spent',
          ),
          const SizedBox(height: Brand.xl),
          Text(
            'Small moments.\nMindful spending.',
            style: context.text.headlineLarge,
            textAlign: TextAlign.center,
          ),
          Text(
            'A clearer picture of where your money goes. No account needed. No connection required.',
            style: context.text.bodyLarge?.copyWith(color: Brand.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Brand.sm),
          const AppCard(
            child: Column(
              children: [
                FeatureRow(
                  icon: Icons.edit_note,
                  title: 'Capture the everyday',
                  detail: 'Log an expense in a couple of taps.',
                ),
                SizedBox(height: Brand.lg),
                FeatureRow(
                  icon: Icons.insights_outlined,
                  title: 'Find your spending rhythm',
                  detail: 'Daily, weekly, monthly and yearly views.',
                ),
                SizedBox(height: Brand.lg),
                FeatureRow(
                  icon: Icons.lock_outline,
                  title: 'Keep your ledger on your device',
                  detail: 'Private by design. Nothing leaves your phone.',
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onContinue,
            child: const Text('Continue without account'),
          ),
          TextButton(
            onPressed: onContinue,
            child: const Text('Skip introduction'),
          ),
        ],
      ),
    ),
  );
}
