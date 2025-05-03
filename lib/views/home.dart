import 'dart:ui'; // Import for ImageFilter
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';
import 'article_page.dart';

void main() => runApp(
  const MaterialApp(debugShowCheckedModeBanner: false, home: HomePage()),
);

const lunajs = "https://luna-proxy.lunajs.workers.dev";

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String pageTitle = "World News";
  int selectedIndex = 0;
  List articles = [];
  bool isLoading = false;
  bool isArticleLoading = false;
  String? errorMessage;
  final ScrollController _scrollController = ScrollController();
  final unescape = HtmlUnescape();

  final List<Map<String, dynamic>> menuItems = [
    {'title': 'World News', 'icon': Symbols.globe, 'section': 'world'},
    {'title': 'US News', 'icon': Symbols.flag_rounded, 'section': 'us-news'},
    {
      'title': 'Politics',
      'icon': Symbols.podium_rounded,
      'section': 'politics',
    },
    {'divider': true},
    {'title': 'Technology', 'icon': Symbols.computer, 'section': 'technology'},
    {'title': 'Science', 'icon': Symbols.science, 'section': 'science'},
    {
      'title': 'Environment',
      'icon': Symbols.eco_rounded,
      'section': 'environment',
    },
    {'title': 'Video Games', 'icon': Symbols.games, 'section': 'games'},
    {
      'title': 'Business',
      'icon': Symbols.business_center,
      'section': 'business',
    },
    {'divider': true},
    {'title': 'Settings', 'icon': Symbols.settings, 'isSettings': true},
  ];

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
        '$lunajs/?path=search&query=section=$section&page-size=20&show-fields=thumbnail',
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

  String formatDate(String rawDate) {
    try {
      final parsed = DateTime.parse(rawDate).toLocal();
      return DateFormat('MMM d, y – h:mm a').format(parsed);
    } catch (_) {
      return rawDate;
    }
  }

  Future<void> _loadArticleContent(String articleId) async {
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
    return Scaffold(
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
      body: Stack(
        children: [
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

                  return Card(
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
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final articleId = article['id'];
                        _loadArticleContent(articleId);
                      },
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(formatDate(date)),
                      ),
                    ),
                  );
                },
              ),
          if (isArticleLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: const CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
