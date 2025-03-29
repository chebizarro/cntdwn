import 'dart:io';
import 'package:vidrome/features/video_editor/video_editor_notifier.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';

/// A simple "multi-tab" editor UI with tabs for Edit, Filters, Transitions, & Export.
/// Each tab handles a slice of the editing logic. The merging and final export is triggered
/// in the "Export" tab.
class VideoEditorScreen extends ConsumerStatefulWidget {
  const VideoEditorScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _VideoEditorScreenState();
}

class _VideoEditorScreenState extends ConsumerState<VideoEditorScreen> {
  /// Controller for the main video editing flow
  VideoEditorController? _videoEditorController;

  /// Controller for the real-time playback in preview
  VideoPlayerController? _videoPlayerController;

  /// Keep track of multiple trimmed clips
  final List<Map<String, String>> _trimmedClips = [];

  /// A reference to the Flutter [ImagePicker]
  final ImagePicker _picker = ImagePicker();

  /// Currently selected bottom tab index
  int _selectedTab = 0;

  /// Some toggle states
  bool _isSeeking = false;
  bool _isMuted = false;
  bool _enableTransition = false;

  /// For playback speed
  double _playbackSpeed = 1.0;

  /// For showing/hiding the speed slider
  bool _speedSliderVisible = false;

  bool _hasInitialized = false;

