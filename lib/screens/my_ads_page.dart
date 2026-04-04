import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../widgets/room_card.dart';

class MyAdsPage extends StatelessWidget {
  const MyAdsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Ads')),
      body: ValueListenableBuilder(
        valueListenable: AppState.instance.rooms,
        builder: (context, rooms, child) {
          final user = AppState.instance.currentUser.value;
          if (user == null) {
            return const Center(child: Text('Please login to view your ads.'));
          }

          final myRooms = List.of(rooms.cast().where(
            (room) => room.creatorEmail == user.email,
          ));

          if (myRooms.isEmpty) {
            return const Center(child: Text('You have not posted any ads yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: myRooms.length,
            itemBuilder: (context, index) => RoomCard(room: myRooms[index]),
          );
        },
      ),
    );
  }
}
