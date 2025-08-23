import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/models.dart';
import '../../../core/data/providers/trip_provider.dart';
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
  String _selectedCategory = 'Transportation';
  bool _isExpense = true;

  final List<String> _categories = [
    'Transportation',
    'Accommodation',
    'Food & Dining',
    'Activities',
    'Equipment',
    'Insurance',
    'Miscellaneous',
  ];

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
        data: (trip) => trip != null ? _buildBudgetContent(context, trip) : const Center(child: Text('Trip not found')),
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
        onPressed: () => _showAddTransactionDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
    );
  }

  Widget _buildBudgetContent(BuildContext context, Trip trip) {
    final theme = Theme.of(context);
    
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        // Budget Overview Card
        _buildBudgetOverview(context),
        AppSpacing.verticalSpaceLg,
        
        // Budget Breakdown
        _buildBudgetBreakdown(context),
        AppSpacing.verticalSpaceLg,
        
        // Recent Transactions
        _buildRecentTransactions(context),
        AppSpacing.verticalSpaceLg,
        
        // Budget Alerts
        _buildBudgetAlerts(context),
        AppSpacing.verticalSpaceLg,
      ],
    );
  }

  Widget _buildBudgetOverview(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: theme.colorScheme.primary),
                AppSpacing.horizontalSpaceSm,
                Text(
                  'Budget Overview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            AppSpacing.verticalSpaceMd,
            Row(
              children: [
                Expanded(
                  child: _buildBudgetMetric(
                    context,
                    'Total Budget',
                    '\$5,000',
                    Icons.account_balance,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildBudgetMetric(
                    context,
                    'Spent',
                    '\$3,250',
                    Icons.trending_down,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildBudgetMetric(
                    context,
                    'Remaining',
                    '\$1,750',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
            AppSpacing.verticalSpaceMd,
            LinearProgressIndicator(
              value: 0.65, // 65% spent
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            AppSpacing.verticalSpaceSm,
            Text(
              '65% of budget used',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetBreakdown(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget Breakdown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _showDetailedBreakdown(context),
                  child: const Text('View All'),
                ),
              ],
            ),
            AppSpacing.verticalSpaceMd,
            _buildCategoryItem('Transportation', 1200, 0.24, Colors.blue),
            AppSpacing.verticalSpaceSm,
            _buildCategoryItem('Accommodation', 1800, 0.36, Colors.green),
            AppSpacing.verticalSpaceSm,
            _buildCategoryItem('Food & Dining', 800, 0.16, Colors.orange),
            AppSpacing.verticalSpaceSm,
            _buildCategoryItem('Activities', 450, 0.09, Colors.purple),
            AppSpacing.verticalSpaceSm,
            _buildCategoryItem('Equipment', 300, 0.06, Colors.teal),
            AppSpacing.verticalSpaceSm,
            _buildCategoryItem('Insurance', 200, 0.04, Colors.indigo),
            AppSpacing.verticalSpaceSm,
            _buildCategoryItem('Miscellaneous', 250, 0.05, Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _showAllTransactions(context),
                  child: const Text('View All'),
                ),
              ],
            ),
            AppSpacing.verticalSpaceMd,
            _buildTransactionItem('Hotel Booking', 'Accommodation', -450, '2 hours ago'),
            _buildTransactionItem('Train Tickets', 'Transportation', -120, '1 day ago'),
            _buildTransactionItem('Group Dinner', 'Food & Dining', -85, '2 days ago'),
            _buildTransactionItem('Member Payment', 'Payment', 200, '3 days ago'),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetAlerts(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Alerts',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalSpaceMd,
            _buildAlertItem(
              'High Spending Alert',
              'Accommodation category is 80% of allocated budget',
              Icons.warning,
              Colors.orange,
            ),
            AppSpacing.verticalSpaceSm,
            _buildAlertItem(
              'Budget Milestone',
              'You\'ve spent 65% of total budget',
              Icons.info,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetMetric(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        AppSpacing.verticalSpaceSm,
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String category, double amount, double percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        AppSpacing.horizontalSpaceSm,
        Expanded(
          child: Text(category),
        ),
        Text(
          '\$${amount.toInt()}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        AppSpacing.horizontalSpaceSm,
        Text(
          '${(percentage * 100).toInt()}%',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(String title, String category, double amount, String time) {
    final theme = Theme.of(context);
    final isExpense = amount < 0;
    
    return Padding(
      padding: AppSpacing.paddingVerticalSm,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isExpense ? Colors.red : Colors.green).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isExpense ? Icons.remove : Icons.add,
              color: isExpense ? Colors.red : Colors.green,
              size: 16,
            ),
          ),
          AppSpacing.horizontalSpaceMd,
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
                Text(
                  '$category • $time',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${amount.abs().toStringAsFixed(0)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isExpense ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(String title, String message, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          AppSpacing.horizontalSpaceMd,
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
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: AppSpacing.paddingLg,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Transaction',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.verticalSpaceMd,
                
                // Transaction Type
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Expense'),
                        value: true,
                        groupValue: _isExpense,
                        onChanged: (value) => setState(() => _isExpense = value!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Income'),
                        value: false,
                        groupValue: _isExpense,
                        onChanged: (value) => setState(() => _isExpense = value!),
                      ),
                    ),
                  ],
                ),
                
                // Amount
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                AppSpacing.verticalSpaceMd,
                
                // Category
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCategory = value!),
                ),
                AppSpacing.verticalSpaceMd,
                
                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                  ),
                  maxLines: 2,
                ),
                AppSpacing.verticalSpaceLg,
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    AppSpacing.horizontalSpaceMd,
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _addTransaction();
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
              leading: const Icon(Icons.download),
              title: const Text('Export Budget Report'),
              onTap: () {
                Navigator.pop(context);
                _exportBudgetReport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Budget'),
              onTap: () {
                Navigator.pop(context);
                _shareBudget();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Budget Settings'),
              onTap: () {
                Navigator.pop(context);
                _showBudgetSettings(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailedBreakdown(BuildContext context) {
    // Navigate to detailed breakdown screen
    context.push('/trips/${widget.tripId}/budget/breakdown');
  }

  void _showAllTransactions(BuildContext context) {
    // Navigate to all transactions screen
    context.push('/trips/${widget.tripId}/budget/transactions');
  }

  void _addTransaction() {
    // Implementation for adding transaction
    final amount = double.parse(_amountController.text);
    final description = _descriptionController.text;
    
    // Here you would typically save the transaction to your backend
    // For now, we'll just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_isExpense ? 'Expense' : 'Income'} of \$${amount.toStringAsFixed(2)} added to $_selectedCategory'),
        backgroundColor: _isExpense ? Colors.red : Colors.green,
      ),
    );
    
    // Clear form
    _amountController.clear();
    _descriptionController.clear();
  }

  void _exportBudgetReport() {
    // Implementation for exporting budget report
  }

  void _shareBudget() {
    // Implementation for sharing budget
  }

  void _showBudgetSettings(BuildContext context) {
    // Show budget settings dialog
  }
}
