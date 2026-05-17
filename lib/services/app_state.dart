import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/room.dart';
import '../models/user.dart';
import '../theme.dart';

class AppState {
  AppState._internal();
  static final AppState instance = AppState._internal();

  final ValueNotifier<User?> currentUser = ValueNotifier<User?>(null);
  final ValueNotifier<List<Room>> rooms = ValueNotifier<List<Room>>([]);
  final ValueNotifier<bool> roomsLoading = ValueNotifier<bool>(true);
  final ValueNotifier<bool> updateAvailable = ValueNotifier<bool>(false);
  final ValueNotifier<bool> forceUpdateRequired = ValueNotifier<bool>(false);
  final ValueNotifier<String?> updateUrl = ValueNotifier<String?>(null);
  final ValueNotifier<String> languageCode = ValueNotifier<String>('en');
  final ValueNotifier<AppThemeMode> themeMode =
      ValueNotifier<AppThemeMode>(AppThemeMode.light);

  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _roomsSub;
  StreamSubscription<fb_auth.User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _updateConfigSub;
  String? _packageName;
  String? _currentVersion;
  static const String _languageKey = 'languageCode';
  static const String _themeModeKey = 'themeMode';

  Future<void> init() async {
    await _initPackageInfo();
    _loadSavedLanguage();
    _loadSavedThemeMode();
    _authSub = _auth.authStateChanges().listen(_handleAuthStateChanged);
    _listenRooms();
    _listenUpdateConfig();
    await _ensureSignedIn();
  }

  Future<void> _ensureSignedIn() async {
    if (_auth.currentUser != null) return;
    await signInAnonymously();
  }

  void _handleAuthStateChanged(fb_auth.User? authUser) {
    _profileSub?.cancel();
    if (authUser == null) {
      currentUser.value = null;
      return;
    }

    final emailValue = authUser.email ?? '';
    if (authUser.isAnonymous) {
      currentUser.value = User(emailValue);
      return;
    }

    final profileDoc = _firestore.collection('users').doc(authUser.uid);
    _profileSub = profileDoc.snapshots().listen(
      (snapshot) {
        final data = snapshot.data();
        if (data != null) {
          currentUser.value = User(
            emailValue,
            name: data['name'] as String?,
            phone: data['phone'] as String?,
            isAdmin: data['isAdmin'] as bool? ?? false,
          );
        } else {
          final user = User(emailValue);
          currentUser.value = user;
          profileDoc.set({
            'id': authUser.uid,
            'email': authUser.email,
            'name': null,
            'phone': null,
            'isAdmin': false,
          }, SetOptions(merge: true));
        }
      },
      onError: (_) {
        currentUser.value = User(emailValue);
      },
    );
  }

  void _listenRooms() {
    _roomsSub?.cancel();
    roomsLoading.value = true;
    _roomsSub = _firestore
        .collection('rooms')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            rooms.value = snapshot.docs
                .map((doc) => Room.fromMap(doc.data(), id: doc.id))
                .toList();
            roomsLoading.value = false;
          },
          onError: (_) {
            roomsLoading.value = false;
          },
        );
  }

  Future<void> _initPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _packageName = info.packageName;
      _currentVersion = info.version;
      updateUrl.value =
          'https://play.google.com/store/apps/details?id=${info.packageName}';
    } catch (_) {
      _packageName = null;
      _currentVersion = null;
    }
  }

  void _loadSavedLanguage() {
    final box = Hive.box('app');
    final savedCode = box.get(_languageKey) as String?;
    if (savedCode != null && savedCode.isNotEmpty) {
      languageCode.value = savedCode;
    }
  }

  void setLanguageCode(String code) {
    languageCode.value = code;
    Hive.box('app').put(_languageKey, code);
  }

  void setThemeMode(AppThemeMode mode) {
    themeMode.value = mode;
    Hive.box('app').put(_themeModeKey, mode.index);
  }

  void _loadSavedThemeMode() {
    final box = Hive.box('app');
    final saved = box.get(_themeModeKey) as int?;
    if (saved != null) {
      themeMode.value =
          AppThemeMode.values[saved.clamp(0, AppThemeMode.values.length - 1)];
    }
  }

  void _listenUpdateConfig() {
    _updateConfigSub?.cancel();
    _updateConfigSub = _firestore
        .collection('app_config')
        .doc('updates')
        .snapshots()
        .listen(
          (snapshot) {
            final data = snapshot.data();
            if (data == null) return;
            final latest = data['latestVersion'] as String?;
            final minSupported = data['minSupportedVersion'] as String?;
            final url = data['updateUrl'] as String?;
            if (url != null && url.isNotEmpty) {
              updateUrl.value = url;
            }
            _evaluateVersionState(latest, minSupported);
          },
          onError: (_) {
            // keep existing values if config cannot be loaded
          },
        );
  }

  void _evaluateVersionState(
    String? latestVersion,
    String? minSupportedVersion,
  ) {
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
    final maxLen = aParts.length > bParts.length
        ? aParts.length
        : bParts.length;
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

  Future<bool> register(
    String email,
    String password, {
    String? name,
    String? phone,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = result.user?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).set({
          'id': uid,
          'email': email,
          'name': name,
          'phone': phone,
        });
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserEmail => _auth.currentUser?.email;
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  Future<bool> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      return result.user != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  String? lastRoomError;

  Future<bool> addRoom(Room room) async {
    final authUser = _auth.currentUser;
    if (authUser == null) {
      throw StateError('User must be signed in to add a room');
    }
    final roomData = Map<String, dynamic>.from(room.toMap());
    roomData['creatorEmail'] = authUser.email;
    roomData['userId'] = authUser.uid;
    lastRoomError = null;

    try {
      await _firestore
          .collection('rooms')
          .add(roomData)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Add room timed out'),
          );
      return true;
    } catch (e, st) {
      lastRoomError = e.toString();
      debugPrint('Failed to add room: $e\n$st');
      return false;
    }
  }

  Future<bool> deleteRoom(Room room) async {
    final authUser = _auth.currentUser;
    if (authUser == null || room.id == null) {
      return false;
    }
    final userId = authUser.uid;
    final userEmail = authUser.email;
    final canDelete = room.userId != null
        ? room.userId == userId
        : room.creatorEmail == userEmail;
    if (!canDelete) return false;
    try {
      lastRoomError = null;
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

      await _firestore
          .collection('rooms')
          .doc(room.id)
          .delete()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Delete room timed out'),
          );
      return true;
    } catch (e, st) {
      lastRoomError = e.toString();
      debugPrint('Failed to delete room: $e\n$st');
      return false;
    }
  }

  Future<bool> updateRoom(Room oldRoom, Room newRoom) async {
    final authUser = _auth.currentUser;
    if (authUser == null || oldRoom.id == null) {
      return false;
    }
    final userId = authUser.uid;
    final userEmail = authUser.email;
    final canUpdate = oldRoom.userId != null
        ? oldRoom.userId == userId
        : oldRoom.creatorEmail == userEmail;
    if (!canUpdate) return false;

    try {
      lastRoomError = null;
      await _firestore
          .collection('rooms')
          .doc(oldRoom.id!)
          .update(newRoom.toMap())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Update room timed out'),
          );
      return true;
    } catch (e, st) {
      lastRoomError = e.toString();
      debugPrint('Failed to update room: $e\n$st');
      return false;
    }
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    final authUser = _auth.currentUser;
    if (authUser == null) return;
    await _firestore.collection('users').doc(authUser.uid).set({
      'name': name,
      'phone': phone,
    }, SetOptions(merge: true));
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
