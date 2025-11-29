import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/playlist.dart';
import 'models/track.dart';
import 'ui/home_screen.dart';
import 'ui/playlist_screen.dart';
import 'ui/player_screen.dart';
import 'services/audio_service.dart';

void main() async {
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(PlaylistAdapter());
  Hive.registerAdapter(TrackAdapter());
  
  // Open boxes
  await Hive.openBox<Playlist>('playlists');
  await Hive.openBox<Track>('tracks');
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Playlist App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      themeMode: ThemeMode.system,
      home: AudioServiceWidget(
        child: HomeScreen(),
      ),
    );
  }
}