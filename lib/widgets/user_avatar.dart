import 'package:flutter/material.dart';
import '../screens/user_profile_screen.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String userId;
  final double size;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.userId,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(userId: userId),
        ),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 2),
          border: Border.all(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular((size - 4) / 2),
          child: imageUrl != null
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                )
              : Container(
                  color: const Color(0xFF1A1A2E),
                  child: Icon(
                    Icons.person,
                    size: size * 0.6,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
        ),
      ),
    );
  }
}
