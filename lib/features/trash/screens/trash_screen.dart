import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../shared/services/item_service.dart';
import '../../../shared/models/item_model.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          Consumer<ItemService>(
            builder: (context, itemService, child) {
              if (itemService.deletedItems.isEmpty) return const SizedBox();
              return TextButton.icon(
                onPressed: () => _showEmptyTrashDialog(context, itemService),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Empty'),
              );
            },
          ),
        ],
      ),
      body: Consumer<ItemService>(
        builder: (context, itemService, child) {
          final deletedItems = itemService.deletedItems;

          if (deletedItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 80,
                    color: colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Trash is empty',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deleted items will appear here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deletedItems.length,
            itemBuilder: (context, index) {
              final item = deletedItems[index];
              return _buildDeletedItemCard(context, item, theme, colorScheme, itemService);
            },
          );
        },
      ),
    );
  }

  Widget _buildDeletedItemCard(
    BuildContext context,
    ItemModel item,
    ThemeData theme,
    ColorScheme colorScheme,
    ItemService itemService,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.categoryIcon,
                color: colorScheme.onSurface.withOpacity(0.5),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 14,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.categoryName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.delete_outline,
                        size: 14,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.deletedAt != null
                            ? DateFormat('dd MMM yyyy').format(item.deletedAt!)
                            : 'Unknown',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _restoreItem(context, item, itemService),
              icon: const Icon(Icons.restore),
              tooltip: 'Restore',
              color: colorScheme.primary,
            ),
            IconButton(
              onPressed: () => _showDeletePermanentlyDialog(context, item, itemService),
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Delete permanently',
              color: colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restoreItem(BuildContext context, ItemModel item, ItemService itemService) async {
    final error = await itemService.restoreItem(item.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? '${item.name} restored'),
          backgroundColor: error != null ? Colors.red : Colors.green,
        ),
      );
    }
  }

  void _showDeletePermanentlyDialog(BuildContext context, ItemModel item, ItemService itemService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: Text(
          'This will permanently delete "${item.name}". This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final error = await itemService.permanentlyDeleteItem(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? '${item.name} permanently deleted'),
                    backgroundColor: error != null ? Colors.red : Colors.orange,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEmptyTrashDialog(BuildContext context, ItemService itemService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: Text(
          'This will permanently delete all ${itemService.deletedCount} items in trash. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final error = await itemService.emptyTrash();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'Trash emptied'),
                    backgroundColor: error != null ? Colors.red : Colors.orange,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );
  }
}
