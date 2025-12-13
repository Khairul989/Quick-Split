import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/deep_link_service.dart';

part 'deep_link_provider.g.dart';

/// Singleton provider for DeepLinkService
@riverpod
DeepLinkService deepLinkService(Ref ref) {
  return DeepLinkService();
}
