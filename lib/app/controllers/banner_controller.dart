import 'package:get/get.dart';

import '../data/models.dart';
import '../services/api_service.dart';

/// Loads the home-screen banner carousel from the backend.
class BannersController extends GetxController {
  final banners = <BannerModel>[].obs;
  final isLoading = false.obs;

  ApiService get _api => Get.find<ApiService>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final list = await _api.getBanners();
      banners.value =
          list.map((e) => BannerModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      // keep whatever we had; hero falls back to a default image
    } finally {
      isLoading.value = false;
    }
  }
}
