import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/providers/trip_provider.dart';
import '../../../core/data/providers/auth_provider.dart';
import '../../../core/data/models/models.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../common/widgets/user_rating_badge.dart';

class TripChatScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripChatScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripChatScreen> createState() => _TripChatScreenState();
}

class _TripChatScreenState extends ConsumerState<TripChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _pollQuestionController = TextEditingController();
  final List<String> _pollOptions = ['', '', '', ''];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pollQuestionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messagesAsync = ref.watch(tripMessagesProvider(widget.tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Chat'),
        leading: IconButton(
          onPressed: () => context.go('/trips/${widget.tripId}'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAnnouncementDialog(context),
            icon: const Icon(Icons.campaign_outlined),
            tooltip: 'Send Announcement',
          ),
          IconButton(
            onPressed: () => _showPollDialog(context),
            icon: const Icon(Icons.poll_outlined),
            tooltip: 'Create Poll',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'emergency',
                child: Row(
                  children: [
                    Icon(Icons.emergency, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Emergency Alert'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'rollcall',
                child: Row(
                  children: [
                    Icon(Icons.how_to_reg),
                    SizedBox(width: 8),
                    Text('Start Roll Call'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'emergency') {
                _sendEmergencyAlert();
              } else if (value == 'rollcall') {
                _startRollCall();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (messages) => _buildMessagesList(messages),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
          
          // Message input
          _buildMessageInput(theme),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<Message> messages) {
    if (messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No messages yet'),
            Text('Start the conversation!'),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: AppSpacing.paddingMd,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Padding(
          padding: AppSpacing.paddingVerticalXs,
          child: _MessageBubble(message: message),
        );
      },
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Attachment options row
            Row(
              children: [
                IconButton(
                  onPressed: () => _showAttachmentOptions(context),
                  icon: const Icon(Icons.attach_file),
                  tooltip: 'Attach',
                ),
                IconButton(
                  onPressed: () => _takePhoto(),
                  icon: const Icon(Icons.camera_alt),
                  tooltip: 'Camera',
                ),
                IconButton(
                  onPressed: () => _chooseFromGallery(),
                  icon: const Icon(Icons.photo_library),
                  tooltip: 'Gallery',
                ),
                IconButton(
                  onPressed: () => _shareLocation(),
                  icon: const Icon(Icons.location_on),
                  tooltip: 'Location',
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showTranslationOptions(context),
                  icon: const Icon(Icons.translate),
                  tooltip: 'Translate',
                ),
              ],
            ),
            
            // Message input row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: AppSpacing.paddingMd,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                AppSpacing.horizontalSpaceSm,
                FloatingActionButton.small(
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    try {
      final tripActions = ref.read(tripActionsProvider.notifier);
      await tripActions.sendMessage(widget.tripId, text);
      
      // Scroll to bottom after sending
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppSpacing.animationFast,
          curve: AppSpacing.curveStandard,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  void _showAnnouncementDialog(BuildContext context) {
    final controller = TextEditingController();
    bool requiresAck = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Send Announcement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Announcement',
                  hintText: 'Important message for all members',
                ),
                maxLines: 3,
              ),
              AppSpacing.verticalSpaceMd,
              CheckboxListTile(
                value: requiresAck,
                onChanged: (value) => setState(() => requiresAck = value ?? false),
                title: const Text('Require Acknowledgment'),
                subtitle: const Text('Members must acknowledge this message'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  try {
                    final tripActions = ref.read(tripActionsProvider.notifier);
                    await tripActions.sendMessage(
                      widget.tripId,
                      controller.text,
                      type: MessageType.announcement,
                      requiresAck: requiresAck,
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to send announcement: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPollDialog(BuildContext context) {
    final questionController = TextEditingController();
    final List<TextEditingController> optionControllers = [
      TextEditingController(),
      TextEditingController(),
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Poll'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  hintText: 'What would you like to ask?',
                ),
              ),
              AppSpacing.verticalSpaceMd,
              ...optionControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Padding(
                  padding: AppSpacing.paddingVerticalXs,
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Option ${index + 1}',
                      hintText: 'Enter option',
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _createPoll();
              Navigator.of(context).pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendEmergencyAlert() async {
    try {
      final tripActions = ref.read(tripActionsProvider.notifier);
      await tripActions.raiseAlert(
        widget.tripId,
        AlertKind.sos,
        const AlertPayload(
          message: 'Emergency alert raised from chat',
        ),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency alert sent to all members'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send emergency alert: $e')),
        );
      }
    }
  }

  Future<void> _startRollCall() async {
    try {
      final tripActions = ref.read(tripActionsProvider.notifier);
      await tripActions.startRollCall(widget.tripId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Roll call started')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start roll call: $e')),
        );
      }
    }
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Photo'),
            onTap: () {
              Navigator.pop(context);
              _chooseFromGallery();
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () {
              Navigator.pop(context);
              _takePhoto();
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Document'),
            onTap: () {
              Navigator.pop(context);
              _chooseDocument();
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Location'),
            onTap: () {
              Navigator.pop(context);
              _shareLocation();
            },
          ),
        ],
      ),
    );
  }

  void _takePhoto() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.blue),
            title: const Text('Take Photo'),
            subtitle: const Text('Use camera to capture a new photo'),
            onTap: () {
              Navigator.pop(context);
              _capturePhoto();
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_roll, color: Colors.green),
            title: const Text('Record Video'),
            subtitle: const Text('Record a short video message'),
            onTap: () {
              Navigator.pop(context);
              _recordVideo();
            },
          ),
        ],
      ),
    );
  }

  void _capturePhoto() {
    // Simulate camera capture
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Camera'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text('Camera viewfinder would appear here'),
            SizedBox(height: 8),
            Text('Tap to capture photo'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _sendPhotoMessage('Camera Photo', '📸');
            },
            child: const Text('Capture'),
          ),
        ],
      ),
    );
  }

  void _recordVideo() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Record Video'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Video recorder would appear here'),
            SizedBox(height: 8),
            Text('Hold to record video'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _sendVideoMessage('Recorded Video', '🎥');
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  void _chooseFromGallery() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.photo_library, color: Colors.green),
                  const SizedBox(width: 12),
                  const Text(
                    'Photo Gallery',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Gallery content
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 20, // Mock gallery items
                itemBuilder: (context, index) {
                  return _buildGalleryItem(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryItem(int index) {
    final List<String> mockPhotos = [
      '🌅', '🏖️', '🏰', '🌊', '🌴', '⛰️', '🌆', '🌉', '🏞️', '🌺',
      '🦋', '🐚', '🌙', '⭐', '🌈', '🌸', '🍀', '🌻', '🌹', '🌷'
    ];
    
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _sendPhotoMessage('Gallery Photo ${index + 1}', mockPhotos[index]);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            mockPhotos[index],
            style: const TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }

  void _chooseDocument() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.description, color: Colors.orange),
                const SizedBox(width: 12),
                const Text(
                  'Select Document',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Document categories
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text('PDF Documents'),
            subtitle: const Text('Select PDF files'),
            onTap: () {
              Navigator.pop(context);
              _showDocumentList('PDF');
            },
          ),
          ListTile(
            leading: const Icon(Icons.description, color: Colors.blue),
            title: const Text('Word Documents'),
            subtitle: const Text('Select .doc, .docx files'),
            onTap: () {
              Navigator.pop(context);
              _showDocumentList('Word');
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_chart, color: Colors.green),
            title: const Text('Spreadsheets'),
            subtitle: const Text('Select .xls, .xlsx files'),
            onTap: () {
              Navigator.pop(context);
              _showDocumentList('Spreadsheet');
            },
          ),
          ListTile(
            leading: const Icon(Icons.image, color: Colors.purple),
            title: const Text('Images'),
            subtitle: const Text('Select image files'),
            onTap: () {
              Navigator.pop(context);
              _showDocumentList('Image');
            },
          ),
        ],
      ),
    );
  }

  void _showDocumentList(String category) {
    final Map<String, List<Map<String, String>>> documents = {
      'PDF': [
        {'name': 'Trip Itinerary.pdf', 'icon': '📄', 'size': '2.4 MB'},
        {'name': 'Hotel Booking.pdf', 'icon': '🏨', 'size': '1.8 MB'},
        {'name': 'Flight Tickets.pdf', 'icon': '✈️', 'size': '3.2 MB'},
      ],
      'Word': [
        {'name': 'Trip Notes.docx', 'icon': '📝', 'size': '1.2 MB'},
        {'name': 'Meeting Minutes.docx', 'icon': '📋', 'size': '0.8 MB'},
      ],
      'Spreadsheet': [
        {'name': 'Budget Tracker.xlsx', 'icon': '💰', 'size': '1.5 MB'},
        {'name': 'Schedule.xlsx', 'icon': '📅', 'size': '0.9 MB'},
      ],
      'Image': [
        {'name': 'Map.jpg', 'icon': '🗺️', 'size': '4.1 MB'},
        {'name': 'Group Photo.jpg', 'icon': '📸', 'size': '3.8 MB'},
      ],
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder, color: Colors.orange),
                  const SizedBox(width: 12),
                  Text(
                    '$category Documents',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Document list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: documents[category]?.length ?? 0,
                itemBuilder: (context, index) {
                  final doc = documents[category]![index];
                  return ListTile(
                    leading: Text(
                      doc['icon']!,
                      style: const TextStyle(fontSize: 32),
                    ),
                    title: Text(doc['name']!),
                    subtitle: Text(doc['size']!),
                    onTap: () {
                      Navigator.pop(context);
                      _sendDocumentMessage(doc['name']!, doc['icon']!);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareLocation() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 12),
                const Text(
                  'Share Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Location options
          ListTile(
            leading: const Icon(Icons.my_location, color: Colors.blue),
            title: const Text('Current Location'),
            subtitle: const Text('Share your current GPS location'),
            onTap: () {
              Navigator.pop(context);
              _shareCurrentLocation();
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_city, color: Colors.green),
            title: const Text('Saved Places'),
            subtitle: const Text('Choose from your saved locations'),
            onTap: () {
              Navigator.pop(context);
              _showSavedPlaces();
            },
          ),
          ListTile(
            leading: const Icon(Icons.search, color: Colors.orange),
            title: const Text('Search Location'),
            subtitle: const Text('Search for a specific location'),
            onTap: () {
              Navigator.pop(context);
              _searchLocation();
            },
          ),
        ],
      ),
    );
  }

  void _shareCurrentLocation() {
    // Simulate getting current location
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Getting Location'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Getting your current location...'),
          ],
        ),
      ),
    );

    // Simulate location fetch delay
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      _sendLocationMessage('Current Location', '📍');
    });
  }

  void _showSavedPlaces() {
    final List<Map<String, String>> savedPlaces = [
      {'name': 'Home', 'address': 'Mumbai, Maharashtra', 'icon': '🏠'},
      {'name': 'Office', 'address': 'Bandra West, Mumbai', 'icon': '🏢'},
      {'name': 'Airport', 'address': 'Chhatrapati Shivaji International Airport', 'icon': '✈️'},
      {'name': 'Hotel', 'address': 'Taj Mahal Palace, Mumbai', 'icon': '🏨'},
      {'name': 'Restaurant', 'address': 'Leopold Cafe, Colaba', 'icon': '🍽️'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bookmark, color: Colors.green),
                  const SizedBox(width: 12),
                  const Text(
                    'Saved Places',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Places list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: savedPlaces.length,
                itemBuilder: (context, index) {
                  final place = savedPlaces[index];
                  return ListTile(
                    leading: Text(
                      place['icon']!,
                      style: const TextStyle(fontSize: 32),
                    ),
                    title: Text(place['name']!),
                    subtitle: Text(place['address']!),
                    onTap: () {
                      Navigator.pop(context);
                      _sendLocationMessage('${place['name']} - ${place['address']}', place['icon']!);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _searchLocation() {
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search for a location',
                hintText: 'e.g., Taj Mahal, Goa Beach',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Search functionality will be implemented with Google Places API',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
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
              if (searchController.text.isNotEmpty) {
                Navigator.pop(context);
                _sendLocationMessage('Searched: ${searchController.text}', '🔍');
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _sendPhotoMessage(String title, String emoji) {
    try {
      final tripActions = ref.read(tripActionsProvider.notifier);
      tripActions.sendMessage(
        widget.tripId,
        '$emoji $title',
        type: MessageType.chat,
        tags: ['photo', 'media'],
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title sent successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send $title: $e')),
      );
    }
  }

  void _sendVideoMessage(String title, String emoji) {
    try {
      final tripActions = ref.read(tripActionsProvider.notifier);
      tripActions.sendMessage(
        widget.tripId,
        '$emoji $title',
        type: MessageType.chat,
        tags: ['video', 'media'],
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title sent successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send $title: $e')),
      );
    }
  }

  void _sendDocumentMessage(String title, String emoji) {
    try {
      final tripActions = ref.read(tripActionsProvider.notifier);
      tripActions.sendMessage(
        widget.tripId,
        '$emoji $title',
        type: MessageType.chat,
        tags: ['document', 'file'],
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title sent successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send $title: $e')),
      );
    }
  }

  void _sendLocationMessage(String title, String emoji) {
    try {
      final tripActions = ref.read(tripActionsProvider.notifier);
      tripActions.sendMessage(
        widget.tripId,
        '$emoji $title',
        type: MessageType.chat,
        tags: ['location', 'map'],
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title shared successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share $title: $e')),
      );
    }
  }

  void _showTranslationOptions(BuildContext context) {
    String _selectedLanguage = 'Hindi';
    String _selectedText = _messageController.text;
    final List<Map<String, String>> _languages = [
      {'name': 'Hindi', 'code': 'hi', 'flag': '🇮🇳'},
      {'name': 'Spanish', 'code': 'es', 'flag': '🇪🇸'},
      {'name': 'French', 'code': 'fr', 'flag': '🇫🇷'},
      {'name': 'German', 'code': 'de', 'flag': '🇩🇪'},
      {'name': 'Chinese', 'code': 'zh', 'flag': '🇨🇳'},
      {'name': 'Japanese', 'code': 'ja', 'flag': '🇯🇵'},
      {'name': 'Arabic', 'code': 'ar', 'flag': '🇸🇦'},
      {'name': 'Russian', 'code': 'ru', 'flag': '🇷🇺'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) => Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.translate, color: Colors.blue),
                    const SizedBox(width: 12),
                    const Text(
                      'Translate Message',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Text to translate
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Text to translate:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedText.isEmpty ? 'Type a message first' : _selectedText,
                        style: TextStyle(
                          color: _selectedText.isEmpty ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Language selection
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _languages.length,
                  itemBuilder: (context, index) {
                    final language = _languages[index];
                    final isSelected = _selectedLanguage == language['name'];
                    
                    return ListTile(
                      leading: Text(
                        language['flag']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(language['name']!),
                      subtitle: Text('Translate to ${language['name']}'),
                      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                      onTap: () {
                        setState(() {
                          _selectedLanguage = language['name']!;
                        });
                      },
                    );
                  },
                ),
              ),
              
              // Action buttons
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: _selectedText.isEmpty ? null : () {
                          Navigator.pop(context);
                          _translateAndSendMessage(_selectedText, _selectedLanguage);
                        },
                        child: const Text('Translate & Send'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _translateAndSendMessage(String originalText, String targetLanguage) {
    // Mock translation
    final Map<String, String> translations = {
      'Hindi': 'नमस्ते! यह एक अनुवादित संदेश है।',
      'Spanish': '¡Hola! Este es un mensaje traducido.',
      'French': 'Bonjour! Ceci est un message traduit.',
      'German': 'Hallo! Dies ist eine übersetzte Nachricht.',
      'Chinese': '你好！这是一条翻译的消息。',
      'Japanese': 'こんにちは！これは翻訳されたメッセージです。',
      'Arabic': 'مرحبا! هذه رسالة مترجمة.',
      'Russian': 'Привет! Это переведенное сообщение.',
    };

    final translatedText = translations[targetLanguage] ?? originalText;
    
    try {
      final tripActions = ref.read(tripActionsProvider.notifier);
      tripActions.sendMessage(
        widget.tripId,
        translatedText,
        type: MessageType.chat,
        tags: ['translated', targetLanguage.toLowerCase()],
      );
      
      // Clear the input
      _messageController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message translated to $targetLanguage and sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send translated message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createPoll() async {
    try {
      final pollQuestion = _pollQuestionController.text.trim();
      final pollOptions = _pollOptions.where((option) => option.trim().isNotEmpty).toList();
      
      if (pollQuestion.isEmpty || pollOptions.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a question and at least 2 options')),
        );
        return;
      }

      // Create poll options
      final pollOptionList = pollOptions.asMap().entries.map((entry) {
        return PollOption(
          id: entry.key.toString(),
          text: entry.value.trim(),
        );
      }).toList();

      // Create poll message
      final pollMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tripId: widget.tripId,
        senderId: ref.read(currentUserProvider)?.id ?? '',
        type: MessageType.poll,
        text: pollQuestion,
        createdAt: DateTime.now(),
        poll: Poll(
          question: pollQuestion,
          options: pollOptionList,
          isActive: true,
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        ),
      );

      // Send poll message
      final tripActions = ref.read(tripActionsProvider.notifier);
      await tripActions.sendMessage(
        widget.tripId,
        pollQuestion,
        type: MessageType.poll,
      );
      
      // Clear form
      _pollQuestionController.clear();
      _pollOptions.clear();
      _pollOptions.addAll(['', '', '', '']);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Poll created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create poll: $e')),
        );
      }
    }
  }
}

class _MessageBubble extends ConsumerWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final isOwnMessage = currentUser?.id == message.senderId;

    Color bubbleColor;
    Color textColor;
    IconData? typeIcon;

    switch (message.type) {
      case MessageType.announcement:
        bubbleColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        typeIcon = Icons.campaign;
        break;
      case MessageType.system:
        bubbleColor = theme.colorScheme.surfaceVariant;
        textColor = theme.colorScheme.onSurfaceVariant;
        typeIcon = Icons.info_outline;
        break;
      case MessageType.poll:
        bubbleColor = AppColors.info.withOpacity(0.1);
        textColor = AppColors.info;
        typeIcon = Icons.poll;
        break;
      default:
        if (isOwnMessage) {
          bubbleColor = theme.colorScheme.primary;
          textColor = theme.colorScheme.onPrimary;
        } else {
          bubbleColor = theme.colorScheme.surfaceVariant;
          textColor = theme.colorScheme.onSurfaceVariant;
        }
    }

    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: AppSpacing.paddingVerticalXs,
        child: Column(
          crossAxisAlignment: isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender name for other messages
            if (!isOwnMessage && message.type == MessageType.chat) ...[
              Padding(
                padding: AppSpacing.paddingHorizontalSm.copyWith(bottom: 4),
                child: Text(
                  'User ${message.senderId.substring(0, 8)}', // Mock sender name
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            
            // Message bubble
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg).copyWith(
                  bottomLeft: Radius.circular(isOwnMessage ? AppSpacing.radiusLg : AppSpacing.radiusXs),
                  bottomRight: Radius.circular(isOwnMessage ? AppSpacing.radiusXs : AppSpacing.radiusLg),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type indicator for special messages
                  if (typeIcon != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          typeIcon,
                          size: AppSpacing.iconSm,
                          color: textColor,
                        ),
                        AppSpacing.horizontalSpaceXs,
                        Text(
                          message.type.name.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.verticalSpaceXs,
                  ],
                  
                  // Message text
                  Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                    ),
                  ),
                  
                  // Tags
                  if (message.tags.isNotEmpty) ...[
                    AppSpacing.verticalSpaceXs,
                    Wrap(
                      spacing: 4,
                      children: message.tags.map((tag) => Chip(
                        label: Text(
                          tag,
                          style: theme.textTheme.labelSmall,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
            
            // Timestamp
            Padding(
              padding: AppSpacing.paddingHorizontalSm.copyWith(top: 4),
              child: Text(
                _formatTime(message.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}