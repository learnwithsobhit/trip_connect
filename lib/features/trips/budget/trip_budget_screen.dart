import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/models.dart';
import '../../../core/data/providers/trip_provider.dart';
import '../../../core/data/providers/budget_provider.dart';
import '../../../core/data/providers/auth_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';

class TripBudgetScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripBudgetScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripBudgetScreen> createState() => _TripBudgetScreenState();
}

class _TripBudgetScreenState extends ConsumerState<TripBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'transportation';
  ExpenseSplitType _selectedSplitType = ExpenseSplitType.equal;
  DateTime _selectedDate = DateTime.now();
  List<String> _selectedMembers = [];
  bool _isExpense = true;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripAsync = ref.watch(tripProvider(widget.tripId));
    final budgetAsync = ref.watch(budgetProvider(widget.tripId));
    final expensesAsync = ref.watch(expensesProvider(widget.tripId));
    final budgetReportAsync = ref.watch(budgetReportProvider(widget.tripId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Budget'),
        actions: [
          IconButton(
            onPressed: () => _showBudgetOptions(context),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: tripAsync.when(
        data: (trip) => trip != null 
          ? _buildBudgetContent(context, trip, budgetAsync, expensesAsync, budgetReportAsync, currentUser)
          : const Center(child: Text('Trip not found')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              AppSpacing.verticalSpaceMd,
              Text('Error loading budget: $error'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildBudgetContent(
    BuildContext context, 
    Trip trip, 
    AsyncValue<Budget?> budgetAsync,
    AsyncValue<List<Expense>> expensesAsync,
    AsyncValue<BudgetReport?> budgetReportAsync,
    User? currentUser,
  ) {
    final theme = Theme.of(context);
    
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        // Budget Overview Card
        _buildBudgetOverview(context, budgetAsync, budgetReportAsync),
        AppSpacing.verticalSpaceLg,
        
        // Budget Breakdown
        _buildBudgetBreakdown(context, budgetAsync),
        AppSpacing.verticalSpaceLg,
        
        // Recent Transactions
        _buildRecentTransactions(context, expensesAsync),
        AppSpacing.verticalSpaceLg,
        
        // Budget Alerts
        _buildBudgetAlerts(context, budgetAsync),
        AppSpacing.verticalSpaceLg,
        
        // Settlement Summary
        _buildSettlementSummary(context, budgetReportAsync),
      ],
    );
  }

  Widget _buildBudgetOverview(
    BuildContext context, 
    AsyncValue<Budget?> budgetAsync,
    AsyncValue<BudgetReport?> budgetReportAsync,
  ) {
    final theme = Theme.of(context);
    
    return budgetAsync.when(
      data: (budget) => budget != null 
        ? Card(
            elevation: 4,
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                      AppSpacing.horizontalSpaceMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Budget Overview',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${budget.currency} ${budget.totalBudget.toStringAsFixed(2)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalSpaceMd,
                  
                  // Progress Bar
                  LinearProgressIndicator(
                    value: budget.totalBudget > 0 ? budget.spentAmount / budget.totalBudget : 0,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      budget.spentAmount > budget.totalBudget * 0.9 
                        ? Colors.red 
                        : budget.spentAmount > budget.totalBudget * 0.7 
                          ? Colors.orange 
                          : theme.colorScheme.primary,
                    ),
                  ),
                  AppSpacing.verticalSpaceSm,
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Spent: ${budget.currency} ${budget.spentAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'Remaining: ${budget.currency} ${(budget.totalBudget - budget.spentAmount).toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: budget.spentAmount > budget.totalBudget * 0.9 
                            ? Colors.red 
                            : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        : _buildNoBudgetCard(context),
      loading: () => Card(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              AppSpacing.verticalSpaceMd,
              Text('Error loading budget: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoBudgetCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            AppSpacing.verticalSpaceMd,
            Text(
              'No Budget Set',
              style: theme.textTheme.headlineSmall,
            ),
            AppSpacing.verticalSpaceSm,
            Text(
              'Create a budget to start tracking expenses',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalSpaceMd,
            FilledButton.icon(
              onPressed: () => _showCreateBudgetDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Budget'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetBreakdown(BuildContext context, AsyncValue<Budget?> budgetAsync) {
    final theme = Theme.of(context);
    
    return budgetAsync.when(
      data: (budget) => budget != null 
        ? Card(
            elevation: 2,
            child: Padding(
              padding: AppSpacing.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget Breakdown',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.verticalSpaceMd,
                  ...budget.categories.map((category) => _buildCategoryItem(context, category)),
                ],
              ),
            ),
          )
        : const SizedBox.shrink(),
      loading: () => const Card(
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildCategoryItem(BuildContext context, BudgetCategory category) {
    final theme = Theme.of(context);
    final progress = category.allocatedAmount > 0 ? (category.spentAmount / category.allocatedAmount).toDouble() : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                category.icon,
                style: const TextStyle(fontSize: 20),
              ),
              AppSpacing.horizontalSpaceSm,
              Expanded(
                child: Text(
                  category.name,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                '\$${category.spentAmount.toStringAsFixed(0)} / \$${category.allocatedAmount.toStringAsFixed(0)}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          AppSpacing.verticalSpaceXs,
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.9 
                ? Colors.red 
                : progress > 0.7 
                  ? Colors.orange 
                  : Color(int.parse(category.color.replaceAll('#', '0xFF'))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(
    BuildContext context, 
    AsyncValue<List<Expense>> expensesAsync,
  ) {
    final theme = Theme.of(context);
    
    return expensesAsync.when(
      data: (expenses) => Card(
        elevation: 2,
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Expenses',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showAllExpenses(context, expenses),
                    child: const Text('View All'),
                  ),
                ],
              ),
              AppSpacing.verticalSpaceMd,
              if (expenses.isEmpty)
                Center(
                  child: Padding(
                    padding: AppSpacing.paddingLg,
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        AppSpacing.verticalSpaceMd,
                        Text(
                          'No expenses yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...expenses.take(5).map((expense) => _buildExpenseItem(context, expense)),
            ],
          ),
        ),
      ),
      loading: () => const Card(
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 32, color: Colors.red),
              AppSpacing.verticalSpaceSm,
              Text('Error loading expenses: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseItem(BuildContext context, Expense expense) {
    final theme = Theme.of(context);
    final categories = ref.read(budgetCategoriesProvider);
    final category = categories.firstWhere(
      (c) => c.id == expense.categoryId,
      orElse: () => categories.first,
    );
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Color(int.parse(category.color.replaceAll('#', '0xFF'))),
        child: Text(
          category.icon,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      title: Text(
        expense.description,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Text(
        '${expense.date.day}/${expense.date.month}/${expense.date.year} • ${expense.splitType.name}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${expense.amount.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: expense.status == ExpenseStatus.settled 
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              expense.status.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: expense.status == ExpenseStatus.settled 
                  ? Colors.green 
                  : Colors.orange,
              ),
            ),
          ),
        ],
      ),
      onTap: () => _showExpenseDetails(context, expense),
    );
  }

  Widget _buildBudgetAlerts(BuildContext context, AsyncValue<Budget?> budgetAsync) {
    final theme = Theme.of(context);
    
    return budgetAsync.when(
      data: (budget) {
        if (budget == null) return const SizedBox.shrink();
        
        final alerts = <Widget>[];
        
        // Budget exceeded alert
        if (budget.spentAmount > budget.totalBudget) {
          alerts.add(
            Card(
              color: Colors.red.withOpacity(0.1),
              child: ListTile(
                leading: Icon(Icons.warning, color: Colors.red),
                title: Text(
                  'Budget Exceeded!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'You have exceeded your budget by \$${(budget.spentAmount - budget.totalBudget).toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
                ),
              ),
            ),
          );
        }
        
        // Budget warning alert
        if (budget.spentAmount > budget.totalBudget * 0.9 && budget.spentAmount <= budget.totalBudget) {
          alerts.add(
            Card(
              color: Colors.orange.withOpacity(0.1),
              child: ListTile(
                leading: Icon(Icons.warning, color: Colors.orange),
                title: Text(
                  'Budget Warning',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'You have used ${((budget.spentAmount / budget.totalBudget) * 100.0).toDouble().toStringAsFixed(1)}% of your budget',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.orange),
                ),
              ),
            ),
          );
        }
        
        return alerts.isNotEmpty 
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alerts',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.verticalSpaceMd,
                ...alerts,
              ],
            )
          : const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildSettlementSummary(
    BuildContext context, 
    AsyncValue<BudgetReport?> budgetReportAsync,
  ) {
    final theme = Theme.of(context);
    
    return budgetReportAsync.when(
      data: (report) => report != null 
        ? Card(
            elevation: 2,
            child: Padding(
              padding: AppSpacing.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settlement Summary',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.verticalSpaceMd,
                  ...report.userReports.map((userReport) => _buildUserSettlement(context, userReport)),
                ],
              ),
            ),
          )
        : const SizedBox.shrink(),
      loading: () => const Card(
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildUserSettlement(BuildContext context, UserExpenseReport userReport) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: userReport.netAmount > 0 
          ? Colors.green.withOpacity(0.1)
          : Colors.red.withOpacity(0.1),
        child: Icon(
          userReport.netAmount > 0 ? Icons.arrow_upward : Icons.arrow_downward,
          color: userReport.netAmount > 0 ? Colors.green : Colors.red,
        ),
      ),
      title: Text(
        userReport.userName,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Text(
        'Paid: \$${userReport.totalPaid.toStringAsFixed(2)} • Owed: \$${userReport.totalOwed.toStringAsFixed(2)}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        userReport.netAmount > 0 
          ? '+\$${userReport.netAmount.toStringAsFixed(2)}'
          : '-\$${userReport.netAmount.abs().toStringAsFixed(2)}',
        style: theme.textTheme.titleMedium?.copyWith(
          color: userReport.netAmount > 0 ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showBudgetOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Budget'),
              onTap: () {
                Navigator.pop(context);
                _showEditBudgetDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('View Reports'),
              onTap: () {
                Navigator.pop(context);
                _showBudgetReports(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Data'),
              onTap: () {
                Navigator.pop(context);
                _exportBudgetData(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateBudgetDialog(BuildContext context) {
    final theme = Theme.of(context);
    final totalBudgetController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCurrency = 'USD';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: totalBudgetController,
              decoration: const InputDecoration(
                labelText: 'Total Budget',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
            ),
            AppSpacing.verticalSpaceMd,
            DropdownButtonFormField<String>(
              value: selectedCurrency,
              decoration: const InputDecoration(labelText: 'Currency'),
              items: ['USD', 'EUR', 'GBP', 'INR'].map((currency) {
                return DropdownMenuItem(value: currency, child: Text(currency));
              }).toList(),
              onChanged: (value) => selectedCurrency = value ?? 'USD',
            ),
            AppSpacing.verticalSpaceMd,
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description (Optional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final totalBudget = double.tryParse(totalBudgetController.text);
              if (totalBudget != null && totalBudget > 0) {
                final categories = ref.read(budgetCategoriesProvider);
                ref.read(budgetActionsProvider.notifier).createBudget(
                  tripId: widget.tripId,
                  totalBudget: totalBudget,
                  currency: selectedCurrency,
                  categories: categories,
                  description: descriptionController.text.isNotEmpty 
                    ? descriptionController.text 
                    : null,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.read(budgetCategoriesProvider);
    final currentUser = ref.read(currentUserProvider);
    
    if (currentUser == null) return;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                ),
                AppSpacing.verticalSpaceMd,
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                AppSpacing.verticalSpaceMd,
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Row(
                        children: [
                          Text(category.icon),
                          AppSpacing.horizontalSpaceSm,
                          Text(category.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCategory = value ?? 'transportation'),
                ),
                AppSpacing.verticalSpaceMd,
                DropdownButtonFormField<ExpenseSplitType>(
                  value: _selectedSplitType,
                  decoration: const InputDecoration(labelText: 'Split Type'),
                  items: ExpenseSplitType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedSplitType = value ?? ExpenseSplitType.equal),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(_amountController.text);
                if (amount != null && amount > 0 && _descriptionController.text.isNotEmpty) {
                  ref.read(budgetActionsProvider.notifier).addExpense(
                    tripId: widget.tripId,
                    categoryId: _selectedCategory,
                    amount: amount,
                    currency: 'USD',
                    description: _descriptionController.text,
                    paidByUserId: currentUser.id,
                    splitBetweenUserIds: [currentUser.id], // TODO: Add member selection
                    splitType: _selectedSplitType,
                    date: _selectedDate,
                  );
                  _amountController.clear();
                  _descriptionController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseDetails(BuildContext context, Expense expense) {
    final theme = Theme.of(context);
    final categories = ref.read(budgetCategoriesProvider);
    final category = categories.firstWhere(
      (c) => c.id == expense.categoryId,
      orElse: () => categories.first,
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Expense Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(int.parse(category.color.replaceAll('#', '0xFF'))),
                child: Text(category.icon),
              ),
              title: Text(expense.description),
              subtitle: Text(category.name),
            ),
            AppSpacing.verticalSpaceMd,
            Text('Amount: \$${expense.amount.toStringAsFixed(2)}'),
            Text('Date: ${expense.date.day}/${expense.date.month}/${expense.date.year}'),
            Text('Status: ${expense.status.name}'),
            Text('Split: ${expense.splitType.name}'),
            if (expense.location != null) Text('Location: ${expense.location}'),
            if (expense.tags != null && expense.tags!.isNotEmpty)
              Text('Tags: ${expense.tags!.join(', ')}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (expense.status != ExpenseStatus.settled)
            FilledButton(
              onPressed: () {
                ref.read(budgetActionsProvider.notifier).settleExpense(expense.id);
                Navigator.pop(context);
              },
              child: const Text('Mark as Settled'),
            ),
        ],
      ),
    );
  }

  void _showAllExpenses(BuildContext context, List<Expense> expenses) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('All Expenses')),
          body: ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (context, index) => _buildExpenseItem(context, expenses[index]),
          ),
        ),
      ),
    );
  }

  void _showEditBudgetDialog(BuildContext context) {
    final theme = Theme.of(context);
    final budgetAsync = ref.read(budgetProvider(widget.tripId));
    
    budgetAsync.when(
      data: (budget) {
        if (budget == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No budget found to edit')),
          );
          return;
        }
        
        final totalBudgetController = TextEditingController(text: budget.totalBudget.toString());
        final descriptionController = TextEditingController(text: budget.description ?? '');
        String selectedCurrency = budget.currency;
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Edit Budget'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: totalBudgetController,
                  decoration: const InputDecoration(
                    labelText: 'Total Budget',
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                ),
                AppSpacing.verticalSpaceMd,
                DropdownButtonFormField<String>(
                  value: selectedCurrency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  items: ['USD', 'EUR', 'GBP', 'INR'].map((currency) {
                    return DropdownMenuItem(value: currency, child: Text(currency));
                  }).toList(),
                  onChanged: (value) => selectedCurrency = value ?? 'USD',
                ),
                AppSpacing.verticalSpaceMd,
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description (Optional)'),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
                               FilledButton(
                   onPressed: () {
                     final totalBudget = double.tryParse(totalBudgetController.text);
                     if (totalBudget != null && totalBudget > 0) {
                       final categories = ref.read(budgetCategoriesProvider);
                       ref.read(budgetActionsProvider.notifier).updateBudget(
                         tripId: widget.tripId,
                         totalBudget: totalBudget,
                         categories: categories,
                         description: descriptionController.text.isNotEmpty 
                           ? descriptionController.text 
                           : null,
                       );
                       Navigator.pop(context);
                     }
                   },
                   child: const Text('Update'),
                 ),
            ],
          ),
        );
      },
      loading: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading budget...')),
      ),
      error: (error, stack) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading budget: $error')),
      ),
    );
  }

  void _showBudgetReports(BuildContext context) {
    final budgetReportAsync = ref.read(budgetReportProvider(widget.tripId));
    final expensesAsync = ref.read(expensesProvider(widget.tripId));
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95, // Increased from 0.9 to 0.95
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Comprehensive Budget Report',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: budgetReportAsync.when(
                  data: (report) => report != null 
                    ? _buildComprehensiveReport(context, report, expensesAsync)
                    : _buildNoReportAvailable(context),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => _buildErrorState(context, error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComprehensiveReport(BuildContext context, BudgetReport report, AsyncValue<List<Expense>> expensesAsync) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16), // Reduced from AppSpacing.paddingLg to 16
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Executive Summary
          _buildExecutiveSummary(context, report),
          const SizedBox(height: 16), // Reduced from AppSpacing.verticalSpaceLg
          
          // Key Metrics Cards
          _buildKeyMetrics(context, report),
          const SizedBox(height: 16), // Reduced from AppSpacing.verticalSpaceLg
          
          // Spending Trends
          _buildSpendingTrends(context, report, expensesAsync),
          const SizedBox(height: 16), // Reduced from AppSpacing.verticalSpaceLg
          
          // Category Analysis
          _buildCategoryAnalysis(context, report),
          const SizedBox(height: 16), // Reduced from AppSpacing.verticalSpaceLg
          
          // User Spending Analysis
          _buildUserSpendingAnalysis(context, report),
          const SizedBox(height: 16), // Reduced from AppSpacing.verticalSpaceLg
          
          // Alerts & Recommendations
          _buildAlertsAndRecommendations(context, report),
          const SizedBox(height: 16), // Reduced from AppSpacing.verticalSpaceLg
          
          // Recent Transactions
          _buildRecentTransactionsSection(context, report),
        ],
      ),
    );
  }

  Widget _buildReportSummary(BuildContext context, BudgetReport report) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Summary',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.verticalSpaceSm,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Budget:'),
                Text('\$${report.totalBudget.toStringAsFixed(2)}'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Spent:'),
                Text('\$${report.totalSpent.toStringAsFixed(2)}'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Remaining:'),
                Text('\$${report.remainingBudget.toStringAsFixed(2)}'),
              ],
            ),
            AppSpacing.verticalSpaceSm,
            LinearProgressIndicator(
              value: report.budgetUtilizationPercentage / 100,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                report.budgetUtilizationPercentage > 90 
                  ? Colors.red 
                  : report.budgetUtilizationPercentage > 70 
                    ? Colors.orange 
                    : Colors.green,
              ),
            ),
            Text(
              '${report.budgetUtilizationPercentage.toStringAsFixed(1)}% utilized',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryReports(BuildContext context, List<CategoryReport> categoryReports) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.verticalSpaceSm,
            ...categoryReports.map((report) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(report.categoryName),
                  ),
                  Expanded(
                    child: Text('\$${report.spentAmount.toStringAsFixed(2)}'),
                  ),
                  Expanded(
                    child: Text('${report.utilizationPercentage.toStringAsFixed(1)}%'),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildUserReports(BuildContext context, List<UserExpenseReport> userReports) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Expenses',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.verticalSpaceSm,
            ...userReports.map((report) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(report.userName),
                  ),
                  Expanded(
                    child: Text('\$${report.totalPaid.toStringAsFixed(2)}'),
                  ),
                  Expanded(
                    child: Text('\$${report.netAmount.toStringAsFixed(2)}'),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  // Helper methods for comprehensive report
  Widget _buildNoReportAvailable(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Budget Report Available',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create a budget and add expenses to generate reports',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Report',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveSummary(BuildContext context, BudgetReport report) {
    final theme = Theme.of(context);
    final isOverBudget = report.totalSpent > report.totalBudget;
    final remainingDays = _calculateRemainingDays();
    
    return Card(
      elevation: 4,
      child: Container(
        padding: AppSpacing.paddingLg,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isOverBudget 
              ? [Colors.red.shade50, Colors.red.shade100]
              : [theme.colorScheme.primaryContainer, theme.colorScheme.secondaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOverBudget ? Icons.warning : Icons.trending_up,
                  color: isOverBudget ? Colors.red : Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Executive Summary',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    context,
                    'Total Budget',
                    '\$${report.totalBudget.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryMetric(
                    context,
                    'Total Spent',
                    '\$${report.totalSpent.toStringAsFixed(2)}',
                    Icons.payments,
                    isOverBudget ? Colors.red : Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildSummaryMetric(
                    context,
                    'Remaining',
                    '\$${report.remainingBudget.toStringAsFixed(2)}',
                    Icons.savings,
                    report.remainingBudget > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Budget Utilization',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${report.budgetUtilizationPercentage.toStringAsFixed(1)}%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: report.budgetUtilizationPercentage > 90 
                            ? Colors.red 
                            : report.budgetUtilizationPercentage > 70 
                              ? Colors.orange 
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (report.budgetUtilizationPercentage / 100).toDouble(),
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      report.budgetUtilizationPercentage > 90 
                        ? Colors.red 
                        : report.budgetUtilizationPercentage > 70 
                          ? Colors.orange 
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            if (remainingDays > 0) ...[
              const SizedBox(height: 8),
              Text(
                '📅 $remainingDays days remaining in trip',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyMetrics(BuildContext context, BudgetReport report) {
    final theme = Theme.of(context);
    final avgExpense = report.recentExpenses.isNotEmpty 
      ? report.recentExpenses.map((e) => e.amount).reduce((a, b) => a + b) / report.recentExpenses.length
      : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8), // Reduced from 12 to 8
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'Average Expense',
                '\$${avgExpense.toStringAsFixed(2)}',
                Icons.analytics,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 8), // Reduced from 12 to 8
            Expanded(
              child: _buildMetricCard(
                context,
                'Total Expenses',
                '${report.recentExpenses.length}',
                Icons.receipt_long,
                Colors.indigo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8), // Reduced from 12 to 8
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'Daily Spending',
                '\$${(report.totalSpent / _calculateTripDuration()).toStringAsFixed(2)}',
                Icons.today,
                Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                'Budget Health',
                _getBudgetHealthStatus(report.budgetUtilizationPercentage),
                Icons.health_and_safety,
                _getBudgetHealthColor(report.budgetUtilizationPercentage),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced from AppSpacing.paddingMd to 12
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingTrends(BuildContext context, BudgetReport report, AsyncValue<List<Expense>> expensesAsync) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Spending Trends',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            expensesAsync.when(
              data: (expenses) => _buildTrendChart(context, expenses),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context, List<Expense> expenses) {
    // Group expenses by date
    final expensesByDate = <DateTime, double>{};
    for (final expense in expenses) {
      final date = DateTime(expense.date.year, expense.date.month, expense.date.day);
      expensesByDate[date] = (expensesByDate[date] ?? 0) + expense.amount;
    }
    
    // Sort by date
    final sortedDates = expensesByDate.keys.toList()..sort();
    
    if (sortedDates.isEmpty) {
      return Container(
        height: 100,
        child: Center(
          child: Text(
            'No spending data available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    
    return Container(
      height: 200,
      child: Row(
        children: sortedDates.map((date) {
          final amount = expensesByDate[date]!;
          final maxAmount = expensesByDate.values.reduce((a, b) => a > b ? a : b);
          final height = maxAmount > 0 ? (amount / maxAmount) * 120.0 : 0.0; // Reduced from 150 to 120
          
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    width: 16, // Reduced from 20 to 16
                    height: height,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 2), // Reduced from 4 to 2
                Flexible(
                  child: Text(
                    '\$${amount.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10), // Smaller font
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    '${date.month}/${date.day}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 9, // Smaller font
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryAnalysis(BuildContext context, BudgetReport report) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Category Analysis',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...report.categoryReports.map((categoryReport) => 
              _buildCategoryAnalysisItem(context, categoryReport)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryAnalysisItem(BuildContext context, CategoryReport categoryReport) {
    final theme = Theme.of(context);
    final isOverBudget = categoryReport.spentAmount > categoryReport.allocatedAmount;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Reduced from 12 to 8
      padding: const EdgeInsets.all(12), // Reduced from AppSpacing.paddingMd to 12
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOverBudget ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  categoryReport.categoryName,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverBudget ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOverBudget ? 'OVER' : 'ON TRACK',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spent: \$${categoryReport.spentAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13), // Smaller font
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Budget: \$${categoryReport.allocatedAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12, // Smaller font
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8), // Added spacing
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${categoryReport.utilizationPercentage.toStringAsFixed(1)}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14, // Smaller font
                        color: categoryReport.utilizationPercentage > 100 
                          ? Colors.red 
                          : categoryReport.utilizationPercentage > 80 
                            ? Colors.orange 
                            : Colors.green,
                      ),
                    ),
                    Text(
                      '${categoryReport.expenseCount} expenses',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11, // Smaller font
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
                     LinearProgressIndicator(
             value: (categoryReport.utilizationPercentage / 100).toDouble(),
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              categoryReport.utilizationPercentage > 100 
                ? Colors.red 
                : categoryReport.utilizationPercentage > 80 
                  ? Colors.orange 
                  : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSpendingAnalysis(BuildContext context, BudgetReport report) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'User Spending Analysis',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...report.userReports.map((userReport) => 
              _buildUserAnalysisItem(context, userReport)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAnalysisItem(BuildContext context, UserExpenseReport userReport) {
    final theme = Theme.of(context);
    final isOwed = userReport.netAmount < 0;
    final isOwing = userReport.netAmount > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6), // Reduced from 8 to 6
      padding: const EdgeInsets.all(10), // Reduced from 12 to 10
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOwed ? Colors.green.withOpacity(0.3) : isOwing ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            radius: 14, // Reduced from 16 to 14
            child: Text(
              userReport.userName[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10), // Reduced from 12 to 10
            ),
          ),
          const SizedBox(width: 6), // Reduced from 8 to 6
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userReport.userName,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${userReport.expenseCount} expenses • \$${userReport.totalPaid.toStringAsFixed(2)} paid',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11, // Smaller font
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 2), // Reduced from 4 to 2
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isOwed ? 'OWED' : isOwing ? 'OWES' : 'SETTLED',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isOwed ? Colors.green : isOwing ? Colors.red : Colors.grey,
                    fontSize: 9, // Reduced from 10 to 9
                  ),
                  textAlign: TextAlign.end,
                ),
                Text(
                  '\$${userReport.netAmount.abs().toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isOwed ? Colors.green : isOwing ? Colors.red : Colors.grey,
                    fontSize: 12, // Reduced from 13 to 12
                  ),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsAndRecommendations(BuildContext context, BudgetReport report) {
    final theme = Theme.of(context);
    final alerts = <Widget>[];
    
    // Budget alerts
    if (report.budgetUtilizationPercentage > 90) {
      alerts.add(_buildAlert(
        context,
        '⚠️ Budget Warning',
        'You\'ve used ${report.budgetUtilizationPercentage.toStringAsFixed(1)}% of your budget. Consider reducing expenses.',
        Colors.orange,
        Icons.warning,
      ));
    }
    
    if (report.totalSpent > report.totalBudget) {
      alerts.add(_buildAlert(
        context,
        '🚨 Over Budget',
        'You\'ve exceeded your budget by \$${(report.totalSpent - report.totalBudget).toStringAsFixed(2)}.',
        Colors.red,
        Icons.error,
      ));
    }
    
    // Category alerts
    for (final category in report.categoryReports) {
      if (category.utilizationPercentage > 100) {
        alerts.add(_buildAlert(
          context,
          '📊 ${category.categoryName} Over Budget',
          'You\'ve exceeded the ${category.categoryName} budget by \$${(category.spentAmount - category.allocatedAmount).toStringAsFixed(2)}.',
          Colors.red,
          Icons.category,
        ));
      }
    }
    
    // Recommendations
    if (report.budgetUtilizationPercentage < 50) {
      alerts.add(_buildAlert(
        context,
        '💡 Budget Opportunity',
        'You\'re only using ${report.budgetUtilizationPercentage.toStringAsFixed(1)}% of your budget. Consider upgrading experiences!',
        Colors.green,
        Icons.lightbulb,
      ));
    }
    
    if (alerts.isEmpty) {
      alerts.add(_buildAlert(
        context,
        '✅ All Good',
        'Your budget is well-managed. Keep up the good work!',
        Colors.green,
        Icons.check_circle,
      ));
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced from AppSpacing.paddingMd to 12
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: theme.colorScheme.primary, size: 20), // Reduced icon size
                const SizedBox(width: 6), // Reduced from 8 to 6
                Expanded(
                  child: Text(
                    'Alerts & Recommendations',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18, // Smaller font size
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...alerts,
          ],
        ),
      ),
    );
  }

  Widget _buildAlert(BuildContext context, String title, String message, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Reduced from 12 to 8
      padding: const EdgeInsets.all(12), // Reduced from AppSpacing.paddingMd to 12
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20), // Reduced from 24 to 20
          const SizedBox(width: 8), // Reduced from 12 to 8
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14, // Smaller font
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2), // Added small spacing
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12, // Smaller font
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2, // Limit to 2 lines
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection(BuildContext context, BudgetReport report) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Recent Transactions',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (report.recentExpenses.isEmpty)
              Center(
                child: Text(
                  'No recent transactions',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...report.recentExpenses.take(5).map((expense) => 
                _buildTransactionItem(context, expense)
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Expense expense) {
    final theme = Theme.of(context);
    final categories = ref.read(budgetCategoriesProvider);
    final category = categories.firstWhere(
      (c) => c.id == expense.categoryId,
      orElse: () => categories.first,
    );
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6), // Reduced from 8 to 6
      padding: const EdgeInsets.all(8), // Reduced from AppSpacing.paddingSm to 8
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(int.parse(category.color.replaceAll('#', '0xFF'))),
            radius: 14, // Reduced from 16
            child: Text(
              category.icon,
              style: const TextStyle(fontSize: 10), // Reduced from 12
            ),
          ),
          const SizedBox(width: 8), // Reduced from 12
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13, // Smaller font
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${expense.date.day}/${expense.date.month}/${expense.date.year} • ${category.name}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11, // Smaller font
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4), // Added spacing
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${expense.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13, // Smaller font
                  ),
                  textAlign: TextAlign.end,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // Reduced padding
                  decoration: BoxDecoration(
                    color: _getStatusColor(expense.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6), // Reduced radius
                  ),
                  child: Text(
                    expense.status.name.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getStatusColor(expense.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 9, // Smaller font
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  int _calculateRemainingDays() {
    // Mock implementation - in real app, get from trip data
    return 5;
  }

  int _calculateTripDuration() {
    // Mock implementation - in real app, get from trip data
    return 7;
  }

  String _getBudgetHealthStatus(double percentage) {
    if (percentage > 90) return 'Critical';
    if (percentage > 70) return 'Warning';
    if (percentage > 50) return 'Good';
    return 'Excellent';
  }

  Color _getBudgetHealthColor(double percentage) {
    if (percentage > 90) return Colors.red;
    if (percentage > 70) return Colors.orange;
    if (percentage > 50) return Colors.yellow;
    return Colors.green;
  }

  Color _getStatusColor(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.pending:
        return Colors.orange;
      case ExpenseStatus.approved:
        return Colors.green;
      case ExpenseStatus.rejected:
        return Colors.red;
      case ExpenseStatus.settled:
        return Colors.blue;
    }
  }

  void _exportBudgetData(BuildContext context) {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon!')),
    );
  }
}

