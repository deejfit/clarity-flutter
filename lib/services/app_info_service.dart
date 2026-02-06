import 'package:package_info_plus/package_info_plus.dart';

/// Provides app version and build number from platform metadata.
abstract class AppInfoService {
  Future<String> getVersion();
  Future<String> getBuildNumber();
  /// Format: "version (build)"
  Future<String> getVersionAndBuild();
}

class AppInfoServiceImpl implements AppInfoService {
  PackageInfo? _cached;

  Future<PackageInfo> get _info async {
    _cached ??= await PackageInfo.fromPlatform();
    return _cached!;
  }

  @override
  Future<String> getVersion() async => (await _info).version;

  @override
  Future<String> getBuildNumber() async => (await _info).buildNumber;

  @override
  Future<String> getVersionAndBuild() async {
    final info = await _info;
    return '${info.version} (${info.buildNumber})';
  }
}
