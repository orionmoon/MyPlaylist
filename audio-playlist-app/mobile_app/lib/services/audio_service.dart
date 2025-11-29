import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/track.dart';

class AudioPlayerHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  final _mediaItemExpando = Expando<MediaItem>();

  AudioPlayerHandler() {
    _init();
  }

  Future<void> _init() async {
    // Handle playback events
    _player.playbackEventStream.listen((event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.rewind,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.fastForward,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState],
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });

    // Handle duration changes
    _player.durationStream.listen((duration) {
      var index = queue.value?.indexOf(_mediaItemExpando[_player]);
      if (index != null && index >= 0 && queue.value != null) {
        final oldMediaItem = queue.value![index];
        final newMediaItem = MediaItem(
          id: oldMediaItem.id,
          album: oldMediaItem.album,
          title: oldMediaItem.title,
          duration: duration ?? Duration.zero,
          artUri: oldMediaItem.artUri,
          extras: oldMediaItem.extras,
        );
        queue.value![index] = newMediaItem;
        _mediaItemExpando[_player] = newMediaItem;
      }
    });
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    await _player.setAudioSource(AudioSource.uri(Uri.parse(mediaItem.id)));
    _mediaItemExpando[_player] = mediaItem;
    play();
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
  }

  @override
  Future<void> skipToNext() async {
    // Implement next track logic
  }

  @override
  Future<void> skipToPrevious() async {
    // Implement previous track logic
  }

  Future<void> setQueue(List<MediaItem> queue) async {
    final audioSource = queue.isEmpty
        ? null
        : queue.length == 1
            ? AudioSource.uri(Uri.parse(queue.first.id))
            : ConcatenatingAudioSource(
                children: queue.map((item) => AudioSource.uri(Uri.parse(item.id))).toList(),
              );
    await _player.setAudioSource(audioSource);
    this.queue.value = List<MediaItem>.from(queue);
  }

  Future<void> addTrackToQueue(Track track) async {
    final mediaItem = MediaItem(
      id: track.sourcePath,
      album: 'Playlist',
      title: track.title,
      duration: Duration(seconds: track.durationSeconds ?? 0),
      extras: {
        'trackId': track.id,
        'playlistId': track.playlistId,
        'lastPosition': track.lastPositionMs,
        'isCompleted': track.isCompleted,
      },
    );
    
    if (queue.value == null) {
      queue.value = [mediaItem];
    } else {
      queue.value!.add(mediaItem);
    }
    
    _mediaItemExpando[_player] = mediaItem;
  }

  // Backend API service methods
  Future<Map<String, dynamic>?> extractAudioFromUrl(String url) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/extract'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error extracting audio: $e');
      return null;
    }
  }
}