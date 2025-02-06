import 'package:flutter/material.dart';
import '../screens/main_screen.dart';
import '../screens/collection_screen.dart';
import '../screens/trades/market_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../main.dart';

class NavigationProvider with ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void changePage(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}
