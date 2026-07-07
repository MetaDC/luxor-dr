import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_ctrl.dart';
import '../../utils/app_theme.dart';

class DeactivatedView extends StatelessWidget {
  const DeactivatedView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents Android back button from popping the screen
      child: Scaffold(
        backgroundColor: DrColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Premium Lock Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_person_rounded,
                      color: Colors.red.shade600,
                      size: 72,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    'Access Restricted',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: DrColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    'Your doctor account has been deactivated by the administrator.\n\nPlease reach out to support or contact admin to reactivate your account.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: DrColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Premium Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await AuthCtrl.to.signOut();
                      },
                      child: Text(
                        'Logout',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
