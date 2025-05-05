import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luna/utils/constants.dart';
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

  bool isLoading = false;
  bool isArticleLoading = false;
  List<dynamic> articles = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCachedArticles();
  }

  Future<void> _loadCachedArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cached_articles_world');
    final cachedTime = prefs.getInt('cached_articles_world_timestamp');
    final now = DateTime.now().millisecondsSinceEpoch;

    var cacheTTL = Duration(hours: 1).inMilliseconds;

    if (cachedData != null &&
        cachedTime != null &&
        (now - cachedTime) < cacheTTL) {
      final List<dynamic> cachedArticles = jsonDecode(cachedData);
      setState(() {
        articles = cachedArticles;
      });
    }

    await fetchArticles('world');
  }

  Future<void> _cacheArticles(String section, List<dynamic> articles) async {
    final prefs = await SharedPreferences.getInstance();
    final timestampKey = 'cached_articles_${section}_timestamp';

    await prefs.setString('cached_articles_$section', jsonEncode(articles));
    await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
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

      await _cacheArticles(section, newArticles);
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

  Future<void> _loadArticleContent(String articleId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedContentStr = prefs.getString('article_$articleId');

    Map? cachedContent;
    if (cachedContentStr != null) {
      cachedContent = jsonDecode(cachedContentStr);
      final fields = cachedContent?['fields'] ?? {};
      final hasThumbnail = fields['thumbnail'] != null;

      if (hasThumbnail) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailPage(articleContent: cachedContent!),
          ),
        );
        return;
      }
    }

    setState(() {
      isArticleLoading = true;
    });

    final Uri contentUrl = Uri.parse(
      '$lunajs/?path=$articleId&query=show-fields=body,headline,byline,thumbnail',
    );

    try {
      final response = await http.get(contentUrl);

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final contentData = json.decode(decoded);
        final content = contentData['response']['content'];

        await prefs.setString('article_$articleId', jsonEncode(content));

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailPage(articleContent: content),
          ),
        );
      } else {
        throw Exception('Failed to load article content.');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load article: $e')));
    } finally {
      setState(() {
        isArticleLoading = false;
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

    setState(() {
      selectedIndex = index;
      pageTitle = item['title'];
      _scrollController.jumpTo(0);
    });

    fetchArticles(item['section']);
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
                  : RefreshIndicator(
                    onRefresh: () async {
                      final section =
                          menuItems
                              .where((e) => !e.containsKey('divider'))
                              .toList()[selectedIndex]['section'];
                      await fetchArticles(section);
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: articles.length,
                      itemBuilder: (context, index) {
                        final article = articles[index];
                        final title = unescape.convert(
                          article['webTitle'] ?? "No Title",
                        );
                        final date = article['webPublicationDate'] ?? '';

                        return MouseRegion(
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              mouseCursor: SystemMouseCursors.click,
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                final articleId = article['id'];
                                await _loadArticleContent(articleId);
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
