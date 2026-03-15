import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/services/item_service.dart';
import '../../../shared/models/item_model.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<ItemService>(
      builder: (context, itemService, child) {
        final stats = itemService.analyticsStats;
        final categoryStats = itemService.categoryStats;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Analytics'),
            actions: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: const Text('This Month'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => itemService.loadItems(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsGrid(context, isDark, stats, itemService),
                  const SizedBox(height: 24),
                  _buildCategoryChart(context, isDark, categoryStats),
                  const SizedBox(height: 24),
                  _buildUsageChart(context, isDark, itemService),
                  const SizedBox(height: 24),
                  _buildInsightsSection(context, isDark, itemService),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    bool isDark,
    Map<String, dynamic> stats,
    ItemService itemService,
  ) {
    final totalItems = stats['total_items'] ?? itemService.items.length;
    final usedThisMonth = stats['used_this_month'] ?? 0;
    final expiredThisMonth = stats['expired_this_month'] ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          title: 'Total Items',
          value: '$totalItems',
          icon: Icons.inventory_2_rounded,
          color: isDark ? AppColors.primaryLight : AppColors.primary,
          onTap: itemService.items.isNotEmpty
              ? () => _showItemsSheet(
                    context,
                    'All Items',
                    itemService.items,
                    Icons.inventory_2_rounded,
                    isDark ? AppColors.primaryLight : AppColors.primary,
                  )
              : null,
        ),
        StatCard(
          title: 'Used This Month',
          value: '$usedThisMonth',
          icon: Icons.check_circle_rounded,
          color: isDark ? AppColors.foodDark : AppColors.foodLight,
          subtitle: usedThisMonth > 0 ? '+$usedThisMonth' : null,
          onTap: itemService.usedItems.isNotEmpty
              ? () => _showItemsSheet(
                    context,
                    'Used This Month',
                    itemService.usedItems,
                    Icons.check_circle_rounded,
                    isDark ? AppColors.foodDark : AppColors.foodLight,
                  )
              : null,
        ),
        StatCard(
          title: 'Expired',
          value: '$expiredThisMonth',
          icon: Icons.error_rounded,
          color: isDark ? AppColors.expiredDark : AppColors.expiredLight,
          onTap: itemService.expiredItems.isNotEmpty
              ? () => _showItemsSheet(
                    context,
                    'Expired Items',
                    itemService.expiredItems,
                    Icons.error_rounded,
                    isDark ? AppColors.expiredDark : AppColors.expiredLight,
                  )
              : null,
        ),
        StatCard(
          title: 'Expiring Soon',
          value: '${itemService.expiringSoon.length}',
          icon: Icons.warning_rounded,
          color: isDark ? AppColors.warningDark : AppColors.warningLight,
          onTap: itemService.expiringSoon.isNotEmpty
              ? () => _showItemsSheet(
                    context,
                    'Expiring Soon',
                    itemService.expiringSoon,
                    Icons.warning_rounded,
                    isDark ? AppColors.warningDark : AppColors.warningLight,
                  )
              : null,
        ),
      ],
    );
  }

  void _showItemsSheet(
    BuildContext context,
    String title,
    List<ItemModel> items,
    IconData icon,
    Color color,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ItemsListSheet(
        title: title,
        items: items,
        icon: icon,
        color: color,
      ),
    );
  }

  Widget _buildCategoryChart(
    BuildContext context,
    bool isDark,
    Map<String, int> categoryStats,
  ) {
    final theme = Theme.of(context);
    final total = categoryStats.values.fold(0, (sum, count) => sum + count);

    if (total == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Items by Category',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 40),
              Icon(
                Icons.pie_chart_outline,
                size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.2),
              ),
              const SizedBox(height: 16),
              Text(
                'No items to display',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    }

    final foodCount = categoryStats['food'] ?? 0;
    final groceryCount = categoryStats['grocery'] ?? 0;
    final medicineCount = categoryStats['medicine'] ?? 0;
    final cosmeticsCount = categoryStats['cosmetics'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items by Category',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: [
                    if (foodCount > 0)
                      PieChartSectionData(
                        value: foodCount.toDouble(),
                        title: '${(foodCount / total * 100).round()}%',
                        color: isDark ? AppColors.foodDark : AppColors.foodLight,
                        radius: 50,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    if (groceryCount > 0)
                      PieChartSectionData(
                        value: groceryCount.toDouble(),
                        title: '${(groceryCount / total * 100).round()}%',
                        color: isDark ? AppColors.groceryDark : AppColors.groceryLight,
                        radius: 50,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    if (medicineCount > 0)
                      PieChartSectionData(
                        value: medicineCount.toDouble(),
                        title: '${(medicineCount / total * 100).round()}%',
                        color: isDark ? AppColors.medicineDark : AppColors.medicineLight,
                        radius: 50,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    if (cosmeticsCount > 0)
                      PieChartSectionData(
                        value: cosmeticsCount.toDouble(),
                        title: '${(cosmeticsCount / total * 100).round()}%',
                        color: isDark ? AppColors.cosmeticsDark : AppColors.cosmeticsLight,
                        radius: 50,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _buildLegendItem('Food ($foodCount)', isDark ? AppColors.foodDark : AppColors.foodLight),
                _buildLegendItem('Grocery ($groceryCount)', isDark ? AppColors.groceryDark : AppColors.groceryLight),
                _buildLegendItem('Medicine ($medicineCount)', isDark ? AppColors.medicineDark : AppColors.medicineLight),
                _buildLegendItem('Cosmetics ($cosmeticsCount)', isDark ? AppColors.cosmeticsDark : AppColors.cosmeticsLight),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageChart(BuildContext context, bool isDark, ItemService itemService) {
    final theme = Theme.of(context);
    final weeklyActivity = itemService.weeklyActivity;
    final maxY = itemService.weeklyActivityMax.toDouble();
    final totalActivity = weeklyActivity.values.fold(0, (sum, count) => sum + count);

    // Get current day of week (0=Mon, 6=Sun)
    final today = DateTime.now().weekday - 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weekly Activity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.primaryLight : AppColors.primary).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalActivity items',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: theme.cardColor,
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return BarTooltipItem(
                          '${days[group.x]}\n${rod.toY.toInt()} items',
                          theme.textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: maxY > 10 ? (maxY / 5).ceilToDouble() : 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          final isToday = value.toInt() == today;
                          if (value.toInt() >= 0 && value.toInt() < days.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: isToday ? BoxDecoration(
                                  color: (isDark ? AppColors.primaryLight : AppColors.primary),
                                  borderRadius: BorderRadius.circular(12),
                                ) : null,
                                child: Text(
                                  days[value.toInt()],
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                    color: isToday 
                                        ? Colors.white 
                                        : theme.colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 10 ? (maxY / 5).ceilToDouble() : 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.dividerColor.withOpacity(0.5),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    final count = weeklyActivity[index] ?? 0;
                    final isToday = index == today;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: isToday
                              ? (isDark ? AppColors.primaryLight : AppColors.primary)
                              : (isDark ? AppColors.primaryLight : AppColors.primary).withOpacity(0.5),
                          width: 28,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: theme.dividerColor.withOpacity(0.2),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  'Items added & used this week',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection(BuildContext context, bool isDark, ItemService itemService) {
    final theme = Theme.of(context);
    final expiringSoon = itemService.expiringSoon;
    final expiredItems = itemService.expiredItems;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  color: isDark ? AppColors.groceryDark : AppColors.groceryLight,
                ),
                const SizedBox(width: 8),
                Text(
                  'Insights',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (expiredItems.isEmpty && expiringSoon.isEmpty)
              _buildInsightTile(
                context,
                icon: Icons.check_circle_rounded,
                color: isDark ? AppColors.foodDark : AppColors.foodLight,
                title: 'Great job!',
                subtitle: 'All your items are fresh. Keep tracking to reduce waste!',
              )
            else ...[
              if (expiredItems.isNotEmpty)
                _buildInsightTile(
                  context,
                  icon: Icons.error_rounded,
                  color: isDark ? AppColors.expiredDark : AppColors.expiredLight,
                  title: 'Items need attention',
                  subtitle: '${expiredItems.length} item(s) have expired. Consider disposing them safely.',
                ),
              if (expiringSoon.isNotEmpty) ...[
                if (expiredItems.isNotEmpty) const SizedBox(height: 12),
                _buildInsightTile(
                  context,
                  icon: Icons.schedule_rounded,
                  color: isDark ? AppColors.warningDark : AppColors.warningLight,
                  title: 'Expiring soon',
                  subtitle: '${expiringSoon.length} item(s) expiring in the next 7 days. Use them soon!',
                ),
              ],
            ],
            const SizedBox(height: 12),
            _buildInsightTile(
              context,
              icon: Icons.local_offer_rounded,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
              title: 'Tip',
              subtitle: 'Check the Deals tab for offers on items you frequently buy.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsListSheet extends StatelessWidget {
  final String title;
  final List<ItemModel> items;
  final IconData icon;
  final Color color;

  const _ItemsListSheet({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${items.length} item${items.length != 1 ? 's' : ''}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icon,
                              size: 64,
                              color: theme.colorScheme.onSurface.withOpacity(0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No items',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildItemTile(context, item, isDark);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemTile(BuildContext context, ItemModel item, bool isDark) {
    final theme = Theme.of(context);
    final categoryColor = item.getCategoryColor(isDark);
    final statusColor = item.getStatusColor(isDark);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.categoryIcon,
                color: categoryColor,
                size: 22,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, y').format(item.expiryDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      if (item.location != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.location!,
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
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(item),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(ItemModel item) {
    final days = item.daysRemaining;
    if (days < 0) return 'Expired';
    if (days == 0) return 'Today';
    if (days == 1) return '1 day';
    if (days <= 7) return '$days days';
    return '${(days / 7).ceil()} weeks';
  }
}
