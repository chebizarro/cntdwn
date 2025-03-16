import 'dart:developer';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/statistics.dart';
import 'package:video_editor/video_editor.dart';

class ExportService {
  /// If you want to cancel any active FFmpeg processes, call this.
  static Future<void> dispose() async {
    final executions = await FFmpegKit.listSessions();
    if (executions.isNotEmpty) {
      await FFmpegKit.cancel();
    }
  }

  /// Runs the given [execute] command from video_editor and fires callbacks.
  /// [onCompleted] receives the exported [File].
  /// [onError] is triggered if FFmpeg fails.
  /// [onProgress] can show encoding progress or stats.
  static Future<FFmpegSession> runFFmpegCommand(
    FFmpegVideoEditorExecute execute, {
    required void Function(File file) onCompleted,
    void Function(Object, StackTrace)? onError,
    void Function(Statistics)? onProgress,
  }) {
    log('FFmpeg start process with command = ${execute.command}');
    return FFmpegKit.executeAsync(
      execute.command,
      (session) async {
        final state =
            FFmpegKitConfig.sessionStateToString(await session.getState());
        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          // FFmpeg completed successfully!
          onCompleted(File(execute.outputPath));
        } else {
          // FFmpeg encountered an error
          final output = await session.getOutput();
          final exception = Exception(
            'FFmpeg process exited with state $state, return code $returnCode.\n$output',
          );
          if (onError != null) {
            onError(exception, StackTrace.current);
          }
        }
      },
      // Log callback (optional)
      null,
      // Progress callback
      onProgress,
    );
  }
}
