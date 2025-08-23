import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TripDocsScreen extends StatelessWidget {
  final String tripId;

  const TripDocsScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        leading: IconButton(
          onPressed: () => context.go('/trips/$tripId'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder, size: 64),
            SizedBox(height: 16),
            Text('Trip Documents'),
            Text('Coming Soon'),
          ],
        ),
      ),
    );
  }
}


