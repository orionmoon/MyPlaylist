import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/playlist.dart';
import 'playlist_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audio Playlists'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _createNewPlaylist(context);
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Playlist>('playlists').listenable(),
        builder: (context, box, widget) {
          final playlists = box.values.toList();
          return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return Card(
                child: ListTile(
                  title: Text(playlist.name),
                  subtitle: Text(
                    playlist.description ?? 'No description',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text('${playlist.trackIds.length} tracks'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaylistScreen(playlist: playlist),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _createNewPlaylist(BuildContext context) {
    String name = '';
    String description = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Create New Playlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(hintText: 'Playlist Name'),
                onChanged: (value) => name = value,
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(hintText: 'Description (optional)'),
                onChanged: (value) => description = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Create'),
              onPressed: () {
                if (name.isNotEmpty) {
                  final playlist = Playlist(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    description: description.isEmpty ? null : description,
                    createdAt: DateTime.now(),
                  );
                  Hive.box<Playlist>('playlists').put(playlist.id, playlist);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}