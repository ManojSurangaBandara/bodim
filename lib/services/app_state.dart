import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/room.dart';
import '../models/user.dart';

class AppState {
  AppState._internal();
  static final AppState instance = AppState._internal();

  final ValueNotifier<User?> currentUser = ValueNotifier<User?>(null);
  final ValueNotifier<List<Room>> rooms = ValueNotifier<List<Room>>([]);
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _roomsSub;
  StreamSubscription<fb_auth.User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  Future<void> init() async {
    final appBox = Hive.box('app');

    final storedTheme = appBox.get('themeMode') as String?;
    if (storedTheme == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.light;
    }

    _authSub = _auth.authStateChanges().listen(_handleAuthStateChanged);
    _listenRooms();
  }

  void _handleAuthStateChanged(fb_auth.User? authUser) {
    _profileSub?.cancel();
    if (authUser == null) {
      currentUser.value = null;
      return;
    }

    final profileDoc = _firestore.collection('users').doc(authUser.uid);
    _profileSub = profileDoc.snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data != null) {
        currentUser.value = User(
          authUser.email ?? '',
          name: data['name'] as String?,
          phone: data['phone'] as String?,
        );
      } else {
        final user = User(authUser.email ?? '');
        currentUser.value = user;
        profileDoc.set(
          {
            'email': authUser.email,
            'name': null,
            'phone': null,
          },
          SetOptions(merge: true),
        );
      }
    }, onError: (_) {
      currentUser.value = User(authUser.email ?? '');
    });
  }

  void _listenRooms() {
    _roomsSub?.cancel();
    _roomsSub = _firestore
        .collection('rooms')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      rooms.value = snapshot.docs
          .map((doc) => Room.fromMap(doc.data(), id: doc.id))
          .toList();
    });
  }

  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = result.user?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).set(
          {
            'email': email,
            'name': null,
            'phone': null,
          },
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<bool> addRoom(Room room) async {
    final user = currentUser.value;
    if (user == null) {
      throw StateError('User must be signed in to add a room');
    }
    try {
      await _firestore.collection('rooms').add(room.toMap()).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Add room timed out'),
      );
      return true;
    } catch (e, st) {
      debugPrint('Failed to add room: $e\n$st');
      return false;
    }
  }

  Future<bool> deleteRoom(Room room) async {
    final user = currentUser.value;
    if (user == null || room.creatorEmail != user.email || room.id == null) {
      return false;
    }
    try {
      await _firestore.collection('rooms').doc(room.id).delete().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Delete room timed out'),
      );
      return true;
    } catch (e, st) {
      debugPrint('Failed to delete room: $e\n$st');
      return false;
    }
  }

  Future<bool> updateRoom(Room oldRoom, Room newRoom) async {
    final user = currentUser.value;
    if (user == null || oldRoom.creatorEmail != user.email || oldRoom.id == null) {
      return false;
    }
    try {
      await _firestore.collection('rooms').doc(oldRoom.id!).update(newRoom.toMap()).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Update room timed out'),
      );
      return true;
    } catch (e, st) {
      debugPrint('Failed to update room: $e\n$st');
      return false;
    }
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    final appBox = Hive.box('app');
    final s = mode == ThemeMode.dark ? 'dark' : 'light';
    appBox.put('themeMode', s);
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    final authUser = _auth.currentUser;
    if (authUser == null) return;
    await _firestore.collection('users').doc(authUser.uid).set(
      {
        'name': name,
        'phone': phone,
      },
      SetOptions(merge: true),
    );
  }

  Future<bool> changePassword(String current, String newPassword) async {
    final authUser = _auth.currentUser;
    if (authUser == null || authUser.email == null) return false;

    try {
      final credential = fb_auth.EmailAuthProvider.credential(
        email: authUser.email!,
        password: current,
      );
      await authUser.reauthenticateWithCredential(credential);
      await authUser.updatePassword(newPassword);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Cycle theme mode: Light <-> Dark
  void cycleThemeMode() {
    final current = themeMode.value;
    final next = (current == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(next);
  }

  void dispose() {
    _roomsSub?.cancel();
    _authSub?.cancel();
    _profileSub?.cancel();
  }
}
