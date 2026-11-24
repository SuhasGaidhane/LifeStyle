import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import 'auth_controller.dart';
import 'services_controller.dart';

class ShopController extends GetxController {
  ApiService get _api => Get.find<ApiService>();
  SessionService get _session => Get.find<SessionService>();

  // Shops shown on a Service list screen (loaded per service + state/district).
  final serviceShops = <ShopModel>[].obs;
  final loadingShops = false.obs;

  /// Loads shops for a service, optionally filtered by state & district
  /// — "Show Shop List as per State and District".
  Future<void> loadServiceShops(
    ServiceCategory category, {
    String? state,
    String? district,
    String? q,
  }) async {
    loadingShops.value = true;
    try {
      final list = await _api.getShops(
        serviceId: int.tryParse(category.id),
        service: category.id.isEmpty ? category.name : null,
        state: state,
        city: district, // districts map to the shops.city filter
        q: q,
      );
      serviceShops.value = list
          .map((e) => ShopModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      serviceShops.clear();
    } finally {
      loadingShops.value = false;
    }
  }

  /// Posting is gated: the user must have at least one listed shop
  /// (i.e. premium access). Otherwise send them to Add Shop.
  Future<void> openUploadPost() async {
    if (myShops.isEmpty) {
      await loadMyShops();
    }
    if (myShops.isNotEmpty) {
      Get.toNamed(AppRoutes.uploadPost);
    } else {
      Get.snackbar(
        'Premium Access Required',
        'List at least one shop on the portal to unlock posting.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      Get.toNamed(AppRoutes.addShop);
    }
  }

  /// Full detail for one shop (images, products, updates, onsite, clients).
  Future<ShopModel?> fetchShopDetail(String id) async {
    try {
      final map = await _api.getShopDetail(id);
      return ShopModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Loads the logged-in user's shops — "My Shop List as per Userid".
  Future<void> loadMyShops() async {
    final uid = _session.userId;
    if (uid == null) {
      myShops.clear();
      return;
    }
    loadingShops.value = true;
    try {
      final list = await _api.getShops(userId: uid, includeInactive: true);
      myShops.value = list
          .map((e) => ShopModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      existingShops.value = myShops.length;
    } catch (_) {
      myShops.clear();
      existingShops.value = 0;
    } finally {
      loadingShops.value = false;
    }
  }

  // Form fields used in Add Shop / Update Shop
  final firmNameCtrl = TextEditingController();
  final ownerNameCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final otherMobileCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  // Selected categories the owner wants to list under
  final selectedCategories = <String>[].obs;

  // Selected location (dropdowns) — used to filter shops by state & city later.
  final selectedState = ''.obs;
  final selectedCity = ''.obs;

  // The user's shops (one shop entry per category, even if it's the same physical shop)
  final myShops = <ShopModel>[].obs;

  // How many shops the user already owns (drives pricing).
  final existingShops = 0.obs;
  final isSubmitting = false.obs;

  // Pricing rules — loaded from admin settings (defaults until fetched).
  final firstCategoryPrice = 3000.obs;
  final additionalCategoryPrice = 1000.obs;

  /// First-ever shop: firstPrice then +addPrice per extra service.
  /// Already has a shop: flat addPrice per selected service.
  int get totalPrice {
    final n = selectedCategories.length;
    if (n == 0) return 0;
    if (existingShops.value > 0) return n * additionalCategoryPrice.value;
    return firstCategoryPrice.value + (n - 1) * additionalCategoryPrice.value;
  }

  /// Price for a single line in the order summary at position [index].
  int priceForLine(int index) {
    if (existingShops.value > 0) return additionalCategoryPrice.value;
    return index == 0 ? firstCategoryPrice.value : additionalCategoryPrice.value;
  }

  String get priceBreakdown {
    final n = selectedCategories.length;
    final add = additionalCategoryPrice.value;
    final first = firstCategoryPrice.value;
    if (n == 0) return 'Select at least one service';
    if (existingShops.value > 0) return '₹${n * add} ($n services × ₹$add)';
    final extras = n - 1;
    if (extras == 0) return '₹$first (1 service)';
    return '₹$first + ₹${extras * add} ($n services)';
  }

  /// Fetch admin-configured pricing.
  Future<void> loadPricing() async {
    try {
      final s = await _api.getPricingSettings();
      firstCategoryPrice.value = int.tryParse('${s['first_shop_price']}') ?? firstCategoryPrice.value;
      additionalCategoryPrice.value = int.tryParse('${s['additional_shop_price']}') ?? additionalCategoryPrice.value;
    } catch (_) {/* keep defaults */}
  }

  /// Load current shop count so pricing reflects "already has a shop".
  Future<void> prepareAddShop() async {
    await loadMyShops();
    await loadPricing();
    // ensure the service list (for selection) is available
    if (Get.isRegistered<ServicesController>()) {
      final sc = Get.find<ServicesController>();
      if (sc.categories.isEmpty) await sc.load();
    }
  }

  void toggleCategory(String name) {
    if (selectedCategories.contains(name)) {
      selectedCategories.remove(name);
    } else {
      selectedCategories.add(name);
    }
  }

  bool isSelected(String name) => selectedCategories.contains(name);

  void resetForm() {
    firmNameCtrl.clear();
    ownerNameCtrl.clear();
    mobileCtrl.clear();
    otherMobileCtrl.clear();
    addressCtrl.clear();
    cityCtrl.clear();
    locationCtrl.clear();
    emailCtrl.clear();
    descCtrl.clear();
    selectedCategories.clear();
    selectedState.value = '';
    selectedCity.value = '';
  }

  bool validateForm() {
    if (firmNameCtrl.text.isEmpty ||
        ownerNameCtrl.text.isEmpty ||
        mobileCtrl.text.isEmpty ||
        addressCtrl.text.isEmpty) {
      Get.snackbar('Incomplete', 'Please fill all required fields',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    if (selectedState.value.isEmpty || selectedCity.value.isEmpty) {
      Get.snackbar('Location', 'Please select State and City',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    if (selectedCategories.isEmpty) {
      Get.snackbar('No Service', 'Please select at least one service',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    return true;
  }

  /// Step 1: User fills out the form, then taps "Continue to payment".
  /// We pass the form data into the payment screen.
  void goToPayment() {
    if (!validateForm()) return;
    Get.toNamed(AppRoutes.payment);
  }

  /// Maps the selected service names to backend service ids.
  List<int> get _selectedServiceIds {
    final services = Get.isRegistered<ServicesController>()
        ? Get.find<ServicesController>().categories
        : <ServiceCategory>[];
    final ids = <int>[];
    for (final name in selectedCategories) {
      for (final s in services) {
        if (s.name == name) {
          final id = int.tryParse(s.id);
          if (id != null && id > 0) ids.add(id);
          break;
        }
      }
    }
    return ids;
  }

  /// Step 2: Payment success handler — creates one shop row per selected
  /// service via the backend, then refreshes the user's shop list.
  Future<void> confirmPaymentAndCreateShops() async {
    final uid = _session.userId;
    if (uid == null) {
      Get.snackbar('Not logged in', 'Please log in again',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final serviceIds = _selectedServiceIds;
    if (serviceIds.isEmpty) {
      Get.snackbar('No service', 'Please select at least one service',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isSubmitting.value = true;
    try {
      await _api.createShop({
        'user_id': uid,
        'service_ids': serviceIds,
        'shop_name': firmNameCtrl.text.trim(),
        'owner_name': ownerNameCtrl.text.trim(),
        'owner_mobile': mobileCtrl.text.trim(),
        'alternative_number': otherMobileCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'state': selectedState.value,
        'city': selectedCity.value,      // district-level city (used for filtering)
        'district': selectedCity.value,
        'story_description': descCtrl.text.trim(),
      });

      await loadMyShops();
      Get.find<AuthController>().markShopAdded();
      resetForm();

      Get.until((route) => Get.currentRoute == AppRoutes.home);
      Get.toNamed(AppRoutes.myShops);

      Get.snackbar('Success', 'Shop added successfully! 🎉',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } on ApiException catch (e) {
      Get.snackbar('Failed', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      Get.snackbar('Network error', 'Could not create shop',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Update a shop's details (called from Update Shop screen)
  void updateShop(ShopModel shop) {
    final i = myShops.indexWhere((s) => s.id == shop.id);
    if (i != -1) {
      myShops[i] = shop;
      myShops.refresh();
      Get.snackbar('Updated', 'Shop details updated',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Delete a single shop entry
  /// Deletes a shop on the backend, then removes it from the local list.
  Future<void> deleteShop(String id) async {
    try {
      await _api.deleteShop(id);
      myShops.removeWhere((s) => s.id == id);
      if (myShops.isEmpty) {
        Get.find<AuthController>().user.value?.hasShop = false;
        Get.find<AuthController>().user.refresh();
      }
      Get.snackbar('Deleted', 'Shop removed successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } on ApiException catch (e) {
      Get.snackbar('Failed', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      Get.snackbar('Error', 'Could not delete shop. Check your connection.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  void onClose() {
    firmNameCtrl.dispose();
    ownerNameCtrl.dispose();
    mobileCtrl.dispose();
    otherMobileCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    locationCtrl.dispose();
    emailCtrl.dispose();
    descCtrl.dispose();
    super.onClose();
  }
}
