import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/user.dart';
import '../models/room.dart';

class AppState {
  AppState._internal();
  static final AppState instance = AppState._internal();

  final ValueNotifier<User?> currentUser = ValueNotifier<User?>(null);
  final ValueNotifier<List<Room>> rooms = ValueNotifier<List<Room>>([]);
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

  // in-memory mirror of registered users (backed by Hive box)
  final List<User> registered = [];

  // Call from main before runApp
  Future<void> init() async {
    final usersBox = Hive.box<User>('users');
    final roomsBox = Hive.box<Room>('rooms');
    final appBox = Hive.box('app');

    // load users
    registered.clear();
    registered.addAll(usersBox.values.toList());

    // load rooms into notifier
    rooms.value = roomsBox.values.toList();

    // load current user if any
    final currentEmail = appBox.get('currentUserEmail') as String?;
    if (currentEmail != null) {
      try {
        final u = registered.firstWhere((u) => u.email == currentEmail);
        currentUser.value = u;
      } catch (_) {
        currentUser.value = null;
      }
    }

    // load persisted theme mode if any (only 'light'|'dark' supported now)
    final storedTheme = appBox.get('themeMode') as String?;
    if (storedTheme == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.light;
    }

    // listen to Hive changes and keep notifier in sync
    roomsBox.watch().listen((event) {
      rooms.value = roomsBox.values.toList();
    });
  }

  bool login(String email, String password) {
    try {
      final user = registered.firstWhere(
        (u) => u.email == email && u.password == password,
      );
      currentUser.value = user;
      Hive.box('app').put('currentUserEmail', user.email);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool register(String email, String password) {
    if (registered.any((u) => u.email == email)) return false;
    final u = User(email, password: password);
    // persist
    Hive.box<User>('users').put(email, u);
    registered.add(u);
    currentUser.value = u;
    Hive.box('app').put('currentUserEmail', u.email);
    return true;
  }

  void logout() {
    currentUser.value = null;
    Hive.box('app').delete('currentUserEmail');
  }

  void addRoom(Room room) {
    Hive.box<Room>('rooms').add(room);
    // rooms notifier will update via the box watcher
  }

  void deleteRoom(Room room) {
    final user = currentUser.value;
    if (user == null || room.creatorEmail != user.email) {
      // not logged in or not the creator
      return;
    }
    final index = rooms.value.indexOf(room);
    if (index != -1) {
      Hive.box<Room>('rooms').deleteAt(index);
      // rooms notifier will update via the box watcher
    }
  }

  void updateRoom(Room oldRoom, Room newRoom) {
    final user = currentUser.value;
    if (user == null || oldRoom.creatorEmail != user.email) {
      // not logged in or not the creator
      return;
    }
    final index = rooms.value.indexOf(oldRoom);
    if (index != -1) {
      Hive.box<Room>('rooms').putAt(index, newRoom);
      // rooms notifier will update via the box watcher
    }
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    final appBox = Hive.box('app');
    final s = mode == ThemeMode.dark ? 'dark' : 'light';
    appBox.put('themeMode', s);
  }

  /// Cycle theme mode: Light <-> Dark
  void cycleThemeMode() {
    final current = themeMode.value;
    final next = (current == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(next);
  }
}
