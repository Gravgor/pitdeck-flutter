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
import 'package:pitdeck/screens/auth/onboarding_screen.dart';
import 'package:pitdeck/screens/auth/auth_screen.dart';

class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, AuthProvider>(
      builder: (context, userProvider, authProvider, child) {
        final user = userProvider.user;

        // Check if user is authenticated
        if (user == null) {
          return const AuthScreen();
        }

        if (!authProvider.hasCompletedOnboarding) {
          return const OnboardingScreen();
        }


        return Scaffold(
          body: IndexedStack(
            index: Provider.of<NavigationProvider>(context).currentIndex,
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
  }
}
