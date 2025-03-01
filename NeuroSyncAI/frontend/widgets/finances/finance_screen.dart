import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/api/finance_api.dart';
import '../models/finance_summary.dart';
import '../services/local/shared_prefs_service.dart';
import '../widgets/common/loading_indicator.dart';
import '../widgets/common/error_view.dart';

// Finance API provider
final financeApiProvider = Provider<FinanceApi>((ref) => FinanceApi());

// Shared prefs provider
final sharedPrefsProvider = Provider<SharedPrefsService>((ref) => SharedPrefsService());

// Finance summary provider
final financeSummaryProvider = FutureProvider<FinanceSummary>((ref) async {
  final api = ref.watch(financeApiProvider);
  final prefs = ref.watch(sharedPrefsProvider);
  
  final userId = await prefs.getUserId();
  if (userId == null) {
    throw Exception('User ID not found');
  }
  
  return api.getFinanceSummary(userId);
});

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the finance summary
    final financeSummaryAsync = ref.watch(financeSummaryProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Finances',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh the data
              ref.refresh(financeSummaryProvider);
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SafeArea(
        child: financeSummaryAsync.when(
          data: (summary) => _buildContent(context, summary),
          loading: () => const LoadingIndicator(message: 'Loading financial data...'),
          error: (error, stack) => ErrorView(
            message: 'Error loading financial data: $error',
            onRetry: () => ref.refresh(financeSummaryProvider),
          ),
        ),
      ),
    );
  }
  
  Widget _buildContent(BuildContext context, FinanceSummary summary) {
    return RefreshIndicator(
      onRefresh: () async {
        // This will be called when the user pulls down to refresh
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Total Budget Section
          _buildTotalBudgetSection(context, summary),
          
          const SizedBox(height: 24.0),
          
          // Spending Breakdown Section
          _buildSpendingBreakdownSection(summary),
          
          const SizedBox(height: 24.0),
          
          // Category Spending Chart Section
          _buildCategoryChartSection(summary),
        ],
      ),
    );
  }

  // Total Budget Section
  Widget _buildTotalBudgetSection(BuildContext context, FinanceSummary summary) {
    final currencyFormatter = NumberFormat.currency(symbol: '\
  }

  // Budget detail item
  Widget _buildBudgetDetailItem(String label, String amount, Color amountColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          amount,
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
        ),
      ],
    );
  }

  // Spending Breakdown Section
  Widget _buildSpendingBreakdownSection(FinanceSummary summary) {
    final currencyFormatter = NumberFormat.currency(symbol: '\
  }

  // Category list item
  Widget _buildCategoryListItem(String category, String amount, double percentage, Color color) {
    return Row(
      children: [
        // Category color indicator
        Container(
          width: 16.0,
          height: 16.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12.0),
        
        // Category name
        Expanded(
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 16.0,
            ),
          ),
        ),
        
        // Amount
        Text(
          amount,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(width: 12.0),
        
        // Percentage
        Text(
          '${(percentage * 100).toInt()}%',
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Category Chart Section
  Widget _buildCategoryChartSection(FinanceSummary summary) {
    final currencyFormatter = NumberFormat.currency(symbol: '\
  }

  // Legend item
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12.0,
          height: 12.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6.0),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.0,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
, decimalDigits: 0);
    
    // Calculate values
    final totalBudget = summary.monthlyBudget;
    final totalSpent = summary.totalSpent;
    final remaining = totalBudget - totalSpent;
    final spentPercentage = (totalSpent / totalBudget).clamp(0.0, 1.0);
    
    // Determine color based on spending
    Color progressColor;
    if (totalSpent > totalBudget) {
      progressColor = Colors.red;
    } else if (spentPercentage > 0.8) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.blue;
    }
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Budget',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Budget progress indicator
          Container(
            height: 24.0,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: (spentPercentage * 100).toInt(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                Expanded(
                  flex: 100 - (spentPercentage * 100).toInt(),
                  child: const SizedBox(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          // Budget details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBudgetDetailItem(
                'Spent', 
                currencyFormatter.format(totalSpent), 
                totalSpent > totalBudget ? Colors.red : Colors.blue,
              ),
              _buildBudgetDetailItem(
                'Budget', 
                currencyFormatter.format(totalBudget), 
                Colors.black87,
              ),
              _buildBudgetDetailItem(
                'Remaining', 
                currencyFormatter.format(remaining), 
                remaining < 0 ? Colors.red : Colors.green,
              ),
            ],
          ),
          
          // Show percentage of budget used
          const SizedBox(height: 8.0),
          Center(
            child: Text(
              '${(spentPercentage * 100).toInt()}% of budget used',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Budget detail item
  Widget _buildBudgetDetailItem(String label, String amount, Color amountColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          amount,
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
        ),
      ],
    );
  }

  // Spending Breakdown Section
  Widget _buildSpendingBreakdownSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Breakdown',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Category list placeholder
          _buildCategoryListItem('Food & Groceries', '\$540', 0.27, Colors.green),
          const SizedBox(height: 12.0),
          _buildCategoryListItem('Housing', '\$420', 0.21, Colors.blue),
          const SizedBox(height: 12.0),
          _buildCategoryListItem('Transportation', '\$380', 0.19, Colors.orange),
          const SizedBox(height: 12.0),
          _buildCategoryListItem('Entertainment', '\$110', 0.06, Colors.purple),
        ],
      ),
    );
  }

  // Category list item
  Widget _buildCategoryListItem(String category, String amount, double percentage, Color color) {
    return Row(
      children: [
        // Category color indicator
        Container(
          width: 16.0,
          height: 16.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12.0),
        
        // Category name
        Expanded(
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 16.0,
            ),
          ),
        ),
        
        // Amount
        Text(
          amount,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(width: 12.0),
        
        // Percentage
        Text(
          '${(percentage * 100).toInt()}%',
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Category Chart Section
  Widget _buildCategoryChartSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Spending',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Placeholder for pie chart
          Container(
            height: 200.0,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Center(
              child: Text(
                'Pie Chart Placeholder',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          // Legend placeholder
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Food', Colors.green),
              _buildLegendItem('Housing', Colors.blue),
              _buildLegendItem('Transport', Colors.orange),
              _buildLegendItem('Other', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  // Legend item
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12.0,
          height: 12.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4.0),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.0,
          ),
        ),
      ],
    );
  }
}
, decimalDigits: 0);
    final totalSpent = summary.totalSpent;
    
    // Sort categories by amount (highest first)
    final sortedCategories = List.of(summary.categories);
    sortedCategories.sort((a, b) => b.amount.compareTo(a.amount));
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Breakdown',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Category list from actual data
          ...sortedCategories.map((category) {
            final percentage = totalSpent > 0 ? category.amount / totalSpent : 0;
            
            // Map category names to colors (simplified)
            final Map<String, Color> categoryColors = {
              'Food': Colors.green,
              'Groceries': Colors.green,
              'Housing': Colors.blue,
              'Rent': Colors.blue,
              'Transportation': Colors.orange,
              'Travel': Colors.orange,
              'Entertainment': Colors.purple,
              'Shopping': Colors.teal,
              'Health': Colors.red,
              'Utilities': Colors.indigo,
            };
            
            // Try to find a matching color, or use a default
            Color categoryColor = Colors.grey;
            categoryColors.forEach((key, color) {
              if (category.name.toLowerCase().contains(key.toLowerCase())) {
                categoryColor = color;
              }
            });
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildCategoryListItem(
                category.name,
                currencyFormatter.format(category.amount),
                percentage,
                categoryColor,
              ),
            );
          }).toList(),
          
          // If no categories, show a message
          if (sortedCategories.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No spending categories to display',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Category list item
  Widget _buildCategoryListItem(String category, String amount, double percentage, Color color) {
    return Row(
      children: [
        // Category color indicator
        Container(
          width: 16.0,
          height: 16.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12.0),
        
        // Category name
        Expanded(
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 16.0,
            ),
          ),
        ),
        
        // Amount
        Text(
          amount,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(width: 12.0),
        
        // Percentage
        Text(
          '${(percentage * 100).toInt()}%',
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Category Chart Section
  Widget _buildCategoryChartSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Spending',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Placeholder for pie chart
          Container(
            height: 200.0,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Center(
              child: Text(
                'Pie Chart Placeholder',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          // Legend placeholder
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Food', Colors.green),
              _buildLegendItem('Housing', Colors.blue),
              _buildLegendItem('Transport', Colors.orange),
              _buildLegendItem('Other', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  // Legend item
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12.0,
          height: 12.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4.0),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.0,
          ),
        ),
      ],
    );
  }
}
, decimalDigits: 0);
    
    // Calculate values
    final totalBudget = summary.monthlyBudget;
    final totalSpent = summary.totalSpent;
    final remaining = totalBudget - totalSpent;
    final spentPercentage = (totalSpent / totalBudget).clamp(0.0, 1.0);
    
    // Determine color based on spending
    Color progressColor;
    if (totalSpent > totalBudget) {
      progressColor = Colors.red;
    } else if (spentPercentage > 0.8) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.blue;
    }
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Budget',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Budget progress indicator
          Container(
            height: 24.0,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: (spentPercentage * 100).toInt(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                Expanded(
                  flex: 100 - (spentPercentage * 100).toInt(),
                  child: const SizedBox(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          // Budget details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBudgetDetailItem(
                'Spent', 
                currencyFormatter.format(totalSpent), 
                totalSpent > totalBudget ? Colors.red : Colors.blue,
              ),
              _buildBudgetDetailItem(
                'Budget', 
                currencyFormatter.format(totalBudget), 
                Colors.black87,
              ),
              _buildBudgetDetailItem(
                'Remaining', 
                currencyFormatter.format(remaining), 
                remaining < 0 ? Colors.red : Colors.green,
              ),
            ],
          ),
          
          // Show percentage of budget used
          const SizedBox(height: 8.0),
          Center(
            child: Text(
              '${(spentPercentage * 100).toInt()}% of budget used',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Budget detail item
  Widget _buildBudgetDetailItem(String label, String amount, Color amountColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          amount,
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
        ),
      ],
    );
  }

  // Spending Breakdown Section
  Widget _buildSpendingBreakdownSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Breakdown',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Category list placeholder
          _buildCategoryListItem('Food & Groceries', '\$540', 0.27, Colors.green),
          const SizedBox(height: 12.0),
          _buildCategoryListItem('Housing', '\$420', 0.21, Colors.blue),
          const SizedBox(height: 12.0),
          _buildCategoryListItem('Transportation', '\$380', 0.19, Colors.orange),
          const SizedBox(height: 12.0),
          _buildCategoryListItem('Entertainment', '\$110', 0.06, Colors.purple),
        ],
      ),
    );
  }

  // Category list item
  Widget _buildCategoryListItem(String category, String amount, double percentage, Color color) {
    return Row(
      children: [
        // Category color indicator
        Container(
          width: 16.0,
          height: 16.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12.0),
        
        // Category name
        Expanded(
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 16.0,
            ),
          ),
        ),
        
        // Amount
        Text(
          amount,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(width: 12.0),
        
        // Percentage
        Text(
          '${(percentage * 100).toInt()}%',
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Category Chart Section
  Widget _buildCategoryChartSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Spending',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Placeholder for pie chart
          Container(
            height: 200.0,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Center(
              child: Text(
                'Pie Chart Placeholder',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          // Legend placeholder
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Food', Colors.green),
              _buildLegendItem('Housing', Colors.blue),
              _buildLegendItem('Transport', Colors.orange),
              _buildLegendItem('Other', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  // Legend item
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12.0,
          height: 12.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4.0),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.0,
          ),
        ),
      ],
    );
  }
}
, decimalDigits: 0);
    
    // Get categories sorted by amount
    final categories = List.of(summary.categories);
    categories.sort((a, b) => b.amount.compareTo(a.amount));
    
    // Map for storing category colors
    final Map<String, Color> categoryColorMap = {
      'Food': Colors.green[600]!,
      'Groceries': Colors.green[400]!,
      'Housing': Colors.blue[600]!,
      'Rent': Colors.blue[400]!,
      'Transportation': Colors.orange[600]!,
      'Travel': Colors.orange[400]!,
      'Entertainment': Colors.purple[600]!,
      'Shopping': Colors.teal[600]!,
      'Health': Colors.red[600]!,
      'Utilities': Colors.indigo[600]!,
      'Education': Colors.amber[600]!,
      'Personal': Colors.pink[400]!,
      'Other': Colors.grey[600]!,
    };
    
    // Get colors for categories, ensuring uniqueness
    final List<Color> usedColors = [];
    final categoryColorsList = categories.map((category) {
      // Look for a matching category name
      Color? color;
      categoryColorMap.forEach((key, value) {
        if (category.name.toLowerCase().contains(key.toLowerCase()) && color == null) {
          color = value;
        }
      });
      
      // If no match or color already used, pick a new color
      if (color == null || usedColors.contains(color)) {
        final availableColors = [
          Colors.green[600]!, Colors.blue[600]!, Colors.orange[600]!,
          Colors.purple[600]!, Colors.teal[600]!, Colors.red[600]!,
          Colors.indigo[600]!, Colors.amber[600]!, Colors.pink[400]!,
          Colors.cyan[600]!, Colors.brown[600]!, Colors.lightGreen[600]!,
        ].where((c) => !usedColors.contains(c)).toList();
        
        color = availableColors.isNotEmpty 
            ? availableColors.first 
            : Colors.grey[(usedColors.length * 100) % 900]!;
      }
      
      usedColors.add(color!);
      return color!;
    }).toList();
    
    // Create pie chart sections
    final sections = <PieChartSectionData>[];
    double totalAmount = 0;
    
    // Only show top 8 categories to prevent overcrowding
    final numCategoriesToShow = categories.length > 8 ? 8 : categories.length;
    double otherAmount = 0;
    
    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      totalAmount += category.amount;
      
      if (i < numCategoriesToShow) {
        sections.add(
          PieChartSectionData(
            color: categoryColorsList[i],
            value: category.amount,
            title: '',  // We'll use a legend instead
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      } else {
        // Accumulate "Other" category
        otherAmount += category.amount;
      }
    }
    
    // Add "Other" section if needed
    if (otherAmount > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.grey[600]!,
          value: otherAmount,
          title: '',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    
    // Create legend items
    final legendItems = <Widget>[];
    for (int i = 0; i < numCategoriesToShow && i < categories.length; i++) {
      legendItems.add(
        _buildLegendItem(
          categories[i].name,
          categoryColorsList[i],
        ),
      );
    }
    
    // Add "Other" to legend if needed
    if (otherAmount > 0) {
      legendItems.add(
        _buildLegendItem('Other', Colors.grey[600]!),
      );
    }
    
    // Calculate rows needed for legend
    final int legendItemsPerRow = 3;  // Adjust based on screen width
    final int legendRows = (legendItems.length / legendItemsPerRow).ceil();
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Spending',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20.0),
          
          // Pie chart
          AspectRatio(
            aspectRatio: 1.3,
            child: sections.isEmpty
                ? Center(
                    child: Text(
                      'No spending data to display',
                      style: TextStyle(
                        color: Colors.grey[600]!,
                        fontSize: 16.0,
                      ),
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: sections,
                          sectionsSpace: 2,
                          centerSpaceRadius: 60,
                          startDegreeOffset: -90,
                        ),
                      ),
                      // Total spent in center
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey[600]!,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            currencyFormatter.format(totalAmount),
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800]!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          
          const SizedBox(height: 20.0),
          
          // Legend with categories
          for (int row = 0; row < legendRows; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (int i = row * legendItemsPerRow; 
                       i < (row + 1) * legendItemsPerRow && i < legendItems.length; 
                       i++)
                    Expanded(child: legendItems[i]),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Legend item
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12.0,
          height: 12.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4.0),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.0,
          ),
        ),
      ],
    );
  }
}
, decimalDigits: 0);
    
    // Calculate values
    final totalBudget = summary.monthlyBudget;
    final totalSpent = summary.totalSpent;
    final remaining = totalBudget - totalSpent;
    final spentPercentage = (totalSpent / totalBudget).clamp(0.0, 1.0);
    
    // Determine color based on spending
    Color progressColor;
    if (totalSpent > totalBudget) {
      progressColor = Colors.red;
    } else if (spentPercentage > 0.8) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.blue;
    }
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Budget',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Budget progress indicator
          Container(
            height: 24.0,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: (spentPercentage * 100).toInt(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                Expanded(
                  flex: 100 - (spentPercentage * 100).toInt(),
                  child: const SizedBox(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          // Budget details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBudgetDetailItem(
                'Spent', 
                currencyFormatter.format(totalSpent), 
                totalSpent > totalBudget ? Colors.red : Colors.blue,
              ),
              _buildBudgetDetailItem(
                'Budget', 
                currencyFormatter.format(totalBudget), 
                Colors.black87,
              ),
              _buildBudgetDetailItem(
                'Remaining', 
                currencyFormatter.format(remaining), 
                remaining < 0 ? Colors.red : Colors.green,
              ),
            ],
          ),
          
          // Show percentage of budget used
          const SizedBox(height: 8.0),
          Center(
            child: Text(
              '${(spentPercentage * 100).toInt()}% of budget used',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Budget detail item
  Widget _buildBudgetDetailItem(String label, String amount, Color amountColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          amount,
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
        ),
      ],
    );
  }

  // Spending Breakdown Section
  Widget _buildSpendingBreakdownSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Breakdown',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Category list placeholder
          _buildCategoryListItem('Food & Groceries', '\$540', 0.27, Colors.green),
          const SizedBox(height: 12.0),
          _buildCategoryListItem('Housing', '\$420', 0.21, Colors.blue),
          const SizedBox(height: 12.0),
          _buildCategoryListItem('Transportation', '\$380', 0.19, Colors.orange),
          const SizedBox(height: 12.0),
          _buildCategoryListItem('Entertainment', '\$110', 0.06, Colors.purple),
        ],
      ),
    );
  }

  // Category list item
  Widget _buildCategoryListItem(String category, String amount, double percentage, Color color) {
    return Row(
      children: [
        // Category color indicator
        Container(
          width: 16.0,
          height: 16.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12.0),
        
        // Category name
        Expanded(
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 16.0,
            ),
          ),
        ),
        
        // Amount
        Text(
          amount,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(width: 12.0),
        
        // Percentage
        Text(
          '${(percentage * 100).toInt()}%',
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Category Chart Section
  Widget _buildCategoryChartSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Spending',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Placeholder for pie chart
          Container(
            height: 200.0,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Center(
              child: Text(
                'Pie Chart Placeholder',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          // Legend placeholder
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Food', Colors.green),
              _buildLegendItem('Housing', Colors.blue),
              _buildLegendItem('Transport', Colors.orange),
              _buildLegendItem('Other', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  // Legend item
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12.0,
          height: 12.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4.0),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.0,
          ),
        ),
      ],
    );
  }
}
, decimalDigits: 0);
    final totalSpent = summary.totalSpent;
    
    // Sort categories by amount (highest first)
    final sortedCategories = List.of(summary.categories);
    sortedCategories.sort((a, b) => b.amount.compareTo(a.amount));
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Breakdown',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Category list from actual data
          ...sortedCategories.map((category) {
            final percentage = totalSpent > 0 ? category.amount / totalSpent : 0;
            
            // Map category names to colors (simplified)
            final Map<String, Color> categoryColors = {
              'Food': Colors.green,
              'Groceries': Colors.green,
              'Housing': Colors.blue,
              'Rent': Colors.blue,
              'Transportation': Colors.orange,
              'Travel': Colors.orange,
              'Entertainment': Colors.purple,
              'Shopping': Colors.teal,
              'Health': Colors.red,
              'Utilities': Colors.indigo,
            };
            
            // Try to find a matching color, or use a default
            Color categoryColor = Colors.grey;
            categoryColors.forEach((key, color) {
              if (category.name.toLowerCase().contains(key.toLowerCase())) {
                categoryColor = color;
              }
            });
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildCategoryListItem(
                category.name,
                currencyFormatter.format(category.amount),
                percentage,
                categoryColor,
              ),
            );
          }).toList(),
          
          // If no categories, show a message
          if (sortedCategories.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No spending categories to display',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Category list item
  Widget _buildCategoryListItem(String category, String amount, double percentage, Color color) {
    return Row(
      children: [
        // Category color indicator
        Container(
          width: 16.0,
          height: 16.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12.0),
        
        // Category name
        Expanded(
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 16.0,
            ),
          ),
        ),
        
        // Amount
        Text(
          amount,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(width: 12.0),
        
        // Percentage
        Text(
          '${(percentage * 100).toInt()}%',
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Category Chart Section
  Widget _buildCategoryChartSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Spending',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Placeholder for pie chart
          Container(
            height: 200.0,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Center(
              child: Text(
                'Pie Chart Placeholder',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          // Legend placeholder
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Food', Colors.green),
              _buildLegendItem('Housing', Colors.blue),
              _buildLegendItem('Transport', Colors.orange),
              _buildLegendItem('Other', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  // Legend item
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12.0,
          height: 12.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4.0),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.0,
          ),
        ),
      ],
    );
  }
}
, decimalDigits: 0);
    
    // Calculate values
    final totalBudget = summary.monthlyBudget;
    final totalSpent = summary.totalSpent;
    final remaining = totalBudget - totalSpent;
    final spentPercentage = (totalSpent / totalBudget).clamp(0.0, 1.0);
    
    // Determine color based on spending
    Color progressColor;
    if (totalSpent > totalBudget) {
      progressColor = Colors.red;
    } else if (spentPercentage > 0.8) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.blue;
    }
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Budget',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Budget progress indicator
          Container(
            height: 24.0,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: (spentPercentage * 100).toInt(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                Expanded(
                  flex: 100 - (spentPercentage * 100).toInt(),
                  child: const SizedBox(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          // Budget details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBudgetDetailItem(
                'Spent', 
                currencyFormatter.format(totalSpent), 
                totalSpent > totalBudget ? Colors.red : Colors.blue,
              ),
              _buildBudgetDetailItem(
                'Budget', 
                currencyFormatter.format(totalBudget), 
                Colors.black87,
              ),
              _buildBudgetDetailItem(
                'Remaining', 
                currencyFormatter.format(remaining), 
                remaining < 0 ? Colors.red : Colors.green,
              ),
            ],
          ),
          
          // Show percentage of budget used
          const SizedBox(height: 8.0),
          Center(
            child: Text(
              '${(spentPercentage * 100).toInt()}% of budget used',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Budget detail item
  Widget _buildBudgetDetailItem(String label, String amount, Color amountColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          amount,
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
        ),
      ],
    );
  }

  // Spending Breakdown Section
  Widget _buildSpendingBreakdownSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Breakdown',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Category list placeholder
          _buildCategoryListItem('Food & Groceries', '\$540', 0.27, Colors.green),
          const SizedBox(height: 12.0),
          _buildCategoryListItem('Housing', '\$420', 0.21, Colors.blue),
          const SizedBox(height: 12.0),
          _buildCategoryListItem('Transportation', '\$380', 0.19, Colors.orange),
          const SizedBox(height: 12.0),
          _buildCategoryListItem('Entertainment', '\$110', 0.06, Colors.purple),
        ],
      ),
    );
  }

  // Category list item
  Widget _buildCategoryListItem(String category, String amount, double percentage, Color color) {
    return Row(
      children: [
        // Category color indicator
        Container(
          width: 16.0,
          height: 16.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12.0),
        
        // Category name
        Expanded(
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 16.0,
            ),
          ),
        ),
        
        // Amount
        Text(
          amount,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(width: 12.0),
        
        // Percentage
        Text(
          '${(percentage * 100).toInt()}%',
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Category Chart Section
  Widget _buildCategoryChartSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Spending',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Placeholder for pie chart
          Container(
            height: 200.0,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Center(
              child: Text(
                'Pie Chart Placeholder',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          // Legend placeholder
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Food', Colors.green),
              _buildLegendItem('Housing', Colors.blue),
              _buildLegendItem('Transport', Colors.orange),
              _buildLegendItem('Other', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  // Legend item
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12.0,
          height: 12.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4.0),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.0,
          ),
        ),
      ],
    );
  }
}
