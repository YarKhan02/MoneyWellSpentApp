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
                const SizedBox(height: 24),
                Image.asset(
                  'assets/01_primary_logo.png',
                  height: 160,
                  semanticLabel: 'Money Well Spent',
                ),
                const SizedBox(height: 20),
                Text(
                  'Small moments.\nMindful spending.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const Text(
                  'A clearer picture of where your money goes. No account needed. No connection required.',
                ),
                const ListTile(
                  leading: Icon(Icons.edit_note),
                  title: Text('Capture the everyday'),
                ),
                const ListTile(
                  leading: Icon(Icons.insights_outlined),
                  title: Text('Find your spending rhythm'),
                ),
                const ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Keep your ledger on your device'),
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
            const SizedBox(height: 16),
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
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Text(
            'Choose your book currency and timezone. Amounts are never converted or relabeled. Currency is locked once you have expense history or budgets.',
          ),
          DropdownButtonFormField<String>(
            initialValue: currency,
            decoration: const InputDecoration(labelText: 'Book currency'),
            items: Money.exponents.keys
                .map((code) => DropdownMenuItem(value: code, child: Text(code)))
                .toList(),
            onChanged: busy
                ? null
                : (value) => setState(() => currency = value),
          ),
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
          if (!widget.onboarding) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('In-app budget signals'),
              subtitle: const Text('Show 75%, 90% and 100% milestones'),
              value: budgetSignals,
              onChanged: (v) => setState(() => budgetSignals = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reduce motion'),
              value: reduceMotion,
              onChanged: (v) => setState(() => reduceMotion = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Opaque surfaces'),
              subtitle: const Text('Reduce transparency and blur'),
              value: reduceTransparency,
              onChanged: (v) => setState(() => reduceTransparency = v),
            ),
          ],
          if (error != null)
            Semantics(
              liveRegion: true,
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.category_outlined),
              title: const Text('Manage categories'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/categories'),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.notifications_none),
              title: Text('Budget signals'),
              subtitle: Text(
                'In-app signals are shown at 75%, 90% and 100%. Device notifications are not enabled in this version.',
              ),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : export,
              icon: const Icon(Icons.ios_share),
              label: const Text('Export expenses as CSV'),
            ),
            const Text(
              'CSV includes active expenses, exact minor units and UTC timestamps. It is an export, not a restorable backup.',
            ),
            TextButton(
              onPressed: busy ? null : erase,
              child: const Text('Erase local data'),
            ),
            const Divider(),
            Text(
              'Privacy, by design',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text(
              'Your ledger stays in local SQLite storage. No account, analytics, crash reporting or network service is used. Exports leave the app only through the destination you choose. Protect access to your device. Uninstalling the app may remove your records; export before uninstalling.',
            ),
            TextButton(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'Money Well Spent',
              ),
              child: const Text('Open-source licenses'),
            ),
          ],
        ],
      ),
    ),
  );
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
                  spacing: 8,
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
    body: PageBody(
      children: [
        const Text(
          'Archive custom categories to keep history intact. Built-in categories always remain available.',
        ),
        FilledButton.icon(
          onPressed: () => edit(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('New category'),
        ),
        ...data.categories.map(
          (c) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(categoryIcon(c.icon)),
            title: Text(c.name),
            subtitle: Text(
              c.system
                  ? 'Built-in'
                  : c.archived
                  ? 'Archived · retained in history'
                  : 'Custom',
            ),
            onTap: c.system ? null : () => edit(context, ref, c),
            trailing: c.system
                ? null
                : IconButton(
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
          ),
        ),
      ],
    ),
  );
}
