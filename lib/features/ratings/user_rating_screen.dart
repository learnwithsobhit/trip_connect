import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/models/models.dart';
import '../../core/data/providers/rating_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../common/widgets/star_rating.dart';

class UserRatingScreen extends ConsumerStatefulWidget {
  final String ratedUserId;
  final String tripId;
  final String userName;
  final String? userAvatar;

  const UserRatingScreen({
    super.key,
    required this.ratedUserId,
    required this.tripId,
    required this.userName,
    this.userAvatar,
  });

  @override
  ConsumerState<UserRatingScreen> createState() => _UserRatingScreenState();
}

class _UserRatingScreenState extends ConsumerState<UserRatingScreen> {
  final _feedbackController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(userRatingFormProvider(widget.tripId));
    final formNotifier = ref.read(userRatingFormProvider(widget.tripId).notifier);

    // Watch existing rating
    final existingRatingAsync = ref.watch(userRatingByCurrentUserProvider(
      UserRatingQuery(ratedUserId: widget.ratedUserId, tripId: widget.tripId),
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text('Rate ${widget.userName}'),
        actions: [
          TextButton(
            onPressed: formState.isSubmitting ? null : () => _submitRating(),
            child: formState.isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
        ],
      ),
      body: existingRatingAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading rating data...'),
            ],
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Error loading rating: $error'),
              SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.refresh(userRatingByCurrentUserProvider(
                  UserRatingQuery(ratedUserId: widget.ratedUserId, tripId: widget.tripId),
                )),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (existingRating) {
          // Initialize form with existing rating if available
          if (existingRating != null && formState.rating == 5.0 && formState.feedback.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              formNotifier.updateRating(existingRating.rating);
              formNotifier.updateFeedback(existingRating.feedback ?? '');
              _feedbackController.text = existingRating.feedback ?? '';
              for (final tag in existingRating.tags) {
                final ratingTag = UserRatingTag.values.firstWhere(
                  (t) => t.name == tag,
                  orElse: () => UserRatingTag.friendly,
                );
                formNotifier.toggleTag(ratingTag);
              }
            });
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: AppSpacing.paddingLg,
              children: [
                // User info card
                _buildUserInfoCard(theme),
                
                AppSpacing.verticalSpaceLg,
                
                // Rating section
                _buildRatingSection(theme, formState, formNotifier),
                
                AppSpacing.verticalSpaceLg,
                
                // Tags section
                _buildTagsSection(theme, formState, formNotifier),
                
                AppSpacing.verticalSpaceLg,
                
                // Feedback section
                _buildFeedbackSection(theme, formState, formNotifier),
                
                AppSpacing.verticalSpaceLg,
                
                // Error message
                if (formState.error != null)
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      formState.error!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                
                AppSpacing.verticalSpaceXl,
                
                // Submit button
                FilledButton(
                  onPressed: formState.isSubmitting ? null : () => _submitRating(),
                  child: formState.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(existingRating != null ? 'Update Rating' : 'Submit Rating'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: widget.userAvatar != null
                  ? NetworkImage(widget.userAvatar!)
                  : null,
              child: widget.userAvatar == null
                  ? Text(
                      widget.userName.substring(0, 1).toUpperCase(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : null,
            ),
            AppSpacing.horizontalSpaceMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.verticalSpaceXs,
                  Text(
                    'How was your travel experience with ${widget.userName}?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(ThemeData theme, UserRatingFormState formState, UserRatingFormNotifier formNotifier) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Rating',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalSpaceMd,
            Center(
              child: StarRating(
                rating: formState.rating,
                size: 40,
                allowSelection: true,
                onRatingChanged: (rating) => formNotifier.updateRating(rating),
              ),
            ),
            AppSpacing.verticalSpaceSm,
            Center(
              child: Text(
                _getRatingDescription(formState.rating),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: _getRatingColor(formState.rating, theme),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection(ThemeData theme, UserRatingFormState formState, UserRatingFormNotifier formNotifier) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What made them a great travel companion?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalSpaceSm,
            Text(
              'Select all that apply',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            AppSpacing.verticalSpaceMd,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: UserRatingTag.values.map((tag) {
                final isSelected = formState.selectedTags.contains(tag);
                return FilterChip(
                  label: Text(
                    tag.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                        ? theme.colorScheme.onPrimaryContainer 
                        : theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => formNotifier.toggleTag(tag),
                  selectedColor: theme.colorScheme.primaryContainer,
                  backgroundColor: theme.colorScheme.surface,
                  side: BorderSide(
                    color: isSelected 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.outline.withOpacity(0.5),
                    width: isSelected ? 2 : 1,
                  ),
                  checkmarkColor: theme.colorScheme.onPrimaryContainer,
                  elevation: isSelected ? 2 : 0,
                  shadowColor: theme.colorScheme.primary.withOpacity(0.2),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection(ThemeData theme, UserRatingFormState formState, UserRatingFormNotifier formNotifier) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Feedback (Optional)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalSpaceMd,
            TextFormField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                hintText: 'Share your experience traveling with this person...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              maxLength: 500,
              onChanged: (value) => formNotifier.updateFeedback(value),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingDescription(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 3.5) return 'Good';
    if (rating >= 2.5) return 'Average';
    if (rating >= 1.5) return 'Poor';
    return 'Terrible';
  }

  Color _getRatingColor(double rating, ThemeData theme) {
    if (rating >= 4.0) return Colors.green;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }

  Future<void> _submitRating() async {
    if (!_formKey.currentState!.validate()) return;

    final formState = ref.read(userRatingFormProvider(widget.tripId));
    final formNotifier = ref.read(userRatingFormProvider(widget.tripId).notifier);

    formNotifier.setSubmitting(true);
    formNotifier.setError(null);

    try {
      final request = UserRatingRequest(
        ratedUserId: widget.ratedUserId,
        tripId: widget.tripId,
        rating: formState.rating,
        feedback: formState.feedback.isNotEmpty ? formState.feedback : null,
        tags: formState.selectedTags.map((tag) => tag.name).toList(),
      );

      final result = await ref.read(submitUserRatingProvider(request).future);

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Rating submitted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } else {
        formNotifier.setError(result['error'] ?? 'Failed to submit rating');
      }
    } catch (e) {
      formNotifier.setError('An unexpected error occurred: $e');
    } finally {
      formNotifier.setSubmitting(false);
    }
  }
}
