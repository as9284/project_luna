import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  static const _repoOwner = 'as9284';
  static const _repoName = 'project_luna';

  static Future<String?> getLatestVersion() async {
    final url = Uri.parse(
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['tag_name']?.replaceFirst('v', '');
    } else {
      return null;
    }
  }

  static Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  static Future<bool> isUpdateAvailable() async {
    final latest = await getLatestVersion();
    final current = await getCurrentVersion();
    if (latest == null) return false;

    return _compareVersions(latest, current) > 0;
  }

  // Basic version comparison
  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();
    for (var i = 0; i < parts1.length; i++) {
      if (parts1[i] > parts2[i]) return 1;
      if (parts1[i] < parts2[i]) return -1;
    }
    return 0;
  }
}
