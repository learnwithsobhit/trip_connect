import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/data/models/models.dart';
import '../../../../core/theme/app_spacing.dart';

class LocationSearchDialog extends StatefulWidget {
  final String tripId;
  final List<Membership> tripMembers;
  final Function(RollCallLocation location, String locationName) onLocationSelected;

  const LocationSearchDialog({
    super.key,
    required this.tripId,
    required this.tripMembers,
    required this.onLocationSelected,
  });

  @override
  State<LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<LocationSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _memberMarkers = {};
  Set<Marker> _searchResultMarkers = {};
  
  List<LocationSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingLocation = false;
  
  // Suggested locations based on trip members
  List<SuggestedLocation> _suggestedLocations = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _generateSuggestedLocations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: AppSpacing.paddingMd,
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select Roll Call Location',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Search Bar
            _buildSearchBar(theme),
            
            const SizedBox(height: 16),
            
            // Suggested Locations
            if (_suggestedLocations.isNotEmpty) ...[
              _buildSuggestedLocations(theme),
              const SizedBox(height: 16),
            ],
            
            // Map View
            Expanded(
              child: _buildMapView(theme),
            ),
            
            const SizedBox(height: 16),
            
            // Search Results
            if (_searchResults.isNotEmpty) ...[
              _buildSearchResults(theme),
              const SizedBox(height: 16),
            ],
            
