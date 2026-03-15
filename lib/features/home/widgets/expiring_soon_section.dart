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
    final warningColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: (1 - value) * 0.3,
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Icon(
                Icons.warning_rounded,
                color: warningColor,
                size: 22,
              ),
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
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 80)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(30 * (1 - value), 0),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Container(
                  width: 140,
                  margin: EdgeInsets.only(right: index < items.length - 1 ? 12 : 0),
                  child: _ExpiringItemCard(item: item, isDark: isDark, index: index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ExpiringItemCard extends StatefulWidget {
  final ItemModel item;
  final bool isDark;
  final int index;

  const _ExpiringItemCard({
    required this.item,
    required this.isDark,
    this.index = 0,
  });

  @override
  State<_ExpiringItemCard> createState() => _ExpiringItemCardState();
}

class _ExpiringItemCardState extends State<_ExpiringItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = widget.item.getStatusColor(widget.isDark);
    final categoryColor = widget.item.getCategoryColor(widget.isDark);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
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
                      widget.item.categoryIcon,
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
                widget.item.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM d').format(widget.item.expiryDate),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDaysText() {
    final days = widget.item.daysRemaining;
    if (days <= 0) return 'Today';
    if (days == 1) return '1 day';
    return '$days days';
  }
}
