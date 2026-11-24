import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../data/models.dart';

/// Persists the logged-in user in GetStorage so the app can skip the
/// login screen and open Home directly on the next launch.
class SessionService extends GetxService {
  final _box = GetStorage();

  static const _kUser = 'user';
  static const _kLoggedIn = 'is_logged_in';

  bool get isLoggedIn => _box.read(_kLoggedIn) == true && _box.read(_kUser) != null;

  /// Reads the stored user (or null if not logged in).
  UserModel? get user {
    final raw = _box.read(_kUser);
    if (raw == null) return null;
    return UserModel.fromJson(Map<String, dynamic>.from(raw));
  }

  int? get userId => int.tryParse(user?.id ?? '');

  Future<void> save(UserModel u) async {
    await _box.write(_kUser, u.toJson());
    await _box.write(_kLoggedIn, true);
  }

  Future<void> clear() async {
    await _box.remove(_kUser);
    await _box.write(_kLoggedIn, false);
  }
}
