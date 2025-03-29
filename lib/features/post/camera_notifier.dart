import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the current camera's controller, or null if not yet initialized.
class CameraNotifier extends StateNotifier<CameraController?> {
  CameraNotifier() : super(null);

  Future<void> initializeCamera() async {
    final List<CameraDescription> cameras = await availableCameras();
    if (cameras.isEmpty) {
      return;
    }

    final camera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    try {
      await controller.initialize();
      // Start the camera feed
      //await controller.startVideoStreaming();
    } catch (e) {

      rethrow;
    }

    state = controller;
  }

  @override
  void dispose() {
    state?.dispose();
    super.dispose();
  }

  Future<void> startPreview() async {
    if (state != null && !state!.value.isStreamingImages) {
      //await state!.startVideoStreaming();
    }
  }

  Future<void> stopPreview() async {
    if (state != null && state!.value.isStreamingImages) {
      //await state!.stopVideoStreaming();
    }
  }
}

