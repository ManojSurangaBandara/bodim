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
    return Room(
      title: fields[0] as String,
      price: fields[1] as String,
      images: (fields[2] as List?)?.cast<String>(),
      description: fields[3] as String?,
      contact: fields[4] as String?,
      creatorEmail: fields[5] as String?,
      createdAt: fields[6] as DateTime?,
      district: fields[7] as String?,
      town: fields[8] as String?,
      status: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Room obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.price)
      ..writeByte(2)
      ..write(obj.images)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.contact)
      ..writeByte(5)
      ..write(obj.creatorEmail)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.district)
      ..writeByte(8)
      ..write(obj.town)
      ..writeByte(9)
      ..write(obj.status);
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
