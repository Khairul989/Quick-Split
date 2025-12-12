import 'package:envied/envied.dart';

part 'app_env_service.g.dart';

/// Centralized access to environment variables (managed by Envied).
///
/// Values are sourced from the root `.env` file.
///
/// Required keys:
/// - GOOGLE_SERVER_CLIENT_ID
@Envied(path: '.env')
abstract class AppEnv {
  @EnviedField(varName: 'GOOGLE_SERVER_CLIENT_ID', obfuscate: true)
  static final String googleServerClientId = _AppEnv.googleServerClientId;
}
