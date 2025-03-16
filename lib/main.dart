import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Screens
import 'features/home_feed/home_feed_screen.dart';
import 'features/video_editor/video_editor_screen.dart';
import 'features/preferences/preferences_screen.dart';
import 'features/profile/profile_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'cntdwn',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/edit',
      routes: {
        '/': (context) => const HomeFeedScreen(),
        '/edit': (context) => VideoEditorScreen(),
        '/preferences': (context) => const PreferencesScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
