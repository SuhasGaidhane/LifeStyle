import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/post_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class EditPostScreen extends StatefulWidget {
  const EditPostScreen({super.key});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late final TextEditingController descCtrl;
  late final String postId;
  late final c = Get.find<PostController>();

  @override
  void initState() {
    super.initState();
    postId = Get.arguments as String;
    final p = c.findPost(postId);
    descCtrl = TextEditingController(text: p?.description ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final p = c.findPost(postId);
    if (p == null) {
      return const Scaffold(body: Center(child: Text('Post not found')));
    }
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: BrandAppBar(title: 'Edit Post', actions: [
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.white),
          onPressed: () => _confirmDelete(),
        ),
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BrandTextField(
                controller: descCtrl,
                hint: 'Description',
                maxLines: 4,
                prefixIcon: Icons.edit),
            const SizedBox(height: 16),
            Text('Media',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: p.media.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (_, i) => Stack(
                fit: StackFit.expand,
                children: [
                  SafeNetworkImage(
                      url: p.media[i].url,
                      borderRadius: BorderRadius.circular(8)),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => p.media.removeAt(i)),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Save Changes',
              icon: Icons.save,
              onTap: () {
                c.editPost(p.id, descCtrl.text, p.media);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    Get.dialog(AlertDialog(
      title: const Text('Delete Post'),
      content: const Text('Are you sure you want to delete this post?'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            c.deletePost(postId);
            Get.back();
            Get.back();
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ));
  }
}
