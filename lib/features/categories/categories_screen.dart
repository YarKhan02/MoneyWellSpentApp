import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/design/tokens.dart';
import '../../shared/errors.dart';
import '../../shared/widgets/widgets.dart';
import '../ledger/models.dart';
import 'widgets/category_editor_sheet.dart';
import 'widgets/category_manager_row.dart';

/// Manage custom categories. Nothing here deletes: archiving hides a
/// category from new entries while every past expense keeps its filing.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key, required this.data});
  final LedgerSnapshot data;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Categories'),
      actions: [
        // Compact, conventionally placed action in place of the former
        // full-width button.
        IconButton(
          tooltip: 'New category',
          onPressed: () => showCategoryEditor(context, ref),
          icon: const Icon(Icons.add),
        ),
        const SizedBox(width: Brand.xs),
      ],
    ),
    body: SafeArea(
      child: PageBody(
        gap: Brand.lg,
        children: [
          Text(
            'Archive a custom category to keep its history while hiding it from new entries. Built-in categories always stay available.',
            style: context.text.bodyMedium?.copyWith(color: Brand.muted),
          ),
          ListSurface(
            children: [
              for (final c in data.categories)
                CategoryManagerRow(
                  category: c,
                  onEdit: () => showCategoryEditor(context, ref, c),
                  onArchiveToggled: () => _toggleArchive(context, ref, c),
                ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _toggleArchive(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    try {
      await ref
          .read(repositoryProvider)
          .archiveCategory(category.id, !category.archived);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }
}
