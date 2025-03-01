import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/finance_summary.dart';
import '../utils/logger.dart';
import 'api_client.dart';

class FinanceApi {
  final ApiClient _apiClient = ApiClient();
  
  // Endpoint for finances
  static const String _financesEndpoint = '/finance';
  
  // Get financial summary for user
  Future<FinanceSummary> getFinanceSummary(String userId) async {
    try {
      final response = await _apiClient.get('$_financesEndpoint/summary/$userId');
      
      // Parse response into FinanceSummary object
      final summaryData = json.decode(response.body);
      return FinanceSummary.fromJson(summaryData);
    } catch (e) {
      Logger.error('Error fetching finance summary: $e');
      throw Exception('Failed to load finance summary: $e');
    }
  }
  
  // Add a financial transaction
  Future<void> addTransaction(Map<String, dynamic> transaction) async {
    try {
      await _apiClient.post(
        '$_financesEndpoint/transaction',
        body: json.encode(transaction),
      );
    } catch (e) {
      Logger.error('Error adding transaction: $e');
      throw Exception('Failed to add transaction: $e');
    }
  }
  
  // Update user's monthly budget
  Future<void> updateBudget(String userId, double newBudget) async {
    try {
      await _apiClient.patch(
        '$_financesEndpoint/budget/$userId',
        body: json.encode({'budget': newBudget}),
      );
    } catch (e) {
      Logger.error('Error updating budget: $e');
      throw Exception('Failed to update budget: $e');
    }
  }
  
  // Update category budget
  Future<void> updateCategoryBudget(String categoryId, double newBudget) async {
    try {
      await _apiClient.patch(
        '$_financesEndpoint/category/$categoryId',
        body: json.encode({'budget': newBudget}),
      );
    } catch (e) {
      Logger.error('Error updating category budget: $e');
      throw Exception('Failed to update category budget: $e');
    }
  }
}
