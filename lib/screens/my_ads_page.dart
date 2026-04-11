import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../widgets/room_card.dart';

class MyAdsPage extends StatelessWidget {
  const MyAdsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.home_work,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'My Ads',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
            stops: [0.0, 1.0],
          ),
        ),
        child: ValueListenableBuilder(
          valueListenable: AppState.instance.rooms,
          builder: (context, rooms, child) {
            final user = AppState.instance.currentUser.value;
            if (user == null) {
              return const Center(
                child: Card(
                  margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Please login to view your ads.'),
                  ),
                ),
              );
            }

            final myRooms = List.of(rooms.cast().where(
              (room) => room.creatorEmail == user.email,
            ));

            if (myRooms.isEmpty) {
              return const Center(
                child: Card(
                  margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('You have not posted any ads yet.'),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: myRooms.length,
              itemBuilder: (context, index) {
                final room = myRooms[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RoomCard(
                    room: room,
                    hideDetailsOnPendingRejected: room.status != 'approved',
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
