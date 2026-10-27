import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../app/app.dart';
import '../../app/providers.dart';
import '../../core/design/theme.dart';
import '../../core/money/money.dart';
import '../ledger/models.dart';
import 'forms.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.data});
  final LedgerSnapshot data;
  @override
  State<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends State<OnboardingScreen> {
  bool setup = false;
  @override
  Widget build(BuildContext context) => setup
      ? PreferencesScreen(data: widget.data, onboarding: true)
      : Scaffold(
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
                AppCard(
                  child: Column(
                    children: const [
                      _Feature(
                        icon: Icons.edit_note,
                        title: 'Capture the everyday',
                        detail: 'Log an expense in a couple of taps.',
                      ),
                      SizedBox(height: Brand.lg),
                      _Feature(
                        icon: Icons.insights_outlined,
                        title: 'Find your spending rhythm',
                        detail: 'Daily, weekly, monthly and yearly views.',
                      ),
                      SizedBox(height: Brand.lg),
                      _Feature(
                        icon: Icons.lock_outline,
                        title: 'Keep your ledger on your device',
                        detail: 'Private by design. Nothing leaves your phone.',
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => setState(() => setup = true),
                  child: const Text('Continue without account'),
                ),
                TextButton(
                  onPressed: () => setState(() => setup = true),
                  child: const Text('Skip introduction'),
                ),
              ],
            ),
          ),
        );
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title, detail;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Brand.forest.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Brand.forest),
      ),
      const SizedBox(width: Brand.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: context.text.titleMedium),
            const SizedBox(height: 2),
            Text(
              detail,
              style: context.text.bodyMedium?.copyWith(color: Brand.muted),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget settingsScreen(BuildContext context, LedgerSnapshot data) =>
    PreferencesScreen(data: data);

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({
    super.key,
    required this.data,
    this.onboarding = false,
  });
  final LedgerSnapshot data;
  final bool onboarding;
  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesState();
}

class _PreferencesState extends ConsumerState<PreferencesScreen> {
  String? currency;
  final timezone = TextEditingController();
  int weekStart = 1;
  bool reduceMotion = false, reduceTransparency = false, busy = false;
  bool budgetSignals = true;
  String? error;
  @override
  void initState() {
    super.initState();
    final p = widget.data.profile;
    currency = p?.currency;
    timezone.text = p?.timezone ?? '';
    weekStart = p?.weekStart ?? 1;
    reduceMotion = p?.reduceMotion ?? false;
    reduceTransparency = p?.reduceTransparency ?? false;
    budgetSignals = p?.budgetSignals ?? true;
    if (p == null) detectTimezone();
  }

  // Currency is locked once any expense history or budget exists.
  bool get currencyLocked =>
      !widget.onboarding &&
      (widget.data.expenses.isNotEmpty || widget.data.budgets.isNotEmpty);

