import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/post_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PostController>();
    final userId = (Get.arguments as String?) ?? 'u1';
    final userPosts = c.posts.where((p) => p.userId == userId).toList();
    final user = userPosts.isNotEmpty
        ? userPosts.first
        : c.posts.first; // fallback for demo

    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: BrandAppBar(title: user.userName),
      body: ListView(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                SafeNetworkImage(
                  url: user.userAvatar,
                  width: 90,
                  height: 90,
                  borderRadius: BorderRadius.circular(45),
                ),
                const SizedBox(height: 12),
                Text(user.userName,
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(user.userCity,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: () => Get.toNamed(AppRoutes.followersList,
                          arguments: 'followers'),
                      child: _stat('${userPosts.length * 12}', 'Followers'),
                    ),
                    InkWell(
                      onTap: () => Get.toNamed(AppRoutes.followersList,
                          arguments: 'following'),
                      child: _stat('${userPosts.length * 5}', 'Following'),
                    ),
                    _stat('${userPosts.length}', 'Posts'),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 200,
                  child: GradientButton(
                    label: 'Follow',
                    icon: Icons.person_add,
                    onTap: () => Get.snackbar('Followed',
                        'You are now following ${user.userName}',
                        snackPosition: SnackPosition.BOTTOM),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text('Posts',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: userPosts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (_, i) {
              final p = userPosts[i];
              return InkWell(
                onTap: () =>
                    Get.toNamed(AppRoutes.postDetail, arguments: p.id),
                child: SafeNetworkImage(
                  url: p.media.isNotEmpty
                      ? p.media.first.url
                      : 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400',
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _stat(String n, String label) {
    return Column(
      children: [
        Text(n,
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700)),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
