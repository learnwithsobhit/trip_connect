import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/models/models.dart';
import '../../core/data/providers/rating_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../common/widgets/star_rating.dart';

class TripRatingScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String tripName;
  final String? tripImage;

  const TripRatingScreen({
    super.key,
    required this.tripId,
    required this.tripName,
    this.tripImage,
  });

  @override
  ConsumerState<TripRatingScreen> createState() => _TripRatingScreenState();
}

class _TripRatingScreenState extends ConsumerState<TripRatingScreen> {
  final _feedbackController = TextEditingController();
  final _improvementsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _feedbackController.dispose();
    _improvementsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(tripRatingFormProvider(widget.tripId));
    final formNotifier = ref.read(tripRatingFormProvider(widget.tripId).notifier);

    // Watch existing rating
    final existingRatingAsync = ref.watch(tripRatingByCurrentUserProvider(widget.tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Trip'),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (existingRating) {
          // Initialize form with existing rating if available
          if (existingRating != null && formState.overallRating == 5.0 && formState.feedback.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              formNotifier.updateOverallRating(existingRating.overallRating);
              formNotifier.updateOrganizationRating(existingRating.organizationRating);
              formNotifier.updateValueRating(existingRating.valueRating);
              formNotifier.updateExperienceRating(existingRating.experienceRating);
              formNotifier.updateFeedback(existingRating.feedback ?? '');
              formNotifier.updateWouldRecommend(existingRating.wouldRecommend);
              _feedbackController.text = existingRating.feedback ?? '';
              
              for (final highlight in existingRating.highlights) {
                final tripHighlight = TripHighlight.values.firstWhere(
                  (h) => h.name == highlight,
                  orElse: () => TripHighlight.amazingExperience,
                );
                formNotifier.toggleHighlight(tripHighlight);
              }
            });
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: AppSpacing.paddingLg,
              children: [
                // Trip info card
                _buildTripInfoCard(theme),
                
                AppSpacing.verticalSpaceLg,
                
                // Overall rating section
                _buildOverallRatingSection(theme, formState, formNotifier),
                
                AppSpacing.verticalSpaceLg,
                
                // Detailed ratings section
                _buildDetailedRatingsSection(theme, formState, formNotifier),
                
                AppSpacing.verticalSpaceLg,
                
                // Highlights section
                _buildHighlightsSection(theme, formState, formNotifier),
                
                AppSpacing.verticalSpaceLg,
                
                // Feedback section
                _buildFeedbackSection(theme, formState, formNotifier),
                
                AppSpacing.verticalSpaceLg,
                
                // Recommendation section
                _buildRecommendationSection(theme, formState, formNotifier),
                
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

  Widget _buildTripInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 60,
                color: theme.colorScheme.primaryContainer,
                child: widget.tripImage != null
                    ? Image.network(widget.tripImage!, fit: BoxFit.cover)
                    : Icon(
                        Icons.landscape,
                        size: 30,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
              ),
            ),
            AppSpacing.horizontalSpaceMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.tripName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.verticalSpaceXs,
                  Text(
                    'How was your overall trip experience?',
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

  Widget _buildOverallRatingSection(ThemeData theme, TripRatingFormState formState, TripRatingFormNotifier formNotifier) {
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
                rating: formState.overallRating,
                size: 40,
                allowSelection: true,
                onRatingChanged: (rating) => formNotifier.updateOverallRating(rating),
              ),
            ),
            AppSpacing.verticalSpaceSm,
            Center(
              child: Text(
                _getRatingDescription(formState.overallRating),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: _getRatingColor(formState.overallRating, theme),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedRatingsSection(ThemeData theme, TripRatingFormState formState, TripRatingFormNotifier formNotifier) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Ratings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalSpaceMd,
            
            // Organization Rating
            _buildDetailedRatingItem(
              'Organization & Planning',
              'How well was the trip organized?',
              formState.organizationRating,
              formNotifier.updateOrganizationRating,
              theme,
            ),
            
            AppSpacing.verticalSpaceMd,
            
            // Value Rating
            _buildDetailedRatingItem(
              'Value for Money',
              'Was the trip worth the cost?',
              formState.valueRating,
              formNotifier.updateValueRating,
              theme,
            ),
            
            AppSpacing.verticalSpaceMd,
            
            // Experience Rating
            _buildDetailedRatingItem(
              'Overall Experience',
              'How enjoyable was the trip?',
              formState.experienceRating,
              formNotifier.updateExperienceRating,
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedRatingItem(
    String title,
    String subtitle,
    double rating,
    Function(double) onChanged,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        AppSpacing.verticalSpaceXs,
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        AppSpacing.verticalSpaceXs,
        StarRating(
          rating: rating,
          size: 24,
          allowSelection: true,
          onRatingChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildHighlightsSection(ThemeData theme, TripRatingFormState formState, TripRatingFormNotifier formNotifier) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Highlights',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalSpaceSm,
            Text(
              'What were the best parts of this trip?',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            AppSpacing.verticalSpaceMd,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TripHighlight.values.map((highlight) {
                final isSelected = formState.selectedHighlights.contains(highlight);
                return FilterChip(
                  label: Text(
                    highlight.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                        ? theme.colorScheme.onPrimaryContainer 
                        : theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => formNotifier.toggleHighlight(highlight),
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

  Widget _buildFeedbackSection(ThemeData theme, TripRatingFormState formState, TripRatingFormNotifier formNotifier) {
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
                hintText: 'Share your detailed experience about this trip...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              maxLength: 1000,
              onChanged: (value) => formNotifier.updateFeedback(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationSection(ThemeData theme, TripRatingFormState formState, TripRatingFormNotifier formNotifier) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommendation',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalSpaceMd,
            SwitchListTile(
              value: formState.wouldRecommend,
              onChanged: (value) => formNotifier.updateWouldRecommend(value),
              title: const Text('Would you recommend this trip to others?'),
              subtitle: Text(
                formState.wouldRecommend 
                    ? 'Yes, I would recommend this trip'
                    : 'No, I would not recommend this trip',
                style: TextStyle(
                  color: formState.wouldRecommend ? Colors.green : Colors.red,
                ),
              ),
              contentPadding: EdgeInsets.zero,
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

    final formState = ref.read(tripRatingFormProvider(widget.tripId));
    final formNotifier = ref.read(tripRatingFormProvider(widget.tripId).notifier);

    formNotifier.setSubmitting(true);
    formNotifier.setError(null);

    try {
      final request = TripRatingRequest(
        tripId: widget.tripId,
        overallRating: formState.overallRating,
        organizationRating: formState.organizationRating,
        valueRating: formState.valueRating,
        experienceRating: formState.experienceRating,
        feedback: formState.feedback.isNotEmpty ? formState.feedback : null,
        highlights: formState.selectedHighlights.map((h) => h.name).toList(),
        wouldRecommend: formState.wouldRecommend,
      );

      final result = await ref.read(submitTripRatingProvider(request).future);

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Trip rating submitted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } else {
        formNotifier.setError(result['error'] ?? 'Failed to submit trip rating');
      }
    } catch (e) {
      formNotifier.setError('An unexpected error occurred: $e');
    } finally {
      formNotifier.setSubmitting(false);
    }
  }
}