  Future<void> detectTimezone() async {
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      if (mounted && timezone.text.isEmpty) {
        setState(() => timezone.text = zone);
      }
    } catch (_) {
      /* Manual timezone selection remains available offline. */
    }
  }

  @override
  void dispose() {
    timezone.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
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
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final csv = await ref.read(repositoryProvider).exportCsv();
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          title: 'Money Well Spent — expense export',
          files: [
            XFile.fromData(
              utf8.encode(csv),
              mimeType: 'text/csv',
              name: 'money-well-spent.csv',
            ),
          ],
          fileNameOverrides: ['money-well-spent.csv'],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
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
            onPressed: () => Navigator.pop(c, input.text == 'ERASE'),
            child: const Text('Erase local data'),
          ),
        ],
      ),
    );
    final confirmation = input.text;
    // Dispose after the dialog's closing transition releases its text field.
    Future<void>.delayed(const Duration(seconds: 1), input.dispose);
    if (accepted != true || !mounted) return;
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.onboarding ? 'Make it yours' : 'Settings'),
    ),
    body: SafeArea(
      child: PageBody(
        children: [
          Text(
            widget.onboarding
                ? 'Your money, your perspective.'
                : 'Your private space',
            style: context.text.headlineMedium,
          ),
          Text(
            'Amounts are never converted or relabeled. Currency is locked once you have expense history or budgets.',
            style: context.text.bodyMedium?.copyWith(color: Brand.muted),
          ),
          _Group(
            title: 'Preferences',
            children: [
              DropdownButtonFormField<String>(
                initialValue: currency,
                decoration: InputDecoration(
                  labelText: 'Book currency',
                  suffixIcon: currencyLocked
                      ? const Icon(Icons.lock_outline, size: 20)
                      : null,
                  helperText: currencyLocked
                      ? 'Locked — you have expense history or budgets.'
                      : null,
                ),
                items: Money.exponents.keys
                    .map(
                      (code) =>
                          DropdownMenuItem(value: code, child: Text(code)),
                    )
                    .toList(),
                onChanged: (busy || currencyLocked)
                    ? null
                    : (value) => setState(() => currency = value),
              ),
              const SizedBox(height: Brand.lg),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: timezone.text),
                optionsBuilder: (value) => tz.timeZoneDatabase.locations.keys
                    .where(
                      (zone) =>
                          zone.toLowerCase().contains(value.text.toLowerCase()),
                    )
                    .take(30),
                onSelected: (value) => timezone.text = value,
                fieldViewBuilder: (context, controller, focus, submit) {
                  // Device timezone may arrive after the field is first built.
                  if (controller.text.isEmpty && timezone.text.isNotEmpty) {
                    controller.text = timezone.text;
                  }
                  return TextField(
                    controller: controller,
                    focusNode: focus,
                    onChanged: (value) => timezone.text = value,
                    decoration: const InputDecoration(
                      labelText: 'Timezone (IANA)',
                      hintText: 'Asia/Karachi',
                    ),
                  );
                },
              ),
              const SizedBox(height: Brand.lg),
              DropdownButtonFormField<int>(
                initialValue: weekStart,
                decoration: const InputDecoration(labelText: 'Week starts on'),
                items: [
                  for (var i = 1; i <= 7; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(
                        [
                          'Monday',
                          'Tuesday',
                          'Wednesday',
                          'Thursday',
                          'Friday',
                          'Saturday',
                          'Sunday',
                        ][i - 1],
                      ),
                    ),
                ],
                onChanged: busy ? null : (v) => setState(() => weekStart = v!),
              ),
            ],
          ),
          if (!widget.onboarding)
            _Group(
              title: 'Budget & accessibility',
              children: [
                _SwitchRow(
                  title: 'Budget reminders',
                  subtitle: 'Show in-app signals at 75%, 90% and 100%.',
                  value: budgetSignals,
                  onChanged: (v) => setState(() => budgetSignals = v),
                ),
                _SwitchRow(
                  title: 'Reduce motion',
                  subtitle: 'Minimise animations and transitions.',
                  value: reduceMotion,
                  onChanged: (v) => setState(() => reduceMotion = v),
                ),
                _SwitchRow(
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
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(
              busy
                  ? 'Working…'
                  : widget.onboarding
                  ? 'Start my book'
                  : 'Save preferences',
            ),
          ),
          if (!widget.onboarding) ...[
            _Group(
              title: 'Your data',
              children: [
                _NavRow(
                  icon: Icons.category_outlined,
                  title: 'Manage categories',
                  onTap: () => context.push('/settings/categories'),
                ),
                _NavRow(
                  icon: Icons.ios_share,
                  title: 'Export expenses as CSV',
                  subtitle:
                      'Active expenses, exact minor units, UTC timestamps. An export, not a restorable backup.',
                  onTap: busy ? null : export,
                ),
                _NavRow(
                  icon: Icons.delete_forever_outlined,
                  title: 'Erase local data',
                  destructive: true,
                  onTap: busy ? null : erase,
                  last: true,
                ),
              ],
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Privacy, by design', style: context.text.titleMedium),
                  const SizedBox(height: Brand.sm),
                  Text(
                    'Your ledger stays in local SQLite storage. No account, analytics, crash reporting or network service is used. Exports leave the app only through the destination you choose. Uninstalling may remove your records; export before uninstalling.',
                    style: context.text.bodyMedium?.copyWith(
                      color: Brand.muted,
                    ),
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
            ),
          ],
        ],
      ),
    ),
  );
}

