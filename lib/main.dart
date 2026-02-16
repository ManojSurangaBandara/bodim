import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/user.dart';
import 'models/room.dart';
import 'screens/home_page.dart';
import 'services/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(RoomAdapter());

  await Hive.openBox<User>('users');
  await Hive.openBox<Room>('rooms');
  await Hive.openBox('app');

  await AppState.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppState.instance.themeMode,
      builder: (context, mode, _) {
        final appliedTheme = (mode == ThemeMode.dark) ? AppTheme.dark() : AppTheme.light();

        return AnimatedTheme(
          data: appliedTheme,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Room Renting',
            theme: appliedTheme,
            home: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: HomePage(key: ValueKey(mode)),
            ),
          ),
        );
      },
    );
  }
}
