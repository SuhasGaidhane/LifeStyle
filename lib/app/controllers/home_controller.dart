import 'package:get/get.dart';

class HomeController extends GetxController {
  final selectedIndex = 0.obs; // 0 = Data, 1 = Post, 2 = Profile
  void changeTab(int index) => selectedIndex.value = index;
}
