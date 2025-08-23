import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';

class ChatPoll {
  final String id;
  final String question;
  final List<String> options;
  final Map<String, int> votes; // option -> vote count
  final Map<String, String> userVotes; // userId -> selectedOption
  final DateTime createdAt;
  final DateTime? deadline;
  final String creatorId;
  final bool isActive;

  ChatPoll({
    required this.id,
    required this.question,
    required this.options,
    this.votes = const {},
    this.userVotes = const {},
    required this.createdAt,
    this.deadline,
    required this.creatorId,
    this.isActive = true,
  });

  ChatPoll copyWith({
    String? id,
    String? question,
    List<String>? options,
    Map<String, int>? votes,
    Map<String, String>? userVotes,
    DateTime? createdAt,
    DateTime? deadline,
    String? creatorId,
    bool? isActive,
  }) {
    return ChatPoll(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      votes: votes ?? this.votes,
      userVotes: userVotes ?? this.userVotes,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      creatorId: creatorId ?? this.creatorId,
      isActive: isActive ?? this.isActive,
    );
  }

  int get totalVotes => votes.values.fold(0, (sum, count) => sum + count);
  
  String? get winningOption {
    if (votes.isEmpty) return null;
    var maxVotes = votes.values.reduce((a, b) => a > b ? a : b);
    return votes.entries.firstWhere((entry) => entry.value == maxVotes).key;
  }

  bool get hasDeadlinePassed {
    return deadline != null && DateTime.now().isAfter(deadline!);
  }

  Duration? get timeRemaining {
    if (deadline == null) return null;
    final now = DateTime.now();
    if (now.isAfter(deadline!)) return null;
    return deadline!.difference(now);
  }
}

class PollWidget extends ConsumerStatefulWidget {
  final ChatPoll poll;
  final String currentUserId;
  final VoidCallback? onVote;
  final VoidCallback? onClose;

  const PollWidget({
    super.key,
    required this.poll,
    required this.currentUserId,
    this.onVote,
    this.onClose,
  });

  @override
  ConsumerState<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends ConsumerState<PollWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    
    // Check if user has already voted
    _selectedOption = widget.poll.userVotes[widget.currentUserId];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _vote(String option) {
    if (!widget.poll.isActive || widget.poll.hasDeadlinePassed) return;
    
    setState(() {
      _selectedOption = option;
    });
    
    // In a real app, this would update the poll via a provider
    widget.onVote?.call();
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voted for: $option'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTimeRemaining() {
    final timeRemaining = widget.poll.timeRemaining;
    if (timeRemaining == null) return '';
    
    if (timeRemaining.inMinutes > 0) {
      return '${timeRemaining.inMinutes}m ${timeRemaining.inSeconds % 60}s left';
    } else {
      return '${timeRemaining.inSeconds}s left';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final poll = widget.poll;
    final hasVoted = _selectedOption != null;
    final isExpired = poll.hasDeadlinePassed;
    final canVote = poll.isActive && !isExpired && !hasVoted;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        elevation: 8,
        margin: AppSpacing.paddingMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.poll,
                          size: 16,
                          color: theme.colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'POLL',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (poll.deadline != null && !isExpired) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatTimeRemaining(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  if (widget.onClose != null) ...[
                    AppSpacing.horizontalSpaceXs,
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                    ),
                  ],
                ],
              ),
              
              AppSpacing.verticalSpaceMd,
              
              // Question
              Text(
                poll.question,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              AppSpacing.verticalSpaceMd,
              
              // Options
              ...poll.options.map((option) {
                final voteCount = poll.votes[option] ?? 0;
                final percentage = poll.totalVotes > 0 
                    ? (voteCount / poll.totalVotes) * 100 
                    : 0.0;
                final isSelected = _selectedOption == option;
                final isWinning = hasVoted && option == poll.winningOption;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _PollOption(
                    option: option,
                    voteCount: voteCount,
                    percentage: percentage,
                    isSelected: isSelected,
                    isWinning: isWinning,
                    canVote: canVote,
                    hasVoted: hasVoted,
                    onTap: () => _vote(option),
                  ),
                );
              }),
              
              AppSpacing.verticalSpaceMd,
              
