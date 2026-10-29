import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../app/providers.dart';
import '../../core/design/tokens.dart';
import '../../shared/errors.dart';
import '../../shared/widgets/widgets.dart';
import '../ledger/models.dart';
import 'csv_share.dart';
import 'widgets/erase_dialog.dart';
import 'widgets/nav_row.dart';
import 'widgets/preference_fields.dart';
import 'widgets/privacy_card.dart';
import 'widgets/settings_group.dart';
import 'widgets/switch_row.dart';

/// Book preferences, data export and erase.
///
/// The same screen doubles as the final onboarding step: in [onboarding] mode
/// it shows only the fields needed to open a book, and the data section is
/// hidden because there is nothing to export or erase yet.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
    required this.data,
    this.onboarding = false,
  });
  final LedgerSnapshot data;
  final bool onboarding;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? currency;
  final timezone = TextEditingController();
  int weekStart = DateTime.monday;
  bool reduceMotion = false, reduceTransparency = false, busy = false;
  bool budgetSignals = true;
  String? error;

  /// True when the form differs from what is stored, so the Save button can
  /// say so instead of leaving people guessing whether a change took.
  bool get hasUnsavedChanges {
    final p = widget.data.profile;
    if (p == null) return true;
    return currency != p.currency ||
        timezone.text.trim() != p.timezone ||
        weekStart != p.weekStart ||
        reduceMotion != p.reduceMotion ||
        reduceTransparency != p.reduceTransparency ||
        budgetSignals != p.budgetSignals;
  }

  @override
  void initState() {
    super.initState();
    final p = widget.data.profile;
    currency = p?.currency;
    timezone.text = p?.timezone ?? '';
    weekStart = p?.weekStart ?? DateTime.monday;
    reduceMotion = p?.reduceMotion ?? false;
    reduceTransparency = p?.reduceTransparency ?? false;
    budgetSignals = p?.budgetSignals ?? true;
    if (p == null) _detectTimezone();
  }

  @override
  void dispose() {
    timezone.dispose();
    super.dispose();
  }

  /// Currency is locked once any expense history or budget exists.
  bool get currencyLocked =>
      !widget.onboarding &&
      (widget.data.expenses.isNotEmpty || widget.data.budgets.isNotEmpty);

  Future<void> _detectTimezone() async {
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      if (mounted && timezone.text.isEmpty) {
        setState(() => timezone.text = zone);
      }
    } catch (_) {
      /* Manual timezone selection remains available offline. */
    }
  }

  Future<void> save() async {
    _begin();
    try {
      if (currency == null) {
        throw const FormatException('Choose your currency.');
      }
      if (!tz.timeZoneDatabase.locations.containsKey(timezone.text.trim())) {
        throw const FormatException(
          'Choose a valid IANA timezone, such as Asia/Karachi.',
        );
      }
      await ref
          .read(repositoryProvider)
          .saveProfile(
            currency!,
            timezone.text.trim(),
            weekStart,
            reduceMotion: reduceMotion,
            reduceTransparency: reduceTransparency,
            budgetSignals: budgetSignals,
          );
      if (!mounted) return;
      if (!widget.onboarding) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Preferences saved.')));
      }
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> export() async {
    _begin();
    try {
      final csv = await ref.read(repositoryProvider).exportCsv();
      if (!mounted) return;
      // iPad needs an anchor rect for the share popover.
      final box = context.findRenderObject() as RenderBox?;
      await shareExpenseCsv(
        csv,
        originRect: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Export could not be shared. Your entries are safe. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> erase() async {
    final confirmation = await showEraseDialog(context);
    if (confirmation == null || !mounted) return;
    setState(() => busy = true);
    try {
      await ref.read(repositoryProvider).erase(confirmation);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = friendlyError(e);
        });
      }
    }
  }

  void _begin() => setState(() {
    busy = true;
    error = null;
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.onboarding ? 'Make it yours' : 'Settings'),
    ),
    body: SafeArea(
      child: PageBody(
        children: [
          if (widget.onboarding)
            Text(
              'Set your currency and timezone. Both shape every total you will see.',
              style: context.text.bodyMedium?.copyWith(color: Brand.muted),
            ),
          SettingsGroup(
            title: 'Preferences',
            children: [
              CurrencyField(
                value: currency,
                locked: currencyLocked,
                enabled: !busy,
                onChanged: (value) => setState(() => currency = value),
              ),
              preferenceFieldGap,
              TimezoneField(controller: timezone),
              preferenceFieldGap,
              WeekStartField(
                value: weekStart,
                enabled: !busy,
                onChanged: (v) => setState(() => weekStart = v),
              ),
            ],
          ),
          if (!widget.onboarding)
            SettingsGroup(
              title: 'Budget & accessibility',
              children: [
                SwitchRow(
                  title: 'Budget reminders',
                  subtitle: 'Show in-app signals at 75%, 90% and 100%.',
                  value: budgetSignals,
                  onChanged: (v) => setState(() => budgetSignals = v),
                ),
                SwitchRow(
                  title: 'Reduce motion',
                  subtitle: 'Minimise animations and transitions.',
                  value: reduceMotion,
                  onChanged: (v) => setState(() => reduceMotion = v),
                ),
                SwitchRow(
                  title: 'Opaque surfaces',
                  subtitle: 'Turn off translucency and blur.',
                  value: reduceTransparency,
                  onChanged: (v) => setState(() => reduceTransparency = v),
                  last: true,
                ),
              ],
            ),
          if (error != null)
            Semantics(
              liveRegion: true,
              child: Text(
                error!,
                style: TextStyle(color: context.scheme.error),
              ),
            ),
          _SaveButton(
            busy: busy,
            onboarding: widget.onboarding,
            hasUnsavedChanges: hasUnsavedChanges,
            onPressed: save,
          ),
          if (!widget.onboarding) ...[
            SettingsGroup(
              title: 'Your data',
              children: [
                NavRow(
                  icon: Icons.category_outlined,
                  title: 'Manage categories',
                  onTap: () => context.push('/settings/categories'),
                ),
                NavRow(
                  icon: Icons.ios_share,
                  title: 'Export expenses as CSV',
                  subtitle: 'An export, not a restorable backup.',
                  onTap: busy ? null : export,
                  last: true,
                ),
              ],
            ),
            // Erasing sits in its own group, away from the everyday
            // actions, so it cannot be reached by mistake.
            SettingsGroup(
              title: 'Danger zone',
              children: [
                NavRow(
                  icon: Icons.delete_forever_outlined,
                  title: 'Erase local data',
                  subtitle:
                      'Permanently removes every expense, budget and preference on this device.',
                  destructive: true,
                  onTap: busy ? null : erase,
                  last: true,
                ),
              ],
            ),
            const PrivacyCard(),
          ],
        ],
      ),
    ),
  );
}

/// Primary action for the preferences form.
///
/// Outside onboarding it stays enabled but states whether there is anything
/// to save, so an unsaved change is never silently lost on navigation.
class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.busy,
    required this.onboarding,
    required this.hasUnsavedChanges,
    required this.onPressed,
  });

  final bool busy, onboarding, hasUnsavedChanges;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (onboarding) {
      return FilledButton(
        onPressed: busy ? null : onPressed,
        child: Text(busy ? 'Working…' : 'Start my book'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasUnsavedChanges && !busy) ...[
          Row(
            children: [
              const Icon(
                Icons.edit_outlined,
                size: Brand.smallIconSize,
                color: Brand.muted,
              ),
              const SizedBox(width: Brand.sm),
              Expanded(
                child: Text(
                  'You have unsaved changes.',
                  style: context.text.bodyMedium?.copyWith(color: Brand.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: Brand.sm),
        ],
        FilledButton(
          onPressed: busy ? null : onPressed,
          child: Text(busy ? 'Working…' : 'Save preferences'),
        ),
      ],
    );
  }
}
