import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/auth_ctrl.dart';
import '../../utils/app_theme.dart';

class UpdateAppView extends StatelessWidget {
  const UpdateAppView({super.key});

  Future<void> _openStore() async {
    Uri url;
    if (io.Platform.isAndroid) {
      url = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.diwizon.luxor_dr',
      );
    } else if (io.Platform.isIOS) {
      // TODO: Replace 'YOUR_APP_ID' with the actual App Store ID when published
      url = Uri.parse(
        'https://apps.apple.com/us/app/luxor-admin/id6786658379',
        // 'https://apps.apple.com/app/luxor-dr/idYOUR_APP_ID',
      );
    } else {
      return;
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents Android hardware back button
      child: Scaffold(
        backgroundColor: DrColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: DrColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      size: 64,
                      color: DrColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Update Required',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: DrColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'A new version of the app is available. Please update the app to the latest version to continue.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: DrColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _openStore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DrColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Update Now',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () async {
                      await AuthCtrl.to.signOut();
                    },
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: DrColors.error,
                      size: 20,
                    ),
                    label: Text(
                      'Logout',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: DrColors.error,
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
