import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/data/providers/trip_provider.dart';
import '../../../core/data/providers/auth_provider.dart';
import '../../../core/data/models/models.dart';
import '../../../core/theme/app_spacing.dart';

class TripJoinScreen extends ConsumerStatefulWidget {
  final String? inviteCode;

  const TripJoinScreen({super.key, this.inviteCode});

  @override
  ConsumerState<TripJoinScreen> createState() => _TripJoinScreenState();
}

class _TripJoinScreenState extends ConsumerState<TripJoinScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  
  MobileScannerController? _scannerController;
  bool _isScanning = false;
  bool _isJoining = false;
  String _selectedLanguage = 'en';
  bool _preciseLocation = true;
  
  // Language options for Polyglot agent
  final Map<String, String> _languages = {
    'en': 'English',
    'hi': 'हिन्दी',
    'mr': 'मराठी', 
    'gu': 'ગુજરાતી',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
    'kn': 'ಕನ್ನಡ',
    'ml': 'മലയാളം',
    'bn': 'বাংলা',
    'pa': 'ਪੰਜਾਬੀ',
  };

  @override
  void initState() {
    super.initState();
    if (widget.inviteCode != null) {
      _codeController.text = widget.inviteCode!;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _scannerController = MobileScannerController();
    });
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
      _scannerController?.dispose();
      _scannerController = null;
    });
  }

  void _onQRCodeScanned(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final scannedData = barcodes.first.rawValue;
      if (scannedData != null) {
        _processScannedCode(scannedData);
      }
    }
  }

  void _processScannedCode(String scannedData) {
    _stopScanning();
    
    // Extract invite code from URL or use directly
    String inviteCode = scannedData;
    if (scannedData.contains('/join/')) {
      final parts = scannedData.split('/join/');
      if (parts.length > 1) {
        inviteCode = parts.last.split('?').first; // Remove query params if any
      }
    }
    
    setState(() {
      _codeController.text = inviteCode.toUpperCase();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('QR code scanned: $inviteCode'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }



  void _showJoinSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            AppSpacing.horizontalSpaceSm,
            const Text('Welcome to the Trip!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Successfully joined with code: ${_codeController.text}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            AppSpacing.verticalSpaceMd,
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.translate,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      AppSpacing.horizontalSpaceXs,
                      Text(
                        'Polyglot Agent Activated',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalSpaceXs,
                  Text(
                    'Chat messages will be auto-translated to ${_languages[_selectedLanguage]}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            AppSpacing.verticalSpaceMd,
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _preciseLocation ? Icons.gps_fixed : Icons.location_on,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      AppSpacing.horizontalSpaceXs,
                      Text(
                        'Location Sharing',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalSpaceXs,
                  Text(
                    _preciseLocation 
                        ? 'Precise location enabled for safety'
                        : 'Approximate location enabled',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/');
            },
            child: const Text('Start Exploring'),
          ),
        ],
      ),
    );
  }

  void _showDateOverlapDialog(String errorMessage) {
    // Extract trip names and dates from error message
    final conflictingTripRegex = RegExp(r'overlap with "([^"]+)"');
    final conflictingMatch = conflictingTripRegex.firstMatch(errorMessage);
    final conflictingTripName = conflictingMatch?.group(1) ?? 'existing trip';

    final datesRegex = RegExp(r'\(([^)]+)\)');
    final datesMatch = datesRegex.firstMatch(errorMessage);
    final conflictingDates = datesMatch?.group(1) ?? 'overlapping dates';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.date_range,
              color: Colors.orange,
              size: 28,
            ),
            AppSpacing.horizontalSpaceSm,
            const Text('Date Conflict'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You can have multiple trips, but not with overlapping dates for safety and coordination.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            AppSpacing.verticalSpaceMd,
            
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      AppSpacing.horizontalSpaceXs,
                      Text(
                        'Conflicting Trip',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalSpaceXs,
                  Text(
                    '"$conflictingTripName"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Dates: $conflictingDates',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
            
            AppSpacing.verticalSpaceMd,
            
            Text(
              'What would you like to do?',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showLeaveConflictingTripDialog(conflictingTripName, conflictingDates);
            },
            child: const Text('Leave Conflicting Trip'),
          ),
        ],
      ),
    );
  }

  void _showLeaveConflictingTripDialog(String tripName, String conflictingDates) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Conflicting Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Leave "$tripName" to resolve the date conflict?'),
            AppSpacing.verticalSpaceMd,
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conflicting dates: $conflictingDates',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  AppSpacing.verticalSpaceXs,
                  Text(
                    'Leaving will:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.verticalSpaceXs,
                  const Text('• Remove you from conflicting trip activities'),
                  const Text('• Stop location sharing for that trip'),
                  const Text('• Allow you to join the new trip'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _leaveCurrentTripAndJoin(),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave & Join New Trip'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveCurrentTripAndJoin() async {
    Navigator.of(context).pop(); // Close dialog
    
    setState(() => _isJoining = true);
    
    try {
      // Get user's current trips to find the active one
      final currentTrips = ref.read(tripsProvider);
      
      await currentTrips.when(
        data: (trips) async {
          // Find active trip
          final activeTrip = trips.firstWhere(
            (trip) => trip.status == TripStatus.active || trip.status == TripStatus.planning,
            orElse: () => trips.first, // Fallback to first trip
          );
          
          // Leave current trip
          await ref.read(tripsProvider.notifier).leaveTrip(activeTrip.id);
          
          // Join new trip
          await ref.read(tripsProvider.notifier).joinTrip(_codeController.text.trim());
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    AppSpacing.horizontalSpaceSm,
                    const Expanded(
                      child: Text('Successfully switched trips! 🎉'),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            
            context.go('/');
          }
        },
        loading: () => throw Exception('Loading trips...'),
        error: (error, stack) => throw error,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch trips: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Trip'),
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.close),
        ),
      ),
      body: _isScanning ? _buildScannerView() : _buildFormView(),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onQRCodeScanned,
        ),
        
        // Scanner overlay
        Container(
          decoration: ShapeDecoration(
            shape: QrScannerOverlayShape(
              borderColor: Theme.of(context).colorScheme.primary,
              borderRadius: 16,
              borderLength: 30,
              borderWidth: 4,
              cutOutSize: 250,
            ),
          ),
        ),
        
        // Instructions overlay
        SafeArea(
          child: Column(
            children: [
              AppSpacing.verticalSpaceLg,
              Container(
                margin: AppSpacing.paddingMd,
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Point your camera at the QR code to join the trip',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const Spacer(),
              
              // Controls
              Container(
                margin: AppSpacing.paddingMd,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton(
                      heroTag: 'close_scanner',
                      onPressed: _stopScanning,
                      backgroundColor: Colors.black54,
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                    FloatingActionButton(
                      heroTag: 'toggle_flash',
                      onPressed: () => _scannerController?.toggleTorch(),
                      backgroundColor: Colors.black54,
                      child: const Icon(Icons.flash_on, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              AppSpacing.verticalSpaceLg,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormView() {
    final theme = Theme.of(context);
    
    return ListView(
      padding: AppSpacing.paddingMd,
      children: [
        // Header
        Card(
          elevation: 4,
          child: Padding(
            padding: AppSpacing.paddingMd,
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                AppSpacing.verticalSpaceMd,
                Text(
                  'Join a Trip',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.verticalSpaceSm,
                Text(
                  'Scan a QR code or enter the invite code to join an existing trip',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        
        AppSpacing.verticalSpaceLg,
        
        // QR Scanner Button
        SizedBox(
          height: AppSpacing.buttonHeightLg,
          child: OutlinedButton.icon(
            onPressed: _startScanning,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR Code'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
        
        AppSpacing.verticalSpaceLg,
        
        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: theme.colorScheme.outline)),
            Padding(
              padding: AppSpacing.paddingHorizontalMd,
              child: Text(
                'OR',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: Divider(color: theme.colorScheme.outline)),
          ],
        ),
        
        AppSpacing.verticalSpaceLg,
        
        // Manual Code Entry
        TextFormField(
          controller: _codeController,
          decoration: const InputDecoration(
            labelText: 'Invite Code',
            hintText: 'e.g., TC123ABC',
            prefixIcon: Icon(Icons.confirmation_number_outlined),
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            // Auto-format code
            _codeController.value = _codeController.value.copyWith(
              text: value.toUpperCase(),
              selection: TextSelection.collapsed(offset: value.length),
            );
          },
        ),
        
        AppSpacing.verticalSpaceLg,
        
        // Display Name
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Your Display Name',
            hintText: 'How others will see you',
            prefixIcon: Icon(Icons.person_outline),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        
        AppSpacing.verticalSpaceLg,
        
        // Language Preference
        DropdownButtonFormField<String>(
          value: _selectedLanguage,
          decoration: const InputDecoration(
            labelText: 'Preferred Language',
            prefixIcon: Icon(Icons.translate),
          ),
          items: _languages.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedLanguage = value);
            }
          },
        ),
        
        AppSpacing.verticalSpaceLg,
        
        // Location Preference
        Card(
          child: Padding(
            padding: AppSpacing.paddingMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location Sharing',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.verticalSpaceSm,
                SwitchListTile(
                  title: const Text('Precise Location'),
                  subtitle: const Text('Share exact location for safety and coordination'),
                  value: _preciseLocation,
                  onChanged: (value) => setState(() => _preciseLocation = value),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
        
        AppSpacing.verticalSpaceXxl,
        
        // Join Button
        SizedBox(
          height: AppSpacing.buttonHeightLg,
          child: FilledButton(
            onPressed: _isJoining ? null : _joinTrip,
            child: _isJoining
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Join Trip',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        
        AppSpacing.verticalSpaceLg,
      ],
    );
  }

  Future<void> _joinTrip() async {
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a trip code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      final tripProvider = ref.read(tripsProvider.notifier);
      await tripProvider.joinTrip(_codeController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                AppSpacing.horizontalSpaceSm,
                const Expanded(
                  child: Text('Successfully joined the trip! 🎉'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        _showJoinSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        
        // Handle different types of errors
        if (errorMessage.contains('Date overlap') || errorMessage.contains('Trip dates overlap')) {
          _showDateOverlapDialog(errorMessage);
        } else if (errorMessage.contains('rating') && errorMessage.contains('below the minimum required')) {
          // Create a mock result object for rating requirement errors
          final ratingErrorResult = {
            'error': errorMessage,
            'type': 'RATING_REQUIREMENT_NOT_MET',
            // Try to extract rating values from error message
            'currentRating': _extractRatingFromMessage(errorMessage, 'Your rating'),
            'requiredRating': _extractRatingFromMessage(errorMessage, 'minimum required'),
          };
          _showRatingRequirementDialog(ratingErrorResult);
        } else if (errorMessage.contains('Added to waiting list') || errorMessage.contains('waiting list')) {
          _showWaitingListDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  double? _extractRatingFromMessage(String message, String prefix) {
    try {
      final regex = RegExp('$prefix.*?([0-9]+\\.?[0-9]*)');
      final match = regex.firstMatch(message);
      if (match != null && match.group(1) != null) {
        return double.tryParse(match.group(1)!);
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return null;
  }

  void _showRatingRequirementDialog(dynamic result) {
    final currentRating = result['currentRating'] as double?;
    final requiredRating = result['requiredRating'] as double?;
    final errorMessage = result['error'] as String?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.star_border,
              color: Colors.orange,
              size: 28,
            ),
            AppSpacing.horizontalSpaceSm,
            const Text('Rating Requirement'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              errorMessage ?? 'Your rating does not meet the minimum requirement for this trip.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            AppSpacing.verticalSpaceMd,
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rating Details:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.verticalSpaceXs,
                  if (currentRating != null)
                    Text('Your rating: ${currentRating.toStringAsFixed(1)}⭐'),
                  if (requiredRating != null)
                    Text('Required rating: ${requiredRating.toStringAsFixed(1)}⭐'),
                  AppSpacing.verticalSpaceXs,
                  Text(
                    'Complete more trips and get positive ratings to improve your score!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (currentRating != null && currentRating > 0)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to user profile/ratings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Check your profile for detailed ratings'),
                  ),
                );
              },
              child: const Text('View My Ratings'),
            ),
        ],
      ),
    );
  }

  void _showWaitingListDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.access_time,
              color: Colors.orange,
              size: 28,
            ),
            AppSpacing.horizontalSpaceSm,
            const Text('Added to Waiting List'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This trip is currently full, but you\'ve been added to the waiting list.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            AppSpacing.verticalSpaceMd,
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What happens next:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.verticalSpaceXs,
                  const Text('• You\'ll be notified if a seat becomes available'),
                  const Text('• Your position will move up as others leave'),
                  const Text('• You can leave the waiting list anytime'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/');
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// Custom QR Scanner Overlay Shape
class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
  }) : cutOutSize = cutOutSize ?? 250;

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderHeightSize = height / 2;
    final cutOutWidth = cutOutSize < width ? cutOutSize : width - borderWidth;
    final cutOutHeight = cutOutSize < height ? cutOutSize : height - borderWidth;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromLTWH(
      borderWidthSize - cutOutWidth / 2,
      borderHeightSize - cutOutHeight / 2,
      cutOutWidth,
      cutOutHeight,
    );

    // Draw overlay
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
          ),
      ),
      backgroundPaint,
    );

    // Draw border corners
    final path = Path()
      ..moveTo(cutOutRect.left - borderLength, cutOutRect.top)
      ..lineTo(cutOutRect.left, cutOutRect.top)
      ..lineTo(cutOutRect.left, cutOutRect.top + borderLength);

    canvas.drawPath(path, borderPaint);

    final path2 = Path()
      ..moveTo(cutOutRect.right + borderLength, cutOutRect.top)
      ..lineTo(cutOutRect.right, cutOutRect.top)
      ..lineTo(cutOutRect.right, cutOutRect.top + borderLength);
    canvas.drawPath(path2, borderPaint);

    final path3 = Path()
      ..moveTo(cutOutRect.left - borderLength, cutOutRect.bottom)
      ..lineTo(cutOutRect.left, cutOutRect.bottom)
      ..lineTo(cutOutRect.left, cutOutRect.bottom - borderLength);
    canvas.drawPath(path3, borderPaint);

    final path4 = Path()
      ..moveTo(cutOutRect.right + borderLength, cutOutRect.bottom)
      ..lineTo(cutOutRect.right, cutOutRect.bottom)
      ..lineTo(cutOutRect.right, cutOutRect.bottom - borderLength);
    canvas.drawPath(path4, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
