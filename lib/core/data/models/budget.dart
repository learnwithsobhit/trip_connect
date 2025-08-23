import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'budget.freezed.dart';
part 'budget.g.dart';

@freezed
@HiveType(typeId: 20)
class Budget with _$Budget {
  const factory Budget({
    @HiveField(0) required String id,
    @HiveField(1) required String tripId,
    @HiveField(2) required double totalBudget,
    @HiveField(3) required double spentAmount,
    @HiveField(4) required String currency,
    @HiveField(5) required DateTime createdAt,
    @HiveField(6) required DateTime updatedAt,
    @HiveField(7) required List<BudgetCategory> categories,
    @HiveField(8) required List<String> memberIds,
    @HiveField(9) String? description,
  }) = _Budget;

  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);
}

@freezed
@HiveType(typeId: 21)
class BudgetCategory with _$BudgetCategory {
  const factory BudgetCategory({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required double allocatedAmount,
    @HiveField(3) required double spentAmount,
    @HiveField(4) required String color,
    @HiveField(5) required String icon,
    @HiveField(6) String? description,
  }) = _BudgetCategory;

  factory BudgetCategory.fromJson(Map<String, dynamic> json) => _$BudgetCategoryFromJson(json);
}

@freezed
@HiveType(typeId: 22)
class Expense with _$Expense {
  const factory Expense({
    @HiveField(0) required String id,
    @HiveField(1) required String tripId,
    @HiveField(2) required String categoryId,
    @HiveField(3) required double amount,
    @HiveField(4) required String currency,
    @HiveField(5) required String description,
    @HiveField(6) required String paidByUserId,
    @HiveField(7) required List<String> splitBetweenUserIds,
    @HiveField(8) required ExpenseSplitType splitType,
    @HiveField(9) required DateTime date,
    @HiveField(10) required DateTime createdAt,
    @HiveField(11) required DateTime updatedAt,
    @HiveField(12) @Default(ExpenseStatus.pending) ExpenseStatus status,
    @HiveField(13) String? receiptUrl,
    @HiveField(14) String? location,
    @HiveField(15) Map<String, double>? customSplitAmounts,
    @HiveField(16) List<String>? tags,
  }) = _Expense;

  factory Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);
}

@freezed
@HiveType(typeId: 23)
class ExpenseSplit with _$ExpenseSplit {
  const factory ExpenseSplit({
    @HiveField(0) required String userId,
    @HiveField(1) required double amount,
    @HiveField(2) required bool isPaid,
    @HiveField(3) DateTime? paidAt,
  }) = _ExpenseSplit;

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) => _$ExpenseSplitFromJson(json);
}

enum ExpenseSplitType {
  @HiveField(0)
  equal,
  @HiveField(1)
  percentage,
  @HiveField(2)
  custom,
  @HiveField(3)
  individual,
}

enum ExpenseStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  approved,
  @HiveField(2)
  rejected,
  @HiveField(3)
  settled,
}

@freezed
@HiveType(typeId: 24)
class BudgetReport with _$BudgetReport {
  const factory BudgetReport({
    @HiveField(0) required String tripId,
    @HiveField(1) required double totalBudget,
    @HiveField(2) required double totalSpent,
    @HiveField(3) required double remainingBudget,
    @HiveField(4) required double budgetUtilizationPercentage,
    @HiveField(5) required List<CategoryReport> categoryReports,
    @HiveField(6) required List<UserExpenseReport> userReports,
    @HiveField(7) required List<Expense> recentExpenses,
    @HiveField(8) required DateTime generatedAt,
  }) = _BudgetReport;

  factory BudgetReport.fromJson(Map<String, dynamic> json) => _$BudgetReportFromJson(json);
}

@freezed
@HiveType(typeId: 25)
class CategoryReport with _$CategoryReport {
  const factory CategoryReport({
    @HiveField(0) required String categoryId,
    @HiveField(1) required String categoryName,
    @HiveField(2) required double allocatedAmount,
    @HiveField(3) required double spentAmount,
    @HiveField(4) required double remainingAmount,
    @HiveField(5) required double utilizationPercentage,
    @HiveField(6) required int expenseCount,
  }) = _CategoryReport;

  factory CategoryReport.fromJson(Map<String, dynamic> json) => _$CategoryReportFromJson(json);
}

@freezed
@HiveType(typeId: 26)
class UserExpenseReport with _$UserExpenseReport {
  const factory UserExpenseReport({
    @HiveField(0) required String userId,
    @HiveField(1) required String userName,
    @HiveField(2) required double totalPaid,
    @HiveField(3) required double totalOwed,
    @HiveField(4) required double netAmount,
    @HiveField(5) required int expenseCount,
    @HiveField(6) required List<Expense> expenses,
  }) = _UserExpenseReport;

  factory UserExpenseReport.fromJson(Map<String, dynamic> json) => _$UserExpenseReportFromJson(json);
}
