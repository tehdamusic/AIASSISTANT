import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../models/finance_summary.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/finances/budget_progress_bar.dart';
import '../../widgets/finances/category_list_item.dart';

class FinancesScreen extends ConsumerStatefulWidget {
  const FinancesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends ConsumerState<FinancesScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch financial data when screen is initialized
    Future.microtask(() => ref.read(financeProvider.notifier).fetchFinanceSummary());
  }

  @override
  Widget build(BuildContext context) {
    // Watch the finance state
    final financeState = ref.watch(financeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Finances',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(financeProvider.notifier).fetchFinanceSummary();
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(financeProvider.notifier).fetchFinanceSummary();
        },
        child: _buildBody(financeState),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add transaction screen
          // This will be implemented later
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Transaction',
      ),
    );
  }

  Widget _buildBody(FinanceState state) {
    if (state.isLoading) {
      return const LoadingIndicator(message: 'Loading your financial data...');
    }

    if (state.error != null) {
      return ErrorView(
        message: 'Error loading financial data: ${state.error}',
        onRetry: () => ref.read(financeProvider.notifier).fetchFinanceSummary(),
      );
    }

    if (state.summary == null) {
      return const Center(
        child: Text('No financial data available.'),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Budget summary card
          _buildBudgetSummaryCard(state.summary!),
          
          const SizedBox(height: 24),
          
          // Category breakdown
          _buildCategorySection(state.summary!),
          
          const SizedBox(height: 24),
          
          // Monthly spending chart
          _buildMonthlySpendingChart(state.summary!),
        ],
      ),
    );
  }

  Widget _buildBudgetSummaryCard(FinanceSummary summary) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    final percentFormatter = NumberFormat.percentPattern();
    
    final budgetUsedPercentage = summary.totalSpent / summary.monthlyBudget;
    final remaining = summary.monthlyBudget - summary.totalSpent;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Budget',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  currencyFormatter.format(summary.monthlyBudget),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Budget progress bar
            BudgetProgressBar(
              spentAmount: summary.totalSpent,
              budgetAmount: summary.monthlyBudget,
            ),
            
            const SizedBox(height: 16),
            
            // Spent and remaining amounts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Spent',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      currencyFormatter.format(summary.totalSpent),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: summary.totalSpent > summary.monthlyBudget
                            ? Colors.red
                            : Colors.black87,
                      ),
                    ),
                    Text(
                      percentFormatter.format(budgetUsedPercentage),
                      style: TextStyle(
                        fontSize: 14,
                        color: summary.totalSpent > summary.monthlyBudget
                            ? Colors.red
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Remaining',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      currencyFormatter.format(remaining),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: remaining < 0 ? Colors.red : Colors.green,
                      ),
                    ),
                    Text(
                      percentFormatter.format(1 - budgetUsedPercentage > 0 
                          ? 1 - budgetUsedPercentage 
                          : 0),
                      style: TextStyle(
                        fontSize: 14,
                        color: remaining < 0 ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(FinanceSummary summary) {
    final sortedCategories = [...summary.categories];
    // Sort by amount spent (descending)
    sortedCategories.sort((a, b) => b.amount.compareTo(a.amount));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spending Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to detailed breakdown
                // This will be implemented later
              },
              child: const Text('See Details'),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Pie chart for category visualization
        SizedBox(
          height: 200,
          child: _buildCategoryPieChart(sortedCategories),
        ),
        
        const SizedBox(height: 16),
        
        // List of categories
        Column(
          children: sortedCategories.map((category) {
            return CategoryListItem(
              category: category,
              totalSpent: summary.totalSpent,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryPieChart(List<SpendingCategory> categories) {
    final colorScheme = [
      Colors.blue[400]!,
      Colors.green[400]!,
      Colors.orange[400]!,
      Colors.purple[400]!,
      Colors.red[400]!,
      Colors.teal[400]!,
      Colors.pink[400]!,
      Colors.amber[400]!,
    ];

    // Generate sections
    final sections = <PieChartSectionData>[];
    
    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final color = i < colorScheme.length 
          ? colorScheme[i] 
          : Colors.grey[400]!;
          
      sections.add(
        PieChartSectionData(
          color: color,
          value: category.amount,
          title: '', // No title inside chart for cleaner look
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              startDegreeOffset: -90,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                categories.length > 5 ? 5 : categories.length,
                (index) {
                  final category = categories[index];
                  final color = index < colorScheme.length 
                      ? colorScheme[index] 
                      : Colors.grey[400]!;
                      
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category.name,
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
                },
              ),
              // Show "Others" if there are more than 5 categories
              if (categories.length > 5)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Others',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlySpendingChart(FinanceSummary summary) {
    // This chart shows daily spending for the current month
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Spending',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        
        const SizedBox(height: 16),
        
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 100,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[300],
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      // Only show every 5 days for cleaner look
                      if (value.toInt() % 5 != 0) {
                        return const SizedBox.shrink();
                      }
                      
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          '\$${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                  left: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              minX: 1,
              maxX: 31, // Days in a month
              minY: 0,
              maxY: summary.dailySpending.fold(
                  0, (max, point) => point.amount > max ? point.amount : max) * 1.2,
              lineBarsData: [
                LineChartBarData(
                  spots: summary.dailySpending
                      .map((point) => FlSpot(point.day.toDouble(), point.amount))
                      .toList(),
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: false,
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
