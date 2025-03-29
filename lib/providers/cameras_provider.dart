import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidrome/features/post/camera_notifier.dart';


final cameraNotifierProvider =
    StateNotifierProvider<CameraNotifier, CameraController?>((ref) {
  return CameraNotifier();
});
