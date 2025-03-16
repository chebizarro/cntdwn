import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define some editing state
class VideoEditingState {
  final double trimStart;
  final double trimEnd;
  final String filter;
  final bool isExporting;
  final bool exportSuccess;
  final String errorMessage;

  const VideoEditingState({
    this.trimStart = 0.0,
    this.trimEnd = 1.0,
    this.filter = '',
    this.isExporting = false,
    this.exportSuccess = false,
    this.errorMessage = '',
  });

  VideoEditingState copyWith({
    double? trimStart,
    double? trimEnd,
    String? filter,
    bool? isExporting,
    bool? exportSuccess,
    String? errorMessage,
  }) {
    return VideoEditingState(
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
      filter: filter ?? this.filter,
      isExporting: isExporting ?? this.isExporting,
      exportSuccess: exportSuccess ?? this.exportSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class VideoEditorNotifier extends StateNotifier<VideoEditingState> {
  VideoEditorNotifier() : super(const VideoEditingState());

  void setTrimStart(double value) {
    state = state.copyWith(trimStart: value);
  }

  void setTrimEnd(double value) {
    state = state.copyWith(trimEnd: value);
  }

  void setFilter(String filterName) {
    state = state.copyWith(filter: filterName);
  }

  Future<void> exportVideo(String videoPath) async {
    // Example: call an FFmpeg command with state.trimStart, state.trimEnd, and state.filter
    // Then generate an output file
  }

  void setExporting(bool value) {
    state = state.copyWith(isExporting: value);
  }

  void setExportSuccess(bool value) {
    state = state.copyWith(exportSuccess: value);
  }

  void setErrorMessage(String msg) {
    state = state.copyWith(errorMessage: msg);
  }
}

final videoEditorProvider =
    StateNotifierProvider<VideoEditorNotifier, VideoEditingState>(
        (ref) => VideoEditorNotifier());
