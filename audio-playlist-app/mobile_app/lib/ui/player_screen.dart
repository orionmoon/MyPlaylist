import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class PlayerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Now Playing'),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StreamBuilder<MediaItem?>(
                stream: AudioService.currentMediaItemStream,
                builder: (context, snapshot) {
                  final mediaItem = snapshot.data;
                  return Text(
                    mediaItem?.title ?? 'No track playing',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  );
                },
              ),
              SizedBox(height: 20),
              StreamBuilder<Duration>(
                stream: AudioService.positionStream,
                builder: (context, snapshot) {
                  final duration = snapshot.data ?? Duration.zero;
                  return Text(
                    '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 16),
                  );
                },
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StreamBuilder<PlaybackState>(
                    stream: AudioService.playbackStateStream,
                    builder: (context, snapshot) {
                      final state = snapshot.data;
                      final playing = state?.playing ?? false;
                      return IconButton(
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                        iconSize: 64.0,
                        onPressed: () {
                          if (playing) {
                            AudioService.pause();
                          } else {
                            AudioService.play();
                          }
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.stop),
                    iconSize: 64.0,
                    onPressed: AudioService.stop,
                  ),
                ],
              ),
              SizedBox(height: 20),
              StreamBuilder<Duration?>(
                stream: AudioService.currentMediaItemStream
                    .map((item) => item?.duration)
                    .distinct(),
                builder: (context, snapshot) {
                  final duration = snapshot.data ?? Duration.zero;
                  return StreamBuilder<Duration>(
                    stream: AudioService.positionStream,
                    builder: (context, positionSnapshot) {
                      final position = positionSnapshot.data ?? Duration.zero;
                      return Column(
                        children: [
                          Slider(
                            value: position.inMilliseconds.toDouble(),
                            max: duration.inMilliseconds.toDouble(),
                            onChanged: (value) {
                              AudioService.seek(
                                Duration(milliseconds: value.toInt()),
                              );
                            },
                          ),
                          Text(
                            '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')} / ${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}