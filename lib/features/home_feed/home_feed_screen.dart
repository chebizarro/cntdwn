import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidrome/providers/video_repository_provider.dart';
import 'package:vidrome/widgets/video_player.dart';
import 'package:go_router/go_router.dart';

class HomeFeedScreen extends ConsumerWidget {
  HomeFeedScreen({super.key});

  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoStream = ref.watch(filteredVideoStreamProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: videoStream.length,
        itemBuilder: (context, index) {
          return VidromeVideoPlayer(videoData: videoStream[index]);
        },
      ),

      // 1) Use the bottomNavigationBar property to make a fixed bar:
      bottomNavigationBar: SizedBox(
        height: 60,
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.home_outlined),
                color: Colors.white,
                onPressed: () {
                  // TODO: handle Home action
                },
              ),
              IconButton(
                icon: const Icon(Icons.search),
                color: Colors.white,
                onPressed: () {
                  // TODO: handle Search action
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_box_outlined),
                color: Colors.white,
                onPressed: () {
                  context.push('/post');
                },
              ),
              IconButton(
                icon: const Icon(Icons.message_outlined),
                color: Colors.white,
                onPressed: () {
                  // TODO: handle Inbox action
                },
              ),
              IconButton(
                icon: const Icon(Icons.person_outline),
                color: Colors.white,
                onPressed: () {
                  // TODO: handle Profile action
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
