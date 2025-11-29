import 'package:hive/hive.dart';
import 'track.dart';

part 'playlist.g.dart';

@HiveType(typeId: 0)
class Playlist {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  List<String> trackIds;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.trackIds = const [],
  });
}