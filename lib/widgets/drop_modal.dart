import 'package:flutter/material.dart';
import 'package:pitdeck/models/drop_rarity.dart';

class DropModal extends StatelessWidget {
  final DropRarity rarity;
  final String dropName;
  final VoidCallback onCollect;

  const DropModal({
    super.key,
    required this.rarity,
    required this.dropName,
    required this.onCollect,
  });

  String _getRarityText() {
    return rarity.toString().split('.').last.toUpperCase();
  }

  Color _getRarityColor() {
    switch (rarity) {
      case DropRarity.common:
        return Colors.grey[400]!;
      case DropRarity.uncommon:
        return Colors.green[400]!;
      case DropRarity.rare:
        return Colors.blue[400]!;
      case DropRarity.epic:
        return Colors.purple[400]!;
      case DropRarity.legendary:
        return Colors.orange[400]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getRarityColor().withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getRarityColor().withOpacity(0.2),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${_getRarityText()} DROP',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getRarityColor(),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _getRarityColor(),
                        _getRarityColor().withOpacity(0.7),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getRarityColor().withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getIconForRarity(),
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  dropName,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: onCollect,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getRarityColor(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'COLLECT',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForRarity() {
    switch (rarity) {
      case DropRarity.legendary:
        return Icons.emoji_events;
      case DropRarity.epic:
        return Icons.auto_awesome;
      case DropRarity.rare:
        return Icons.speed;
      case DropRarity.uncommon:
        return Icons.flag;
      case DropRarity.common:
        return Icons.place;
    }
  }
}
