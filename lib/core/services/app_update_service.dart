import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateInfo {
  final String version;
  final int versionCode;
  final String downloadUrl;
  final String? releaseNotes;

  const UpdateInfo({
    required this.version,
    required this.versionCode,
    required this.downloadUrl,
    this.releaseNotes,
  });
}

class AppUpdateService {
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      final response = await Supabase.instance.client
          .from('app_versions')
          .select()
          .order('version_code', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      final remoteVersionCode = response['version_code'] as int;
      if (remoteVersionCode <= currentBuildNumber) return null;

      return UpdateInfo(
        version: response['version'] as String,
        versionCode: remoteVersionCode,
        downloadUrl: response['download_url'] as String,
        releaseNotes: response['release_notes'] as String?,
      );
    } catch (_) {
      // Falha silenciosa — update check não deve derrubar o app
      return null;
    }
  }
}
