import 'package:cloud_firestore/cloud_firestore.dart';
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

  @HiveField(7)
  final String? district;

  @HiveField(8)
  final String? town;

  @HiveField(9)
  final String status;

  @HiveField(10)
  final String? rejectionReason;

  final String? id;

  Room({
    required this.title,
    required this.price,
    this.images,
    this.description,
    this.contact,
    this.creatorEmail,
    this.createdAt,
    this.district,
    this.town,
    this.status = 'approved',
    this.rejectionReason,
    this.id,
  });

  factory Room.fromMap(Map<String, dynamic> map, {String? id}) {
    final createdAtField = map['createdAt'];
    DateTime? createdAt;
    if (createdAtField is Timestamp) {
      createdAt = createdAtField.toDate();
    } else if (createdAtField is DateTime) {
      createdAt = createdAtField;
    }

    return Room(
      id: id,
      title: map['title'] as String? ?? '',
      price: map['price'] as String? ?? '',
      images: (map['images'] as List<dynamic>?)?.cast<String>(),
      description: map['description'] as String?,
      contact: map['contact'] as String?,
      creatorEmail: map['creatorEmail'] as String?,
      createdAt: createdAt,
      district: map['district'] as String?,
      town: map['town'] as String?,
      status: map['status'] as String? ?? 'approved',
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'price': price,
      'images': images,
      'description': description,
      'contact': contact,
      'creatorEmail': creatorEmail,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'district': district,
      'town': town,
      'status': status,
      'rejectionReason': rejectionReason,
    };
  }
}
