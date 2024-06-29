import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'album_screen.dart';
import 'gallery_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gallery App'),
          actions: [
            Switch(
              value: Provider.of<ThemeProvider>(context).isDarkMode,
              onChanged: (value) {
                Provider.of<ThemeProvider>(context, listen: false)
                    .toggleTheme(value);
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Albums'),
              Tab(text: 'All Media'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AlbumScreen(),
            GalleryScreen(),
          ],
        ),
      ),
    );
  }
}
