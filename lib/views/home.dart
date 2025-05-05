import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:luna/utils/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import 'package:luna/utils/misc_functions.dart';
import 'article_page.dart';

void main() => runApp(
  const MaterialApp(debugShowCheckedModeBanner: false, home: HomePage()),
);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final unescape = HtmlUnescape();

  final Map<String, Map> _articleCache = {};

  @override
  void initState() {
    super.initState();
    fetchArticles('world');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchArticles(String section) async {
    setState(() {
      isLoading = true;
      articles = [];
      errorMessage = null;
    });

    try {
      final url = Uri.parse(
        '$lunajs/?path=search&query=section=$section&page-size=20',
      );
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception("HTTP ${response.statusCode}: ${response.body}");
      }

      final decoded = utf8.decode(response.bodyBytes);
      final data = json.decode(decoded);

      final newArticles = data['response']?['results'] ?? [];

      newArticles.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['webPublicationDate'] ?? '') ?? DateTime(0);
        final dateB =
            DateTime.tryParse(b['webPublicationDate'] ?? '') ?? DateTime(0);
        return dateB.compareTo(dateA);
      });

      setState(() {
        articles = newArticles;
      });
    } catch (e) {
      debugPrint("Error fetching articles: $e");
      setState(() {
        errorMessage = "Failed to load articles. Please try again.";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void handleDrawerTap(int index) {
    final item =
        menuItems.where((e) => !e.containsKey('divider')).toList()[index];
    Navigator.pop(context);

    if (item['isSettings'] == true) {
      Navigator.pushNamed(context, "/settings");
      return;
    }

    if (selectedIndex != index) {
      setState(() {
        selectedIndex = index;
        pageTitle = item['title'];
        _scrollController.jumpTo(0);
      });
    }

    fetchArticles(item['section']);
  }

  Future<void> _loadArticleContent(String articleId) async {
    if (_articleCache.containsKey(articleId)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) =>
                  ArticleDetailPage(articleContent: _articleCache[articleId]!),
        ),
      );
      return;
    }

    setState(() {
      isArticleLoading = true;
    });

    final Uri contentUrl = Uri.parse(
      '$lunajs/?path=$articleId&query=show-fields=body,headline,byline',
    );

    try {
      final response = await http.get(contentUrl);

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final contentData = json.decode(decoded);
        final content = contentData['response']['content'];

        _articleCache[articleId] = content;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailPage(articleContent: content),
          ),
        ).then((_) {
          setState(() {
            isArticleLoading = false;
          });
        });
      } else {
        throw Exception('Failed to load article content.');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load article: $e')));

      setState(() {
        isArticleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              pageTitle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            leading: Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),
          ),
          drawer: NavigationDrawer(
            selectedIndex: selectedIndex,
            onDestinationSelected: handleDrawerTap,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Luna',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...menuItems.map<Widget>((item) {
                if (item.containsKey('divider')) return const Divider();
                return NavigationDrawerDestination(
                  icon: Icon(item['icon']),
                  label: Text(item['title']),
                );
              }),
            ],
          ),
          body:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                  ? Center(child: Text(errorMessage!))
                  : articles.isEmpty
                  ? const Center(child: Text("No articles found."))
                  : ListView.builder(
                    controller: _scrollController,
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      final title = unescape.convert(
                        article['webTitle'] ?? "No Title",
                      );
                      final date = article['webPublicationDate'] ?? '';

                      return MouseRegion(
                        child: Card(
                          margin: const EdgeInsets.only(
                            left: 12,
                            right: 12,
                            top: 4,
                            bottom: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            mouseCursor: SystemMouseCursors.click,
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              final articleId = article['id'];
                              _loadArticleContent(articleId);
                            },
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(20),
                              title: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  formatDate(date),
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
        if (isArticleLoading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: Colors.black45,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
      ],
    );
  }
}
