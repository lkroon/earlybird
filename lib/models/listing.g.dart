// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listing.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ListingAdapter extends TypeAdapter<Listing> {
  @override
  final int typeId = 0;

  @override
  Listing read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Listing(
      title: fields[0] as String,
      content: fields[1] as String,
      url: fields[2] as String,
      imageUrls: (fields[3] as List).cast<String>(),
      firstSeenAt: fields[4] as DateTime?,
      lastSeenAt: fields[5] as DateTime?,
      isViewed: fields[6] as bool,
      filterKey: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Listing obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.imageUrls)
      ..writeByte(4)
      ..write(obj.firstSeenAt)
      ..writeByte(5)
      ..write(obj.lastSeenAt)
      ..writeByte(6)
      ..write(obj.isViewed)
      ..writeByte(7)
      ..write(obj.filterKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
