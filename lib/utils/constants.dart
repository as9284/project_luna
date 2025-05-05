import 'package:material_symbols_icons/material_symbols_icons.dart';

const lunajs = "https://luna-proxy.lunajs.workers.dev";

String pageTitle = "World News";
int selectedIndex = 0;
List articles = [];
bool isLoading = false;
bool isArticleLoading = false;
String? errorMessage;

final List<Map<String, dynamic>> menuItems = [
  {'title': 'World News', 'icon': Symbols.globe, 'section': 'world'},
  {'title': 'US News', 'icon': Symbols.flag_rounded, 'section': 'us-news'},
  {'title': 'Politics', 'icon': Symbols.podium_rounded, 'section': 'politics'},
  {'divider': true},
  {'title': 'Technology', 'icon': Symbols.computer, 'section': 'technology'},
  {'title': 'Science', 'icon': Symbols.science, 'section': 'science'},
  {
    'title': 'Environment',
    'icon': Symbols.eco_rounded,
    'section': 'environment',
  },
  {'title': 'Video Games', 'icon': Symbols.games, 'section': 'games'},
  {'title': 'Business', 'icon': Symbols.business_center, 'section': 'business'},
  {'divider': true},
  {'title': 'Settings', 'icon': Symbols.settings, 'isSettings': true},
];
