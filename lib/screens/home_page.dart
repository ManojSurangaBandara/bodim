import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../widgets/room_card.dart';
import 'login_page.dart';
import 'add_post_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Listings'),
        actions: [
          ValueListenableBuilder(
            valueListenable: app.currentUser,
            builder: (context, user, child) {
              if (user == null) {
                return IconButton(
                  icon: const Icon(Icons.login),
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const LoginPage())),
                  tooltip: 'Login',
                );
              } else {
                return PopupMenuButton<int>(
                  onSelected: (v) {
                    if (v == 1) app.logout();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 0, child: Text(user.email)),
                    const PopupMenuItem(value: 1, child: Text('Logout')),
                  ],
                  icon: const Icon(Icons.account_circle),
                );
              }
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List>(
        valueListenable: app.rooms,
        builder: (context, rooms, child) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              return RoomCard(room: rooms[index]);
            },
          );
        },
      ),
      floatingActionButton: ValueListenableBuilder(
        valueListenable: app.currentUser,
        builder: (context, user, child) {
          if (user == null) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AddPostPage())),
            tooltip: 'Add Post',
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
