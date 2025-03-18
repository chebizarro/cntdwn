import 'package:cntdwn/data/models/nostr_event.dart';
import 'package:cntdwn/data/preferences.dart';
import 'package:cntdwn/data/repositories/video_repository.dart';
import 'package:cntdwn/providers/nostr_service_provider.dart';
import 'package:cntdwn/providers/preferences_provider.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final videoRepositoryProvider = Provider((ref) {
  final nostrService = ref.read(nostrServiceProvider);
  final settings = ref.read(preferencesProvider);
  final videoRepo = VideoRepository(nostrService, settings);

  ref.listen<Preferences>(preferencesProvider, (previous, next) {
    videoRepo.updateSettings(next);
  });

  return videoRepo;
});

final videoStreamProvider = StreamProvider<List<NostrEvent>>((ref) {
  final videoRepository = ref.read(videoRepositoryProvider);
  return videoRepository.eventsStream;
});

final filteredVideoStreamProvider = Provider<List<NostrEvent>>((ref) {
  final allOrdersAsync = ref.watch(videoStreamProvider);

  return allOrdersAsync.maybeWhen(
    data: (allOrders) {
      allOrders.sort((o1, o2) => o1.createdAt!.compareTo(o2.createdAt!));

      final filtered =
          allOrders.reversed.where((e) => e.videoUrl != null).toList();
      return filtered;
    },
    orElse: () => [],
  );
});
