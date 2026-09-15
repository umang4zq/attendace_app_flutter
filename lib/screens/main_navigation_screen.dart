import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'admin_panel_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();

  List<Widget> get _screens {
    final screens = <Widget>[
      const HomeScreen(),
      const ProfileScreen(),
    ];
    if (_authService.isSuperAdmin) {
      screens.add(const AdminPanelScreen());
    }
    return screens;
  }

  List<BottomNavigationBarItem> get _navItems {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: ImageIcon(AssetImage('assets/images/home_ic.png')),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: ImageIcon(AssetImage('assets/images/user_ic.png')),
        label: 'Profile',
      ),
    ];
    if (_authService.isSuperAdmin) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.admin_panel_settings),
        label: 'Admin',
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final screens = _screens;
    // Clamp index to avoid out-of-bounds
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      extendBody: true, // Allow body to scroll under the translucent bottom bar
      body: screens[_currentIndex],
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withAlpha(180),
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant.withAlpha(50),
                  width: 1.w,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                HapticFeedback.selectionClick(); // Apple design: meaningful haptic feedback
                setState(() => _currentIndex = index);
              },
              backgroundColor: Colors.transparent, // Let the BackdropFilter show through
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Theme.of(context).textTheme.bodySmall?.color,
              selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12.sp),
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              items: _navItems,
            ),
          ),
        ),
      ),
    );
  }
}
