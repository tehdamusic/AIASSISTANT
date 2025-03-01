class FinanceSummary {
  final double monthlyBudget;
  final double totalSpent;
  final List<SpendingCategory> categories;
  final List<DailySpending> dailySpending;
  final String userId;
  final String month;
  final String year;

  FinanceSummary({
    required this.monthlyBudget,
    required this.totalSpent,
    required this.categories,
    required this.dailySpending,
    required this.userId,
    required this.month,
    required this.year,
  });

  // Create FinanceSummary from JSON
  factory FinanceSummary.fromJson(Map<String, dynamic> json) {
    // Parse categories
    final categoriesJson = json['categories'] as List<dynamic>;
    final categories = categoriesJson
        .map((categoryJson) => SpendingCategory.fromJson(categoryJson))
        .toList();

    // Parse daily spending
    final dailySpendingJson = json['dailySpending'] as List<dynamic>;
    final dailySpending = dailySpendingJson
        .map((spendingJson) => DailySpending.fromJson(spendingJson))
        .toList();

    return FinanceSummary(
      monthlyBudget: json['monthlyBudget'].toDouble(),
      totalSpent: json['totalSpent'].toDouble(),
      categories: categories,
      dailySpending: dailySpending,
      userId: json['userId'],
      month: json['month'],
      year: json['year'],
    );
  }

  // Convert FinanceSummary to JSON
  Map<String, dynamic> toJson() {
    return {
      'monthlyBudget': monthlyBudget,
      'totalSpent': totalSpent,
      'categories': categories.map((category) => category.toJson()).toList(),
      'dailySpending': dailySpending.map((spending) => spending.toJson()).toList(),
      'userId': userId,
      'month': month,
      'year': year,
    };
  }
}

class SpendingCategory {
  final String id;
  final String name;
  final double amount;
  final double budget;
  final String color;
  final String icon;

  SpendingCategory({
    required this.id,
    required this.name,
    required this.amount,
    required this.budget,
    required this.color,
    required this.icon,
  });

  // Create SpendingCategory from JSON
  factory SpendingCategory.fromJson(Map<String, dynamic> json) {
    return SpendingCategory(
      id: json['id'],
      name: json['name'],
      amount: json['amount'].toDouble(),
      budget: json['budget'].toDouble(),
      color: json['color'],
      icon: json['icon'],
    );
  }

  // Convert SpendingCategory to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'budget': budget,
      'color': color,
      'icon': icon,
    };
  }

  // Calculate percentage of budget used
  double get budgetUsedPercentage => amount / budget;

  // Check if over budget
  bool get isOverBudget => amount > budget;
}

class DailySpending {
  final int day;
  final double amount;

  DailySpending({
    required this.day,
    required this.amount,
  });

  // Create DailySpending from JSON
  factory DailySpending.fromJson(Map<String, dynamic> json) {
    return DailySpending(
      day: json['day'],
      amount: json['amount'].toDouble(),
    );
  }

  // Convert DailySpending to JSON
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'amount': amount,
    };
  }
}
