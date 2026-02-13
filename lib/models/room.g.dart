// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoomAdapter extends TypeAdapter<Room> {
  @override
  final int typeId = 1;

  @override
  Room read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    // backward-compatible handling: older records stored a single `String`
    // in field 2 (imageUrl). Coerce that to a List<String> when reading.
    final rawImages = fields[2];
    List<String>? images;
    if (rawImages == null) {
      images = null;
    } else if (rawImages is String) {
      images = [rawImages];
    } else if (rawImages is List) {
      images = rawImages.cast<String>();
    } else {
      images = null;
    }

    return Room(
      title: fields[0] as String,
      price: fields[1] as String,
      images: images,
      description: fields[3] as String?,
      contact: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Room obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.price)
      ..writeByte(2)
      ..write(obj.images)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.contact);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
