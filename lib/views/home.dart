import 'dart:io';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';
import 'package:project_luna/views/article_page.dart';
import 'package:project_luna/views/settings_page.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(
  const MaterialApp(debugShowCheckedModeBanner: false, home: HomePage()),
);

const lunajs = "https://luna-proxy.lunajs.workers.dev/search";

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
  String? errorMessage;
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
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
        '$lunajs?path=search&query=section=$section&page-size=20&show-fields=thumbnail',
      );
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception("HTTP ${response.statusCode}: ${response.body}");
      }

      final data = json.decode(utf8.decode(response.bodyBytes));
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsPage()),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle, style: TextStyle(fontWeight: FontWeight.w600)),
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
                      onTap: () {
                        if (Platform.isAndroid) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ArticleDetailPage(article: article),
                            ),
                          );
                        } else {
                          final Uri url = Uri.parse(article['webUrl']);
                          launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          ).catchError((error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not open article: $error'),
                              ),
                            );
                          });
                        }
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
    );
  }
}
