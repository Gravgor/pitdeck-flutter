import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../screens/main_screen.dart';
import '../screens/collection_screen.dart';
import '../screens/profile_screen.dart';
import '../main.dart';

class NavigationProvider with ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void changePage(int index) {
    _currentIndex = index;

    switch (index) {
      case 0:
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
        break;
      case 1:
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CollectionScreen()),
          (route) => false,
        );
        break;
      case 2:
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              backgroundColor: const Color(0xFF0A0A1A),
              body: const Center(
                child: Text('Market Coming Soon',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
          (route) => false,
        );
        break;
      case 3:
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
          (route) => false,
        );
        break;
    }

    notifyListeners();
  }
}
