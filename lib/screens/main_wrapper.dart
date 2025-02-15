import 'package:flutter/material.dart';
import 'package:pitdeck/screens/trades/market_screen.dart';
import 'package:provider/provider.dart';
import 'package:pitdeck/providers/navigation_provider.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'package:pitdeck/providers/card_provider.dart';
import 'package:pitdeck/providers/trade_provider.dart';
import 'package:pitdeck/providers/favorite_provider.dart';
import 'package:pitdeck/providers/badge_provider.dart';
import 'package:pitdeck/providers/scroll_notifier.dart';
import 'package:pitdeck/screens/main_screen.dart';
import 'package:pitdeck/screens/collection_screen.dart';
import 'package:pitdeck/screens/profile_screen.dart';
import 'package:pitdeck/widgets/bottom_navigation_bar.dart';
import 'package:pitdeck/providers/auth_provider.dart';
import 'package:pitdeck/services/push_notification_service.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  final _pushNotificationService = PushNotificationService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      if (!_isInitialized) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;

        if (currentUser != null) {
          await _pushNotificationService.updateServerToken(currentUser.token);
          _isInitialized = true;
        }
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;

        if (user != null && !_isInitialized) {
          _initializeNotifications();
        }

        return Consumer<NavigationProvider>(
          builder: (context, navigationProvider, _) {
            return Scaffold(
              body: IndexedStack(
                index: navigationProvider.currentIndex,
                children: const [
                  MainScreen(),
                  CollectionScreen(),
                  MarketScreen(),
                  ProfileScreen(),
                ],
              ),
              bottomNavigationBar: const GlobalBottomNavigationBar(),
            );
          },
        );
      },
    );
  }
}
