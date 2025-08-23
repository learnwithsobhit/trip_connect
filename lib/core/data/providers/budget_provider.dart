import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget.dart';
import '../models/models.dart';
import '../../services/mock_server.dart';

// Budget Provider
final budgetProvider = FutureProvider.family<Budget?, String>((ref, tripId) async {
  final mockServer = MockServer();
  return await mockServer.getBudget(tripId);
});

// Expenses Provider
final expensesProvider = FutureProvider.family<List<Expense>, String>((ref, tripId) async {
  final mockServer = MockServer();
  return await mockServer.getExpenses(tripId);
});

// Budget Report Provider
final budgetReportProvider = FutureProvider.family<BudgetReport?, String>((ref, tripId) async {
  final mockServer = MockServer();
  return await mockServer.getBudgetReport(tripId);
});

// Budget Actions Notifier
class BudgetActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final MockServer _mockServer;

  BudgetActionsNotifier(this._mockServer) : super(const AsyncValue.data(null));

  Future<void> createBudget({
    required String tripId,
    required double totalBudget,
    required String currency,
    required List<BudgetCategory> categories,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _mockServer.createBudget(
        tripId: tripId,
        totalBudget: totalBudget,
        currency: currency,
        categories: categories,
        description: description,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addExpense({
    required String tripId,
    required String categoryId,
    required double amount,
    required String currency,
    required String description,
    required String paidByUserId,
    required List<String> splitBetweenUserIds,
    required ExpenseSplitType splitType,
    required DateTime date,
    String? receiptUrl,
    String? location,
    Map<String, double>? customSplitAmounts,
    List<String>? tags,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _mockServer.addExpense(
        tripId: tripId,
        categoryId: categoryId,
        amount: amount,
        currency: currency,
        description: description,
        paidByUserId: paidByUserId,
        splitBetweenUserIds: splitBetweenUserIds,
        splitType: splitType,
        date: date,
        receiptUrl: receiptUrl,
        location: location,
        customSplitAmounts: customSplitAmounts,
        tags: tags,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateExpense({
    required String expenseId,
    required String categoryId,
    required double amount,
    required String description,
    required List<String> splitBetweenUserIds,
    required ExpenseSplitType splitType,
    Map<String, double>? customSplitAmounts,
    List<String>? tags,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _mockServer.updateExpense(
        expenseId: expenseId,
        categoryId: categoryId,
        amount: amount,
        description: description,
        splitBetweenUserIds: splitBetweenUserIds,
        splitType: splitType,
        customSplitAmounts: customSplitAmounts,
        tags: tags,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    state = const AsyncValue.loading();
    try {
      await _mockServer.deleteExpense(expenseId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> settleExpense(String expenseId) async {
    state = const AsyncValue.loading();
    try {
      await _mockServer.settleExpense(expenseId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateBudget({
    required String tripId,
    required double totalBudget,
    required List<BudgetCategory> categories,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _mockServer.updateBudget(
        tripId: tripId,
        totalBudget: totalBudget,
        categories: categories,
        description: description,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final budgetActionsProvider = StateNotifierProvider<BudgetActionsNotifier, AsyncValue<void>>((ref) {
  return BudgetActionsNotifier(MockServer());
});

// Budget Categories Provider
final budgetCategoriesProvider = Provider<List<BudgetCategory>>((ref) {
  return [
    const BudgetCategory(
      id: 'transportation',
      name: 'Transportation',
      allocatedAmount: 0,
      spentAmount: 0,
      color: '#FF6B6B',
      icon: '🚗',
    ),
    const BudgetCategory(
      id: 'accommodation',
      name: 'Accommodation',
      allocatedAmount: 0,
      spentAmount: 0,
      color: '#4ECDC4',
      icon: '🏨',
    ),
    const BudgetCategory(
      id: 'food',
      name: 'Food & Dining',
      allocatedAmount: 0,
      spentAmount: 0,
      color: '#45B7D1',
      icon: '🍽️',
    ),
    const BudgetCategory(
      id: 'activities',
      name: 'Activities',
      allocatedAmount: 0,
      spentAmount: 0,
      color: '#96CEB4',
      icon: '🎯',
    ),
    const BudgetCategory(
      id: 'equipment',
      name: 'Equipment',
      allocatedAmount: 0,
      spentAmount: 0,
      color: '#FFEAA7',
      icon: '🎒',
    ),
    const BudgetCategory(
      id: 'insurance',
      name: 'Insurance',
      allocatedAmount: 0,
      spentAmount: 0,
      color: '#DDA0DD',
      icon: '🛡️',
    ),
    const BudgetCategory(
      id: 'miscellaneous',
      name: 'Miscellaneous',
      allocatedAmount: 0,
      spentAmount: 0,
      color: '#98D8C8',
      icon: '📦',
    ),
  ];
});

// Expense Split Types Provider
final expenseSplitTypesProvider = Provider<List<ExpenseSplitType>>((ref) {
  return ExpenseSplitType.values;
});

// Currency Provider
final currenciesProvider = Provider<List<String>>((ref) {
  return ['USD', 'EUR', 'GBP', 'INR', 'CAD', 'AUD', 'JPY', 'CHF'];
});
