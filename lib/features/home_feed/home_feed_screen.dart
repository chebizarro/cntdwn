import 'package:cntdwn/providers/video_repository_provider.dart';
import 'package:cntdwn/widgets/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A screen that displays videos in a vertical PageView,
/// mimicking TikTok's "swipe up/down" feed.
class HomeFeedScreen extends ConsumerWidget {
  HomeFeedScreen({super.key});

  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoStream = ref.watch(filteredVideoStreamProvider);

    return Scaffold(
      // We want an “immersive” look, so the video is behind the system UI
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: videoStream.length,
        itemBuilder: (context, index) {
          return CntDwnVideoPlayer(videoData: videoStream[index]);
        },
      ),
    );
  }
}
