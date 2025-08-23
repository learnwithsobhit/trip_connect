import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/models.dart';
import '../../../core/data/providers/trip_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';

class TripChecklistScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripChecklistScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripChecklistScreen> createState() => _TripChecklistScreenState();
}

class _TripChecklistScreenState extends ConsumerState<TripChecklistScreen> {
  String _selectedCategory = 'All';
  String _selectedFilter = 'All';
  final List<String> _categories = [
    'All', 'Documents', 'Packing', 'Health', 'Travel', 'Accommodation', 'Activities'
  ];
  final List<String> _filters = ['All', 'Completed', 'Pending', 'Important'];

  final List<ChecklistItem> _checklistItems = [
    // Documents
    ChecklistItem(
      id: 'doc1',
      title: 'Passport',
      description: 'Valid passport with at least 6 months remaining',
      category: 'Documents',
      isCompleted: true,
      isImportant: true,
      dueDate: DateTime.now().subtract(const Duration(days: 30)),
    ),
    ChecklistItem(
      id: 'doc2',
      title: 'Visa Application',
      description: 'Submit visa application if required',
      category: 'Documents',
      isCompleted: true,
      isImportant: true,
      dueDate: DateTime.now().subtract(const Duration(days: 14)),
    ),
    ChecklistItem(
      id: 'doc3',
      title: 'Travel Insurance',
      description: 'Purchase comprehensive travel insurance',
      category: 'Documents',
      isCompleted: false,
      isImportant: true,
      dueDate: DateTime.now().add(const Duration(days: 7)),
    ),
    ChecklistItem(
      id: 'doc4',
      title: 'Flight Tickets',
      description: 'Print or download flight confirmations',
      category: 'Documents',
      isCompleted: false,
      isImportant: true,
      dueDate: DateTime.now().add(const Duration(days: 2)),
    ),

    // Packing
    ChecklistItem(
      id: 'pack1',
      title: 'Clothing',
      description: 'Pack weather-appropriate clothing',
      category: 'Packing',
      isCompleted: false,
      isImportant: false,
      dueDate: DateTime.now().add(const Duration(days: 1)),
    ),
    ChecklistItem(
      id: 'pack2',
      title: 'Electronics',
      description: 'Chargers, adapters, camera, phone',
      category: 'Packing',
      isCompleted: false,
      isImportant: false,
      dueDate: DateTime.now().add(const Duration(days: 1)),
    ),
    ChecklistItem(
      id: 'pack3',
      title: 'Toiletries',
      description: 'Personal hygiene items and medications',
      category: 'Packing',
      isCompleted: true,
      isImportant: false,
      dueDate: DateTime.now().add(const Duration(days: 1)),
    ),

    // Health
    ChecklistItem(
      id: 'health1',
      title: 'Vaccinations',
      description: 'Get required vaccinations for destination',
      category: 'Health',
      isCompleted: true,
      isImportant: true,
      dueDate: DateTime.now().subtract(const Duration(days: 21)),
    ),
    ChecklistItem(
      id: 'health2',
      title: 'Medical Kit',
      description: 'Pack first aid kit and prescription medicines',
      category: 'Health',
      isCompleted: false,
      isImportant: true,
      dueDate: DateTime.now().add(const Duration(days: 2)),
    ),

    // Travel
    ChecklistItem(
      id: 'travel1',
      title: 'Airport Check-in',
      description: 'Complete online check-in 24 hours before',
      category: 'Travel',
      isCompleted: false,
      isImportant: false,
      dueDate: DateTime.now().add(const Duration(hours: 24)),
    ),
    ChecklistItem(
      id: 'travel2',
      title: 'Currency Exchange',
      description: 'Exchange currency or notify bank of travel',
      category: 'Travel',
      isCompleted: false,
      isImportant: false,
      dueDate: DateTime.now().add(const Duration(days: 3)),
    ),

    // Accommodation
    ChecklistItem(
      id: 'acc1',
      title: 'Hotel Confirmation',
      description: 'Confirm hotel reservations',
      category: 'Accommodation',
      isCompleted: true,
      isImportant: true,
      dueDate: DateTime.now().subtract(const Duration(days: 7)),
    ),

    // Activities
    ChecklistItem(
      id: 'act1',
      title: 'Activity Bookings',
      description: 'Book tours and activities in advance',
      category: 'Activities',
      isCompleted: false,
      isImportant: false,
      dueDate: DateTime.now().add(const Duration(days: 5)),
    ),
  ];

  List<ChecklistItem> get _filteredItems {
    List<ChecklistItem> filtered = _checklistItems;

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((item) => item.category == _selectedCategory).toList();
    }

    // Filter by status
    switch (_selectedFilter) {
      case 'Completed':
        filtered = filtered.where((item) => item.isCompleted).toList();
        break;
      case 'Pending':
        filtered = filtered.where((item) => !item.isCompleted).toList();
        break;
      case 'Important':
        filtered = filtered.where((item) => item.isImportant).toList();
        break;
    }

