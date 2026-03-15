import 'package:flutter/material.dart';
import '../models/item_model.dart';

class CategoryChip extends StatefulWidget {
  final ItemCategory category;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<CategoryChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
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
    final color = _getCategoryColor(isDark);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isSelected ? color : color.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedRotation(
                turns: widget.isSelected ? 0.05 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _getCategoryIcon(),
                  size: 18,
                  color: widget.isSelected ? Colors.white : color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getCategoryName(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: widget.isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(bool isDark) {
    switch (widget.category) {
      case ItemCategory.food:
        return isDark ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50);
      case ItemCategory.grocery:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800);
      case ItemCategory.medicine:
        return isDark ? const Color(0xFFEF5350) : const Color(0xFFF44336);
      case ItemCategory.cosmetics:
        return isDark ? const Color(0xFFBA68C8) : const Color(0xFF9C27B0);
    }
  }

  IconData _getCategoryIcon() {
    switch (widget.category) {
      case ItemCategory.food:
        return Icons.restaurant_rounded;
      case ItemCategory.grocery:
        return Icons.shopping_basket_rounded;
      case ItemCategory.medicine:
        return Icons.medical_services_rounded;
      case ItemCategory.cosmetics:
        return Icons.face_rounded;
    }
  }

  String _getCategoryName() {
    switch (widget.category) {
      case ItemCategory.food:
        return 'Food';
      case ItemCategory.grocery:
        return 'Grocery';
      case ItemCategory.medicine:
        return 'Medicine';
      case ItemCategory.cosmetics:
        return 'Cosmetics';
    }
  }
}
