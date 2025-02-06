import 'package:flutter/material.dart';
import 'package:pitdeck/screens/trades/market_screen.dart';
import 'package:provider/provider.dart';
import 'package:pitdeck/providers/navigation_provider.dart';
import 'package:pitdeck/screens/main_screen.dart';
import 'package:pitdeck/screens/collection_screen.dart';
import 'package:pitdeck/screens/profile_screen.dart';
import 'package:pitdeck/widgets/bottom_navigation_bar.dart';

class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context) {
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
  }
}
