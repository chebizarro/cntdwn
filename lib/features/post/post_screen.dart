import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';

IconData _getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
  // Fallback for future lens directions not in the enum
  return Icons.camera;
}

void _logError(String code, String? message) {
  debugPrint('Error: $code${message == null ? '' : '\nError Message: $message'}');
}

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  XFile? _imageFile;
  XFile? _videoFile;
  VideoPlayerController? _videoController;
  VoidCallback? _videoPlayerListener;

  bool _enableAudio = true;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;
  late final AnimationController _flashModeControlRowAnimationController;
  late final CurvedAnimation _flashModeControlRowAnimation;
  late final AnimationController _exposureModeControlRowAnimationController;
  late final CurvedAnimation _exposureModeControlRowAnimation;
  late final AnimationController _focusModeControlRowAnimationController;
  late final CurvedAnimation _focusModeControlRowAnimation;

  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  int _pointers = 0; // number of user fingers on screen

  /// Store all cameras in a static list for toggling.
  static List<CameraDescription> _cameras = <CameraDescription>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _flashModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flashModeControlRowAnimation = CurvedAnimation(
      parent: _flashModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    _exposureModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _exposureModeControlRowAnimation = CurvedAnimation(
      parent: _exposureModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    _focusModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _focusModeControlRowAnimation = CurvedAnimation(
      parent: _focusModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );

    // Load cameras once at the start (or you can do it outside this widget).
    _initializeCameras();
  }

  Future<void> _initializeCameras() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        // Default to the first camera or pick your desired lens direction.
        await _initializeCameraController(_cameras.first);
      } else {
        _showInSnackBar('No cameras found on device.');
      }
    } on CameraException catch (e) {
      _logError(e.code, e.description);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flashModeControlRowAnimationController.dispose();
    _exposureModeControlRowAnimationController.dispose();
    _focusModeControlRowAnimationController.dispose();
    _videoController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  // #docregion AppLifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // If no controller or not initialized, nothing to do.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraController(cameraController.description);
    }
  }
  // #enddocregion AppLifecycle

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Camera Example'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  color: _controller != null && _controller!.value.isRecordingVideo
                      ? Colors.redAccent
                      : Colors.grey,
                  width: 3.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Center(child: _cameraPreviewWidget()),
              ),
            ),
          ),
          _captureControlRowWidget(),
          _modeControlRowWidget(),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              children: <Widget>[
                _cameraTogglesRowWidget(),
                _thumbnailWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the camera preview or a placeholder message.
  Widget _cameraPreviewWidget() {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return const Text(
        'Select a camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    return Listener(
      onPointerDown: (_) => _pointers++,
      onPointerUp: (_) => _pointers--,
      child: CameraPreview(
        cameraController,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onTapDown: (TapDownDetails details) =>
                  _onViewFinderTap(details, constraints),
            );
          },
        ),
      ),
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (_controller == null || _pointers != 2) {
      return;
    }
    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await _controller!.setZoomLevel(_currentScale);
  }

  void _onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (_controller == null) return;
    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    _controller!.setExposurePoint(offset);
    _controller!.setFocusPoint(offset);
  }

  /// Displays the last taken picture or recorded video as a thumbnail.
  Widget _thumbnailWidget() {
    final VideoPlayerController? localVideoController = _videoController;

    return Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (localVideoController == null && _imageFile == null)
              Container()
            else
              SizedBox(
                width: 64.0,
                height: 64.0,
                child: localVideoController == null
                    ? (kIsWeb
                        ? Image.network(_imageFile!.path)
                        : Image.file(File(_imageFile!.path)))
                    : Container(
                        decoration:
                            BoxDecoration(border: Border.all(color: Colors.pink)),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: localVideoController.value.aspectRatio,
                            child: VideoPlayer(localVideoController),
                          ),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  /// The top row of toggles for flash/exposure/focus/etc.
  Widget _modeControlRowWidget() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.flash_on),
              color: Colors.blue,
              onPressed: _controller != null ? _onFlashModeButtonPressed : null,
            ),
            if (!kIsWeb) ...[
              IconButton(
                icon: const Icon(Icons.exposure),
                color: Colors.blue,
                onPressed:
                    _controller != null ? _onExposureModeButtonPressed : null,
              ),
              IconButton(
                icon: const Icon(Icons.filter_center_focus),
                color: Colors.blue,
                onPressed: _controller != null ? _onFocusModeButtonPressed : null,
              ),
            ],
            IconButton(
              icon: Icon(_enableAudio ? Icons.volume_up : Icons.volume_mute),
              color: Colors.blue,
              onPressed: _controller != null ? _onAudioModeButtonPressed : null,
            ),
            IconButton(
              icon: Icon(
                _controller?.value.isCaptureOrientationLocked ?? false
                    ? Icons.screen_lock_rotation
                    : Icons.screen_rotation,
              ),
              color: Colors.blue,
              onPressed: _controller != null
                  ? _onCaptureOrientationLockButtonPressed
                  : null,
            ),
          ],
        ),
        _flashModeControlRowWidget(),
        _exposureModeControlRowWidget(),
        _focusModeControlRowWidget(),
      ],
    );
  }

  /// The bottom row with capture/record/pause/stop/etc.
  Widget _captureControlRowWidget() {
    final CameraController? cameraController = _controller;
    final bool isInitialized =
        (cameraController != null) && cameraController.value.isInitialized;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.camera_alt),
          color: Colors.blue,
          onPressed:
              isInitialized && !cameraController!.value.isRecordingVideo
                  ? _onTakePictureButtonPressed
                  : null,
        ),
        IconButton(
          icon: const Icon(Icons.videocam),
          color: Colors.blue,
          onPressed:
              isInitialized && !cameraController!.value.isRecordingVideo
                  ? _onVideoRecordButtonPressed
                  : null,
        ),
        IconButton(
          icon: cameraController != null &&
                  cameraController.value.isRecordingPaused
              ? const Icon(Icons.play_arrow)
              : const Icon(Icons.pause),
          color: Colors.blue,
          onPressed: isInitialized && cameraController!.value.isRecordingVideo
              ? (cameraController.value.isRecordingPaused
                  ? _onResumeButtonPressed
                  : _onPauseButtonPressed)
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.stop),
          color: Colors.red,
          onPressed:
              isInitialized && cameraController!.value.isRecordingVideo
                  ? _onStopButtonPressed
                  : null,
        ),
        IconButton(
          icon: Icon(
            (cameraController?.value.isPreviewPaused ?? false)
                ? Icons.pause_presentation
                : Icons.play_for_work,
          ),
          color:
              (cameraController != null && cameraController.value.isPreviewPaused)
                  ? Colors.red
                  : Colors.blue,
          onPressed: cameraController == null ? null : _onPausePreviewButtonPressed,
        ),
      ],
    );
  }

  /// Toggle between different cameras if multiple are available.
  Widget _cameraTogglesRowWidget() {
    final List<Widget> toggles = <Widget>[];

    void onChanged(CameraDescription? description) {
      if (description == null) return;
      _onNewCameraSelected(description);
    }

    if (_cameras.isEmpty) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        _showInSnackBar('No camera found.');
      });
      return const Text('None');
    } else {
      for (final CameraDescription cameraDescription in _cameras) {
        toggles.add(
          SizedBox(
            width: 90.0,
            child: RadioListTile<CameraDescription>(
              title: Icon(_getCameraLensIcon(cameraDescription.lensDirection)),
              groupValue: _controller?.description,
              value: cameraDescription,
              onChanged: onChanged,
            ),
          ),
        );
      }
    }

    return Row(children: toggles);
  }

  Widget _flashModeControlRowWidget() {
    return SizeTransition(
      sizeFactor: _flashModeControlRowAnimation,
      child: ClipRect(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.flash_off),
              color: _controller?.value.flashMode == FlashMode.off
                  ? Colors.orange
                  : Colors.blue,
              onPressed: _controller != null
                  ? () => _onSetFlashModeButtonPressed(FlashMode.off)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.flash_auto),
              color: _controller?.value.flashMode == FlashMode.auto
                  ? Colors.orange
                  : Colors.blue,
              onPressed: _controller != null
                  ? () => _onSetFlashModeButtonPressed(FlashMode.auto)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.flash_on),
              color: _controller?.value.flashMode == FlashMode.always
                  ? Colors.orange
                  : Colors.blue,
              onPressed: _controller != null
                  ? () => _onSetFlashModeButtonPressed(FlashMode.always)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.highlight),
              color: _controller?.value.flashMode == FlashMode.torch
                  ? Colors.orange
                  : Colors.blue,
              onPressed: _controller != null
                  ? () => _onSetFlashModeButtonPressed(FlashMode.torch)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _exposureModeControlRowWidget() {
    final ButtonStyle styleAuto = TextButton.styleFrom(
      foregroundColor: _controller?.value.exposureMode == ExposureMode.auto
          ? Colors.orange
          : Colors.blue,
    );
    final ButtonStyle styleLocked = TextButton.styleFrom(
      foregroundColor: _controller?.value.exposureMode == ExposureMode.locked
          ? Colors.orange
          : Colors.blue,
    );

    return SizeTransition(
      sizeFactor: _exposureModeControlRowAnimation,
      child: ClipRect(
        child: ColoredBox(
          color: Colors.grey.shade50,
          child: Column(
            children: <Widget>[
              const Center(child: Text('Exposure Mode')),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  TextButton(
                    style: styleAuto,
                    onPressed: _controller != null
                        ? () => _onSetExposureModeButtonPressed(ExposureMode.auto)
                        : null,
                    onLongPress: () {
                      if (_controller != null) {
                        _controller!.setExposurePoint(null);
                        _showInSnackBar('Reset exposure point');
                      }
                    },
                    child: const Text('AUTO'),
                  ),
                  TextButton(
                    style: styleLocked,
                    onPressed: _controller != null
                        ? () =>
                            _onSetExposureModeButtonPressed(ExposureMode.locked)
                        : null,
                    child: const Text('LOCKED'),
                  ),
                  TextButton(
                    style: styleLocked,
                    onPressed: _controller != null
                        ? () => _controller!.setExposureOffset(0.0)
                        : null,
                    child: const Text('RESET OFFSET'),
                  ),
                ],
              ),
              const Center(child: Text('Exposure Offset')),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(_minAvailableExposureOffset.toString()),
                  Slider(
                    value: _currentExposureOffset,
                    min: _minAvailableExposureOffset,
                    max: _maxAvailableExposureOffset,
                    label: _currentExposureOffset.toString(),
                    onChanged: _minAvailableExposureOffset ==
                            _maxAvailableExposureOffset
                        ? null
                        : _setExposureOffset,
                  ),
                  Text(_maxAvailableExposureOffset.toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _focusModeControlRowWidget() {
    final ButtonStyle styleAuto = TextButton.styleFrom(
      foregroundColor: _controller?.value.focusMode == FocusMode.auto
          ? Colors.orange
          : Colors.blue,
    );
    final ButtonStyle styleLocked = TextButton.styleFrom(
      foregroundColor: _controller?.value.focusMode == FocusMode.locked
          ? Colors.orange
          : Colors.blue,
    );

    return SizeTransition(
      sizeFactor: _focusModeControlRowAnimation,
      child: ClipRect(
        child: ColoredBox(
          color: Colors.grey.shade50,
          child: Column(
            children: <Widget>[
              const Center(child: Text('Focus Mode')),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  TextButton(
                    style: styleAuto,
                    onPressed: _controller != null
                        ? () => _onSetFocusModeButtonPressed(FocusMode.auto)
                        : null,
                    onLongPress: () {
                      if (_controller != null) {
                        _controller!.setFocusPoint(null);
                      }
                      _showInSnackBar('Reset focus point');
                    },
                    child: const Text('AUTO'),
                  ),
                  TextButton(
                    style: styleLocked,
                    onPressed: _controller != null
                        ? () => _onSetFocusModeButtonPressed(FocusMode.locked)
                        : null,
                    child: const Text('LOCKED'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Camera Lifecycle & Actions
  // --------------------------------------------------------------------------

  Future<void> _onNewCameraSelected(CameraDescription cameraDescription) async {
    if (_controller != null) {
      // If the controller is already created, we can re-use it or re-init
      await _controller!.setDescription(cameraDescription);
    } else {
      await _initializeCameraController(cameraDescription);
    }
    setState(() {});
  }

  Future<void> _initializeCameraController(CameraDescription description) async {
    final CameraController controller = CameraController(
      description,
      kIsWeb ? ResolutionPreset.max : ResolutionPreset.medium,
      enableAudio: _enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = controller;

    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        _showInSnackBar('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
      await Future.wait(<Future<Object?>>[
        // The exposure mode is not supported on web
        if (!kIsWeb) ...[
          controller
              .getMinExposureOffset()
              .then((value) => _minAvailableExposureOffset = value),
          controller
              .getMaxExposureOffset()
              .then((value) => _maxAvailableExposureOffset = value),
        ],
        controller
            .getMaxZoomLevel()
            .then((value) => _maxAvailableZoom = value),
        controller
            .getMinZoomLevel()
            .then((value) => _minAvailableZoom = value),
      ]);
    } on CameraException catch (e) {
      _showCameraException(e);
    }
    if (mounted) setState(() {});
  }

  // --------------------------------------------------------------------------
  // Action Buttons
  // --------------------------------------------------------------------------

  void _onTakePictureButtonPressed() {
    _takePicture().then((XFile? file) {
      if (!mounted) return;
      setState(() {
        _imageFile = file;
        _videoController?.dispose();
        _videoController = null;
      });
      if (file != null) {
        _showInSnackBar('Picture saved at ${file.path}');
      }
    });
  }

  void _onVideoRecordButtonPressed() {
    _startVideoRecording().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _onStopButtonPressed() {
    _stopVideoRecording().then((XFile? file) {
      if (!mounted) return;
      if (file != null) {
        _showInSnackBar('Video recorded to ${file.path}');
        _videoFile = file;
        _startVideoPlayer();
      }
      setState(() {});
    });
  }

  Future<void> _onPausePreviewButtonPressed() async {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      _showInSnackBar('Error: select a camera first.');
      return;
    }
    if (cameraController.value.isPreviewPaused) {
      await cameraController.resumePreview();
    } else {
      await cameraController.pausePreview();
    }
    if (mounted) setState(() {});
  }

  void _onPauseButtonPressed() {
    _pauseVideoRecording().then((_) {
      if (mounted) setState(() {});
      _showInSnackBar('Video recording paused');
    });
  }

  void _onResumeButtonPressed() {
    _resumeVideoRecording().then((_) {
      if (mounted) setState(() {});
      _showInSnackBar('Video recording resumed');
    });
  }

  Future<void> _startVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      _showInSnackBar('Error: select a camera first.');
      return;
    }
    if (_controller!.value.isRecordingVideo) {
      // Already recording
      return;
    }
    try {
      await _controller!.startVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  Future<XFile?> _stopVideoRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) {
      return null;
    }
    try {
      return _controller!.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  Future<void> _pauseVideoRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) return;
    try {
      await _controller!.pauseVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> _resumeVideoRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) return;
    try {
      await _controller!.resumeVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // Flash / Exposure / Focus / Audio Controls
  // --------------------------------------------------------------------------

  void _onFlashModeButtonPressed() {
    if (_flashModeControlRowAnimationController.value == 1) {
      _flashModeControlRowAnimationController.reverse();
    } else {
      _flashModeControlRowAnimationController.forward();
      _exposureModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
    }
  }

  void _onExposureModeButtonPressed() {
    if (_exposureModeControlRowAnimationController.value == 1) {
      _exposureModeControlRowAnimationController.reverse();
    } else {
      _exposureModeControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
    }
  }

  void _onFocusModeButtonPressed() {
    if (_focusModeControlRowAnimationController.value == 1) {
      _focusModeControlRowAnimationController.reverse();
    } else {
      _focusModeControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
      _exposureModeControlRowAnimationController.reverse();
    }
  }

  void _onAudioModeButtonPressed() {
    _enableAudio = !_enableAudio;
    if (_controller != null) {
      _onNewCameraSelected(_controller!.description);
    }
  }

  Future<void> _onCaptureOrientationLockButtonPressed() async {
    if (_controller == null) return;
    try {
      final CameraController cameraController = _controller!;
      if (cameraController.value.isCaptureOrientationLocked) {
        await cameraController.unlockCaptureOrientation();
        _showInSnackBar('Capture orientation unlocked');
      } else {
        await cameraController.lockCaptureOrientation();
        _showInSnackBar(
          'Capture orientation locked to '
          '${cameraController.value.lockedCaptureOrientation.toString().split('.').last}',
        );
      }
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  Future<void> _onSetFlashModeButtonPressed(FlashMode mode) async {
    if (_controller == null) return;
    try {
      await _controller!.setFlashMode(mode);
      setState(() {});
      _showInSnackBar('Flash mode set to ${mode.toString().split('.').last}');
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  Future<void> _onSetExposureModeButtonPressed(ExposureMode mode) async {
    if (_controller == null) return;
    try {
      await _controller!.setExposureMode(mode);
      setState(() {});
      _showInSnackBar('Exposure mode set to ${mode.toString().split('.').last}');
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  Future<void> _onSetFocusModeButtonPressed(FocusMode mode) async {
    if (_controller == null) return;
    try {
      await _controller!.setFocusMode(mode);
      setState(() {});
      _showInSnackBar('Focus mode set to ${mode.toString().split('.').last}');
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  Future<void> _setExposureOffset(double offset) async {
    if (_controller == null) return;
    setState(() => _currentExposureOffset = offset);
    try {
      offset = await _controller!.setExposureOffset(offset);
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  // --------------------------------------------------------------------------
  // Picture / Video Handling
  // --------------------------------------------------------------------------

  Future<XFile?> _takePicture() async {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      _showInSnackBar('Error: select a camera first.');
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      // A capture is already pending
      return null;
    }

    try {
      final XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  // For playing recorded videos
  Future<void> _startVideoPlayer() async {
    if (_videoFile == null) return;
    final VideoPlayerController vController = kIsWeb
        ? VideoPlayerController.networkUrl(Uri.parse(_videoFile!.path))
        : VideoPlayerController.file(File(_videoFile!.path));

    _videoPlayerListener = () {
      if (_videoController != null) {
        if (mounted) setState(() {});
        _videoController!.removeListener(_videoPlayerListener!);
      }
    };
    vController.addListener(_videoPlayerListener!);
    await vController.setLooping(true);
    await vController.initialize();
    await _videoController?.dispose();
    if (mounted) {
      setState(() {
        _imageFile = null;
        _videoController = vController;
      });
    }
    await vController.play();
  }

  // --------------------------------------------------------------------------
  // Utility
  // --------------------------------------------------------------------------

  void _showInSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showCameraException(CameraException e) {
    _logError(e.code, e.description);
    _showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}
