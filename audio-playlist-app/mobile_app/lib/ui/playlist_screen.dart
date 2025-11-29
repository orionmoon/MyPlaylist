import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../services/audio_service.dart';
import 'player_screen.dart';

class PlaylistScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistScreen({Key? key, required this.playlist}) : super(key: key);

  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _addTrackToPlaylist(context);
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Track>('tracks').listenable(),
        builder: (context, box, widget) {
          final tracks = box.values.where((track) => track.playlistId == widget.playlist.id).toList();
          return ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return Card(
                child: ListTile(
                  title: Text(track.title),
                  subtitle: Text(
                    track.sourceType.toString().split('.').last,
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: track.isCompleted 
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : (track.lastPositionMs != null && track.lastPositionMs! > 0)
                          ? Text(
                              '${Duration(milliseconds: track.lastPositionMs!).inMinutes}:${(Duration(milliseconds: track.lastPositionMs!).inSeconds % 60).toString().padLeft(2, '0')}',
                              style: TextStyle(color: Colors.blue),
                            )
                          : null,
                  onTap: () {
                    // Start playing this track
                    final audioHandler = AudioService.current;
                    audioHandler.stop();
                    audioHandler.addTrackToQueue(track);
                    audioHandler.playMediaItem(audioHandler.queue.value![0]);
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(),
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

  void _addTrackToPlaylist(BuildContext context) {
    String sourceUrl = '';
    bool isUrl = true;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Track to Playlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(hintText: 'Enter URL or select file'),
                onChanged: (value) => sourceUrl = value,
              ),
              Row(
                children: [
                  Radio(
                    value: true,
                    groupValue: isUrl,
                    onChanged: (bool? value) {
                      setState(() {
                        isUrl = value ?? true;
                      });
                    },
                  ),
                  Text('URL'),
                  Radio(
                    value: false,
                    groupValue: isUrl,
                    onChanged: (bool? value) {
                      setState(() {
                        isUrl = !(value ?? false);
                      });
                    },
                  ),
                  Text('Local File'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () async {
                if (sourceUrl.isNotEmpty) {
                  if (isUrl) {
                    // Extract audio from URL using backend
                    final audioHandler = AudioService.current;
                    final result = await audioHandler.extractAudioFromUrl(sourceUrl);
                    
                    if (result != null) {
                      final track = Track(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        playlistId: widget.playlist.id,
                        title: result['title'] ?? 'Unknown Title',
                        sourceType: SourceType.extracted,
                        sourcePath: result['audio_url'],
                        durationSeconds: result['duration'],
                        addedAt: DateTime.now(),
                      );
                      
                      Hive.box<Track>('tracks').put(track.id, track);
                      Navigator.of(context).pop();
                    } else {
                      // Handle error
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to extract audio from URL')),
                      );
                    }
                  } else {
                    // For local file, we would use file_picker package
                    // This is a simplified implementation
                    final track = Track(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      playlistId: widget.playlist.id,
                      title: 'Local File',
                      sourceType: SourceType.localFile,
                      sourcePath: sourceUrl,
                      addedAt: DateTime.now(),
                    );
                    
                    Hive.box<Track>('tracks').put(track.id, track);
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}