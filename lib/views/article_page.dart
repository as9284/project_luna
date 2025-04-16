import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ArticleDetailPage extends StatefulWidget {
  final Map article;

  const ArticleDetailPage({super.key, required this.article});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  late final WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Only initialize WebView on Android
    if (Platform.isAndroid) {
      _controller =
          WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageFinished: (_) {
                  setState(() => _isLoading = false);
                },
              ),
            )
            ..loadRequest(Uri.parse(widget.article['webUrl']));
    } else {
      _controller = null;
      // Launch URL externally for non-Android platforms
      _launchUrl(widget.article['webUrl']);
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!Platform.isAndroid) {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // Go back after launching URL externally
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Show error if URL can't be launched
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open article: $url')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // For non-Android platforms, show a loading screen until the external browser is launched
    if (!Platform.isAndroid) {
      return Scaffold(
        appBar: AppBar(title: const Text("Luna")),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Opening article in browser..."),
            ],
          ),
        ),
      );
    }

    // For Android, show the WebView
    return Scaffold(
      appBar: AppBar(title: const Text("Luna")),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller!),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
