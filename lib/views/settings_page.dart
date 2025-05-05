import 'package:flutter/material.dart';
import 'package:luna/utils/update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  final void Function(bool) onThemeChanged;
  final bool isDarkMode;

  const SettingsPage({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _darkMode;

  @override
  void initState() {
    super.initState();
    _darkMode = widget.isDarkMode;
  }

  final Uri _url = Uri.parse('https://github.com/as9284/project_luna');

  Future<void> _launchUrl() async {
    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }

  Future<String> getPackageVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    return packageInfo.version;
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    final isAvailable = await UpdateService.isUpdateAvailable();
    final latestVersion = await UpdateService.getLatestVersion();

    if (!context.mounted) return;

    if (isAvailable) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Update Available"),
              content: Text("A new version ($latestVersion) is available."),
              actions: [
                TextButton(
                  child: const Text("Later"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text("Download"),
                  onPressed: () {
                    launchUrl(
                      Uri.parse(
                        "https://github.com/as9284/project_zero/releases/latest",
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You're on the latest version.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 20, bottom: 10),
                  child: Text(
                    "General Settings",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
                  ),
                ),
                SwitchListTile(
                  title: const Text("Dark Mode"),
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() {
                      _darkMode = value;
                    });
                    widget.onThemeChanged(value);
                  },
                ),

                const Divider(),

                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 20, bottom: 10),
                  child: Text(
                    "About",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
                  ),
                ),
                FutureBuilder<String>(
                  future: getPackageVersion(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text("App Version"),
                        subtitle: const Text("Loading..."),
                      );
                    } else if (snapshot.hasError) {
                      return ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text("App Version"),
                        subtitle: Text("Error: ${snapshot.error}"),
                      );
                    } else {
                      return ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text("App Version"),
                        subtitle: Text(snapshot.data ?? "Unknown"),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text("View Source Code"),
                  onTap: () async {
                    _launchUrl();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.system_update),
                  title: const Text("Check for Updates"),
                  onTap: () => _checkForUpdates(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                "Made with ❤️ by Anthony Saliba",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
