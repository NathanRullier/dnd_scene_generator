import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles platform permissions (microphone, storage).
class PermissionService {
  /// Requests microphone permission.
  /// Returns true if granted.
  Future<bool> requestMicrophonePermission() async {
    if (Platform.isWindows || Platform.isLinux) {
      return true;
    }

    final status = await Permission.microphone.status;
    if (status.isGranted) return true;

    final result = await Permission.microphone.request();
    debugPrint('[PermissionService] Microphone permission: $result');
    return result.isGranted;
  }

  /// Requests storage permission for saving images (Android).
  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Android 13+ uses granular media permissions
    if (await Permission.photos.status.isGranted) return true;

    final result = await Permission.photos.request();
    return result.isGranted;
  }

  /// Checks all required permissions and returns missing ones.
  Future<List<String>> checkPermissions() async {
    final missing = <String>[];

    if (Platform.isAndroid || Platform.isIOS) {
      if (!(await Permission.microphone.status.isGranted)) {
        missing.add('Microphone');
      }
    }

    return missing;
  }
}
