import 'package:package_info_plus/package_info_plus.dart';

/// Provides app version and build number from platform metadata.
/// Never throws; returns fallback on unsupported platforms or errors.
abstract class AppInfoService {
  Future<String> getVersion();
  Future<String> getBuildNumber();
  /// Format: "version (build)" e.g. "1.0.3 (42)"
  Future<String> getVersionAndBuild();
}

class AppInfoServiceImpl implements AppInfoService {
  PackageInfo? _cached;
  bool _failed = false;

  Future<PackageInfo?> get _info async {
    if (_cached != null) return _cached;
    if (_failed) return null;
    try {
      _cached = await PackageInfo.fromPlatform();
      return _cached;
    } catch (_) {
      _failed = true;
      return null;
    }
  }

  @override
  Future<String> getVersion() async {
    final info = await _info;
    return info?.version ?? '—';
  }

  @override
  Future<String> getBuildNumber() async {
    final info = await _info;
    return info?.buildNumber ?? '—';
  }

  @override
  Future<String> getVersionAndBuild() async {
    final info = await _info;
    if (info == null) return '—';
    return '${info.version} (${info.buildNumber})';
  }
}
