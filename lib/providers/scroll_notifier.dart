import 'package:flutter/material.dart';

class ScrollNotifier extends ChangeNotifier {
  bool _showTitle = false;

  bool get showTitle => _showTitle;

  void updateScrollPosition(double position) {
    final shouldShowTitle = position > 40;
    if (shouldShowTitle != _showTitle) {
      _showTitle = shouldShowTitle;
      notifyListeners();
    }
  }
}