              // Footer
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  AppSpacing.horizontalSpaceXs,
                  Text(
                    '${poll.totalVotes} vote${poll.totalVotes == 1 ? '' : 's'}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (isExpired)
                    Text(
                      'Poll ended',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else if (hasVoted)
                    Text(
                      'You voted',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PollOption extends StatelessWidget {
  final String option;
  final int voteCount;
  final double percentage;
  final bool isSelected;
  final bool isWinning;
  final bool canVote;
  final bool hasVoted;
  final VoidCallback onTap;

  const _PollOption({
    required this.option,
    required this.voteCount,
    required this.percentage,
    required this.isSelected,
    required this.isWinning,
    required this.canVote,
    required this.hasVoted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color getBackgroundColor() {
      if (isSelected) return theme.colorScheme.primary.withOpacity(0.2);
      if (isWinning) return theme.colorScheme.tertiary.withOpacity(0.1);
      return theme.colorScheme.surfaceContainerHighest;
    }
    
    Color getBorderColor() {
      if (isSelected) return theme.colorScheme.primary;
      if (isWinning) return theme.colorScheme.tertiary;
      return theme.colorScheme.outline.withOpacity(0.3);
    }

    return GestureDetector(
      onTap: canVote ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: getBackgroundColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: getBorderColor(), width: 1.5),
        ),
        child: Stack(
          children: [
            // Progress bar background for voted options
            if (hasVoted)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: percentage / 100 * 
                         (MediaQuery.of(context).size.width - 96), // Approximate width
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            
            // Content
            Row(
              children: [
                if (canVote)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                      color: isSelected 
                          ? theme.colorScheme.primary 
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 12,
                            color: theme.colorScheme.onPrimary,
                          )
                        : null,
                  )
                else if (isWinning)
                  Icon(
                    Icons.emoji_events,
                    size: 20,
                    color: theme.colorScheme.tertiary,
                  )
                else
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surfaceContainerHigh,
                    ),
                  ),
                
                AppSpacing.horizontalSpaceSm,
                
                Expanded(
                  child: Text(
                    option,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected || isWinning 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                ),
                
                if (hasVoted) ...[
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.horizontalSpaceXs,
                  Text(
                    '($voteCount)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Quick poll creation dialog
class QuickPollDialog extends StatefulWidget {
  final Function(String question, List<String> options, int? deadlineMinutes) onCreate;

  const QuickPollDialog({super.key, required this.onCreate});

  @override
  State<QuickPollDialog> createState() => _QuickPollDialogState();
}

class _QuickPollDialogState extends State<QuickPollDialog> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  int _deadlineMinutes = 1;

  @override
  void dispose() {
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 5) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  void _createPoll() {
    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question')),
      );
      return;
    }

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 2 options')),
      );
      return;
    }

    widget.onCreate(question, options, _deadlineMinutes);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.poll, color: theme.colorScheme.primary),
          AppSpacing.horizontalSpaceSm,
          const Text('Create Quick Poll'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Question',
                hintText: 'What time should we have dinner?',
              ),
              maxLines: 2,
            ),
            
            AppSpacing.verticalSpaceMd,
            
            Text(
              'Options',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            AppSpacing.verticalSpaceSm,
            
            ..._optionControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Option ${index + 1}',
                          hintText: index == 0 ? '19:00' : index == 1 ? '19:30' : 'Add option...',
                        ),
                      ),
                    ),
                    if (_optionControllers.length > 2)
                      IconButton(
                        onPressed: () => _removeOption(index),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                  ],
                ),
              );
            }),
            
            if (_optionControllers.length < 5)
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add),
                label: const Text('Add Option'),
              ),
            
            AppSpacing.verticalSpaceMd,
            
            Row(
              children: [
                Text(
                  'Deadline:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.horizontalSpaceSm,
                DropdownButton<int>(
                  value: _deadlineMinutes,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 minute')),
                    DropdownMenuItem(value: 2, child: Text('2 minutes')),
                    DropdownMenuItem(value: 5, child: Text('5 minutes')),
                    DropdownMenuItem(value: 10, child: Text('10 minutes')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _deadlineMinutes = value);
                    }
                  },
                ),
              ],
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
          onPressed: _createPoll,
          child: const Text('Create Poll'),
        ),
      ],
    );
  }
}
