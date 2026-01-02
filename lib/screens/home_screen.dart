import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'clients_screen.dart';
import 'games_screen.dart';
import 'import_export_screen.dart';
import 'results_dashboard_screen.dart';
import 'settings_screen.dart';

import '../services/settings_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.settingsController});

  final SettingsController settingsController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const GamesScreen(),
      const ClientsScreen(),
      ResultsDashboardScreen(controller: widget.settingsController),
      SettingsScreen(controller: widget.settingsController),
      const ImportExportScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForIndex(_index)),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_on), label: 'Games'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Clients'),
          NavigationDestination(icon: Icon(Icons.calculate), label: 'Results'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
          NavigationDestination(icon: Icon(Icons.import_export), label: 'I/O'),
        ],
      ),
    );
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Game Data';
      case 1:
        return 'Client Data';
      case 2:
        return 'Results';
      case 3:
        return 'Settings';
      case 4:
        return 'Import / Export';
      default:
        return 'Track Management';
    }
  }
}
