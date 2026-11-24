import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/admin_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ManageFirmsScreen extends StatelessWidget {
  const ManageFirmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AdminController>();
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: BrandAppBar(title: 'Manage Firms', actions: [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () => Get.snackbar('Add Firm',
              'Use the user-side Add Shop flow (₹3000+)',
              snackPosition: SnackPosition.BOTTOM),
        ),
      ]),
      body: Obx(() => ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: c.firms.length,
            itemBuilder: (_, i) {
              final s = c.firms[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    SafeNetworkImage(
                        url: s.avatar,
                        width: 50,
                        height: 50,
                        borderRadius: BorderRadius.circular(8)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.firmName,
                              style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700)),
                          Text('${s.ownerName} • ${s.city}',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            children: s.categories
                                .map((c) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentYellow
                                            .withOpacity(.3),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(c,
                                          style: const TextStyle(
                                              fontSize: 10)),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (v) {
                        if (v == 'view') {
                          Get.toNamed(AppRoutes.ownerDetail, arguments: s);
                        } else if (v == 'delete') {
                          c.deleteFirm(s.id);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'view', child: Text('View')),
                        const PopupMenuItem(
                            value: 'edit', child: Text('Edit')),
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
}
