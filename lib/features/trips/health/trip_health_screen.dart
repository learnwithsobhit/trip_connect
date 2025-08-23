import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/models.dart';
import '../../../core/data/providers/trip_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';

class TripHealthScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripHealthScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripHealthScreen> createState() => _TripHealthScreenState();
}

class _TripHealthScreenState extends ConsumerState<TripHealthScreen> {
  String _selectedHealthCategory = 'Vaccinations';
  bool _hasAllergies = false;
  bool _hasMedications = false;
  bool _hasConditions = false;

  final List<String> _healthCategories = [
    'Vaccinations',
    'Medical Facilities',
    'Health Tips',
    'Emergency Contacts',
    'Personal Health',
    'Local Health Info',
  ];

  // Mock health data
  final Map<String, List<HealthItem>> _healthData = {
    'Vaccinations': [
      HealthItem(
        id: '1',
        title: 'COVID-19 Vaccine',
        description: 'Recommended for all travelers',
        status: 'Required',
        priority: 'High',
        isCompleted: true,
      ),
      HealthItem(
        id: '2',
        title: 'Hepatitis A',
        description: 'Recommended for food and water safety',
        status: 'Recommended',
        priority: 'Medium',
        isCompleted: true,
      ),
      HealthItem(
        id: '3',
        title: 'Typhoid',
        description: 'Recommended for rural areas',
        status: 'Recommended',
        priority: 'Medium',
        isCompleted: false,
      ),
    ],
    'Medical Facilities': [
      HealthItem(
        id: '4',
        title: 'Goa Medical College Hospital',
        description: '24/7 emergency care, English speaking staff',
        status: 'Available',
        priority: 'High',
        isCompleted: false,
        contact: '+91-832-2458700',
        address: 'Bambolim, Goa 403202',
        distance: '15 km',
      ),
      HealthItem(
        id: '5',
        title: 'Manipal Hospital',
        description: 'Private hospital with international standards',
        status: 'Available',
        priority: 'High',
        isCompleted: false,
        contact: '+91-832-2444444',
        address: 'Dona Paula, Goa 403004',
        distance: '8 km',
      ),
    ],
    'Health Tips': [
      HealthItem(
        id: '6',
        title: 'Stay Hydrated',
        description: 'Drink 2-3 liters of water daily, avoid tap water',
        status: 'Important',
        priority: 'High',
        isCompleted: false,
      ),
      HealthItem(
        id: '7',
        title: 'Food Safety',
        description: 'Eat at clean restaurants, avoid street food',
        status: 'Important',
        priority: 'High',
        isCompleted: false,
      ),
      HealthItem(
        id: '8',
        title: 'Sun Protection',
        description: 'Use SPF 30+, wear hats, avoid peak sun hours',
        status: 'Important',
        priority: 'Medium',
        isCompleted: false,
      ),
    ],
    'Emergency Contacts': [
      HealthItem(
        id: '9',
        title: 'Emergency Services',
        description: 'Police, Fire, Ambulance',
        status: 'Emergency',
        priority: 'High',
        isCompleted: false,
        contact: '112',
        address: 'National Emergency Number',
        distance: 'N/A',
      ),
      HealthItem(
        id: '10',
        title: 'Tourist Police',
        description: 'Tourist assistance and safety',
        status: 'Emergency',
        priority: 'High',
        isCompleted: false,
        contact: '+91-832-2424000',
        address: 'Panaji Police Station',
        distance: '12 km',
      ),
    ],
    'Personal Health': [
      HealthItem(
        id: '11',
        title: 'Allergies',
        description: 'Food, environmental, or medication allergies',
        status: 'Personal',
        priority: 'High',
        isCompleted: false,
      ),
      HealthItem(
        id: '12',
        title: 'Medications',
        description: 'Current medications and dosages',
        status: 'Personal',
        priority: 'High',
        isCompleted: false,
      ),
      HealthItem(
        id: '13',
        title: 'Medical Conditions',
        description: 'Chronic conditions or special needs',
        status: 'Personal',
        priority: 'High',
        isCompleted: false,
      ),
    ],
    'Local Health Info': [
      HealthItem(
        id: '14',
        title: 'Water Quality',
        description: 'Tap water is not safe to drink, use bottled water',
        status: 'Local Info',
        priority: 'High',
        isCompleted: false,
      ),
      HealthItem(
        id: '15',
        title: 'Air Quality',
        description: 'Generally good, may be poor during monsoon',
        status: 'Local Info',
        priority: 'Low',
        isCompleted: false,
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripAsync = ref.watch(tripProvider(widget.tripId));

    return tripAsync.when(
      data: (trip) => trip != null ? _buildHealthContent(context, theme, trip) : const Center(child: Text('Trip not found')),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            AppSpacing.verticalSpaceMd,
            Text('Error loading health info: $error'),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthContent(BuildContext context, ThemeData theme, Trip trip) {
    final currentItems = _healthData[_selectedHealthCategory] ?? [];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Health & Safety'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Health Info'),
              Tab(text: 'Personal'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => _showHealthOptions(context),
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildHealthInfoTab(context, theme, currentItems),
            _buildPersonalHealthTab(context, theme),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddHealthItemDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Health Item'),
        ),
      ),
    );
  }

  Widget _buildHealthInfoTab(BuildContext context, ThemeData theme, List<HealthItem> items) {
    return Column(
      children: [
        // Category Selector
        Container(
          padding: AppSpacing.paddingMd,
          child: DropdownButtonFormField<String>(
            value: _selectedHealthCategory,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
              labelText: 'Health Category',
            ),
            items: _healthCategories.map((category) {
              final categoryItems = _healthData[category] ?? [];
              final categoryCompleted = categoryItems.where((item) => item.isCompleted).length;
              final categoryTotal = categoryItems.length;
              
              return DropdownMenuItem(
                value: category,
                child: Text('$category (${categoryCompleted}/${categoryTotal})'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedHealthCategory = value!;
              });
            },
          ),
        ),

        // Health Items
        Expanded(
          child: ListView.builder(
            padding: AppSpacing.paddingMd,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildHealthItemCard(theme, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalHealthTab(BuildContext context, ThemeData theme) {
    return ListView(
      padding: AppSpacing.paddingMd,
      children: [
        // Personal Health Summary
        Card(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Health Summary',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.verticalSpaceMd,
                _buildHealthSummaryItem('Allergies', _hasAllergies, Icons.warning),
                _buildHealthSummaryItem('Medications', _hasMedications, Icons.medication),
                _buildHealthSummaryItem('Medical Conditions', _hasConditions, Icons.medical_services),
              ],
            ),
          ),
        ),

        AppSpacing.verticalSpaceLg,

        // Allergies Section
        Card(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    AppSpacing.horizontalSpaceSm,
                    Text(
                      'Allergies',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _hasAllergies,
                      onChanged: (value) {
                        setState(() {
                          _hasAllergies = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        AppSpacing.verticalSpaceMd,

        // Medications Section
        Card(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.medication, color: Colors.blue),
                    AppSpacing.horizontalSpaceSm,
                    Text(
                      'Current Medications',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _hasMedications,
                      onChanged: (value) {
                        setState(() {
                          _hasMedications = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        AppSpacing.verticalSpaceMd,

        // Medical Conditions Section
        Card(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.medical_services, color: Colors.red),
                    AppSpacing.horizontalSpaceSm,
                    Text(
                      'Medical Conditions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _hasConditions,
                      onChanged: (value) {
                        setState(() {
                          _hasConditions = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        AppSpacing.verticalSpaceLg,

        // Emergency Action Plan
        Card(
          color: Colors.red.shade50,
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emergency, color: Colors.red),
                    AppSpacing.horizontalSpaceSm,
                    Text(
                      'Emergency Action Plan',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalSpaceMd,
                Text(
                  'In case of emergency:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.verticalSpaceSm,
                Text('1. Call emergency services: 112'),
                Text('2. Contact trip leader immediately'),
                Text('3. Go to nearest medical facility'),
                Text('4. Share your health information'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthSummaryItem(String title, bool hasItem, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: hasItem ? Colors.orange : Colors.grey,
          ),
          AppSpacing.horizontalSpaceSm,
          Text(title),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: hasItem ? Colors.orange : Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              hasItem ? 'Yes' : 'No',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthItemCard(ThemeData theme, HealthItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPriorityColor(item.priority),
          child: Icon(
            _getHealthIcon(item.title),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            color: item.isCompleted ? theme.colorScheme.onSurfaceVariant : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description),
            if (item.contact != null) Text('Contact: ${item.contact}'),
            if (item.address != null) Text('Address: ${item.address}'),
            if (item.distance != null) Text('Distance: ${item.distance}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(item.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            AppSpacing.horizontalSpaceSm,
            Checkbox(
              value: item.isCompleted,
              onChanged: (value) {
                setState(() {
                  item.isCompleted = value ?? false;
                });
              },
            ),
          ],
        ),
        onTap: () => _showHealthItemDetails(context, item),
      ),
    );
  }

  IconData _getHealthIcon(String title) {
    if (title.toLowerCase().contains('vaccine')) return Icons.vaccines;
    if (title.toLowerCase().contains('hospital') || title.toLowerCase().contains('medical')) return Icons.local_hospital;
    if (title.toLowerCase().contains('emergency')) return Icons.emergency;
    if (title.toLowerCase().contains('water')) return Icons.water_drop;
    if (title.toLowerCase().contains('sun')) return Icons.wb_sunny;
    return Icons.health_and_safety;
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'required':
      case 'emergency':
        return Colors.red;
      case 'recommended':
      case 'important':
        return Colors.orange;
      case 'available':
        return Colors.green;
      case 'not required':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  void _showHealthItemDetails(BuildContext context, HealthItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description),
            AppSpacing.verticalSpaceMd,
            Text('Status: ${item.status}'),
            Text('Priority: ${item.priority}'),
            if (item.contact != null) Text('Contact: ${item.contact}'),
            if (item.address != null) Text('Address: ${item.address}'),
            if (item.distance != null) Text('Distance: ${item.distance}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (item.contact != null)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _callContact(item.contact!);
              },
              child: const Text('Call'),
            ),
        ],
      ),
    );
  }

  void _callContact(String contact) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling: $contact')),
    );
  }

  void _showHealthOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: AppSpacing.paddingMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Health Info'),
              onTap: () {
                Navigator.pop(context);
                _shareHealthInfo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Health Summary'),
              onTap: () {
                Navigator.pop(context);
                _exportHealthSummary();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Health Settings'),
              onTap: () {
                Navigator.pop(context);
                _showHealthSettings(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHealthItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Health Item'),
        content: const Text('Add custom health information or reminders.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Health item added')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _shareHealthInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Health information shared')),
    );
  }

  void _exportHealthSummary() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Health summary exported')),
    );
  }

  void _showHealthSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Health Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Health Notifications'),
              subtitle: const Text('Get health reminders and alerts'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Emergency Alerts'),
              subtitle: const Text('Get emergency health notifications'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Share with Trip Leader'),
              subtitle: const Text('Share health info with trip organizer'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class HealthItem {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  bool isCompleted;
  final String? contact;
  final String? address;
  final String? distance;

  HealthItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.isCompleted,
    this.contact,
    this.address,
    this.distance,
  });
}
