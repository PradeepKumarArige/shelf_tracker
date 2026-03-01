import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/deal_model.dart';
import '../../../shared/services/deal_service.dart';

class DealsScreen extends StatelessWidget {
  const DealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<DealService>(
      builder: (context, dealService, child) {
        if (dealService.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final featuredDeals = dealService.featuredDeals;
        final deals = dealService.filteredDeals;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Deals & Offers'),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => _showFilterSheet(context, dealService),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => dealService.loadDeals(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (featuredDeals.isNotEmpty)
                    _buildFeaturedDeal(context, featuredDeals.first, isDark),
                  const SizedBox(height: 24),
                  _buildDealSection(
                    context,
                    title: 'All Deals',
                    deals: deals,
                    dealService: dealService,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturedDeal(BuildContext context, DealModel deal, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  'Featured',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            deal.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${deal.store} • Expires in ${deal.daysRemaining} days',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          if (deal.description != null) ...[
            const SizedBox(height: 8),
            Text(
              deal.description!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
            ),
            child: const Text('View Offer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDealSection(
    BuildContext context, {
    required String title,
    required List<DealModel> deals,
    required DealService dealService,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    if (deals.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  'No deals available',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${deals.length} deals',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: deals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _DealCard(
            deal: deals[index],
            dealService: dealService,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context, DealService dealService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Filter Deals',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 24),
            const Text('Categories'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: dealService.selectedCategory == null ||
                      dealService.selectedCategory == 'All',
                  onSelected: (_) {
                    dealService.setSelectedCategory(null);
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Food'),
                  selected: dealService.selectedCategory == 'Food',
                  onSelected: (_) {
                    dealService.setSelectedCategory('Food');
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Grocery'),
                  selected: dealService.selectedCategory == 'Grocery',
                  onSelected: (_) {
                    dealService.setSelectedCategory('Grocery');
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Medicine'),
                  selected: dealService.selectedCategory == 'Medicine',
                  onSelected: (_) {
                    dealService.setSelectedCategory('Medicine');
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Cosmetics'),
                  selected: dealService.selectedCategory == 'Cosmetics',
                  onSelected: (_) {
                    dealService.setSelectedCategory('Cosmetics');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Apply Filters'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final DealModel deal;
  final DealService dealService;
  final bool isDark;

  const _DealCard({
    required this.deal,
    required this.dealService,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = _getCategoryColor();
    final isSaved = dealService.isDealSaved(deal.id);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showDealDetails(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    deal.discount,
                    style: TextStyle(
                      color: categoryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deal.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.store_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            deal.store,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    onPressed: () => dealService.toggleSaveDeal(deal.id),
                    visualDensity: VisualDensity.compact,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getExpiryColor(theme).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getExpiryText(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _getExpiryColor(theme),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (deal.category) {
      case 'Food':
        return isDark ? AppColors.foodDark : AppColors.foodLight;
      case 'Grocery':
        return isDark ? AppColors.groceryDark : AppColors.groceryLight;
      case 'Medicine':
        return isDark ? AppColors.medicineDark : AppColors.medicineLight;
      case 'Cosmetics':
        return isDark ? AppColors.cosmeticsDark : AppColors.cosmeticsLight;
      default:
        return isDark ? AppColors.primaryLight : AppColors.primary;
    }
  }

  Color _getExpiryColor(ThemeData theme) {
    if (deal.daysRemaining <= 3) {
      return isDark ? AppColors.expiredDark : AppColors.expiredLight;
    } else if (deal.daysRemaining <= 7) {
      return isDark ? AppColors.warningDark : AppColors.warningLight;
    }
    return theme.colorScheme.primary;
  }

  String _getExpiryText() {
    final days = deal.daysRemaining;
    if (days <= 0) return 'Expired';
    if (days == 1) return '1 day left';
    return '$days days';
  }

  void _showDealDetails(BuildContext context) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _getCategoryColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      deal.discount,
                      style: TextStyle(
                        color: _getCategoryColor(),
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deal.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deal.store,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (deal.description != null) ...[
              const SizedBox(height: 20),
              Text(
                deal.description!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getExpiryColor(theme).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: _getExpiryColor(theme),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Expires in ${_getExpiryText()}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _getExpiryColor(theme),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => dealService.toggleSaveDeal(deal.id),
                    icon: Icon(
                      dealService.isDealSaved(deal.id)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                    ),
                    label: Text(
                      dealService.isDealSaved(deal.id) ? 'Saved' : 'Save',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('View Store'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