  @override
  void dispose() {
    _videoEditorController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  /// Picks a single video from the gallery, sets up controllers
  Future<void> _importVideo() async {
    final xfile = await _picker.pickVideo(source: ImageSource.gallery);
    if (xfile == null) return;

    _videoEditorController = VideoEditorController.file(
      File(xfile.path),
      minDuration: const Duration(seconds: 1),
      maxDuration: const Duration(seconds: 60),
    );
    _videoPlayerController = VideoPlayerController.file(File(xfile.path));
    try {
      await Future.wait([
        _videoEditorController!.initialize(),
        _videoPlayerController!.initialize(),
      ]);

      _videoPlayerController!.addListener(() {
        // Pause at endTrim
        if (_videoEditorController == null) return;
        final end = _videoEditorController!.endTrim;
        if (_videoPlayerController!.value.position >= end) {
          _videoPlayerController!.pause();
        }
      });

      setState(() {
        _hasInitialized = true;
      });
    } catch (e) {
      debugPrint('Error picking video: $e');
    }
  }

  /// Toggles play/pause behavior. If we are out-of-bounds, reset to startTrim.
  void _togglePlayPause() {
    if (_videoPlayerController == null) return;
    final vp = _videoPlayerController!;
    if (vp.value.isPlaying) {
      vp.pause();
    } else {
      if (!_isSeeking && _videoEditorController != null) {
        final startTrimSec = _videoEditorController!.startTrim.inSeconds;
        vp.seekTo(Duration(seconds: startTrimSec));
      }
      vp.play();
    }
    setState(() {});
  }

  /// On the "Edit" tab, the user can do a basic trim and store the result in _trimmedClips
  Future<void> _trimClip() async {
    if (_videoEditorController == null) return;
    final startSec = _videoEditorController!.startTrim.inMilliseconds / 1000;
    final endSec = _videoEditorController!.endTrim.inMilliseconds / 1000;

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final tempDir = await getTemporaryDirectory();
    final outputPath = path.join(tempDir.path, 'trimmed_$timestamp.mp4');

    // We'll keep it simple: do a single pass with copy
    final trimCmd =
        '-i ${_videoEditorController!.file.path} -ss $startSec -to $endSec -c copy $outputPath';
    final session = await FFmpegKit.execute(trimCmd);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) {
      // Generate a thumbnail
      await _generateThumbnail(outputPath, timestamp);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trimmed clip saved to $outputPath')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to trim video')));
    }
  }

  /// Basic crop function
  Future<void> _cropClip() async {
    // Hard-coded example. In real usage you'd get actual crop coords
    if (_videoEditorController == null) return;
    final x = 0, y = 0, width = 480, height = 480;
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final tempDir = await getTemporaryDirectory();
    final outputPath = path.join(tempDir.path, 'cropped_$timestamp.mp4');

    final cmd =
        '-i ${_videoEditorController!.file.path} '
        '-filter:v "crop=$width:$height:$x:$y" -c:a copy $outputPath';
    final session = await FFmpegKit.execute(cmd);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) {
      _replaceMainVideo(outputPath);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cropped clip => $outputPath')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to crop video')));
    }
  }

  /// Replaces the main video used by the editor with a new path (for example, after cropping).
  Future<void> _replaceMainVideo(String pathToFile) async {
    await _videoEditorController?.dispose();
    await _videoPlayerController?.dispose();

    _videoEditorController = VideoEditorController.file(
      File(pathToFile),
      minDuration: const Duration(seconds: 1),
      maxDuration: const Duration(seconds: 60),
    );
    _videoPlayerController = VideoPlayerController.file(File(pathToFile));
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
      setState(() {});
    } catch (e) {
      debugPrint('Error re-initializing after crop: $e');
    }
  }

  /// Creates a single thumbnail for a newly trimmed clip
  Future<void> _generateThumbnail(String videoPath, String timestamp) async {
    final tempDir = await getTemporaryDirectory();
    final thumbPath = path.join(tempDir.path, 'thumb_$timestamp.jpg');
    final cmd = '-i $videoPath -ss 00:00:00.500 -vframes 1 $thumbPath';
    final session = await FFmpegKit.execute(cmd);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) {
      setState(() {
        _trimmedClips.add({'video': videoPath, 'thumbnail': thumbPath});
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save thumbnail')));
    }
  }

  /// Called in the "Export" tab to produce a final video from the trimmed clips,
  /// applying a filter, transitions, speed changes, and mute if selected.
  Future<void> _exportFinal() async {
    if (_trimmedClips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No trimmed clips to merge')),
      );
      return;
    }

    final editingState = ref.read(videoEditorProvider);
    final filterName = editingState.filter; // "none", "gblur", etc.
    final double speed = _playbackSpeed;
    final bool doMute = _isMuted;
    final bool doTransition = _enableTransition;

    final tempDir = await getTemporaryDirectory();
    final fileListPath = path.join(tempDir.path, 'filelist.txt');
    final mergedPath = path.join(
      tempDir.path,
      'merged_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );
    final intermediatePath = path.join(
      tempDir.path,
      'intermediate_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );

    // 1) Concat all trimmed clips
    final content = _trimmedClips.map((m) => "file '${m['video']}'").join('\n');
    await File(fileListPath).writeAsString(content);
    final concatCmd =
        '-f concat -safe 0 -i $fileListPath -c copy -y $mergedPath';
    final s1 = await FFmpegKit.execute(concatCmd);
    final rc1 = await s1.getReturnCode();
    if (!ReturnCode.isSuccess(rc1)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Concat step failed!')));
      return;
    }

    // 2) Now we apply filter, speed, transitions, and mute in a second pass.
    //    We'll rename merged => intermediate so we can read from it.
    final mergedFile = File(mergedPath);
    await mergedFile.rename(intermediatePath);

    // Build filter graph
    final filterParts = <String>[];
    String videoIn = '[0:v]';
    String audioIn = '[0:a]';
    bool needFilterComplex = false;

    // Speed
    if (speed != 1.0) {
      needFilterComplex = true;
      filterParts.add(
        '$videoIn setpts=${(1 / speed).toStringAsFixed(3)}*PTS[v]',
      );
      filterParts.add('$audioIn atempo=$speed[a]');
      videoIn = '[v]'; // rename for subsequent usage
      audioIn = '[a]';
    }

    // Transitions (fade in from black)
    if (doTransition) {
      needFilterComplex = true;
      final fadePart = '$videoIn fade=in:0:30[finalv]';
      filterParts.add(fadePart);
      videoIn = '[finalv]';

      // audio remains [a] or nothing
      if (speed != 1.0) {
        filterParts.add('$audioIn asplit[finala]');
        audioIn = '[finala]';
      }
    }

    final secondPassCmd = StringBuffer();
    secondPassCmd.write('-i $intermediatePath ');

    if (needFilterComplex) {
      secondPassCmd.write('-filter_complex "');
      secondPassCmd.write(filterParts.join('; '));
      secondPassCmd.write('" ');
      secondPassCmd.write('-map $videoIn -map $audioIn ');
    }

    if (doMute) {
      secondPassCmd.write('-an ');
    }

    // If filterName != "none", we’ll do a separate pass or unify it. We'll unify here:
    // We can do color filter last in the chain:
    if (filterName != 'none') {
      needFilterComplex = true;
      // If we haven't created a chain yet, we need to define the placeholders
      if (filterParts.isEmpty) {
        // We haven't done speed or fade. We'll just do one pass:
        secondPassCmd.clear();
        secondPassCmd.write('-i $intermediatePath ');
        final filterCmd = _buildFilterCommand(
          inputPath: '\$dummy', // not used
          outputPath: '\$dummy', // not used
          filterName: filterName,
        );
        // That command has form: '-i X -vf "stuff" -c:a copy Y'
        // We'll parse out the part after -vf and reuse it
        final splitted = filterCmd.split('-vf');
        if (splitted.length > 1) {
          final afterVf = splitted[1].trim(); // "gblur=sigma=10" -c:a copy ...
          final splitted2 = afterVf.split('-c:a');
          final filterArgs = splitted2[0].trim(); // "gblur=sigma=10"
          secondPassCmd.write('-vf "$filterArgs" ');
          // Then we handle audio
          if (doMute) {
            secondPassCmd.write('');
          } else {
            secondPassCmd.write('-c:a copy ');
          }
        }
      } else {
        // We already have filter_complex? Then we chain color effect at the end
        // This is more complicated. We'll do a second pass. Keep it simpler:
        // We'll do a third pass for color filter. Sorry. :-)
      }
    }

    // We'll finalize the second pass output
    final finalPath = path.join(
      tempDir.path,
      'final_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );
    secondPassCmd.write('-c:v libx264 -preset medium -crf 23 -y $finalPath');

    final s2 = await FFmpegKit.execute(secondPassCmd.toString());
    final rc2 = await s2.getReturnCode();
    if (!ReturnCode.isSuccess(rc2)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Second pass failed')));
      return;
    }

    // If the user had a color filter AND speed or transitions, we do a third pass:
    if (filterName != 'none' && needFilterComplex) {
      // We'll read from final => apply color filter => final2
      final tmpIn = finalPath;
      final finalPath2 = path.join(
        tempDir.path,
        'final2_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      final colorCmd = _buildFilterCommand(
        inputPath: tmpIn,
        outputPath: finalPath2,
        filterName: filterName,
      );
      final s3 = await FFmpegKit.execute(colorCmd);
      final rc3 = await s3.getReturnCode();
      if (!ReturnCode.isSuccess(rc3)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Color filter pass failed')),
        );
        return;
      }
      // final output is final2
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exported final to $finalPath2')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exported final to $finalPath')));
    }
  }

  /// Builds the bottom nav bar with 4 tabs
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedTab,
      onTap: (idx) => setState(() => _selectedTab = idx),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Edit'),
        BottomNavigationBarItem(
          icon: Icon(Icons.palette_outlined),
          label: 'Filters',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_awesome_motion),
          label: 'Transitions',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.check_circle),
          label: 'Export',
        ),
      ],
    );
  }

  /// The main body changes depending on selected tab
  Widget _buildBody() {
    switch (_selectedTab) {
      case 0:
        return _buildEditTab();
      case 1:
        return _buildFiltersTab();
      case 2:
        return _buildTransitionsTab();
      case 3:
        return _buildExportTab();
      default:
        return const Center(child: Text('Invalid tab'));
    }
  }

  /// Tab 0: Basic editing - preview, trimming, cropping, multi-clip timeline
  Widget _buildEditTab() {
    if (!_hasInitialized ||
        _videoEditorController == null ||
        _videoPlayerController == null) {
      return _buildImportCTA();
    }
    return Column(
      children: [
        // Video preview
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _videoPlayerController!.value.aspectRatio,
                child: VideoPlayer(_videoPlayerController!),
              ),
              IconButton(
                icon: Icon(
                  _videoPlayerController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
                onPressed: _togglePlayPause,
              ),
            ],
          ),
        ),

        // Scrubber
        Slider(
          value:
              _videoPlayerController!.value.position.inMilliseconds.toDouble(),
          max: _videoPlayerController!.value.duration.inMilliseconds.toDouble(),
          onChangeStart: (val) => _isSeeking = true,
          onChanged: (val) {
            _videoPlayerController!.seekTo(Duration(milliseconds: val.toInt()));
            setState(() {});
          },
          onChangeEnd: (val) {
            _isSeeking = false;
            _videoPlayerController!.play();
          },
        ),

        // Trim Slider from video_editor
        TrimSlider(
          controller: _videoEditorController!,
          height: 60,
          horizontalMargin: 16,
          child: TrimTimeline(controller: _videoEditorController!),
        ),

        // Action row: trim & crop
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _trimClip,
              icon: const Icon(Icons.cut),
              label: const Text('Trim'),
            ),
            ElevatedButton.icon(
              onPressed: _cropClip,
              icon: const Icon(Icons.crop),
              label: const Text('Crop'),
            ),
          ],
        ),

        // Reorderable list of trimmed clips
        Expanded(
          child: ReorderableListView.builder(
            itemCount: _trimmedClips.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              final item = _trimmedClips.removeAt(oldIndex);
              _trimmedClips.insert(newIndex, item);
            },
            itemBuilder: (context, index) {
              return ReorderableDragStartListener(
                key: ValueKey(_trimmedClips[index]),
                index: index,
                child: ListTile(
                  leading:
                      _trimmedClips[index]['thumbnail'] != null
                          ? Image.file(
                            File(_trimmedClips[index]['thumbnail']!),
                            fit: BoxFit.cover,
                            width: 60,
                            height: 60,
                          )
                          : const SizedBox(width: 60, height: 60),
                  title: Text(_trimmedClips[index]['video'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _trimmedClips.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Tab 1: Filters
  Widget _buildFiltersTab() {
    final editingState = ref.watch(videoEditorProvider);
    final currentFilter = editingState.filter;
    final filters = <String>['none', 'gblur', 'brightness', 'sepia'];

    if (!_hasInitialized) {
      return _buildImportCTA();
    }
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Text(
              'Select a Filter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final f = filters[index];
              final isSelected = f == currentFilter;
              return GestureDetector(
                onTap:
                    () => ref.read(videoEditorProvider.notifier).setFilter(f),
                child: Container(
                  width: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey[300],
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
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  /// Tab 2: Transitions, Speed, Audio
  Widget _buildTransitionsTab() {
    if (!_hasInitialized) {
      return _buildImportCTA();
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Enable fade-in from black (simple transition)'),
            value: _enableTransition,
            onChanged: (val) => setState(() => _enableTransition = val),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Mute Audio Track'),
            value: _isMuted,
            onChanged:
                (val) => setState(() {
                  _isMuted = val;
                  if (_videoPlayerController != null) {
                    _videoPlayerController!.setVolume(_isMuted ? 0 : 1);
                  }
                }),
          ),
          const Divider(),
          ListTile(
            title: const Text('Playback Speed'),
            subtitle: Text('${_playbackSpeed.toStringAsFixed(1)}x'),
            trailing: IconButton(
              icon: const Icon(Icons.speed),
              onPressed: () {
                setState(() {
                  _speedSliderVisible = !_speedSliderVisible;
                });
              },
            ),
          ),
          if (_speedSliderVisible)
            Slider(
              value: _playbackSpeed,
              min: 0.5,
              max: 3.0,
              divisions: 6,
              onChanged: (val) {
                setState(() {
                  _playbackSpeed = val;
                  if (_videoPlayerController != null) {
                    _videoPlayerController!.setPlaybackSpeed(_playbackSpeed);
                  }
                });
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Tab 3: Merging & Export
  Widget _buildExportTab() {
    if (!_hasInitialized) {
      return _buildImportCTA();
    }
    return Center(
      child: ElevatedButton(
        onPressed: _exportFinal,
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
        child: const Text('Merge & Export Final Video'),
      ),
    );
  }

  /// Shown if we haven't picked any video yet
  Widget _buildImportCTA() {
    return Center(
      child: ElevatedButton(
        onPressed: _importVideo,
        child: const Text('Import Video'),
      ),
    );
  }

  /// Helper to build the full screen UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Editor')),
      bottomNavigationBar: _buildBottomNavBar(),
      body: _buildBody(),
    );
  }

  /// The "filterName => actual ffmpeg args" logic
  String _buildFilterCommand({
    required String inputPath,
    required String outputPath,
    required String filterName,
  }) {
    switch (filterName) {
      case 'gblur':
        return '-i $inputPath -vf "gblur=sigma=10" -c:a copy $outputPath';
      case 'brightness':
        return '-i $inputPath -vf "eq=brightness=0.06" -c:a copy $outputPath';
      case 'sepia':
        return '-i $inputPath -vf "colorchannelmixer='
            '.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131" -c:a copy $outputPath';
      default:
        return '-i $inputPath -c copy $outputPath';
    }
  }
}