    // Sort by importance, then by due date
    filtered.sort((a, b) {
      if (a.isImportant && !b.isImportant) return -1;
      if (!a.isImportant && b.isImportant) return 1;
      return a.dueDate.compareTo(b.dueDate);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripAsync = ref.watch(tripProvider(widget.tripId));

    return tripAsync.when(
      data: (trip) => trip != null 
          ? _buildChecklistContent(context, theme, trip)
          : const Center(child: Text('Trip not found')),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Error loading trip: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistContent(BuildContext context, ThemeData theme, Trip trip) {
    final filteredItems = _filteredItems;
    final completedCount = _checklistItems.where((item) => item.isCompleted).length;
    final totalCount = _checklistItems.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Checklist'),
        actions: [
          IconButton(
            onPressed: () => _showChecklistOptions(context),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Card
          Container(
            margin: const EdgeInsets.all(AppSpacing.md),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$completedCount / $totalCount',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${(progress * 100).round()}% Complete',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _categories.map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filter',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _filters.map((filter) => DropdownMenuItem(
                      value: filter,
                      child: Text(filter),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedFilter = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Checklist Items
          Expanded(
            child: filteredItems.isEmpty 
                ? _buildEmptyState(theme)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return _buildChecklistItem(theme, item);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'checklist-add-item',
        onPressed: () => _showAddItemDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  Widget _buildChecklistItem(ThemeData theme, ChecklistItem item) {
    final isOverdue = !item.isCompleted && item.dueDate.isBefore(DateTime.now());
    final isDueSoon = !item.isCompleted && 
        item.dueDate.isAfter(DateTime.now()) && 
        item.dueDate.isBefore(DateTime.now().add(const Duration(days: 3)));

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: (value) {
            setState(() {
              final index = _checklistItems.indexWhere((i) => i.id == item.id);
              if (index != -1) {
                _checklistItems[index] = item.copyWith(isCompleted: value ?? false);
              }
            });
          },
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                  color: item.isCompleted 
                      ? theme.colorScheme.onSurface.withOpacity(0.6)
                      : null,
                ),
              ),
            ),
            if (item.isImportant)
              Icon(Icons.priority_high, color: Colors.red, size: 20),
            if (isOverdue)
              Icon(Icons.warning, color: Colors.red, size: 20),
            if (isDueSoon)
              Icon(Icons.schedule, color: Colors.orange, size: 20),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description.isNotEmpty) ...[
              Text(item.description),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _formatDueDate(item.dueDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isOverdue 
                          ? Colors.red 
                          : isDueSoon 
                              ? Colors.orange 
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    item.category,
                    style: theme.textTheme.bodySmall,
                  ),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  side: BorderSide.none,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleItemAction(value, item),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checklist,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No checklist items found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add items to start planning your trip',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => _showAddItemDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add First Item'),
          ),
        ],
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) {
      return 'Overdue by ${-difference} day(s)';
    } else if (difference == 0) {
      return 'Due today';
    } else if (difference == 1) {
      return 'Due tomorrow';
    } else {
      return 'Due in $difference days';
    }
  }

  void _handleItemAction(String action, ChecklistItem item) {
    switch (action) {
      case 'edit':
        _showEditItemDialog(context, item);
        break;
      case 'duplicate':
        _duplicateItem(item);
        break;
      case 'delete':
        _deleteItem(item);
        break;
    }
  }

  void _duplicateItem(ChecklistItem item) {
    setState(() {
      _checklistItems.add(item.copyWith(
        id: 'dup_${DateTime.now().millisecondsSinceEpoch}',
        title: '${item.title} (Copy)',
        isCompleted: false,
      ));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item duplicated successfully!')),
    );
  }

  void _deleteItem(ChecklistItem item) {
    setState(() {
      _checklistItems.removeWhere((i) => i.id == item.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.title} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _checklistItems.add(item);
            });
          },
        ),
      ),
    );
  }

  void _showChecklistOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Checklist'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checklist exported!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share Checklist'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checklist shared!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.save),
            title: const Text('Save as Template'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Template saved!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    _showItemDialog(context, 'Add Checklist Item');
  }

  void _showEditItemDialog(BuildContext context, ChecklistItem item) {
    _showItemDialog(context, 'Edit Checklist Item', item);
  }

  void _showItemDialog(BuildContext context, String title, [ChecklistItem? existingItem]) {
    final titleController = TextEditingController(text: existingItem?.title ?? '');
    final descriptionController = TextEditingController(text: existingItem?.description ?? '');
    String selectedCategory = existingItem?.category ?? 'Documents';
    bool isImportant = existingItem?.isImportant ?? false;
    DateTime selectedDate = existingItem?.dueDate ?? DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.skip(1).map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                CheckboxListTile(
                  title: const Text('Mark as Important'),
                  value: isImportant,
                  onChanged: (value) {
                    setDialogState(() => isImportant = value ?? false);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  title: const Text('Due Date'),
                  subtitle: Text(_formatDueDate(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
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
                if (titleController.text.isNotEmpty) {
                  final newItem = ChecklistItem(
                    id: existingItem?.id ?? 'item_${DateTime.now().millisecondsSinceEpoch}',
                    title: titleController.text,
                    description: descriptionController.text,
                    category: selectedCategory,
                    isCompleted: existingItem?.isCompleted ?? false,
                    isImportant: isImportant,
                    dueDate: selectedDate,
                  );

                  setState(() {
                    if (existingItem != null) {
                      final index = _checklistItems.indexWhere((i) => i.id == existingItem.id);
                      if (index != -1) {
                        _checklistItems[index] = newItem;
                      }
                    } else {
                      _checklistItems.add(newItem);
                    }
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${existingItem != null ? 'Updated' : 'Added'} successfully!')),
                  );
                }
              },
              child: Text(existingItem != null ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChecklistItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final bool isCompleted;
  final bool isImportant;
  final DateTime dueDate;

  ChecklistItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.isCompleted,
    required this.isImportant,
    required this.dueDate,
  });

  ChecklistItem copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    bool? isCompleted,
    bool? isImportant,
    DateTime? dueDate,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
