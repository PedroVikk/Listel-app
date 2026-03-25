import 'dart:io';
import 'package:path_provider/path_provider.dart';

class OnboardingService {
  static const _flagFile = '.onboarding_done';

  static Future<bool> hasSeenOnboarding() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/$_flagFile').existsSync();
    } catch (_) {
      return false;
    }
  }

  static Future<void> markSeen() async {
    final dir = await getApplicationDocumentsDirectory();
    await File('${dir.path}/$_flagFile').create();
  }
}
