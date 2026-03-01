import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/item_model.dart';

class ExpiringSoonSection extends StatelessWidget {
  final List<ItemModel> items;

  const ExpiringSoonSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Expiring Soon',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                width: 140,
                margin: EdgeInsets.only(right: index < items.length - 1 ? 12 : 0),
                child: _ExpiringItemCard(item: item, isDark: isDark),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ExpiringItemCard extends StatelessWidget {
  final ItemModel item;
  final bool isDark;

  const _ExpiringItemCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = item.getStatusColor(isDark);
    final categoryColor = item.getCategoryColor(isDark);

    return Container(
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.categoryIcon,
                  color: categoryColor,
                  size: 18,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getDaysText(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            item.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM d').format(item.expiryDate),
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getDaysText() {
    final days = item.daysRemaining;
    if (days <= 0) return 'Today';
    if (days == 1) return '1 day';
    return '$days days';
  }
}
