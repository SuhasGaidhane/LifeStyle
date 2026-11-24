import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/post_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class FollowersListScreen extends StatelessWidget {
  const FollowersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PostController>();
    final type = (Get.arguments as String?) ?? 'followers';
    final isFollowers = type == 'followers';
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: BrandAppBar(title: isFollowers ? 'Followers' : 'Following'),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: c.followers.length,
        itemBuilder: (_, i) {
          final f = c.followers[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SafeNetworkImage(
                  url: f.avatar,
                  width: 44,
                  height: 44,
                  borderRadius: BorderRadius.circular(22),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.name,
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(f.city,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ],
                )),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: isFollowers
                        ? AppColors.accentYellow
                        : Colors.grey.shade200,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(isFollowers ? 'Follow Back' : 'Following',
                      style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: AppColors.textPrimary)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
