import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:luna/utils/misc_functions.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../utils/constants.dart';

class ArticleDetailPage extends StatefulWidget {
  final Map articleContent;

  const ArticleDetailPage({super.key, required this.articleContent});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  late Map content;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    content = widget.articleContent;
  }

  Future<void> _refreshArticle() async {
    setState(() {
      isRefreshing = true;
    });

    final articleId = content['id'];
    final Uri contentUrl = Uri.parse(
      '$lunajs/?path=$articleId&query=show-fields=body,headline,byline',
    );

    try {
      final response = await http.get(contentUrl);
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final contentData = json.decode(decoded);
        final updatedContent = contentData['response']['content'];

        setState(() {
          content = updatedContent;
        });
      } else {
        throw Exception('Failed to refresh article.');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Refresh failed: $e")));
    } finally {
      setState(() {
        isRefreshing = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      if (!launched) debugPrint('Could not launch $url');
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = content['fields'] ?? {};
    final title = HtmlUnescape().convert(
      fields['headline'] ?? content['webTitle'] ?? "No Title",
    );
    final rawBody = fields['body'] ?? "<p>No content available.</p>";
    final byline = fields['byline'];
    final date = content['webPublicationDate'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Go back",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
                Clipboard.setData(ClipboardData(text: content['webUrl']));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Link copied to clipboard")),
                );
              } else {
                SharePlus.instance.share(
                  ShareParams(uri: Uri.parse(content['webUrl'])),
                );
              }
            },
          ),
        ],
        actionsPadding: const EdgeInsets.only(right: 16),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshArticle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (byline != null) ...[
                const SizedBox(height: 8),
                Text(
                  byline,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 8),
              if (date != null)
                Text(
                  formatDate(date),
                  style: const TextStyle(color: Colors.grey),
                ),
              const Divider(height: 20),
              Html(
                data: rawBody,
                onLinkTap: (url, _, __) async {
                  if (url != null) await _launchUrl(url);
                },
                style: {
                  "a": Style(
                    textDecoration: TextDecoration.none,
                    color: const Color.fromARGB(255, 75, 174, 255),
                  ),
                },
                extensions: [
                  TagExtension(
                    tagsToExtend: {"img"},
                    builder: (context) {
                      final src = context.attributes['src'];
                      if (src != null) {
                        return Image.network(src);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
