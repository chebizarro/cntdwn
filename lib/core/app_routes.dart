import 'package:cntdwn/features/home_feed/home_feed_screen.dart';
import 'package:cntdwn/features/preferences/preferences_screen.dart';
import 'package:cntdwn/features/profile/profile_screen.dart';
import 'package:cntdwn/features/video_editor/video_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final goRouter = GoRouter(
  navigatorKey: GlobalKey<NavigatorState>(),
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => HomeFeedScreen()),
    GoRoute(
      path: '/edit',
      builder: (context, state) => const VideoEditorScreen(),
    ),
    GoRoute(
      path: '/preferences',
      builder: (context, state) => const PreferencesScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