/// A titled group of settings rendered as one card.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: Brand.md, left: Brand.xs),
        child: Text(title, style: context.text.titleLarge),
      ),
      AppCard(child: Column(children: children)),
    ],
  );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.last = false,
  });
  final String title, subtitle;
  final bool value, last;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : Brand.md),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: context.text.titleMedium),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: context.text.bodyMedium?.copyWith(color: Brand.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: Brand.md),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: Brand.forest,
        ),
      ],
    ),
  );
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
    this.last = false,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive, last;
  @override
  Widget build(BuildContext context) {
    final color = destructive ? Brand.cherry : context.scheme.onSurface;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : Brand.xs),
      child: InkWell(
        borderRadius: BorderRadius.circular(Brand.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Brand.sm),
          child: Row(
            children: [
              Icon(icon, color: destructive ? Brand.cherry : Brand.forest),
              const SizedBox(width: Brand.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: context.text.titleMedium?.copyWith(color: color),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: context.text.bodyMedium?.copyWith(
                          color: Brand.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!destructive)
                const Icon(Icons.chevron_right, color: Brand.muted),
            ],
          ),
        ),
      ),
    );
  }
}

Widget categoriesScreen(BuildContext context, LedgerSnapshot data) =>
    CategoryManager(data: data);

class CategoryManager extends ConsumerWidget {
  const CategoryManager({super.key, required this.data});
  final LedgerSnapshot data;
  Future<void> edit(
    BuildContext context,
    WidgetRef ref, [
    Category? category,
  ]) async {
    final name = TextEditingController(text: category?.name);
    String icon = category?.icon ?? '7', color = category?.color ?? 'forest';
    String? error;
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(category == null ? 'New category' : 'Edit category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  maxLength: 40,
                  decoration: const InputDecoration(labelText: 'Category name'),
                ),
                Wrap(
                  spacing: Brand.sm,
                  children: [
                    for (var i = 0; i < categoryIcons.length; i++)
                      ChoiceChip(
                        label: Icon(
                          categoryIcons[i],
                          semanticLabel: [
                            'Food',
                            'Groceries',
                            'Transport',
                            'Shopping',
                            'Bills',
                            'Health',
                            'Entertainment',
                            'Other',
                          ][i],
                        ),
                        selected: icon == '$i',
                        onSelected: (_) => setState(() => icon = '$i'),
                      ),
                  ],
                ),
                const SizedBox(height: Brand.sm),
                DropdownButtonFormField<String>(
                  initialValue: color,
                  decoration: const InputDecoration(labelText: 'Accent'),
                  items: ['forest', 'wheat', 'cherry']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => color = v!,
                ),
                if (error != null) Text(error!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setState(() => saving = true);
                      try {
                        await ref
                            .read(repositoryProvider)
                            .saveCategory(
                              id: category?.id,
                              name: name.text,
                              icon: icon,
                              color: color,
                            );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      } catch (e) {
                        if (dialogContext.mounted) {
                          setState(() {
                            saving = false;
                            error = friendlyError(e);
                          });
                        }
                      }
                    },
              child: Text(saving ? 'Saving…' : 'Save category'),
            ),
          ],
        ),
      ),
    );
    Future<void>.delayed(const Duration(seconds: 1), name.dispose);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Categories')),
    body: SafeArea(
      child: PageBody(
        children: [
          Text(
            'Archive custom categories to keep history intact. Built-in categories always remain available.',
            style: context.text.bodyMedium?.copyWith(color: Brand.muted),
          ),
          FilledButton.icon(
            onPressed: () => edit(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('New category'),
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: Brand.md,
              vertical: Brand.sm,
            ),
            child: Column(
              children: [
                for (final c in data.categories)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Brand.sm),
                    child: Row(
                      children: [
                        CategoryAvatar(
                          iconKey: c.icon,
                          colorKey: c.color,
                          size: 40,
                        ),
                        const SizedBox(width: Brand.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(c.name, style: context.text.titleMedium),
                              const SizedBox(height: 2),
                              Text(
                                c.system
                                    ? 'Built-in'
                                    : c.archived
                                    ? 'Archived · retained in history'
                                    : 'Custom',
                                style: context.text.bodyMedium?.copyWith(
                                  color: Brand.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!c.system) ...[
                          IconButton(
                            tooltip: c.archived
                                ? 'Restore category'
                                : 'Archive category',
                            icon: Icon(
                              c.archived
                                  ? Icons.unarchive_outlined
                                  : Icons.archive_outlined,
                            ),
                            onPressed: () async {
                              try {
                                await ref
                                    .read(repositoryProvider)
                                    .archiveCategory(c.id, !c.archived);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(friendlyError(e))),
                                  );
                                }
                              }
                            },
                          ),
                          IconButton(
                            tooltip: 'Edit category',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => edit(context, ref, c),
                          ),
                        ],
                      ],
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
