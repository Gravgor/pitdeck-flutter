import 'package:flutter/material.dart';

class SnackBarUtils {
  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    _showSnackBar(
      context,
      title: title,
      message: message,
      backgroundColor: const Color(0xFF10B981),
      icon: Icons.check_circle_outline,
    );
  }

  static void showError(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    _showSnackBar(
      context,
      title: title,
      message: message,
      backgroundColor: const Color(0xFFDC2626),
      icon: Icons.error_outline,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    _showSnackBar(
      context,
      title: title,
      message: message,
      backgroundColor: const Color(0xFF3B82F6),
      icon: Icons.info_outline,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    _showSnackBar(
      context,
      title: title,
      message: message,
      backgroundColor: const Color(0xFFF59E0B),
      icon: Icons.warning_amber_rounded,
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
