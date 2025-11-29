import 'package:hive/hive.dart';

part 'track.g.dart';

enum SourceType { localFile, remoteUrl, extracted }

@HiveType(typeId: 1)
class Track {
  @HiveField(0)
  String id;

  @HiveField(1)
  String playlistId;

  @HiveField(2)
  String title;

  @HiveField(3)
  SourceType sourceType;

  @HiveField(4)
  String sourcePath;

  @HiveField(5)
  int? durationSeconds;

  @HiveField(6)
  int? lastPositionMs;

  @HiveField(7)
  bool isCompleted;

  @HiveField(8)
  DateTime addedAt;

  Track({
    required this.id,
    required this.playlistId,
    required this.title,
    required this.sourceType,
    required this.sourcePath,
    this.durationSeconds,
    this.lastPositionMs,
    this.isCompleted = false,
    required this.addedAt,
  });
}