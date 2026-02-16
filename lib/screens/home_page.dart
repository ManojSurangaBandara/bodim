import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../models/room.dart';
import '../widgets/room_card.dart';
import 'login_page.dart';
import 'add_post_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedDistrict;
  String? _selectedTown;

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
                    if (v == 1) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                    } else if (v == 2) {
                      app.logout();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 0, child: Text(user.email)),
                    const PopupMenuItem(value: 1, child: Text('Profile')),
                    const PopupMenuItem(value: 2, child: Text('Logout')),
                  ],
                  icon: const Icon(Icons.account_circle),
                );
              }
            },
          ),
        ],
      ),

      // body: add location filter above the list
      body: ValueListenableBuilder<List>(
        valueListenable: app.rooms,
        builder: (context, rooms, child) {
          final allRooms = List.of(rooms.cast<Room>());

          // compute unique districts and towns
          final districts = {
            for (var r in allRooms)
              if (r.district != null && r.district!.trim().isNotEmpty)
                r.district!,
          }.toList();
          districts.sort();

          final towns = {
            for (var r in allRooms)
              if ((_selectedDistrict == null ||
                      r.district == _selectedDistrict) &&
                  r.town != null &&
                  r.town!.trim().isNotEmpty)
                r.town!,
          }.toList();
          towns.sort();

          // filtered list
          final filtered = allRooms.where((r) {
            if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty) {
              if (r.district != _selectedDistrict) return false;
            }
            if (_selectedTown != null && _selectedTown!.isNotEmpty) {
              if (r.town != _selectedTown) return false;
            }
            return true;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value:
                            (_selectedDistrict != null &&
                                districts.contains(_selectedDistrict))
                            ? _selectedDistrict
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'District',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: ['All', ...districts]
                            .map(
                              (d) => DropdownMenuItem(
                                value: d == 'All' ? null : d,
                                child: Text(d),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedDistrict = v;
                            _selectedTown = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value:
                            (_selectedTown != null &&
                                towns.contains(_selectedTown))
                            ? _selectedTown
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Town',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: ['All', ...towns]
                            .map(
                              (t) => DropdownMenuItem(
                                value: t == 'All' ? null : t,
                                child: Text(t),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedTown = v;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Clear filters',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _selectedDistrict = null;
                          _selectedTown = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('No rooms found for selected location.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return RoomCard(room: filtered[index]);
                        },
                      ),
              ),
            ],
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