            // Action Buttons
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      decoration: InputDecoration(
        hintText: 'Search for a location...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _isSearching
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: _centerOnCurrentLocation,
                tooltip: 'Use my current location',
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onSubmitted: (query) => _searchLocation(query),
    );
  }

  Widget _buildSuggestedLocations(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested Locations',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _suggestedLocations.length,
            itemBuilder: (context, index) {
              final location = _suggestedLocations[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                child: Card(
                  child: InkWell(
                    onTap: () => _selectSuggestedLocation(location),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: AppSpacing.paddingMd,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                location.icon,
                                color: theme.colorScheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  location.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            location.description,
                            style: theme.textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${location.memberCount} members nearby',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMapView(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            _currentPosition?.latitude ?? 20.5937,
            _currentPosition?.longitude ?? 78.9629,
          ),
          zoom: 12.0,
        ),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
          _updateMemberMarkers();
        },
        markers: {..._memberMarkers, ..._searchResultMarkers},
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        onTap: (LatLng position) => _handleMapTap(position),
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Results',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(result.name),
                  subtitle: Text(result.address),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_location),
                    onPressed: () => _selectSearchResult(result),
                  ),
                  onTap: () => _selectSearchResult(result),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _currentPosition != null
                ? () => _selectCurrentLocation()
                : null,
            child: const Text('Use Current Location'),
          ),
        ),
      ],
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check location permission first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _handleLocationError('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _handleLocationError('Location permissions are permanently denied');
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _handleLocationError('Location services are disabled');
        return;
      }

      // Get position with reduced timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // Reduced accuracy for faster response
        timeLimit: const Duration(seconds: 3), // Reduced timeout
      ).timeout(
        const Duration(seconds: 5), // Additional timeout wrapper
        onTimeout: () {
          throw Exception('Location request timed out');
        },
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      _updateMemberMarkers();
    } catch (e) {
      _handleLocationError(e.toString());
    }
  }

  void _handleLocationError(String error) {
    if (!mounted) return;
    
    setState(() {
      _isLoadingLocation = false;
      // Set a default location if location fails (India center)
      _currentPosition = null;
    });
    
    // Only show error message if it's not a timeout (too noisy)
    if (!error.toLowerCase().contains('timeout')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location unavailable: ${error.length > 50 ? 'Service error' : error}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _generateSuggestedLocations() {
    final suggestions = <SuggestedLocation>[];
    
    // Group members by location clusters
    final locationClusters = <String, List<Membership>>{};
    
    for (final member in widget.tripMembers) {
      if (member.location != null) {
        // Create a cluster key based on approximate location (rounded coordinates)
        final clusterKey = '${(member.location!.lat * 100).round()}_${(member.location!.lng * 100).round()}';
        locationClusters.putIfAbsent(clusterKey, () => []).add(member);
      }
    }
    
    // Create suggested locations for each cluster
    for (final cluster in locationClusters.entries) {
      if (cluster.value.length >= 2) { // Only suggest if 2+ members are nearby
        final avgLat = cluster.value.map((m) => m.location!.lat).reduce((a, b) => a + b) / cluster.value.length;
        final avgLng = cluster.value.map((m) => m.location!.lng).reduce((a, b) => a + b) / cluster.value.length;
        
        suggestions.add(SuggestedLocation(
          name: 'Member Cluster',
          description: '${cluster.value.length} members nearby',
          lat: avgLat,
          lng: avgLng,
          memberCount: cluster.value.length,
          icon: Icons.people,
        ));
      }
    }
    
    // Add popular landmarks if available
    if (widget.tripId == 't_001') { // Goa trip
      suggestions.addAll([
        SuggestedLocation(
          name: 'Calangute Beach',
          description: 'Popular beach destination',
          lat: 15.5439,
          lng: 73.7553,
          memberCount: 0,
          icon: Icons.beach_access,
        ),
        SuggestedLocation(
          name: 'Fort Aguada',
          description: 'Historic Portuguese fort',
          lat: 15.4927,
          lng: 73.7737,
          memberCount: 0,
          icon: Icons.castle,
        ),
        SuggestedLocation(
          name: 'Panaji Market',
          description: 'Local market area',
          lat: 15.4909,
          lng: 73.8278,
          memberCount: 0,
          icon: Icons.store,
        ),
      ]);
    }
    
    setState(() {
      _suggestedLocations = suggestions;
    });
  }

  void _updateMemberMarkers() {
    final markers = <Marker>{};
    
    // Add current user marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_user'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(
            title: 'You',
            snippet: 'Current location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    
    // Add trip member markers
    for (final member in widget.tripMembers) {
      if (member.location != null) {
        markers.add(
          Marker(
            markerId: MarkerId('member_${member.userId}'),
            position: LatLng(member.location!.lat, member.location!.lng),
            infoWindow: InfoWindow(
              title: 'Member ${member.userId}',
              snippet: 'Last seen: ${_formatLastSeen(member.lastSeen)}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      }
    }
    
    setState(() {
      _memberMarkers = markers;
    });
  }

  void _centerOnCurrentLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      // Simulate location search (in a real app, this would use Google Places API)
      await Future.delayed(const Duration(seconds: 1));
      
      final results = [
        LocationSearchResult(
          name: '$query Location',
          address: 'Nearby area in $query',
          lat: (_currentPosition?.latitude ?? 20.5937) + (0.01 * (1 + _searchResults.length)),
          lng: (_currentPosition?.longitude ?? 78.9629) + (0.01 * (1 + _searchResults.length)),
        ),
        LocationSearchResult(
          name: '$query Center',
          address: 'Central area of $query',
          lat: (_currentPosition?.latitude ?? 20.5937) + (0.02 * (1 + _searchResults.length)),
          lng: (_currentPosition?.longitude ?? 78.9629) + (0.02 * (1 + _searchResults.length)),
        ),
      ];
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
      
      _updateSearchResultMarkers();
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateSearchResultMarkers() {
    final markers = <Marker>{};
    
    for (int i = 0; i < _searchResults.length; i++) {
      final result = _searchResults[i];
      markers.add(
        Marker(
          markerId: MarkerId('search_$i'),
          position: LatLng(result.lat, result.lng),
          infoWindow: InfoWindow(
            title: result.name,
            snippet: result.address,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    
    setState(() {
      _searchResultMarkers = markers;
    });
  }

  void _handleMapTap(LatLng position) {
    // Show a dialog to confirm the selected location
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select This Location?'),
        content: Text(
          'Latitude: ${position.latitude.toStringAsFixed(6)}\n'
          'Longitude: ${position.longitude.toStringAsFixed(6)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _selectMapLocation(position);
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  void _selectCurrentLocation() {
    if (_currentPosition != null) {
      final location = RollCallLocation(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        timestamp: DateTime.now(),
        accuracy: _currentPosition!.accuracy,
      );
      
      widget.onLocationSelected(location, 'Current Location');
      Navigator.of(context).pop();
    }
  }

  void _selectSuggestedLocation(SuggestedLocation location) {
    final rollCallLocation = RollCallLocation(
      lat: location.lat,
      lng: location.lng,
      timestamp: DateTime.now(),
      accuracy: 10.0,
    );
    
    widget.onLocationSelected(rollCallLocation, location.name);
    Navigator.of(context).pop();
  }

  void _selectSearchResult(LocationSearchResult result) {
    final rollCallLocation = RollCallLocation(
      lat: result.lat,
      lng: result.lng,
      timestamp: DateTime.now(),
      accuracy: 10.0,
    );
    
    widget.onLocationSelected(rollCallLocation, result.name);
    Navigator.of(context).pop();
  }

  void _selectMapLocation(LatLng position) {
    final rollCallLocation = RollCallLocation(
      lat: position.latitude,
      lng: position.longitude,
      timestamp: DateTime.now(),
      accuracy: 10.0,
    );
    
    widget.onLocationSelected(rollCallLocation, 'Selected Location');
    Navigator.of(context).pop();
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class SuggestedLocation {
  final String name;
  final String description;
  final double lat;
  final double lng;
  final int memberCount;
  final IconData icon;

  SuggestedLocation({
    required this.name,
    required this.description,
    required this.lat,
    required this.lng,
    required this.memberCount,
    required this.icon,
  });
}

class LocationSearchResult {
  final String name;
  final String address;
  final double lat;
  final double lng;

  LocationSearchResult({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });
}
