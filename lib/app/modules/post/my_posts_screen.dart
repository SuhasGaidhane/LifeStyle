import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'full_screen_post_viewer.dart';

/// Lists the logged-in user's own posts with view + delete.
class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final _api = Get.find<ApiService>();
  final _session = Get.find<SessionService>();

  List<PostModel> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uid = _session.userId;
      final list = await _api.getPosts(viewerId: uid, authorId: uid);
      _posts = list.map((e) => PostModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      Get.snackbar('Error', 'Could not load your posts', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _view(PostModel p) async {
    // fetch fresh detail for accurate flags
    var post = p;
    try {
      final full = await _api.getPost(p.id, viewerId: _session.userId);
      post = PostModel.fromJson(full);
    } catch (_) {}
    Get.to(() => FullScreenPostViewer(post: post, initialIndex: 0),
        transition: Transition.fadeIn, fullscreenDialog: true);
  }

  Future<void> _confirmDelete(PostModel p) async {
    Get.dialog(AlertDialog(
      title: const Text('Delete Post'),
      content: const Text('This will permanently remove the post, its media, likes and comments.'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            Get.back();
            await _delete(p);
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ));
  }

  Future<void> _delete(PostModel p) async {
    final uid = _session.userId;
    if (uid == null) return;
    try {
      await _api.deletePost(p.id, uid);
      _posts.removeWhere((x) => x.id == p.id);
      setState(() {});
      Get.snackbar('Deleted', 'Your post was removed', snackPosition: SnackPosition.BOTTOM);
    } on ApiException catch (e) {
      Get.snackbar('Failed', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      Get.snackbar('Error', 'Could not delete post', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const BrandAppBar(title: 'My Posts'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _posts.isEmpty
              ? const EmptyState(
                  icon: Icons.photo_library_outlined,
                  title: 'No Posts Yet',
                  subtitle: 'Posts you upload will appear here.',
                )
              : RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: _posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _tile(_posts[i]),
                  ),
                ),
    );
  }

  Widget _tile(PostModel p) {
    final media = p.media.isNotEmpty ? p.media.first : null;
    final isVideo = media?.isVideo ?? false;
    return InkWell(
      onTap: () => _view(p),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: (media == null)
                    ? Container(color: Colors.black12, child: const Icon(Icons.notes, color: Colors.black45))
                    : Stack(fit: StackFit.expand, children: [
                        (isVideo)
                            ? Container(color: Colors.black12, child: const Icon(Icons.play_circle_fill, color: Colors.black45))
                            : SafeNetworkImage(url: media.url),
                      ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.description.isEmpty ? '(no caption)' : p.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text('${p.likeCount} likes · ${p.commentCount} comments',
                      style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmDelete(p),
            ),
          ],
        ),
      ),
    );
  }
}
