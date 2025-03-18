import 'package:cntdwn/providers/nostr_service_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appInitializerProvider = FutureProvider<void>((ref) async {
  final nostrService = ref.read(nostrServiceProvider);
  await nostrService.init();

});
