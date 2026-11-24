import 'package:get/get.dart';

import '../data/models.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

/// Loads the Services grid (premium first, then free) from the backend,
/// with per-user premium click-access flags.
class ServicesController extends GetxController {
  final premium = <ServiceCategory>[].obs;
  final free = <ServiceCategory>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;

  ApiService get _api => Get.find<ApiService>();
  SessionService get _session => Get.find<SessionService>();

  /// premium + free, in the order the Data tab expects (top 3 = premium).
  List<ServiceCategory> get categories => [...premium, ...free];

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      final data = await _api.getServices(userId: _session.userId);
      final services = Map<String, dynamic>.from(data['services'] ?? {});
      premium.value = _map(services['premium']);
      free.value = _map(services['free']);
    } on ApiException catch (e) {
      error.value = e.message;
    } catch (_) {
      error.value = 'Could not load services';
    } finally {
      isLoading.value = false;
    }
  }

  List<ServiceCategory> _map(dynamic list) {
    if (list is! List) return [];
    return list
        .map((e) => ServiceCategory.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
