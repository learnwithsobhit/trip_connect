import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/data/models/rollcall.dart';
import '../../../../core/theme/app_spacing.dart';

class RollCallConfigDialog extends StatefulWidget {
  final RollCallConfig? initialConfig;

  const RollCallConfigDialog({super.key, this.initialConfig});

  @override
  State<RollCallConfigDialog> createState() => _RollCallConfigDialogState();
}

class _RollCallConfigDialogState extends State<RollCallConfigDialog> {
  late double _radiusMeters;
  late int _gracePeriodMinutes;
  late int _locationFreshnessMinutes;
  late bool _allowManualCheckIn;
  late bool _enableGpsTracking;
  late bool _announceOnClose;
  late RollCallMode _mode;
  
  final List<double> _radiusPresets = [20, 30, 50, 75, 100, 150, 200];
  final List<int> _gracePeriodPresets = [2, 3, 5, 10, 15];

  @override
  void initState() {
    super.initState();
    final config = widget.initialConfig ?? const RollCallConfig();
    
    _radiusMeters = config.radiusMeters;
    _gracePeriodMinutes = config.gracePeriodSeconds ~/ 60;
    _locationFreshnessMinutes = config.locationFreshnessSeconds ~/ 60;
    _allowManualCheckIn = config.allowManualCheckIn;
    _enableGpsTracking = config.enableGpsTracking;
    _announceOnClose = config.announceOnClose;
    _mode = config.mode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Roll Call Configuration'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Radius selection
              Text(
                'Detection Radius',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.verticalSpaceSm,
              
              // Radius presets
              Wrap(
                spacing: 8,
                children: _radiusPresets.map((radius) {
                  final isSelected = _radiusMeters == radius;
                  return FilterChip(
                    label: Text('${radius.toInt()}m'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _radiusMeters = radius;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              
              AppSpacing.verticalSpaceSm,
              
              // Custom radius slider
              Row(
                children: [
                  const Text('Custom: '),
                  Expanded(
                    child: Slider(
                      value: _radiusMeters,
                      min: 10,
                      max: 200,
                      divisions: 19,
                      label: '${_radiusMeters.toInt()}m',
                      onChanged: (value) {
                        setState(() {
                          _radiusMeters = value;
                        });
                      },
                    ),
                  ),
                  Text('${_radiusMeters.toInt()}m'),
                ],
              ),
              
              AppSpacing.verticalSpaceMd,
              
              // Grace period
              Text(
                'Grace Period',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.verticalSpaceSm,
              
              Wrap(
                spacing: 8,
                children: _gracePeriodPresets.map((minutes) {
                  final isSelected = _gracePeriodMinutes == minutes;
                  return FilterChip(
                    label: Text('${minutes}min'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _gracePeriodMinutes = minutes;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              
              AppSpacing.verticalSpaceMd,
              
              // Mode selection
              Text(
                'Roll Call Mode',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.verticalSpaceSm,
              
              DropdownButtonFormField<RollCallMode>(
                value: _mode,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: RollCallMode.values.map((mode) {
                  return DropdownMenuItem(
                    value: mode,
                    child: Row(
                      children: [
                        Icon(_getModeIcon(mode), size: 20),
                        AppSpacing.horizontalSpaceSm,
                        Text(_getModeLabel(mode)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (mode) {
                  if (mode != null) {
                    setState(() {
                      _mode = mode;
                    });
                  }
                },
              ),
              
              AppSpacing.verticalSpaceSm,
              
              Text(
                _getModeDescription(_mode),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              
              AppSpacing.verticalSpaceMd,
              
              // Settings switches
              Text(
                'Settings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.verticalSpaceSm,
              
              SwitchListTile(
                title: const Text('GPS Auto Check-in'),
                subtitle: const Text('Automatically check in users within radius'),
                value: _enableGpsTracking,
                onChanged: (value) {
                  setState(() {
                    _enableGpsTracking = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              
              SwitchListTile(
                title: const Text('Manual Check-in'),
                subtitle: const Text('Allow users to check in manually'),
                value: _allowManualCheckIn,
                onChanged: (value) {
                  setState(() {
                    _allowManualCheckIn = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              
              SwitchListTile(
                title: const Text('Announce on Close'),
                subtitle: const Text('Send notification when roll call completes'),
                value: _announceOnClose,
                onChanged: (value) {
                  setState(() {
                    _announceOnClose = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              
              AppSpacing.verticalSpaceMd,
              
              // Advanced settings
              ExpansionTile(
                title: const Text('Advanced Settings'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                children: [
                  ListTile(
                    title: const Text('Location Freshness'),
                    subtitle: Text('${_locationFreshnessMinutes}min - How recent location must be'),
                    trailing: SizedBox(
                      width: 80,
                      child: DropdownButtonFormField<int>(
                        value: _locationFreshnessMinutes,
                        items: [1, 2, 3, 5].map((minutes) {
                          return DropdownMenuItem(
                            value: minutes,
                            child: Text('${minutes}min'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _locationFreshnessMinutes = value;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveConfiguration,
          child: const Text('Start Roll Call'),
        ),
      ],
    );
  }

  void _saveConfiguration() {
    final config = RollCallConfig(
      radiusMeters: _radiusMeters,
      gracePeriodSeconds: _gracePeriodMinutes * 60,
      locationFreshnessSeconds: _locationFreshnessMinutes * 60,
      allowManualCheckIn: _allowManualCheckIn,
      enableGpsTracking: _enableGpsTracking,
      announceOnClose: _announceOnClose,
      mode: _mode,
      enableQrCheckIn: false, // TODO: Add to UI
      enableNfcCheckIn: false, // TODO: Add to UI
      autoStartOnGeofence: false, // TODO: Add to UI
      enableHysteresis: true, // TODO: Add to UI
      maxReminderCount: 2, // TODO: Add to UI
      reminderIntervalSeconds: 60, // TODO: Add to UI
      requireDualConfirmForLeaderMark: false, // TODO: Add to UI
    );
    
    Navigator.of(context).pop(config);
  }

  IconData _getModeIcon(RollCallMode mode) {
    return switch (mode) {
      RollCallMode.standard => Icons.groups,
      RollCallMode.vehicle => Icons.directions_bus,
      RollCallMode.table => Icons.restaurant,
      RollCallMode.indoor => Icons.business,
      RollCallMode.kidsElderly => Icons.family_restroom,
    };
  }

  String _getModeLabel(RollCallMode mode) {
    return switch (mode) {
      RollCallMode.standard => 'Standard',
      RollCallMode.vehicle => 'Vehicle',
      RollCallMode.table => 'Table/Restaurant',
      RollCallMode.indoor => 'Indoor',
      RollCallMode.kidsElderly => 'Kids & Elderly',
    };
  }

  String _getModeDescription(RollCallMode mode) {
    return switch (mode) {
      RollCallMode.standard => 'Standard roll call for outdoor gatherings',
      RollCallMode.vehicle => 'Per-vehicle tracking for bus/van groups',
      RollCallMode.table => 'Table-based check-in for restaurants',
      RollCallMode.indoor => 'Relaxed GPS rules for indoor locations',
      RollCallMode.kidsElderly => 'Guardian pairing and assistance features',
    };
  }
}
