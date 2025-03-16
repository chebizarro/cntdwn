import 'dart:io';
import 'package:cntdwn/features/video_editor/video_editor_notifier.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as path;

class VideoEditorScreen extends ConsumerStatefulWidget {

  const VideoEditorScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _VideoEditorScreenState();
}

class _VideoEditorScreenState extends ConsumerState<VideoEditorScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  VideoEditorController? _videoEditorController;
  VideoPlayerController? _videoPlayerController;
  List<Map<String, String>> trimmedVideos = [];
  bool canShowEditor = false;
  bool isSeeking = false;
  bool enableTransition = false;
  bool isMuted = false;
  double playbackSpeed = 1.0;
  bool isSpeedControlVisible = false;

  Future<void> _pickVideo() async {
    final xfile = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (xfile != null) {
      _videoEditorController = VideoEditorController.file(
        File(xfile.path),
        minDuration: Duration(seconds: 1),
        maxDuration: Duration(seconds: 30),
      );
      _videoPlayerController = VideoPlayerController.file(File(xfile.path));
      try {
        await Future.wait([
          _videoEditorController!.initialize(),
          _videoPlayerController!.initialize(),
        ]);
        _videoPlayerController!.addListener(() {
          if (_videoPlayerController!.value.position >=
              _videoEditorController!.endTrim) {
            _videoPlayerController!.pause();
          }
        });
        setState(() {
          canShowEditor = true;
        });
      } catch (e) {
        print(e);
      }
    }
  }

  Future<void> _trimVideo() async {
    if (_videoEditorController == null) return;
    final start = _videoEditorController!.startTrim.inMilliseconds / 1000;
    final end = _videoEditorController!.endTrim.inMilliseconds / 1000;
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final fileName = 'trimmed_video_$timestamp.mp4';
    final outputPath = path.join(tempDir.path, fileName);
    final command =
        '-i ${_videoEditorController!.file.path} -ss $start -to $end -c copy $outputPath';
    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        _generateThumbnail(outputPath, timestamp);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video exported to $outputPath')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to export video')));
      }
    });
  }

  Future<void> _mergeVideos() async {
    if (trimmedVideos.isEmpty) return;
    final tempDir = await getTemporaryDirectory();
    final mergedVideoPath = '${tempDir.path}/merged_video.mp4';
    final fileListPath = '${tempDir.path}/file_list.txt';
    final fileList = File(fileListPath);
    final fileListContent = trimmedVideos
        .map((path) => "file '$path'")
        .join('\n');
    await fileList.writeAsString(fileListContent);
    String command =
        '-f concat -safe 0 -i $fileListPath -c copy $mergedVideoPath -y';
    if (enableTransition) {
      command =
          '-f concat -safe 0 -i $fileListPath '
          '-vf "fade=in:0:30" '
          '-c:v libx264 -preset medium -crf 23 -movflags +faststart $mergedVideoPath -y';
    }
    if (isMuted) {
      command =
          "-f concat -safe 0 -i $fileListPath -c copy -an $mergedVideoPath -y";
    }
    if (playbackSpeed != 1.0) {
      final setptsValue = 1 / playbackSpeed;
      command =
          '-f concat -safe 0 -i $fileListPath -filter_complex '
          '"[0:v]setpts=$setptsValue*PTS[v];[0:a]atempo=$playbackSpeed[a]" -map "[v]" -map "[a]" '
          '-c:v libx264 -preset medium -crf 23 $mergedVideoPath -y';
    }
    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Final Video exported to $mergedVideoPath')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to export video')));
      }
    });
  }

  Future<void> _generateThumbnail(String videoPath, String timestamp) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = 'thumb_$timestamp.jpg';
    final thumbnailPath = path.join(tempDir.path, fileName);
    final command = '-i $videoPath -ss 00:00:00.500 -yframes 1 $thumbnailPath';
    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        setState(() {
          trimmedVideos.add({'video': videoPath, 'thumbnail': thumbnailPath});
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save thumbnail')));
      }
    });
  }

 
  /// Return a sample FFmpeg command string based on filterName.
  /// For example, "gblur", "brightness", "sepia", etc.
  String _buildFFmpegCommand({
    required String inputPath,
    required String outputPath,
    required String filterName,
  }) {
    // Different filters require different arguments.
    // You can expand this or map filterName -> specific filter string.
    switch (filterName) {
      case 'gblur':
        // Gaussian blur example
        return '-i $inputPath -vf "gblur=sigma=10" -c:a copy $outputPath';
      case 'brightness':
        // Increase brightness a bit
        return '-i $inputPath -vf "eq=brightness=0.06" -c:a copy $outputPath';
      case 'sepia':
        // A sepia-like effect
        return '-i $inputPath -vf "colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131" -c:a copy $outputPath';
      default:
        // No filter
        return '-i $inputPath -c copy $outputPath';
    }
  }

  @override
  Widget build(BuildContext context) {
    final editingState = ref.watch(videoEditorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                enableTransition = !enableTransition;
              });
            },
            icon: Icon(
              enableTransition
                  ? Icons.swap_horizontal_circle
                  : Icons.swap_horizontal_circle_outlined,
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Column(
          children: [
            if (canShowEditor &&
                _videoPlayerController!.value.isInitialized &&
                _videoEditorController!.initialized) ...[
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AspectRatio(
                            aspectRatio:
                                _videoPlayerController!.value.aspectRatio,
                            child: VideoPlayer(_videoPlayerController!),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                if (_videoPlayerController!.value.isPlaying) {
                                  _videoPlayerController!.pause();
                                } else {
                                  if (!isSeeking) {
                                    final startTrimDuration =
                                        _videoEditorController!
                                            .startTrim
                                            .inSeconds;
                                    _videoPlayerController!.seekTo(
                                      Duration(seconds: startTrimDuration),
                                    );
                                  }
                                  _videoPlayerController!.play();
                                }
                              });
                            },
                            icon: Icon(
                              _videoPlayerController!.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Slider(
                      value:
                          _videoPlayerController!.value.position.inMilliseconds
                              .toDouble(),
                      max:
                          _videoPlayerController!.value.duration.inMilliseconds
                              .toDouble(),
                      onChangeStart: (value) {
                        isSeeking = true;
                      },
                      onChanged: (value) {
                        _videoPlayerController!.seekTo(
                          Duration(milliseconds: value.toInt()),
                        );
                        setState(() {});
                      },
                      onChangeEnd: (value) {
                        isSeeking = false;
                        _videoPlayerController!.play();
                      },
                    ),
                    if (isSpeedControlVisible)
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text(
                              'Speed: ${playbackSpeed.toStringAsFixed(1)}x',
                              style: TextStyle(color: Colors.white),
                            ),
                            Slider(
                              value: playbackSpeed,
                              min: 0.5,
                              max: 3.0,
                              divisions: 6,
                              onChanged: (value) {
                                setState(() {
                                  playbackSpeed = value;
                                  _videoPlayerController!.setPlaybackSpeed(
                                    playbackSpeed,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              TrimSlider(
                controller: _videoEditorController!,
                height: 60,
                horizontalMargin: 16,
                child: TrimTimeline(controller: _videoEditorController!),
              ),

              Expanded(
                flex: 1,
                child: ReorderableListView.builder(
                  itemCount: trimmedVideos.length,
                  onReorder: (int oldIndex, int newIndex) {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final movedClip = trimmedVideos.removeAt(oldIndex);
                    trimmedVideos.insert(newIndex, movedClip);
                  },
                  itemBuilder: (context, index) {
                    return ReorderableDragStartListener(
                      index: index,
                      key: ValueKey(trimmedVideos[index]),
                      child: Container(
                        width: 100,
                        margin: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            trimmedVideos[index]['thumbnail'] != null
                                ? Image.file(
                                  File(trimmedVideos[index]['thumbnail']!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                )
                                : Center(child: CircularProgressIndicator()),
                            Positioned(
                              child: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed:
                                    () => setState(() {
                                      trimmedVideos.removeAt(index);
                                    }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _trimVideo,
                      icon: Icon(Icons.content_cut, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.crop, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          isSpeedControlVisible = !isSpeedControlVisible;
                        });
                      },
                      icon: Icon(
                        Icons.speed,
                        color:
                            !isSpeedControlVisible
                                ? Colors.white
                                : Colors.green,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          isMuted = !isMuted;
                          _videoPlayerController!.setVolume(isMuted ? 0 : 1);
                        });
                      },
                      icon: Icon(
                        isMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.only(bottom: 25),
                child: ElevatedButton(
                  onPressed: _mergeVideos,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text('Merge & Export'),
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Text(
                    'Select a video to start editing',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 25),
                child: ElevatedButton(
                  onPressed: _pickVideo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text('Import video'),
                ),
              ),
              const Divider(),
              _buildFilterList(editingState.filter),
            ],
          ],
        ),
      ),
    );
  }

  /// A simple horizontal list of filter options
  Widget _buildFilterList(String filter) {
    final filters = <String>['none', 'gblur', 'brightness', 'sepia'];
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = f == filter;
          return GestureDetector(
            onTap: () {
              ref.read(videoEditorProvider.notifier).setFilter(f);
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                f.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}
