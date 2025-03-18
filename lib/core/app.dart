import 'package:cntdwn/core/app_routes.dart';
import 'package:cntdwn/core/app_theme.dart';
import 'package:cntdwn/providers/app_init_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CntDwnApp extends ConsumerWidget {
  const CntDwnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initAsyncValue = ref.watch(appInitializerProvider);

    return initAsyncValue.when(
      data: (_) {
        return MaterialApp.router(
          title: 'CntDwn',
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          routerConfig: goRouter,
        );
      },
      loading: () => MaterialApp(
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, stack) => MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Initialization Error: $err')),
        ),
      ),
    );
  }
}
