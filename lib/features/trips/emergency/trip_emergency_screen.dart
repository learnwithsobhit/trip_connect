import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/models.dart';
import '../../../core/data/providers/trip_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';

class TripEmergencyScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripEmergencyScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripEmergencyScreen> createState() => _TripEmergencyScreenState();
}

class _TripEmergencyScreenState extends ConsumerState<TripEmergencyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();
  String _selectedContactType = 'Emergency Contact';

  final List<String> _contactTypes = [
    'Emergency Contact',
    'Local Guide',
    'Hotel Contact',
    'Transport Provider',
    'Medical Contact',
    'Police Contact',
    'Embassy Contact',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripAsync = ref.watch(tripProvider(widget.tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency & Safety'),
        actions: [
          IconButton(
            onPressed: () => _showEmergencyOptions(context),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: tripAsync.when(
        data: (trip) => trip != null ? _buildEmergencyContent(context, trip) : const Center(child: Text('Trip not found')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              AppSpacing.verticalSpaceMd,
              Text('Error loading emergency info: $error'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContactDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Contact'),
      ),
    );
  }

  Widget _buildEmergencyContent(BuildContext context, Trip trip) {
    final theme = Theme.of(context);
    
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        // Emergency Quick Actions
        _buildQuickActions(context),
        AppSpacing.verticalSpaceLg,
        
        // Emergency Contacts
        _buildEmergencyContacts(context),
        AppSpacing.verticalSpaceLg,
        
        // Safety Information
        _buildSafetyInformation(context),
        AppSpacing.verticalSpaceLg,
        
        // Local Emergency Numbers
        _buildLocalEmergencyNumbers(context),
        AppSpacing.verticalSpaceLg,
        
        // Safety Tips
        _buildSafetyTips(context),
        AppSpacing.verticalSpaceLg,
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
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
                Icon(Icons.emergency, color: Colors.red),
                AppSpacing.horizontalSpaceSm,
                Text(
                  'Quick Actions',
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
                  child: _buildQuickActionButton(
                    context,
                    'SOS Alert',
                    Icons.sos,
                    Colors.red,
                    () => _sendSOSAlert(),
                  ),
                ),
                AppSpacing.horizontalSpaceMd,
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    'Share Location',
                    Icons.location_on,
                    Colors.blue,
                    () => _shareLocation(),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalSpaceMd,
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    'Call Emergency',
                    Icons.phone,
                    Colors.orange,
                    () => _callEmergency(),
                  ),
                ),
                AppSpacing.horizontalSpaceMd,
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    'Medical Info',
                    Icons.medical_services,
                    Colors.green,
                    () => _showMedicalInfo(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContacts(BuildContext context) {
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
                  'Emergency Contacts',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _showAllContacts(context),
                  child: const Text('View All'),
                ),
              ],
            ),
            AppSpacing.verticalSpaceMd,
            _buildContactItem('John Smith', 'Emergency Contact', '+1-555-0123', Icons.emergency, Colors.red),
            _buildContactItem('Sarah Johnson', 'Local Guide', '+1-555-0456', Icons.person, Colors.blue),
            _buildContactItem('Hotel Reception', 'Hotel Contact', '+1-555-0789', Icons.hotel, Colors.green),
            _buildContactItem('Dr. Michael Brown', 'Medical Contact', '+1-555-0321', Icons.medical_services, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyInformation(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safety Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalSpaceMd,
            _buildSafetyItem(
              'Trip Insurance',
              'Active - Coverage until Aug 25, 2025',
              Icons.security,
              Colors.green,
            ),
            AppSpacing.verticalSpaceSm,
            _buildSafetyItem(
              'Medical Coverage',
              'Basic coverage included',
              Icons.medical_services,
              Colors.blue,
            ),
            AppSpacing.verticalSpaceSm,
            _buildSafetyItem(
              'Emergency Fund',
              '\$500 available for emergencies',
              Icons.account_balance_wallet,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalEmergencyNumbers(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Local Emergency Numbers',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalSpaceMd,
            _buildEmergencyNumber('Police', '911', Icons.local_police, Colors.blue),
            _buildEmergencyNumber('Ambulance', '911', Icons.medical_services, Colors.red),
            _buildEmergencyNumber('Fire Department', '911', Icons.local_fire_department, Colors.orange),
            _buildEmergencyNumber('US Embassy', '+1-202-501-4444', Icons.account_balance, Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTips(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safety Tips',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalSpaceMd,
            _buildSafetyTip(
              'Stay with the group',
              'Always inform someone if you need to leave the group',
              Icons.group,
            ),
            AppSpacing.verticalSpaceSm,
            _buildSafetyTip(
              'Keep emergency contacts handy',
              'Save important numbers in your phone',
              Icons.contact_phone,
            ),
            AppSpacing.verticalSpaceSm,
            _buildSafetyTip(
              'Know your location',
              'Be aware of your surroundings and location',
              Icons.location_on,
            ),
            AppSpacing.verticalSpaceSm,
            _buildSafetyTip(
              'Follow local customs',
              'Respect local laws and customs',
              Icons.public,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onPressed) {
    final theme = Theme.of(context);
    
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 2,
        padding: AppSpacing.paddingMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          AppSpacing.verticalSpaceXs,
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(String name, String type, String phone, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: AppSpacing.paddingVerticalSm,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          AppSpacing.horizontalSpaceMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  type,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _callContact(phone),
            icon: Icon(Icons.phone, color: Colors.green),
          ),
          IconButton(
            onPressed: () => _messageContact(phone),
            icon: Icon(Icons.message, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyItem(String title, String description, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Row(
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
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyNumber(String service, String number, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: AppSpacing.paddingVerticalSm,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          AppSpacing.horizontalSpaceMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  number,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _callEmergencyNumber(number),
            icon: Icon(Icons.phone, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(String title, String description, IconData icon) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 20),
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
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddContactDialog(BuildContext context) {
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
                  'Add Emergency Contact',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.verticalSpaceMd,
                
                // Contact Type
                DropdownButtonFormField<String>(
                  value: _selectedContactType,
                  decoration: const InputDecoration(
                    labelText: 'Contact Type',
                  ),
                  items: _contactTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedContactType = value!),
                ),
                AppSpacing.verticalSpaceMd,
                
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                AppSpacing.verticalSpaceMd,
                
                // Phone
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    return null;
                  },
                ),
                AppSpacing.verticalSpaceMd,
                
                // Relationship
                TextFormField(
                  controller: _relationshipController,
                  decoration: const InputDecoration(
                    labelText: 'Relationship (Optional)',
                  ),
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
                            _addContact();
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

  void _showEmergencyOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Emergency Info'),
              onTap: () {
                Navigator.pop(context);
                _exportEmergencyInfo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Emergency Contacts'),
              onTap: () {
                Navigator.pop(context);
                _shareEmergencyContacts();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Emergency Settings'),
              onTap: () {
                Navigator.pop(context);
                _showEmergencySettings(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAllContacts(BuildContext context) {
    // Navigate to all contacts screen
    context.push('/trips/${widget.tripId}/emergency/contacts');
  }

  void _sendSOSAlert() {
    // Implementation for sending SOS alert
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SOS Alert sent to all emergency contacts'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _shareLocation() {
    // Implementation for sharing location
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location shared with emergency contacts'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _callEmergency() {
    // Implementation for calling emergency
  }

  void _showMedicalInfo() {
    // Show medical information dialog
  }

  void _callContact(String phone) {
    // Implementation for calling contact
  }

  void _messageContact(String phone) {
    // Implementation for messaging contact
  }

  void _callEmergencyNumber(String number) {
    // Implementation for calling emergency number
  }

  void _addContact() {
    // Implementation for adding contact
    final name = _nameController.text;
    final phone = _phoneController.text;
    final relationship = _relationshipController.text;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Emergency contact $name added'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Clear form
    _nameController.clear();
    _phoneController.clear();
    _relationshipController.clear();
  }

  void _exportEmergencyInfo() {
    // Implementation for exporting emergency info
  }

  void _shareEmergencyContacts() {
    // Implementation for sharing emergency contacts
  }

  void _showEmergencySettings(BuildContext context) {
    // Show emergency settings dialog
  }
}
