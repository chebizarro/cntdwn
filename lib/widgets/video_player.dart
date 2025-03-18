import 'package:cntdwn/data/models/nostr_event.dart';
import 'package:dart_nostr/nostr/model/event/event.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Simple data model representing each video in the feed.
class VideoData {
  final String videoUrl;
  final String userName;
  final String caption;
  final int likes;
  final int comments;
  final int shares;

  VideoData({
    required this.videoUrl,
    required this.userName,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.shares,
  });
}

/// A widget that plays a full-screen looping video with
/// a TikTok-style overlay.
class CntDwnVideoPlayer extends StatefulWidget {
  final NostrEvent videoData;

  const CntDwnVideoPlayer({super.key, required this.videoData});

  @override
  State<CntDwnVideoPlayer> createState() => _CntDwnVideoPlayerState();
}

class _CntDwnVideoPlayerState extends State<CntDwnVideoPlayer> {
  late VideoPlayerController _videoController;
  bool _isPlaying = true; // Track play/pause state

  @override
  void initState() {
    super.initState();

    // You can use either network or asset sources here.
    // For network: VideoPlayerController.network(widget.videoData.videoUrl)
    // For asset:   VideoPlayerController.asset(widget.videoData.videoUrl)
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoData.videoUrl!))
      ..initialize().then((_) {
        // Once initialized, start playback and loop
        _videoController.setLooping(true);
        _videoController.play();
        setState(() {
          _isPlaying = true;
        });
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  /// Toggle play/pause on tap
  void _onVideoTap() {
    if (_isPlaying) {
      _videoController.pause();
    } else {
      _videoController.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1) Fullscreen video behind everything
        GestureDetector(
          onTap: _onVideoTap,
          child: Center(
            child: _videoController.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _videoController.value.aspectRatio,
                    child: VideoPlayer(_videoController),
                  )
                : const CircularProgressIndicator(),
          ),
        ),

        // 2) Overlays (username, caption, right-side buttons)
        Positioned.fill(
          child: _buildVideoOverlay(),
        ),
      ],
    );
  }

  /// Builds the TikTok-style overlays: user info/caption on the bottom left,
  /// action buttons (like/comment/share/profile) on the right side.
  Widget _buildVideoOverlay() {
    final data = widget.videoData;
    return Container(
      // A gradient overlay or slight fade can be placed here
      child: SafeArea(
        child: Stack(
          children: [
            // Bottom left: User info & caption
            Positioned(
              bottom: 80,
              left: 16,
              right: 80, // leave some space for right-side buttons
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${data.pubkey}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.content!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.music_note, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Original Sound - Artist Name',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right side: Like/Comment/Share + Profile image
            Positioned(
              bottom: 100,
              right: 16,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Profile image (fake example)
                  _buildIconWithText(
                    icon: Icons.account_circle,
                    label: '',
                    iconSize: 60,
                  ),
                  const SizedBox(height: 20),
                  _buildIconWithText(
                    icon: Icons.favorite,
                    label: '0',
                  ),
                  const SizedBox(height: 20),
                  _buildIconWithText(
                    icon: Icons.chat_bubble,
                    label: '-',
                  ),
                  const SizedBox(height: 20),
                  _buildIconWithText(
                    icon: Icons.share,
                    label: '0',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper for building an icon button with a text label beneath it.
  Widget _buildIconWithText({
    required IconData icon,
    required String label,
    double iconSize = 40,
  }) {
    return Column(
      children: [
        Icon(icon, size: iconSize, color: Colors.white),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}

