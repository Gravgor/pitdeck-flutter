import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/user_provider.dart';

class GlobalBottomNavigationBar extends StatelessWidget {
  const GlobalBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Consumer<NavigationProvider>(
            builder: (context, navigation, _) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  context,
                  Icons.map_outlined,
                  Icons.map,
                  'Map',
                  navigation.currentIndex == 0,
                ),
                _buildNavItem(
                  context,
                  Icons.card_membership_outlined,
                  Icons.card_membership,
                  'Collection',
                  navigation.currentIndex == 1,
                ),
                _buildNavItem(
                  context,
                  Icons.store_outlined,
                  Icons.store,
                  'Market',
                  navigation.currentIndex == 2,
                ),
                _buildNavItem(
                  context,
                  Icons.person_outline,
                  Icons.person,
                  'Profile',
                  navigation.currentIndex == 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData outlinedIcon,
      IconData filledIcon, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          final int index = label == 'Collection'
              ? 1
              : label == 'Market'
                  ? 2
                  : label == 'Profile'
                      ? 3
                      : 0;
          Provider.of<NavigationProvider>(context, listen: false)
              .changePage(index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontFamily: 'Orbitron',
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
