import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/localization.dart';
import '../screens/add_post_page.dart';
import '../widgets/room_card.dart';
import '../theme.dart';

class MyAdsPage extends StatelessWidget {
  const MyAdsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final grad = Theme.of(context).extension<AppGradients>()!;
    return ValueListenableBuilder<String>(
      valueListenable: AppState.instance.languageCode,
      builder: (context, languageCode, __) {
        String t(String key) => AppLocalizations.translate(languageCode, key);

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
                  t('myAds'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddPostPage()),
              );
            },
            icon: const Icon(Icons.add),
            label: Text(t('createAd')),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [grad.bodyStart, grad.bodyEnd],
                stops: const [0.0, 1.0],
              ),
            ),
            child: ValueListenableBuilder(
              valueListenable: AppState.instance.rooms,
              builder: (context, rooms, child) {
                final user = AppState.instance.currentUser.value;
                if (user == null) {
                  return Center(
                    child: Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(t('pleaseLoginToViewYourAds')),
                      ),
                    ),
                  );
                }

                final myRooms = List.of(rooms.cast().where(
                  (room) => room.creatorEmail == user.email,
                ));

                if (myRooms.isEmpty) {
                  return Center(
                    child: Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(t('noMyAdsYet')),
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
                        hideTitle: true,
                        hideDetailsOnPendingRejected: room.status != 'approved',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
