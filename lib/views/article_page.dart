import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';

class ArticleDetailPage extends StatelessWidget {
  final Map articleContent;

  const ArticleDetailPage({super.key, required this.articleContent});

  String formatDate(String rawDate) {
    try {
      final parsed = DateTime.parse(rawDate).toLocal();
      return DateFormat('MMM d, y - h:mm a').format(parsed);
    } catch (_) {
      return rawDate;
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
      appBar: AppBar(title: const Text("Go back")),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
            Html(data: rawBody),
          ],
        ),
      ),
    );
  }
}
