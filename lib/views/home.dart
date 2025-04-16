import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Luna"),
        leading: Builder(
          builder: (context) {
            return IconButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: Icon(Icons.menu),
            );
          },
        ),
      ),
      drawer: NavigationDrawer(
        selectedIndex: 0,
        onDestinationSelected: (int index) {
          switch (index) {
            case 0:
              Navigator.pop(context);
              break;
            case 1:
              // Navigate to settings
              break;
            case 2:
              // Navigate to about
              break;
            case 3:
              // Logout logic
              break;
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Luna',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          NavigationDrawerDestination(
            icon: Icon(Symbols.globe),
            label: Text('World News'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Symbols.flag_rounded),
            label: Text('US News'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Symbols.podium_rounded),
            label: Text('Politics'),
          ),

          Divider(),

          NavigationDrawerDestination(
            icon: Icon(Symbols.computer),
            label: Text('Technology'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Symbols.science),
            label: Text('Science'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Symbols.eco_rounded),
            label: Text('Environment'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Symbols.games),
            label: Text('Video Games'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Symbols.business_center),
            label: Text('Business'),
          ),

          Divider(),

          NavigationDrawerDestination(
            icon: Icon(Symbols.settings),
            label: Text('Settings'),
          ),
        ],
      ),
    );
  }
}
