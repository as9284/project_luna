import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';
import 'package:project_luna/views/article_page.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  int currentPage = 1;
  bool hasMore = true;
  final unescape = HtmlUnescape();

  final List<Map<String, dynamic>> menuItems = [
    {'title': 'World News', 'icon': Symbols.globe, 'query': 'world'},
    {'title': 'US News', 'icon': Symbols.flag_rounded, 'query': 'us'},
    {'title': 'Politics', 'icon': Symbols.podium_rounded, 'query': 'politics'},
    {'divider': true},
    {'title': 'Technology', 'icon': Symbols.computer, 'query': 'technology'},
    {'title': 'Science', 'icon': Symbols.science, 'query': 'science'},
    {
      'title': 'Environment',
      'icon': Symbols.eco_rounded,
      'query': 'environment',
    },
    {'title': 'Video Games', 'icon': Symbols.games, 'query': 'games'},
    {'title': 'Business', 'icon': Symbols.business_center, 'query': 'business'},
    {'divider': true},
    {'title': 'Settings', 'icon': Symbols.settings, 'query': 'settings'},
  ];

  @override
  void initState() {
    super.initState();
    fetchArticles('world');
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        if (!isLoading && hasMore && pageTitle != 'Settings') {
          final item =
              menuItems
                  .where((e) => !e.containsKey('divider'))
                  .toList()[selectedIndex];
          fetchArticles(item['query'], append: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchArticles(String query, {bool append = false}) async {
    if (!append) {
      setState(() {
        isLoading = true;
        articles = [];
        currentPage = 1;
        hasMore = true;
        errorMessage = null;
      });
    } else {
      setState(() {
        errorMessage = null;
      });
    }

    try {
      final url = Uri.parse(
        '$lunajs?path=search&query=q=$query&page=$currentPage&page-size=10&show-fields=thumbnail',
      );
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception("HTTP ${response.statusCode}: ${response.body}");
      }

      final data = json.decode(utf8.decode(response.bodyBytes));
      final newArticles = data['response']?['results'] ?? [];

      // Sort by most recent date
      newArticles.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['webPublicationDate'] ?? '') ?? DateTime(0);
        final dateB =
            DateTime.tryParse(b['webPublicationDate'] ?? '') ?? DateTime(0);
        return dateB.compareTo(dateA);
      });

      setState(() {
        if (append) {
          articles.addAll(newArticles);
        } else {
          articles = newArticles;
        }
        hasMore = newArticles.length >= 10;
        currentPage++;
      });
    } catch (e) {
      debugPrint("Error fetching articles: $e");
      if (!append) {
        setState(() {
          errorMessage = "Failed to load articles. Please try again.";
        });
      }
    } finally {
      if (!append) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void handleDrawerTap(int index) {
    final item =
        menuItems.where((e) => !e.containsKey('divider')).toList()[index];
    Navigator.pop(context);

    if (selectedIndex != index) {
      setState(() {
        selectedIndex = index;
        pageTitle = item['title'];
        _searchTerm = '';
        _searchController.clear();
        _scrollController.jumpTo(0);
      });
    }

    if (item['query'] != 'settings') {
      fetchArticles(item['query']);
    } else {
      setState(() {
        articles = [];
      });
    }
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
        title: Text(pageTitle),
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
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search articles...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchTerm = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final filteredArticles =
                            articles.where((article) {
                              final title =
                                  article['webTitle']
                                      ?.toString()
                                      .toLowerCase() ??
                                  '';
                              return title.contains(_searchTerm.toLowerCase());
                            }).toList();

                        if (filteredArticles.isEmpty) {
                          return const Center(
                            child: Text("No articles found."),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          itemCount:
                              filteredArticles.length + (hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= filteredArticles.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final article = filteredArticles[index];
                            final title = unescape.convert(
                              article['webTitle'] ?? "No Title",
                            );
                            final date = article['webPublicationDate'] ?? '';
                            final thumbnail = article['fields']?['thumbnail'];

                            return Card(
                              margin: const EdgeInsets.all(12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  if (Platform.isAndroid) {
                                    // Use WebView on Android
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => ArticleDetailPage(
                                              article: article,
                                            ),
                                      ),
                                    );
                                  } else {
                                    // Launch URL externally on other platforms
                                    final Uri url = Uri.parse(
                                      article['webUrl'],
                                    );
                                    launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                    ).catchError((error) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not open article: ${error}',
                                          ),
                                        ),
                                      );
                                    });
                                  }
                                },
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(formatDate(date)),
                                  leading:
                                      thumbnail != null
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              thumbnail,
                                              width: 80,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                          : null,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
