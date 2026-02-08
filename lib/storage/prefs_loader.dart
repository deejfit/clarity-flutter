import 'dart:async';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Timeout for the first SharedPreferences connection on iOS.
const Duration _kPrefsTimeout = Duration(seconds: 5);

/// Returns [SharedPreferences] with timeout and error handling.
/// On channel-error or timeout, returns null so callers can use in-memory fallback.
Future<SharedPreferences?> getSharedPreferencesSafe() async {
  try {
    return await SharedPreferences.getInstance().timeout(
      _kPrefsTimeout,
      onTimeout: () => throw TimeoutException('SharedPreferences.getInstance timed out'),
    );
  } on PlatformException catch (_) {
    return null;
  } on TimeoutException catch (_) {
    return null;
  }
}
