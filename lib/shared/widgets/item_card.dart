import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/item_model.dart';
import '../../core/theme/app_colors.dart';

class ItemCard extends StatefulWidget {
  final ItemModel item;
  final VoidCallback? onTap;
  final bool isCompact;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.isCompact = false,
  });

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
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
    final isDark = theme.brightness == Brightness.dark;
    final categoryColor = widget.item.getCategoryColor(isDark);
    final statusColor = widget.item.getStatusColor(isDark);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
            child: Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    width: widget.isCompact ? 44 : 52,
                    height: widget.isCompact ? 44 : 52,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.item.categoryIcon,
                      color: categoryColor,
                      size: widget.isCompact ? 22 : 26,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, y').format(widget.item.expiryDate),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          if (widget.item.location != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.item.location!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusText() {
    final days = widget.item.daysRemaining;
    if (days < 0) return 'Expired';
    if (days == 0) return 'Today';
    if (days == 1) return '1 day';
    if (days <= 7) return '$days days';
    return '${(days / 7).ceil()} weeks';
  }
}
