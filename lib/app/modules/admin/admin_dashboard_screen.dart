import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/admin_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AdminController>();
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: const BrandAppBar(title: 'Admin Dashboard'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats grid
            Obx(() => GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                  ),
                  children: [
                    _statCard('Total Users', '${c.totalUsers}',
                        Icons.people, AppColors.info),
                    _statCard('Active', '${c.activeUsers}',
                        Icons.check_circle, AppColors.accentGreen),
                    _statCard('Firms', '${c.totalFirms}', Icons.store,
                        AppColors.warning),
                    _statCard('Posts', '${c.totalPosts}', Icons.post_add,
                        AppColors.primaryRed),
                  ],
                )),
            const SizedBox(height: 22),
            Text('Manage',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.95,
              ),
              children: [
                _menuTile(Icons.people, 'Users', AppRoutes.adminUsers),
                _menuTile(
                    Icons.business, 'Firms', AppRoutes.adminFirms),
                _menuTile(Icons.category, 'Data &\nCategories',
                    AppRoutes.adminData),
                _menuTile(
                    Icons.local_offer, 'Offers', AppRoutes.adminOffers),
                _menuTile(Icons.subscriptions, 'Subscriptions',
                    AppRoutes.adminSubscriptions),
                _menuTile(Icons.contact_mail, 'Inquiries',
                    AppRoutes.adminContacts),
                _menuTile(
                    Icons.post_add, 'Posts', AppRoutes.adminPosts),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(.12), shape: BoxShape.circle),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String label, String route) {
    return InkWell(
      onTap: () => Get.toNamed(route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: AppColors.gradientButton,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
