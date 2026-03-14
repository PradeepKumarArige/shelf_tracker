import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/services/item_service.dart';

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
                  _buildUsageChart(context, isDark),
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
        ),
        StatCard(
          title: 'Used This Month',
          value: '$usedThisMonth',
          icon: Icons.check_circle_rounded,
          color: isDark ? AppColors.foodDark : AppColors.foodLight,
          subtitle: usedThisMonth > 0 ? '+$usedThisMonth' : null,
        ),
        StatCard(
          title: 'Expired',
          value: '$expiredThisMonth',
          icon: Icons.error_rounded,
          color: isDark ? AppColors.expiredDark : AppColors.expiredLight,
        ),
        StatCard(
          title: 'Expiring Soon',
          value: '${itemService.expiringSoon.length}',
          icon: Icons.warning_rounded,
          color: isDark ? AppColors.warningDark : AppColors.warningLight,
        ),
      ],
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

  Widget _buildUsageChart(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Activity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.dividerColor,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          if (value.toInt() < days.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                days[value.toInt()],
                                style: theme.textTheme.bodySmall,
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
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 3),
                        FlSpot(1, 5),
                        FlSpot(2, 4),
                        FlSpot(3, 8),
                        FlSpot(4, 6),
                        FlSpot(5, 10),
                        FlSpot(6, 7),
                      ],
                      isCurved: true,
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: isDark ? AppColors.primaryLight : AppColors.primary,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: (isDark ? AppColors.primaryLight : AppColors.primary).withOpacity(0.1),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: 15,
                ),
              ),
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
