import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/data/models/models.dart';
import '../../../core/data/providers/entertainment_provider.dart';
import '../../../core/data/providers/auth_provider.dart';
import '../../../core/data/providers/trip_provider.dart';
import '../../../core/theme/app_theme.dart';

class TripEntertainmentScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripEntertainmentScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<TripEntertainmentScreen> createState() => _TripEntertainmentScreenState();
}

class _TripEntertainmentScreenState extends ConsumerState<TripEntertainmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activitiesAsync = ref.watch(entertainmentActivitiesProvider(widget.tripId));
    final categories = ref.watch(entertainmentCategoriesProvider);
    final currentUser = ref.watch(authProvider).maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entertainment & Games'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddActivityDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showEntertainmentReport(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Activities'),
            Tab(text: 'Categories'),
            Tab(text: 'Games'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActivitiesTab(activitiesAsync, currentUser),
          _buildCategoriesTab(categories),
          _buildGamesTab(),
        ],
      ),
    );
  }

  Widget _buildActivitiesTab(AsyncValue<List<EntertainmentActivity>> activitiesAsync, User? currentUser) {
    return activitiesAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return _buildEmptyState();
        }

        final upcomingActivities = activities
            .where((activity) => activity.status == ActivityStatus.planned)
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

        final activeActivities = activities
            .where((activity) => activity.status == ActivityStatus.active)
            .toList();

        final completedActivities = activities
            .where((activity) => activity.status == ActivityStatus.completed)
            .toList()
          ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(entertainmentActivitiesProvider(widget.tripId));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (activeActivities.isNotEmpty) ...[
                _buildSectionHeader('Active Now', Icons.play_circle, Colors.green),
                ...activeActivities.map((activity) => _buildActivityCard(activity, currentUser)),
                const SizedBox(height: 24),
              ],
              if (upcomingActivities.isNotEmpty) ...[
                _buildSectionHeader('Upcoming', Icons.schedule, Colors.blue),
                ...upcomingActivities.map((activity) => _buildActivityCard(activity, currentUser)),
                const SizedBox(height: 24),
              ],
              if (completedActivities.isNotEmpty) ...[
                _buildSectionHeader('Completed', Icons.check_circle, Colors.grey),
                ...completedActivities.map((activity) => _buildActivityCard(activity, currentUser)),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Error loading activities', style: TextStyle(color: Colors.red[300])),
            const SizedBox(height: 8),
            Text(error.toString(), style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesTab(List<EntertainmentCategory> categories) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1, // Reduced from 1.2 to 1.1 to give more height
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildGamesTab() {
    final gamesAsync = ref.watch(gameSessionsProvider(widget.tripId));
    
    return gamesAsync.when(
      data: (games) {
        if (games.isEmpty) {
          return _buildEmptyGamesState();
        }

        final activeGames = games.where((game) => game.status == GameStatus.active).toList();
        final completedGames = games.where((game) => game.status == GameStatus.completed).toList();

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(gameSessionsProvider(widget.tripId));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (activeGames.isNotEmpty) ...[
                _buildSectionHeader('Active Games', Icons.sports_esports, Colors.green),
                ...activeGames.map((game) => _buildGameCard(game)),
                const SizedBox(height: 24),
              ],
              if (completedGames.isNotEmpty) ...[
                _buildSectionHeader('Completed Games', Icons.emoji_events, Colors.orange),
                ...completedGames.map((game) => _buildGameCard(game)),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Error loading games', style: TextStyle(color: Colors.red[300])),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.games, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No activities planned yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first entertainment activity to get started!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddActivityDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Activity'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGamesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_esports, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No games played yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a game session from an activity to begin playing!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(EntertainmentActivity activity, User? currentUser) {
    final theme = Theme.of(context);
    final isParticipant = currentUser != null && activity.participantIds.contains(currentUser.id);
    final isOrganizer = currentUser != null && activity.organizerId == currentUser.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showActivityDetails(activity),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getActivityTypeColor(activity.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getActivityTypeIcon(activity.type),
                      color: _getActivityTypeColor(activity.type),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          activity.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(activity.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    timeago.format(activity.scheduledAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${activity.participantIds.length} participants',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (activity.durationMinutes > 0) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${activity.durationMinutes} min',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              if (activity.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      activity.location!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (isOrganizer)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Organizer',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (isParticipant && !isOrganizer)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Joined',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (currentUser != null && !isParticipant && activity.status == ActivityStatus.planned)
                    TextButton(
                      onPressed: () => _joinActivity(activity.id, currentUser.id),
                      child: const Text('Join'),
                    ),
                  if (isParticipant && activity.status == ActivityStatus.planned)
                    TextButton(
                      onPressed: () => _leaveActivity(activity.id, currentUser!.id),
                      child: const Text('Leave'),
                    ),
                  if (isOrganizer && activity.status == ActivityStatus.planned)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showEditActivityDialog(activity);
                            break;
                          case 'delete':
                            _deleteActivity(activity.id);
                            break;
                          case 'start':
                            _startActivity(activity.id);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'start',
                          child: Row(
                            children: [
                              Icon(Icons.play_arrow, size: 16),
                              SizedBox(width: 8),
                              Text('Start'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(EntertainmentCategory category) {
    final theme = Theme.of(context);
    final color = Color(int.parse(category.color.replaceAll('#', '0xFF')));

    return Card(
      child: InkWell(
        onTap: () => _showCategoryDetails(category),
        child: Padding(
          padding: const EdgeInsets.all(10), // Reduced from 12 to 10
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                category.icon,
                style: const TextStyle(fontSize: 28), // Reduced from 32 to 28
              ),
              const SizedBox(height: 6), // Reduced from 8 to 6
              Text(
                category.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14, // Smaller font size
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3), // Reduced from 4 to 3
              Expanded(
                child: Text(
                  category.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11, // Smaller font size
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6), // Reduced from 8 to 6
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Reduced padding
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8), // Reduced from 12 to 8
                ),
                child: Text(
                  '${category.minParticipants}-${category.maxParticipants} people',
                  style: TextStyle(
                    fontSize: 9, // Reduced from 10 to 9
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(GameSession game) {
    final theme = Theme.of(context);
    final isActive = game.status == GameStatus.active;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showGameDetails(game),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isActive ? Icons.sports_esports : Icons.emoji_events,
                    color: isActive ? Colors.green : Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.gameType,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${game.playerIds.length} players',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildGameStatusChip(game.status),
                ],
              ),
              if (game.scores.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Scores:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: game.scores.entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (game.winnerId != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      'Winner: ${game.winnerId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ActivityStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case ActivityStatus.planned:
        color = Colors.blue;
        text = 'Planned';
        icon = Icons.schedule;
        break;
      case ActivityStatus.active:
        color = Colors.green;
        text = 'Active';
        icon = Icons.play_circle;
        break;
      case ActivityStatus.completed:
        color = Colors.grey;
        text = 'Completed';
        icon = Icons.check_circle;
        break;
      case ActivityStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        icon = Icons.cancel;
        break;
      case ActivityStatus.postponed:
        color = Colors.orange;
        text = 'Postponed';
        icon = Icons.pause_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameStatusChip(GameStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case GameStatus.waiting:
        color = Colors.orange;
        text = 'Waiting';
        icon = Icons.hourglass_empty;
        break;
      case GameStatus.active:
        color = Colors.green;
        text = 'Active';
        icon = Icons.play_circle;
        break;
      case GameStatus.completed:
        color = Colors.grey;
        text = 'Completed';
        icon = Icons.check_circle;
        break;
      case GameStatus.paused:
        color = Colors.blue;
        text = 'Paused';
        icon = Icons.pause_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityTypeColor(ActivityType type) {
    switch (type) {
      case ActivityType.game:
        return Colors.purple;
      case ActivityType.quiz:
        return Colors.blue;
      case ActivityType.challenge:
        return Colors.orange;
      case ActivityType.workshop:
        return Colors.green;
      case ActivityType.performance:
        return Colors.pink;
      case ActivityType.outdoor:
        return Colors.teal;
      case ActivityType.indoor:
        return Colors.indigo;
      case ActivityType.teamBuilding:
        return Colors.cyan;
      case ActivityType.cultural:
        return Colors.brown;
      case ActivityType.adventure:
        return Colors.red;
    }
  }

  IconData _getActivityTypeIcon(ActivityType type) {
    switch (type) {
      case ActivityType.game:
        return Icons.sports_esports;
      case ActivityType.quiz:
        return Icons.quiz;
      case ActivityType.challenge:
        return Icons.fitness_center;
      case ActivityType.workshop:
        return Icons.work;
      case ActivityType.performance:
        return Icons.music_note;
      case ActivityType.outdoor:
        return Icons.outdoor_grill;
      case ActivityType.indoor:
        return Icons.home;
      case ActivityType.teamBuilding:
        return Icons.group;
      case ActivityType.cultural:
        return Icons.museum;
      case ActivityType.adventure:
        return Icons.explore;
    }
  }

  String _getActivityTypeName(ActivityType type) {
    switch (type) {
      case ActivityType.game:
        return 'Game';
      case ActivityType.quiz:
        return 'Quiz';
      case ActivityType.challenge:
        return 'Challenge';
      case ActivityType.workshop:
        return 'Workshop';
      case ActivityType.performance:
        return 'Performance';
      case ActivityType.outdoor:
        return 'Outdoor';
      case ActivityType.indoor:
        return 'Indoor';
      case ActivityType.teamBuilding:
        return 'Team Building';
      case ActivityType.cultural:
        return 'Cultural';
      case ActivityType.adventure:
        return 'Adventure';
    }
  }

  void _showAddActivityDialog(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.read(entertainmentCategoriesProvider);
    final currentUser = ref.read(authProvider).maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to create activities')),
      );
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    final durationController = TextEditingController(text: '60');
    final maxParticipantsController = TextEditingController(text: '10');
    final costController = TextEditingController();
    
    ActivityType selectedType = ActivityType.game;
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay selectedTime = TimeOfDay.now().replacing(minute: (TimeOfDay.now().minute ~/ 15) * 15);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Activity'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Activity Title',
                    hintText: 'e.g., Beach Volleyball Tournament',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe the activity...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ActivityType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Activity Type',
                  ),
                  items: ActivityType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(_getActivityTypeIcon(type), size: 20),
                          const SizedBox(width: 8),
                          Text(_getActivityTypeName(type)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          hintText: 'e.g., Beach, Hotel Lobby',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration (minutes)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: maxParticipantsController,
                        decoration: const InputDecoration(
                          labelText: 'Max Participants',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: costController,
                        decoration: const InputDecoration(
                          labelText: 'Cost (optional)',
                          prefixText: '\$',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Date & Time'),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year} at ${selectedTime.format(context)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        setState(() {
                          selectedDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                          selectedTime = time;
                        });
                      }
                    }
                  },
                ),
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
                if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all required fields')),
                  );
                  return;
                }

                final duration = int.tryParse(durationController.text) ?? 60;
                final maxParticipants = int.tryParse(maxParticipantsController.text) ?? 10;
                final cost = double.tryParse(costController.text);

                ref.read(entertainmentActionsProvider.notifier).createActivity(
                  tripId: widget.tripId,
                  title: titleController.text,
                  description: descriptionController.text,
                  type: selectedType,
                  scheduledAt: selectedDate,
                  durationMinutes: duration,
                  participantIds: [currentUser.id],
                  organizerId: currentUser.id,
                  location: locationController.text.isEmpty ? null : locationController.text,
                  maxParticipants: maxParticipants,
                  cost: cost,
                  tags: [selectedType.name.toLowerCase()],
                );

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Activity created successfully!')),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditActivityDialog(EntertainmentActivity activity) {
    final theme = Theme.of(context);
    final currentUser = ref.read(authProvider).maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );

    if (currentUser == null || activity.organizerId != currentUser.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only the organizer can edit this activity')),
      );
      return;
    }

    final titleController = TextEditingController(text: activity.title);
    final descriptionController = TextEditingController(text: activity.description);
    final locationController = TextEditingController(text: activity.location ?? '');
    final durationController = TextEditingController(text: activity.durationMinutes.toString());
    final maxParticipantsController = TextEditingController(text: activity.maxParticipants?.toString() ?? '10');
    final costController = TextEditingController(text: activity.cost?.toString() ?? '');
    
    ActivityType selectedType = activity.type;
    DateTime selectedDate = activity.scheduledAt;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(activity.scheduledAt);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Activity'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Activity Title',
                    hintText: 'e.g., Beach Volleyball Tournament',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe the activity...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ActivityType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Activity Type',
                  ),
                  items: ActivityType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(_getActivityTypeIcon(type), size: 20),
                          const SizedBox(width: 8),
                          Text(_getActivityTypeName(type)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          hintText: 'e.g., Beach, Hotel Lobby',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration (minutes)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: maxParticipantsController,
                        decoration: const InputDecoration(
                          labelText: 'Max Participants',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: costController,
                        decoration: const InputDecoration(
                          labelText: 'Cost (optional)',
                          prefixText: '\$',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Date & Time'),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year} at ${selectedTime.format(context)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        setState(() {
                          selectedDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                          selectedTime = time;
                        });
                      }
                    }
                  },
                ),
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
                if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all required fields')),
                  );
                  return;
                }

                final duration = int.tryParse(durationController.text) ?? 60;
                final maxParticipants = int.tryParse(maxParticipantsController.text) ?? 10;
                final cost = double.tryParse(costController.text);

                ref.read(entertainmentActionsProvider.notifier).updateActivity(
                  activityId: activity.id,
                  title: titleController.text,
                  description: descriptionController.text,
                  type: selectedType,
                  scheduledAt: selectedDate,
                  durationMinutes: duration,
                  participantIds: activity.participantIds,
                  location: locationController.text.isEmpty ? null : locationController.text,
                  maxParticipants: maxParticipants,
                  cost: cost,
                  tags: [selectedType.name.toLowerCase()],
                );

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Activity updated successfully!')),
                );
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showActivityDetails(EntertainmentActivity activity) {
    final theme = Theme.of(context);
    final currentUser = ref.read(authProvider).maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getActivityTypeIcon(activity.type),
              color: _getActivityTypeColor(activity.type),
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                activity.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                activity.description,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.schedule, 'Date & Time', 
                '${activity.scheduledAt.day}/${activity.scheduledAt.month}/${activity.scheduledAt.year} at ${TimeOfDay.fromDateTime(activity.scheduledAt).format(context)}'),
              if (activity.location != null)
                _buildDetailRow(Icons.location_on, 'Location', activity.location!),
              _buildDetailRow(Icons.timer, 'Duration', '${activity.durationMinutes} minutes'),
              _buildDetailRow(Icons.people, 'Participants', '${activity.participantIds.length}${activity.maxParticipants != null ? '/${activity.maxParticipants}' : ''}'),
              if (activity.cost != null)
                _buildDetailRow(Icons.attach_money, 'Cost', '\$${activity.cost!.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getActivityTypeColor(activity.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getActivityTypeName(activity.type),
                  style: TextStyle(
                    color: _getActivityTypeColor(activity.type),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (activity.tags != null && activity.tags!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Tags:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: activity.tags!.map((tag) => Chip(
                    label: Text(tag),
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    labelStyle: theme.textTheme.bodySmall,
                  )).toList(),
                ),
              ],
              if (activity.notes != null && activity.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Notes:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.notes!,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (currentUser != null && !activity.participantIds.contains(currentUser.id) && activity.status == ActivityStatus.planned)
            FilledButton(
              onPressed: () {
                _joinActivity(activity.id, currentUser.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Joined activity successfully!')),
                );
              },
              child: const Text('Join'),
            ),
          if (currentUser != null && activity.participantIds.contains(currentUser.id) && activity.status == ActivityStatus.planned)
            OutlinedButton(
              onPressed: () {
                _leaveActivity(activity.id, currentUser.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Left activity successfully!')),
                );
              },
              child: const Text('Leave'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryDetails(EntertainmentCategory category) {
    final theme = Theme.of(context);
    final color = Color(int.parse(category.color.replaceAll('#', '0xFF')));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(
              category.icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                category.description,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.people, 'Participants', '${category.minParticipants}-${category.maxParticipants} people'),
              _buildDetailRow(Icons.timer, 'Duration', '${category.estimatedDuration} minutes'),
              _buildDetailRow(Icons.build, 'Equipment', category.requiresEquipment ? 'Required' : 'Not required'),
              if (category.equipment != null && category.equipment!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Equipment needed:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: category.equipment!.map((item) => Chip(
                    label: Text(item),
                    backgroundColor: color.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: color,
                      fontSize: 12,
                    ),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Instructions:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                category.instructions ?? 'No specific instructions available.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Tags:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: category.tags.map((tag) => Chip(
                  label: Text(tag),
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  labelStyle: theme.textTheme.bodySmall,
                )).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showAddActivityDialog(context);
            },
            child: const Text('Create Activity'),
          ),
        ],
      ),
    );
  }

  void _showGameDetails(GameSession game) {
    final theme = Theme.of(context);
    final isActive = game.status == GameStatus.active;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isActive ? Icons.sports_esports : Icons.emoji_events,
              color: isActive ? Colors.green : Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                game.gameType.replaceAll('_', ' ').toUpperCase(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(Icons.people, 'Players', '${game.playerIds.length} players'),
              _buildDetailRow(Icons.schedule, 'Started', timeago.format(game.startedAt)),
              if (game.endedAt != null)
                _buildDetailRow(Icons.check_circle, 'Ended', timeago.format(game.endedAt!)),
              _buildDetailRow(Icons.emoji_events, 'Status', _getGameStatusText(game.status)),
              if (game.winnerId != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Winner: ${game.winnerId}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (game.scores.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Scores:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...game.scores.entries.map((entry) {
                  final isWinner = game.winnerId == entry.key;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isWinner ? Colors.amber.withOpacity(0.1) : theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: isWinner ? Border.all(color: Colors.amber.withOpacity(0.3)) : null,
                    ),
                    child: Row(
                      children: [
                        if (isWinner) ...[
                          Icon(Icons.star, color: Colors.amber[700], size: 16),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
                              color: isWinner ? Colors.amber[700] : null,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value} pts',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isWinner ? Colors.amber[700] : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
              if (game.gameData.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Game Data:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    game.gameData.toString(),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (isActive)
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showUpdateScoreDialog(game);
              },
              child: const Text('Update Score'),
            ),
        ],
      ),
    );
  }

  String _getGameStatusText(GameStatus status) {
    switch (status) {
      case GameStatus.waiting:
        return 'Waiting to start';
      case GameStatus.active:
        return 'In progress';
      case GameStatus.completed:
        return 'Completed';
      case GameStatus.paused:
        return 'Paused';
    }
  }

  void _showUpdateScoreDialog(GameSession game) {
    final theme = Theme.of(context);
    final currentUser = ref.read(authProvider).maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );

    if (currentUser == null || !game.playerIds.contains(currentUser.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not a player in this game')),
      );
      return;
    }

    final scoreController = TextEditingController(
      text: game.scores[currentUser.id]?.toString() ?? '0',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Your Score'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current score: ${game.scores[currentUser.id] ?? 0}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: scoreController,
              decoration: const InputDecoration(
                labelText: 'New Score',
                hintText: 'Enter your new score',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newScore = int.tryParse(scoreController.text);
              if (newScore != null) {
                ref.read(entertainmentActionsProvider.notifier).updateGameScore(
                  sessionId: game.id,
                  playerId: currentUser.id,
                  score: newScore,
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Score updated successfully!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid score')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showEntertainmentReport(BuildContext context) {
    print('Entertainment Report: Opening dialog for trip ${widget.tripId}');
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
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
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Entertainment Report',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final reportAsync = ref.watch(entertainmentReportProvider(widget.tripId));
                    
                    return reportAsync.when(
                      data: (report) {
                        print('Entertainment Report: Received data - report: ${report?.totalActivities} activities');
                        if (report == null || report.totalActivities == 0) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.games, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No entertainment data available',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Create some activities to see analytics',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildReportCard(
                                'Overview',
                                [
                                  _buildReportRow('Total Activities', '${report.totalActivities}'),
                                  _buildReportRow('Completed Activities', '${report.completedActivities}'),
                                  _buildReportRow('Total Participants', '${report.totalParticipants}'),
                                  _buildReportRow('Avg Participation', '${report.averageParticipation.toStringAsFixed(1)}'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (report.popularTypes.isNotEmpty)
                                _buildReportCard(
                                  'Popular Activity Types',
                                  report.popularTypes.map((type) => 
                                    _buildReportRow(_getActivityTypeName(type), '${report.categoryStats[type.name] ?? 0} activities')
                                  ).toList(),
                                ),
                              const SizedBox(height: 16),
                              if (report.topParticipants.isNotEmpty)
                                _buildReportCard(
                                  'Top Participants',
                                  report.topParticipants.map((userId) => 
                                    _buildReportRow('User $userId', 'Most active')
                                  ).toList(),
                                ),
                              const SizedBox(height: 16),
                              if (report.recentGames.isNotEmpty)
                                _buildReportCard(
                                  'Recent Games',
                                  report.recentGames.map((game) => 
                                    _buildReportRow(
                                      game.gameType.replaceAll('_', ' ').toUpperCase(),
                                      '${game.playerIds.length} players • ${game.status.name}'
                                    )
                                  ).toList(),
                                ),
                              const SizedBox(height: 16),
                              _buildReportCard(
                                'Category Breakdown',
                                report.categoryStats.entries.map((entry) => 
                                  _buildReportRow(entry.key, '${entry.value} activities')
                                ).toList(),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () {
                        print('Entertainment Report: Loading state');
                        return const Center(child: CircularProgressIndicator());
                      },
                      error: (error, stack) {
                        print('Entertainment Report: Error state - $error');
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, size: 64, color: Colors.red[300]),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading report',
                                style: TextStyle(color: Colors.red[300]),
                              ),
                              const SizedBox(height: 8),
                              Text(error.toString(), style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _joinActivity(String activityId, String userId) {
    ref.read(entertainmentActionsProvider.notifier).joinActivity(activityId, userId);
  }

  void _leaveActivity(String activityId, String userId) {
    ref.read(entertainmentActionsProvider.notifier).leaveActivity(activityId, userId);
  }

  void _deleteActivity(String activityId) {
    ref.read(entertainmentActionsProvider.notifier).deleteActivity(activityId);
  }

  void _startActivity(String activityId) {
    final currentUser = ref.read(authProvider).maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to start activities')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Game Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('What type of game would you like to start?'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Game Type',
              ),
              items: [
                'trivia',
                'scavenger_hunt',
                'photo_challenge',
                'word_game',
                'charades',
                'storytelling',
              ].map((type) => DropdownMenuItem(
                value: type,
                child: Text(type.replaceAll('_', ' ').toUpperCase()),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  Navigator.of(context).pop();
                  _startGameSession(activityId, value, currentUser.id);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _startGameSession(String activityId, String gameType, String organizerId) {
    // Get participants from the activity
    final activitiesAsync = ref.read(entertainmentActivitiesProvider(widget.tripId));
    activitiesAsync.when(
      data: (activities) {
        final activity = activities.firstWhere((a) => a.id == activityId);
        final playerIds = activity.participantIds;
        
        ref.read(entertainmentActionsProvider.notifier).startGameSession(
          activityId: activityId,
          gameType: gameType,
          playerIds: playerIds,
          gameData: {
            'organizer': organizerId,
            'started_at': DateTime.now().toIso8601String(),
            'game_type': gameType,
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${gameType.replaceAll('_', ' ').toUpperCase()} game started!')),
        );
      },
      loading: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading activity data...')),
      ),
      error: (error, stack) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      ),
    );
  }
}
