import 'package:get/get.dart';

import '../services/api_service.dart';
import '../services/session_service.dart';

/// Handles the Contact Us form submission.
class ContactController extends GetxController {
  final isSubmitting = false.obs;

  ApiService get _api => Get.find<ApiService>();
  SessionService get _session => Get.find<SessionService>();

  /// Returns true on success.
  Future<bool> submit({
    required String name,
    required String mobile,
    required String message,
    String? email,
    String? subject,
  }) async {
    isSubmitting.value = true;
    try {
      await _api.submitContact({
        if (_session.userId != null) 'user_id': _session.userId,
        'name': name,
        'mobile_number': mobile,
        'message': message,
        'email': (email == null || email.isEmpty)
            ? '${mobile}@lifestyle.app' // backend requires an email
            : email,
        if (subject != null && subject.isNotEmpty) 'subject': subject,
      });
      return true;
    } on ApiException catch (e) {
      Get.snackbar('Failed', e.message, snackPosition: SnackPosition.BOTTOM);
      return false;
    } catch (_) {
      Get.snackbar('Network error', 'Could not send your message.',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
