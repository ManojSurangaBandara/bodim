import 'package:cloud_firestore/cloud_firestore.dart';

class SavedAlert {
  final String? id;
  final String userId;
  final String fcmToken;
  final String? district;
  final String? town;
  final String? category;
  final int? minPrice;
  final int? maxPrice;
  final DateTime createdAt;
  final String name;

  const SavedAlert({
    this.id,
    required this.userId,
    required this.fcmToken,
    this.district,
    this.town,
    this.category,
    this.minPrice,
    this.maxPrice,
    required this.createdAt,
    required this.name,
  });

  factory SavedAlert.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return SavedAlert(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      fcmToken: d['fcmToken'] as String? ?? '',
      district: d['district'] as String?,
      town: d['town'] as String?,
      category: d['category'] as String?,
      minPrice: (d['minPrice'] as num?)?.toInt(),
      maxPrice: (d['maxPrice'] as num?)?.toInt(),
      createdAt: d['createdAt'] is Timestamp
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(d['createdAt']?.toString() ?? '') ??
                DateTime.now(),
      name: d['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'fcmToken': fcmToken,
    'district': district,
    'town': town,
    'category': category,
    'minPrice': minPrice,
    'maxPrice': maxPrice,
    'createdAt': FieldValue.serverTimestamp(),
    'name': name,
  };

  /// Builds an auto-generated human-readable name from active filter fields.
  static String buildName(
    String? district,
    String? town,
    String? category,
    int? minPrice,
    int? maxPrice,
  ) {
    final parts = <String>[];
    if (town != null) {
      parts.add(town);
    } else if (district != null) {
      parts.add(district);
    }
    if (category != null) parts.add(category);
    if (minPrice != null && maxPrice != null) {
      parts.add('රු.$minPrice–$maxPrice');
    } else if (minPrice != null) {
      parts.add('රු.>$minPrice');
    } else if (maxPrice != null) {
      parts.add('රු.<$maxPrice');
    }
    return parts.isNotEmpty ? parts.join(' · ') : 'All Ads';
  }
}
