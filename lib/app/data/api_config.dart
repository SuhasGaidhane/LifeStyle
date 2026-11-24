/// Central place for the backend base URL.
///
/// The PHP backend lives at:  http://<host>/LifestyleBackend/api
/// Clean URLs are enabled via .htaccess, so endpoints look like
///   {baseUrl}/auth/send-otp , {baseUrl}/services , {baseUrl}/shops/5 ...
///
/// Pick the host that matches how you run the app:
///   • Android emulator      -> 10.0.2.2  (maps to the PC's localhost)
///   • iOS simulator         -> 127.0.0.1
///   • Real phone (same WiFi) -> your PC's LAN IP, e.g. 192.168.1.5
class ApiConfig {
  // 👉 change only this line for your environment
  static const String host = 'dev.variaindia.com';

  static const String baseUrl = 'https://$host';

  /// Uploaded files (profile images) are served from the app root.
  static const String rootUrl = 'https://$host';

  /// Current build number of THIS app, per platform. Bump on every release
  /// so the update dialog fires when the server has a higher build_number.
  static const int androidBuildNumber = 15;
  static const int iosBuildNumber = 1;

  /// Store identifiers used by the "Update Now" button.
  static const String androidPackage = 'com.varia.lifestyle'; // Play Store id
  static const String iosAppStoreId = '';                     // App Store numeric id, e.g. '1234567890'
}

