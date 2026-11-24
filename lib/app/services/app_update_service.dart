import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/api_config.dart';
import '../theme/app_theme.dart';
import 'api_service.dart';

/// Checks the backend for a newer app build and shows an update dialog.
/// Works on both Android and iOS — it asks the server for the version row
/// matching the running platform and opens the correct store.
class AppUpdateService {
  static bool _shown = false; // only once per app session

  static bool get _isIOS => Platform.isIOS;

  static Future<void> check() async {
    if (_shown) return;
    try {
      final platform = _isIOS ? 'iOS' : 'Android';
      final currentBuild =
          _isIOS ? ApiConfig.iosBuildNumber : ApiConfig.androidBuildNumber;

      final lv = await Get.find<ApiService>().getLatestVersion(platform: platform);
      if (lv == null) return;
      final latestBuild = int.tryParse('${lv['build_number'] ?? 0}') ?? 0;
      if (latestBuild <= currentBuild) return; // up to date

      _shown = true;
      final force = lv['is_force_update'] == true || lv['is_force_update'] == 1;
      _showDialog(
        versionName: '${lv['version_name'] ?? ''}',
        description: '${lv['description'] ?? 'A new version is available.'}',
        force: force,
      );
    } catch (_) {/* silent — never block the app on a failed check */}
  }

  static void _showDialog({
    required String versionName,
    required String description,
    required bool force,
  }) {
    Get.dialog(
      PopScope(
        canPop: !force, // forced update can't be dismissed with back
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(children: [
            const Icon(Icons.system_update, color: AppColors.gold),
            const SizedBox(width: 10),
            Expanded(child: Text(force ? 'Update Required' : 'Update Available',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700))),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (versionName.isNotEmpty)
                Text('Version $versionName',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text(description, style: GoogleFonts.poppins(fontSize: 13)),
            ],
          ),
          actions: [
            if (!force)
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Later', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
              onPressed: _openStore,
              child: Text('Update Now', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
      barrierDismissible: !force,
    );
  }

  static Future<void> _openStore() async {
    if (_isIOS) {
      // App Store — prefer the native app, fall back to web.
      final id = ApiConfig.iosAppStoreId;
      final appStore = Uri.parse('itms-apps://itunes.apple.com/app/id$id');
      final web = Uri.parse('https://apps.apple.com/app/id$id');
      try {
        if (id.isEmpty ||
            !await launchUrl(appStore, mode: LaunchMode.externalApplication)) {
          await launchUrl(web, mode: LaunchMode.externalApplication);
        }
      } catch (_) {
        await launchUrl(web, mode: LaunchMode.externalApplication);
      }
      return;
    }
    // Play Store — prefer the native app, fall back to web.
    final pkg = ApiConfig.androidPackage;
    final market = Uri.parse('market://details?id=$pkg');
    final web = Uri.parse('https://play.google.com/store/apps/details?id=$pkg');
    try {
      if (!await launchUrl(market, mode: LaunchMode.externalApplication)) {
        await launchUrl(web, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }
}
