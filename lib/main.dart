import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme.dart';
import 'screens/home_page.dart';
import 'services/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await Hive.initFlutter();
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
