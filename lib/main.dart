import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('themeMode');
  if (savedTheme == 'dark') {
    themeNotifier.value = ThemeMode.dark;
  } else if (savedTheme == 'light') {
    themeNotifier.value = ThemeMode.light;
  }

  runApp(const AttendanceApp());
}

// Global notifier for theme mode
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            final isDark = currentMode == ThemeMode.dark ||
                (currentMode == ThemeMode.system &&
                    MediaQuery.platformBrightnessOf(context) == Brightness.dark);

            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            ));

            return MaterialApp(
              title: 'Attendance Pro',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: currentMode,
              home: child,
            );
          },
          child: const SplashScreen(),
        );
      },
    );
  }
}
