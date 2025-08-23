import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TripMediaScreen extends StatelessWidget {
  final String tripId;

  const TripMediaScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media'),
        leading: IconButton(
          onPressed: () => context.go('/trips/$tripId'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64),
            SizedBox(height: 16),
            Text('Trip Media'),
            Text('Coming Soon'),
          ],
        ),
      ),
    );
  }
}


