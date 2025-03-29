import 'package:vidrome/core/app_routes.dart';
import 'package:vidrome/core/app_theme.dart';
import 'package:vidrome/providers/app_init_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VidromeApp extends ConsumerWidget {
  const VidromeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initAsyncValue = ref.watch(appInitializerProvider);

    return initAsyncValue.when(
      data: (_) {
        return MaterialApp.router(
          title: 'Vidrome',
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          routerConfig: goRouter,
        );
      },
      loading:
          () => MaterialApp(
            theme: AppTheme.darkTheme,
            darkTheme: AppTheme.darkTheme,
            home: Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              body: Center(child: CircularProgressIndicator()),
            ),
          ),
      error:
          (err, stack) => MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Initialization Error: $err')),
            ),
          ),
    );
  }
}
