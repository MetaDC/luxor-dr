import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum _SnackType { success, error, warning, info }

class AppSnackbar {
  AppSnackbar._();

  static void success(BuildContext context, String message) =>
      _show(context, message, _SnackType.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, _SnackType.error);

  static void warning(BuildContext context, String message) =>
      _show(context, message, _SnackType.warning);

  static void info(BuildContext context, String message) =>
      _show(context, message, _SnackType.info);

  static void _show(BuildContext context, String message, _SnackType type) {
    final (Color bg, IconData icon) = switch (type) {
      _SnackType.success =>
        (const Color(0xFF16A34A), Icons.check_circle_rounded),
      _SnackType.error => (const Color(0xFFDC2626), Icons.cancel_rounded),
      _SnackType.warning =>
        (const Color(0xFFF59E0B), Icons.warning_amber_rounded),
      _SnackType.info =>
        (const Color(0xFF2563EB), Icons.info_rounded),
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: bg,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
          duration: const Duration(seconds: 3),
          dismissDirection: DismissDirection.horizontal,
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
