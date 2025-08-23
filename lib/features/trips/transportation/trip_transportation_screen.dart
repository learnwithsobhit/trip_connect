import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/models.dart';
import '../../../core/data/providers/trip_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';

class TripTransportationScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripTransportationScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripTransportationScreen> createState() => _TripTransportationScreenState();
}

class _TripTransportationScreenState extends ConsumerState<TripTransportationScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Flights', 'Hotels', 'Ground Transport', 'Activities'];

  final List<TransportationItem> _transportationItems = [
    // Flights
    TransportationItem(
      id: 'flight1',
      type: 'Flight',
      title: 'Mumbai to Goa',
      subtitle: 'IndiGo 6E-334',
      description: 'Departure flight to destination',
      icon: Icons.flight_takeoff,
      date: DateTime.now().add(const Duration(days: 1)),
      time: '08:30 - 10:00',
      status: 'Confirmed',
      details: 'Terminal 2, Seat 12A, Check-in opens 2 hours before',
      price: '₹4,500',
      bookingReference: 'INDIGO123456',
      contactInfo: '+91-9876543210',
    ),
    TransportationItem(
      id: 'flight2',
      type: 'Flight',
      title: 'Goa to Mumbai',
      subtitle: 'IndiGo 6E-335',
      description: 'Return flight from destination',
      icon: Icons.flight_land,
      date: DateTime.now().add(const Duration(days: 6)),
      time: '18:45 - 20:15',
      status: 'Confirmed',
      details: 'Terminal 1, Seat 12A, Check-in opens 2 hours before',
      price: '₹4,800',
      bookingReference: 'INDIGO123457',
      contactInfo: '+91-9876543210',
    ),

    // Hotels
    TransportationItem(
      id: 'hotel1',
      type: 'Hotel',
      title: 'Beach Resort Goa',
      subtitle: 'Deluxe Sea View Room',
      description: 'Beachfront accommodation',
      icon: Icons.hotel,
      date: DateTime.now().add(const Duration(days: 1)),
      time: 'Check-in: 14:00',
      status: 'Confirmed',
      details: 'Room 205, Includes breakfast, Pool access',
      price: '₹8,500/night',
      bookingReference: 'BEACH123456',
      contactInfo: '+91-832-2234567',
    ),

    // Ground Transport
    TransportationItem(
      id: 'taxi1',
      type: 'Ground Transport',
      title: 'Airport Pickup',
      subtitle: 'Goa Airport to Hotel',
      description: 'Private cab transfer',
      icon: Icons.local_taxi,
      date: DateTime.now().add(const Duration(days: 1)),
      time: '10:30 - 11:30',
      status: 'Confirmed',
      details: 'AC Sedan, Driver: Ravi (9876543210)',
      price: '₹800',
      bookingReference: 'CAB123456',
      contactInfo: '+91-9876543210',
    ),
    TransportationItem(
      id: 'taxi2',
      type: 'Ground Transport',
      title: 'Hotel to Airport',
      subtitle: 'Return transfer',
      description: 'Private cab transfer',
      icon: Icons.local_taxi,
      date: DateTime.now().add(const Duration(days: 6)),
      time: '16:00 - 17:00',
      status: 'Confirmed',
      details: 'AC Sedan, Driver: Ravi (9876543210)',
      price: '₹800',
      bookingReference: 'CAB123457',
      contactInfo: '+91-9876543210',
    ),

    // Activities
    TransportationItem(
      id: 'activity1',
      type: 'Activity',
      title: 'Dudhsagar Waterfall Trip',
      subtitle: 'Full day excursion',
      description: 'Jeep safari and trekking',
      icon: Icons.landscape,
      date: DateTime.now().add(const Duration(days: 3)),
      time: '07:00 - 18:00',
      status: 'Confirmed',
      details: 'Includes lunch, Guide: Prakash (9876543211)',
      price: '₹2,500',
      bookingReference: 'TREK123456',
      contactInfo: '+91-9876543211',
    ),
    TransportationItem(
      id: 'activity2',
      type: 'Activity',
      title: 'Spice Plantation Tour',
      subtitle: 'Half day tour',
      description: 'Organic spice farm visit',
      icon: Icons.eco,
      date: DateTime.now().add(const Duration(days: 4)),
      time: '09:00 - 13:00',
      status: 'Pending',
      details: 'Includes traditional lunch',
      price: '₹1,200',
      bookingReference: 'SPICE123456',
      contactInfo: '+91-9876543212',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TransportationItem> get _filteredItems {
    if (_selectedFilter == 'All') return _transportationItems;
    return _transportationItems.where((item) => 
        item.type.toLowerCase().contains(_selectedFilter.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripAsync = ref.watch(tripProvider(widget.tripId));

    return tripAsync.when(
      data: (trip) => trip != null 
          ? _buildTransportationContent(context, theme, trip)
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

  Widget _buildTransportationContent(BuildContext context, ThemeData theme, Trip trip) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transportation'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bookings', icon: Icon(Icons.book_online)),
            Tab(text: 'Timeline', icon: Icon(Icons.timeline)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showTransportationOptions(context),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsTab(theme),
          _buildTimelineTab(theme),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'transportation-add-booking',
        onPressed: () => _showAddBookingDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Booking'),
      ),
    );
  }

  Widget _buildBookingsTab(ThemeData theme) {
    final filteredItems = _filteredItems;
    
    return Column(
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Text(
                'Filter:',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: FilterChip(
                        label: Text(filter),
                        selected: _selectedFilter == filter,
                        onSelected: (selected) {
                          setState(() => _selectedFilter = filter);
                        },
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Summary Cards
        Container(
          height: 120,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Expanded(child: _buildSummaryCard(theme, 'Total Cost', '₹22,100', Icons.attach_money, Colors.green)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _buildSummaryCard(theme, 'Bookings', '${_transportationItems.length}', Icons.book, AppColors.primary)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _buildSummaryCard(theme, 'Pending', '1', Icons.pending, Colors.orange)),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Bookings List
        Expanded(
          child: filteredItems.isEmpty 
              ? _buildEmptyState(theme)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _buildBookingCard(theme, item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTimelineTab(ThemeData theme) {
    final sortedItems = List<TransportationItem>.from(_transportationItems)
      ..sort((a, b) => a.date.compareTo(b.date));

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: sortedItems.length,
      itemBuilder: (context, index) {
        final item = sortedItems[index];
        final isLast = index == sortedItems.length - 1;
        
        return _buildTimelineItem(theme, item, isLast);
      },
    );
  }

  Widget _buildSummaryCard(ThemeData theme, String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(ThemeData theme, TransportationItem item) {
    final statusColor = item.status == 'Confirmed' ? Colors.green : 
                      item.status == 'Pending' ? Colors.orange : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.icon, color: AppColors.primary),
        ),
        title: Text(
          item.title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.subtitle),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(item.date)} • ${item.time}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    item.status,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  item.price,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.description.isNotEmpty) ...[
                  Text(
                    'Description',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(item.description),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (item.details.isNotEmpty) ...[
                  Text(
                    'Details',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(item.details),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (item.bookingReference.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'Booking Reference: ',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: SelectableText(
                          item.bookingReference,
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.primary),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _copyToClipboard(item.bookingReference),
                        icon: const Icon(Icons.copy, size: 20),
                      ),
                    ],
                  ),
                ],
                if (item.contactInfo.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'Contact: ',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: SelectableText(
                          item.contactInfo,
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.primary),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _callContact(item.contactInfo),
                        icon: const Icon(Icons.call, size: 20),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _editBooking(item),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _shareBooking(item),
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _cancelBooking(item),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(ThemeData theme, TransportationItem item, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: Colors.white, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 80,
                color: AppColors.primary.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        item.time,
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  Text(item.subtitle),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _formatDate(item.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flight,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No transportation bookings found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add your travel bookings to track them',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => _showAddBookingDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add First Booking'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  void _copyToClipboard(String text) {
    // Implementation for copying to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!')),
    );
  }

  void _callContact(String contact) {
    // Implementation for making phone call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling $contact...')),
    );
  }

  void _editBooking(TransportationItem item) {
    _showAddBookingDialog(context, item);
  }

  void _shareBooking(TransportationItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing ${item.title}...')),
    );
  }

  void _cancelBooking(TransportationItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text('Are you sure you want to cancel ${item.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _transportationItems.removeWhere((i) => i.id == item.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking cancelled')),
              );
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTransportationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Itinerary'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Itinerary exported!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share Itinerary'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Itinerary shared!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync with Calendar'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Synced with calendar!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddBookingDialog(BuildContext context, [TransportationItem? existingItem]) {
    final _formKey = GlobalKey<FormState>();
    final _titleController = TextEditingController(text: existingItem?.title ?? '');
    final _subtitleController = TextEditingController(text: existingItem?.subtitle ?? '');
    final _descriptionController = TextEditingController(text: existingItem?.description ?? '');
    final _priceController = TextEditingController(text: existingItem?.price ?? '');
    final _bookingRefController = TextEditingController(text: existingItem?.bookingReference ?? '');
    final _contactController = TextEditingController(text: existingItem?.contactInfo ?? '');
    final _detailsController = TextEditingController(text: existingItem?.details ?? '');
    
    String _selectedType = existingItem?.type ?? 'Flight';
    DateTime _selectedDate = existingItem?.date ?? DateTime.now().add(const Duration(days: 1));
    TimeOfDay _selectedTime = TimeOfDay.now();
    String _selectedStatus = existingItem?.status ?? 'Confirmed';
    
    final List<String> _types = ['Flight', 'Hotel', 'Ground Transport', 'Activity'];
    final List<String> _statuses = ['Confirmed', 'Pending', 'Cancelled', 'Completed'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existingItem != null ? 'Edit Booking' : 'Add New Booking'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Booking Type
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Booking Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _types.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                    validator: (value) => value == null ? 'Please select a type' : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Mumbai to Goa',
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Please enter a title' : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Subtitle
                  TextFormField(
                    controller: _subtitleController,
                    decoration: const InputDecoration(
                      labelText: 'Subtitle',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., IndiGo 6E-334',
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Departure flight to destination',
                    ),
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Date and Time Row
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() {
                                _selectedDate = date;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                            );
                            if (time != null) {
                              setState(() {
                                _selectedTime = time;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Time',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(_selectedTime.format(context)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Price
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., ₹4,500',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Status
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: _statuses.map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Booking Reference
                  TextFormField(
                    controller: _bookingRefController,
                    decoration: const InputDecoration(
                      labelText: 'Booking Reference',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., INDIGO123456',
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Contact Info
                  TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Info',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., +91-9876543210',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Details
                  TextFormField(
                    controller: _detailsController,
                    decoration: const InputDecoration(
                      labelText: 'Additional Details',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Terminal 2, Seat 12A',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Create new transportation item
                  final newItem = TransportationItem(
                    id: existingItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    type: _selectedType,
                    title: _titleController.text,
                    subtitle: _subtitleController.text,
                    description: _descriptionController.text,
                    icon: _getIconForType(_selectedType),
                    date: _selectedDate,
                    time: _selectedTime.format(context),
                    status: _selectedStatus,
                    details: _detailsController.text,
                    price: _priceController.text,
                    bookingReference: _bookingRefController.text,
                    contactInfo: _contactController.text,
                  );
                  
                  // Add to list (in real app, this would save to backend)
                  if (existingItem == null) {
                    setState(() {
                      _transportationItems.add(newItem);
                    });
                  }
                  
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

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Flight':
        return Icons.flight;
      case 'Hotel':
        return Icons.hotel;
      case 'Ground Transport':
        return Icons.local_taxi;
      case 'Activity':
        return Icons.explore;
      default:
        return Icons.flight;
    }
  }
}

class TransportationItem {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final DateTime date;
  final String time;
  final String status;
  final String details;
  final String price;
  final String bookingReference;
  final String contactInfo;

  TransportationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.date,
    required this.time,
    required this.status,
    required this.details,
    required this.price,
    required this.bookingReference,
    required this.contactInfo,
  });
}
