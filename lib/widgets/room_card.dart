import 'dart:io';

import 'package:flutter/material.dart';
import '../models/room.dart';
import '../screens/room_detail_page.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  const RoomCard({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    Widget leading;
    if (room.images != null && room.images!.isNotEmpty) {
      final first = room.images!.first;
      if (first.startsWith('http')) {
        leading = Image.network(
          first,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        );
      } else {
        final f = File(first);
        leading = f.existsSync()
            ? Image.file(f, width: 60, height: 60, fit: BoxFit.cover)
            : const Icon(Icons.home, size: 40);
      }
    } else {
      leading = const Icon(Icons.home, size: 40);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        leading: leading,
        title: Text(room.title),
        subtitle: Text('රු. ${room.price} / month'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => RoomDetailPage(room: room))),
      ),
    );
  }
}
