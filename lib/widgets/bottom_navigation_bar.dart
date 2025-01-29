import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';

class GlobalBottomNavigationBar extends StatelessWidget {
  const GlobalBottomNavigationBar({super.key});

  Widget _buildNavItem(
      BuildContext context, IconData icon, String label, bool isSelected) {
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF3B82F6) : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.grey,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Consumer<NavigationProvider>(
            builder: (context, nav, _) {
              final currentIndex = nav.currentIndex;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(context, Icons.map, 'Map', currentIndex == 0),
                  _buildNavItem(context, Icons.card_membership, 'Collection',
                      currentIndex == 1),
                  _buildNavItem(
                      context, Icons.store, 'Market', currentIndex == 2),
                  _buildNavItem(
                      context, Icons.person, 'Profile', currentIndex == 3),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
