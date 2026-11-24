import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/post_controller.dart';
import '../controllers/shop_controller.dart';
import '../controllers/admin_controller.dart';
import '../controllers/services_controller.dart';
import '../controllers/location_controller.dart';
import '../controllers/banner_controller.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services first (controllers depend on them).
    Get.put(ApiService(), permanent: true);
    Get.put(SessionService(), permanent: true);

    // Controllers
    Get.put(AuthController(), permanent: true);
    Get.put(HomeController(), permanent: true);
    Get.put(ShopController(), permanent: true);
    Get.put(PostController(), permanent: true);
    Get.put(AdminController(), permanent: true);
    Get.put(ServicesController(), permanent: true);
    Get.put(LocationController(), permanent: true);
    Get.put(BannersController(), permanent: true);

    // Push notifications — depends on ApiService + SessionService above.
    // Async init runs in the background; registration completes when ready.
    Get.putAsync<NotificationService>(
        () => NotificationService().init(),
        permanent: true);
  }
}
