import 'package:vidrome/features/home_feed/home_feed_screen.dart';
import 'package:vidrome/features/post/post_screen.dart';
import 'package:vidrome/features/preferences/preferences_screen.dart';
import 'package:vidrome/features/user_profile/create_account_screen.dart';
import 'package:vidrome/features/user_profile/user_profile_screen.dart';
import 'package:vidrome/features/video_editor/video_editor_screen.dart';
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
      path: '/post',
      builder: (context, state) => const PostScreen(),
    ),
    GoRoute(
      path: '/preferences',
      builder: (context, state) => const PreferencesScreen(),
    ),
    GoRoute(
      path: '/user_profile',
      builder: (context, state) => const UserProfileScreen(),
    ),
    GoRoute(
      path: '/new_user',
      builder: (context, state) => const CreateAccountScreen(),
    ),
  ],
);
