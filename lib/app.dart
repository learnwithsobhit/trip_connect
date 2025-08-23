import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/services/mock_server.dart';
import 'routing/app_router.dart';

class TripConnectApp extends ConsumerStatefulWidget {
  const TripConnectApp({super.key});

  @override
  ConsumerState<TripConnectApp> createState() => _TripConnectAppState();
}

class _TripConnectAppState extends ConsumerState<TripConnectApp> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize Hive
    await Hive.initFlutter();
    
    // Initialize MockServer
    await MockServer().initialize();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'TripConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.2,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}


