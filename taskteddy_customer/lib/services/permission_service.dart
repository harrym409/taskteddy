import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestStartupPermissions() async {
    if (kIsWeb) return;
    
    final permissions = <Permission>[
      Permission.locationWhenInUse,
      Permission.camera,
      Permission.photos,
      if (Platform.isAndroid) ...[
        Permission.storage,
        Permission.notification,
      ],
    ];

    for (final permission in permissions) {
      final status = await permission.status;
      if (status.isGranted || status.isLimited) continue;
      await permission.request();
    }
  }
}
