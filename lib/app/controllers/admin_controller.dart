import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/dummy_data.dart';
import '../data/models.dart';

class AdminController extends GetxController {
  final users = <UserModel>[].obs;
  final firms = <ShopModel>[].obs;
  final categories = <ServiceCategory>[].obs;
  final offers = <OfferModel>[].obs;
  final inquiries = <ContactInquiryModel>[].obs;
  final plans = <SubscriptionPlanModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    users.assignAll(DummyData.adminUsers);
    firms.assignAll(DummyData.shops);
    categories.assignAll(DummyData.categories);
    offers.assignAll(DummyData.offers);
    inquiries.assignAll(DummyData.inquiries);
    plans.assignAll(DummyData.plans);
  }

  // Stats
  int get totalUsers => users.length;
  int get activeUsers => users.where((u) => u.isActive).length;
  int get totalFirms => firms.length;
  int get totalPosts => DummyData.posts.length;

  // ---------------- USERS ----------------
  void deleteUser(String id) {
    users.removeWhere((u) => u.id == id);
    Get.snackbar('Deleted', 'User removed',
        snackPosition: SnackPosition.BOTTOM);
  }

  void toggleUserActive(String id) {
    final i = users.indexWhere((u) => u.id == id);
    if (i != -1) {
      users[i].isActive = !users[i].isActive;
      users.refresh();
    }
  }

  void assignMembership(String id, String plan) {
    final i = users.indexWhere((u) => u.id == id);
    if (i != -1) {
      users[i].membership = plan;
      users.refresh();
      Get.snackbar('Membership', 'Assigned $plan plan',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ---------------- FIRMS ----------------
  void addFirm(ShopModel shop) {
    firms.add(shop);
    Get.snackbar('Added', 'Firm added',
        snackPosition: SnackPosition.BOTTOM);
  }

  void deleteFirm(String id) {
    firms.removeWhere((s) => s.id == id);
  }

  // ---------------- CATEGORIES ----------------
  void addCategory(String name, String icon) {
    categories.add(ServiceCategory(
      id: 'c${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      icon: icon,
      access: true,
      cities: ['Nagpur'],
    ));
  }

  void addCityToCategory(String categoryId, String city) {
    final i = categories.indexWhere((c) => c.id == categoryId);
    if (i != -1 && !categories[i].cities.contains(city)) {
      categories[i].cities.add(city);
      categories.refresh();
    }
  }

  void deleteCategory(String id) {
    categories.removeWhere((c) => c.id == id);
  }

  // ---------------- OFFERS ----------------
  void addOffer(OfferModel offer) => offers.add(offer);
  void deleteOffer(String id) => offers.removeWhere((o) => o.id == id);
  void toggleOffer(String id) {
    final i = offers.indexWhere((o) => o.id == id);
    if (i != -1) {
      offers[i].active = !offers[i].active;
      offers.refresh();
    }
  }

  // ---------------- CONTACTS ----------------
  void resolveInquiry(String id) {
    final i = inquiries.indexWhere((q) => q.id == id);
    if (i != -1) {
      inquiries[i].resolved = true;
      inquiries.refresh();
    }
  }

  void deleteInquiry(String id) =>
      inquiries.removeWhere((q) => q.id == id);

  // ---------------- POSTS ----------------
  void deletePost(String id) {
    DummyData.posts.removeWhere((p) => p.id == id);
    update();
    Get.snackbar('Deleted', 'Post removed',
        snackPosition: SnackPosition.BOTTOM);
  }
}
