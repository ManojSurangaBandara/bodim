import 'package:hive/hive.dart';

part 'room.g.dart';

@HiveType(typeId: 1)
class Room extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String price;

  // store local file paths or network URLs
  @HiveField(2)
  final List<String>? images;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final String? contact;

  @HiveField(5)
  final String? creatorEmail;

  @HiveField(6)
  final DateTime? createdAt;

  Room({
    required this.title,
    required this.price,
    this.images,
    this.description,
    this.contact,
    this.creatorEmail,
    this.createdAt,
  });
}