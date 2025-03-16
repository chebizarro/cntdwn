import 'package:cntdwn/widgets/video_player.dart';
import 'package:flutter/material.dart';

/// A screen that displays videos in a vertical PageView,
/// mimicking TikTok's "swipe up/down" feed.
class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final PageController _pageController = PageController();
  final List<VideoData> _videoItems = [
    VideoData(
      videoUrl: 'assets/video1.mp4', // or network URL
      userName: 'john_doe',
      caption: 'Exploring the mountains!',
      likes: 120,
      comments: 35,
      shares: 10,
    ),
    VideoData(
      videoUrl: 'assets/video2.mp4',
      userName: 'jane_smith',
      caption: 'City lights are amazing tonight.',
      likes: 567,
      comments: 48,
      shares: 22,
    ),
    // Add more videos as desired
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We want an “immersive” look, so the video is behind the system UI
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _videoItems.length,
        itemBuilder: (context, index) {
          return CntDwnVideoPlayer(videoData: _videoItems[index]);
        },
      ),
    );
  }
}