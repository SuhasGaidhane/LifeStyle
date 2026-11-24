import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/admin_controller.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  Color _planColor(String p) {
    switch (p) {
      case 'premium':
        return AppColors.accentYellow;
      case 'basic':
        return AppColors.info;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AdminController>();
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: const BrandAppBar(title: 'Manage Users'),
      body: Obx(() => ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: c.users.length,
            itemBuilder: (_, i) {
              final u = c.users[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    SafeNetworkImage(
                        url: u.avatar,
                        width: 50,
                        height: 50,
                        borderRadius: BorderRadius.circular(25)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(u.name,
                                  style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _planColor(u.membership),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(u.membership.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                            ),
                          ]),
                          Text('${u.mobile} • ${u.city}',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          Row(
                            children: [
                              Icon(
                                u.isActive
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 12,
                                color: u.isActive
                                    ? AppColors.accentGreen
                                    : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(u.isActive ? 'Active' : 'Inactive',
                                  style: GoogleFonts.poppins(
                                      fontSize: 10.5,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (v) => _onAction(c, u, v),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'view', child: Text('View Details')),
                        const PopupMenuItem(
                            value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                            value: 'toggle', child: Text('Toggle Active')),
                        const PopupMenuItem(
                            value: 'membership',
                            child: Text('Assign Membership')),
                        const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete',
                                style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ],
                ),
              );
            },
          )),
    );
  }

  void _onAction(AdminController c, UserModel u, String v) {
    switch (v) {
      case 'view':
        Get.dialog(AlertDialog(
          title: Text(u.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mobile: ${u.mobile}'),
              Text('Email: ${u.email}'),
              Text('City: ${u.city}'),
              Text('Membership: ${u.membership}'),
              Text('Has Shop: ${u.hasShop}'),
              Text('Joined: ${u.joinDate.toString().split(' ')[0]}'),
            ],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Close')),
          ],
        ));
        break;
      case 'toggle':
        c.toggleUserActive(u.id);
        break;
      case 'delete':
        Get.dialog(AlertDialog(
          title: const Text('Delete User'),
          content: Text('Remove ${u.name}?'),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                c.deleteUser(u.id);
                Get.back();
              },
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        ));
        break;
      case 'membership':
        Get.bottomSheet(Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Assign Membership',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...['free', 'basic', 'premium'].map((p) => ListTile(
                    title: Text(p.toUpperCase()),
                    onTap: () {
                      c.assignMembership(u.id, p);
                      Get.back();
                    },
                  )),
            ],
          ),
        ));
        break;
      case 'edit':
        Get.snackbar('Edit', 'Open user edit form (demo)',
            snackPosition: SnackPosition.BOTTOM);
        break;
    }
  }
}
