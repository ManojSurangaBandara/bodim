import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme.dart';
import 'models/room.dart';
import 'screens/home_page.dart';
import 'screens/room_detail_page.dart';
import 'services/app_state.dart';

/// Global navigator key — lets us navigate from outside the widget tree.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Must be top-level — FCM calls this in a background isolate.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background messages are shown automatically by FCM on Android.
}

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

/// Android notification channel used for bodim alerts.
const AndroidNotificationChannel _alertsChannel = AndroidNotificationChannel(
  'bodim_alerts',
  'Bodim Alerts',
  description: 'Notifications for new room listings matching your saved alerts',
  importance: Importance.high,
);

/// Fetches the room by [roomId] and pushes [RoomDetailPage].
Future<void> _openRoomById(String roomId) async {
  if (roomId.isEmpty) return;

  // Try local cache first.
  Room? room = AppState.instance.rooms.value
      .where((r) => r.id == roomId)
      .cast<Room?>()
      .firstOrNull;

  // Fallback: fetch from Firestore.
  if (room == null) {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .get();
      if (doc.exists && doc.data() != null) {
        room = Room.fromMap(doc.data()!, id: doc.id);
      }
    } catch (_) {}
  }

  if (room == null) return;

  navigatorKey.currentState?.push(
    MaterialPageRoute(builder: (_) => RoomDetailPage(room: room!)),
  );
}

/// Called when user taps a notification while app is in the foreground
/// (shown via flutter_local_notifications). Routes through the same
/// pendingNotification path as background/killed so that HomePage
/// applies the matching alert filter in addition to navigating.
void _handleForegroundNotificationTap(String payload) {
  if (payload.isEmpty) return;

  final data = jsonDecode(payload) as Map<String, dynamic>;
  AppState.instance.pendingNotification.value = PendingNotification(
    roomId: data['roomId'] as String? ?? '',
    type: data['type'] as String?,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await Hive.initFlutter();
  await Hive.openBox('app');

  // Register background message handler.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Create Android notification channel so high-importance heads-up works.
  await _localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(_alertsChannel);

  // Initialise local notifications — pass roomId as payload for foreground taps.
  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  await _localNotifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) {
      final roomId = response.payload ?? '';
      _handleForegroundNotificationTap(roomId);
    },
  );

  // Foreground FCM → show as local notification with roomId payload.
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;
    if (notification != null && android != null) {
      final payload = jsonEncode({
        'roomId': message.data['roomId'] as String? ?? '',
        'type': message.data['type'] as String? ?? '',
      });
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _alertsChannel.id,
            _alertsChannel.name,
            channelDescription: _alertsChannel.description,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: payload,
      );
    }
  });

  // Background → foreground: user tapped the system tray notification.
  // Store the roomId; HomePage will navigate once it is fully mounted.
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    AppState.instance.pendingNotification.value = PendingNotification(
      roomId: message.data['roomId'] as String? ?? '',
      type: message.data['type'] as String?,
    );
  });

  await AppState.instance.init();

  // Cold start: app was terminated when the notification was tapped.
  // Store the roomId; HomePage will pick it up after the splash.
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    AppState.instance.pendingNotification.value = PendingNotification(
      roomId: initialMessage.data['roomId'] as String? ?? '',
      type: initialMessage.data['type'] as String?,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: AppState.instance.themeMode,
      builder: (context, mode, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Room Renting',
          theme: AppTheme.forMode(mode),
          home: const SplashPage(),
        );
      },
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: Image.asset('assets/icon/app_icon.png', width: 180, height: 180),
      ),
    );
  }
}
