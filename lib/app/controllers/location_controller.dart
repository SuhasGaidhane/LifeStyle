import 'package:get/get.dart';

import '../services/api_service.dart';

/// Provides State -> District lookups for the shop filters.
class LocationController extends GetxController {
  final states = <Map<String, dynamic>>[].obs;   // {id, name, code}
  final districts = <Map<String, dynamic>>[].obs; // {id, state_id, name}

  ApiService get _api => Get.find<ApiService>();

  List<String> get stateNames => states.map((s) => '${s['name']}').toList();
  List<String> get districtNames => districts.map((d) => '${d['name']}').toList();

  @override
  void onInit() {
    super.onInit();
    loadStates();
  }

  Future<void> loadStates() async {
    try {
      final list = await _api.getStates();
      states.value = list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {/* filters simply stay empty on failure */}
  }

  Future<void> loadDistricts(String stateName) async {
    districts.clear();
    final match = states.firstWhereOrNull((s) => '${s['name']}' == stateName);
    if (match == null) return;
    try {
      final list = await _api.getDistricts(int.parse('${match['id']}'));
      districts.value = list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {}
  }
}
