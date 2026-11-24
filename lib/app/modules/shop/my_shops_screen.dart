import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/shop_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class MyShopsScreen extends StatefulWidget {
  const MyShopsScreen({super.key});

  @override
  State<MyShopsScreen> createState() => _MyShopsScreenState();
}

class _MyShopsScreenState extends State<MyShopsScreen> {
  final c = Get.find<ShopController>();

  @override
  void initState() {
    super.initState();
    c.loadMyShops(); // My Shop List as per Userid
  }

  /// Open the full shop detail (same rich screen used from Services).
  Future<void> _openDetail(String id, dynamic fallback) async {
    final full = await c.fetchShopDetail(id);
    Get.toNamed(AppRoutes.ownerDetail, arguments: full ?? fallback);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: BrandAppBar(title: 'My Shops', actions: [
        IconButton(
          icon: const Icon(Icons.add_business, color: Colors.white),
          onPressed: () => Get.toNamed(AppRoutes.addShop),
        ),
      ]),
      body: Obx(() {
        if (c.myShops.isEmpty) {
          return EmptyState(
            icon: Icons.store_mall_directory_outlined,
            title: 'No Shops Yet',
            subtitle:
                'Add your first shop to start showing up in our directory.',
            action: GradientButton(
              label: 'Add Shop',
              icon: Icons.add,
              width: 180,
              onTap: () => Get.toNamed(AppRoutes.addShop),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: c.myShops.length,
          itemBuilder: (_, i) {
            final s = c.myShops[i];
            return InkWell(
              onTap: () => _openDetail(s.id, s),
              borderRadius: BorderRadius.circular(14),
              child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SafeNetworkImage(
                    url: s.thumbnail,
                    width: 70,
                    height: 70,
                    borderRadius: BorderRadius.circular(10),
                    fallbackAsset: kLifestyleLogoAsset,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.firmName,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentYellow.withOpacity(.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(s.categories.first,
                              style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                        ),
                        const SizedBox(height: 4),
                        Text('${s.city}, ${s.location}',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                        Text(s.mobile,
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: AppColors.accentGreen, size: 20),
                        onPressed: () => Get.toNamed(AppRoutes.updateShop,
                            arguments: s),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error, size: 20),
                        onPressed: () => _confirmDelete(c, s.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            );
          },
        );
      }),
    );
  }

  void _confirmDelete(ShopController c, String id) {
    Get.dialog(AlertDialog(
      title: const Text('Delete Shop'),
      content:
          const Text('Are you sure you want to remove this shop entry?'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            c.deleteShop(id);
            Get.back();
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ));
  }
}
