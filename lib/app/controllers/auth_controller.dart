import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';

class AuthController extends GetxController {
  final mobileCtrl = TextEditingController();
  final otpCtrl = TextEditingController();

  final isLoading = false.obs;
  final user = Rxn<UserModel>();

  ApiService get _api => Get.find<ApiService>();
  SessionService get _session => Get.find<SessionService>();

  @override
  void onInit() {
    super.onInit();
    // Restore any persisted session so the rest of the app has the user.
    user.value = _session.user;
  }

  bool get isLoggedIn => _session.isLoggedIn;

  /// Step 1 — send an OTP over WhatsApp (auto-registers new numbers).
  Future<void> sendOtp() async {
    final mobile = mobileCtrl.text.trim();
    if (mobile.length < 10) {
      _snack('Invalid', 'Please enter a valid mobile number');
      return;
    }
    isLoading.value = true;
    try {
      await _api.sendOtp(mobile);
      otpCtrl.clear();
      Get.toNamed(AppRoutes.otp, arguments: mobile);
    } on ApiException catch (e) {
      _snack('Failed', e.message);
    } catch (_) {
      _snack('Network error', 'Could not reach the server. Check your connection.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Resend the OTP for the number entered on the login screen.
  Future<void> resendOtp() async {
    final mobile = mobileCtrl.text.trim();
    if (mobile.length < 10) return;
    try {
      await _api.resendOtp(mobile);
      _snack('Sent', 'OTP sent again');
    } on ApiException catch (e) {
      _snack('Failed', e.message);
    } catch (_) {
      _snack('Network error', 'Could not resend OTP.');
    }
  }

  /// Step 2 — verify the OTP, persist the user, open Home.
  Future<void> verifyOtp() async {
    final mobile = mobileCtrl.text.trim();
    final otp = otpCtrl.text.trim();
    if (otp.length < 6) {
      _snack('Invalid', 'Please enter the 6-digit OTP');
      return;
    }
    isLoading.value = true;
    try {
      final map = await _api.verifyOtp(mobile, otp);
      final u = UserModel.fromJson(map);
      user.value = u;
      await _session.save(u); // 🔐 store in GetStorage
      // Attach this device's push token to the now logged-in user.
      if (Get.isRegistered<NotificationService>()) {
        Get.find<NotificationService>().syncTokenAfterLogin();
      }
      Get.offAllNamed(AppRoutes.home);
    } on ApiException catch (e) {
      _snack('Verification failed', e.message);
    } catch (_) {
      _snack('Network error', 'Could not verify OTP.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _session.clear();
    user.value = null;
    Get.offAllNamed(AppRoutes.login);
  }

  /// Replace the cached + persisted user (used after profile updates).
  Future<void> setUser(UserModel u) async {
    user.value = u;
    await _session.save(u);
  }

  /// Re-fetches the logged-in user's record so changes made by an admin
  /// (e.g. granting/removing admin access) reflect without re-login.
  /// Only the admin flag is synced here, to avoid clobbering `hasShop`
  /// (which the /users/{id} endpoint doesn't return).
  Future<void> refreshUser() async {
    final u = user.value;
    if (u == null) return;
    try {
      final map = await _api.getUserById(u.id);
      final freshAdmin =
          map['is_admin'] == 1 || map['is_admin'] == true || map['is_admin'] == '1';
      final freshActive = (map['status'] ?? 'active') == 'active';
      if (u.isAdmin != freshAdmin || u.isActive != freshActive) {
        u.isAdmin = freshAdmin;
        u.isActive = freshActive;
        user.refresh();          // notify Obx (shows/hides the Admin tab)
        await _session.save(u);
      }
    } catch (_) {
      // Non-fatal — keep the cached user.
    }
  }

  bool get isAdmin => user.value?.isAdmin ?? false;
  bool get hasShop => user.value?.hasShop ?? false;

  void markShopAdded() {
    final u = user.value;
    if (u != null) {
      u.hasShop = true;
      user.refresh();
      _session.save(u);
    }
  }

  void _snack(String title, String msg) =>
      Get.snackbar(title, msg, snackPosition: SnackPosition.BOTTOM);
}
