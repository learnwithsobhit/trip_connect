import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TripMapScreen extends StatelessWidget {
  final String tripId;

  const TripMapScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Map'),
        leading: IconButton(
          onPressed: () => context.go('/trips/$tripId'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64),
            SizedBox(height: 16),
            Text('Live Location Map'),
            Text('Coming Soon'),
          ],
        ),
      ),
    );
  }
}


