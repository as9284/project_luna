import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:luna/utils/misc_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class ArticleDetailPage extends StatelessWidget {
  final Map articleContent;

  const ArticleDetailPage({super.key, required this.articleContent});

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

      if (!launched) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      final String fallbackUrl = url;
      if (fallbackUrl.startsWith('https://') ||
          fallbackUrl.startsWith('http://')) {
        try {
          await launchUrl(
            Uri.parse(fallbackUrl),
            mode: LaunchMode.inAppWebView,
          );
        } catch (e2) {
          debugPrint('Fallback launch also failed: $e2');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = articleContent['fields'] ?? {};

    final title = HtmlUnescape().convert(
      fields['headline'] ?? articleContent['webTitle'] ?? "No Title",
    );

    final rawBody = fields['body'] ?? "<p>No content available.</p>";
    final byline = fields['byline'];
    final date = articleContent['webPublicationDate'];

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
              SharePlus.instance.share(
                ShareParams(uri: Uri.parse(articleContent['webUrl'])),
              );
            },
          ),
        ],
        actionsPadding: EdgeInsets.only(right: 16),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: ListView(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (byline != null) ...[
              const SizedBox(height: 8),
              Text(byline, style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 8),
            if (date != null)
              Text(
                formatDate(date),
                style: const TextStyle(color: Colors.grey),
              ),
            const Divider(height: 32),
            Html(
              data: rawBody,
              onLinkTap: (url, _, __) async {
                if (url != null) {
                  await _launchUrl(url);
                }
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
                  builder: (extensionContext) {
                    final src = extensionContext.attributes['src'];
                    if (src != null) {
                      return Image.network(src);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
