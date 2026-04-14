import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/room.dart';
import '../models/user.dart';

class AppState {
  AppState._internal();
  static final AppState instance = AppState._internal();

  final ValueNotifier<User?> currentUser = ValueNotifier<User?>(null);
  final ValueNotifier<List<Room>> rooms = ValueNotifier<List<Room>>([]);
  final ValueNotifier<bool> updateAvailable = ValueNotifier<bool>(false);
  final ValueNotifier<bool> forceUpdateRequired = ValueNotifier<bool>(false);
  final ValueNotifier<String?> updateUrl = ValueNotifier<String?>(null);

  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _roomsSub;
  StreamSubscription<fb_auth.User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _updateConfigSub;
  String? _packageName;
  String? _currentVersion;

  Future<void> init() async {
    await _initPackageInfo();
    _authSub = _auth.authStateChanges().listen(_handleAuthStateChanged);
    _listenRooms();
    _listenUpdateConfig();
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
          isAdmin: data['isAdmin'] as bool? ?? false,
        );
      } else {
        final user = User(authUser.email ?? '');
        currentUser.value = user;
        profileDoc.set(
          {
            'email': authUser.email,
            'name': null,
            'phone': null,
            'isAdmin': false,
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

  Future<void> _initPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _packageName = info.packageName;
      _currentVersion = info.version;
      updateUrl.value = 'https://play.google.com/store/apps/details?id=${info.packageName}';
    } catch (_) {
      _packageName = null;
      _currentVersion = null;
    }
  }

  void _listenUpdateConfig() {
    _updateConfigSub?.cancel();
    _updateConfigSub = _firestore
        .collection('app_config')
        .doc('updates')
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data();
      if (data == null) return;
      final latest = data['latestVersion'] as String?;
      final minSupported = data['minSupportedVersion'] as String?;
      final url = data['updateUrl'] as String?;
      if (url != null && url.isNotEmpty) {
        updateUrl.value = url;
      }
      _evaluateVersionState(latest, minSupported);
    }, onError: (_) {
      // keep existing values if config cannot be loaded
    });
  }

  void _evaluateVersionState(String? latestVersion, String? minSupportedVersion) {
    final current = _currentVersion;
    if (current == null || latestVersion == null) {
      updateAvailable.value = false;
      forceUpdateRequired.value = false;
      return;
    }

    final currentCmp = _compareVersionStrings(current, latestVersion);
    final minCmp = minSupportedVersion != null
        ? _compareVersionStrings(current, minSupportedVersion)
        : 1;

    forceUpdateRequired.value = minSupportedVersion != null && minCmp < 0;
    updateAvailable.value = currentCmp < 0;
    if (forceUpdateRequired.value) {
      updateAvailable.value = true;
    }
  }

  int _compareVersionStrings(String a, String b) {
    final aParts = a.split('.').map(int.tryParse).map((v) => v ?? 0).toList();
    final bParts = b.split('.').map(int.tryParse).map((v) => v ?? 0).toList();
    final maxLen = aParts.length > bParts.length ? aParts.length : bParts.length;
    for (var i = 0; i < maxLen; i++) {
      final aVal = i < aParts.length ? aParts[i] : 0;
      final bVal = i < bParts.length ? bParts[i] : 0;
      if (aVal != bVal) return aVal.compareTo(bVal);
    }
    return 0;
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
      if (room.images != null) {
        for (final imageUrl in room.images!) {
          if (!imageUrl.startsWith('http')) continue;
          try {
            final ref = FirebaseStorage.instance.refFromURL(imageUrl);
            await ref.delete().timeout(
              const Duration(seconds: 45),
              onTimeout: () => throw TimeoutException('Image delete timed out'),
            );
          } catch (e, st) {
            debugPrint('Failed to delete image $imageUrl: $e\n$st');
          }
        }
      }

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

  void dispose() {
    _roomsSub?.cancel();
    _authSub?.cancel();
    _profileSub?.cancel();
    _updateConfigSub?.cancel();
  }
}
