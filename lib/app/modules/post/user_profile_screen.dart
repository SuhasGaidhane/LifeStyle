import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/image_viewer.dart';
import 'full_screen_post_viewer.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _api = Get.find<ApiService>();
  final _session = Get.find<SessionService>();

  late final String userId;
  Map<String, dynamic>? _profile;
  List<dynamic> _posts = [];
  bool _loading = true;
  bool _following = false;
  bool _isMe = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    userId = '${Get.arguments ?? ''}';
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getUserProfile(userId, viewerId: _session.userId);
      setState(() {
        _profile = data;
        _posts = (data['posts'] is List) ? data['posts'] : [];
        _following = data['is_following'] == true || data['is_following'] == 1;
        _isMe = data['is_me'] == true || data['is_me'] == 1;
      });
    } catch (_) {
      Get.snackbar('Error', 'Could not load profile',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final viewer = _session.userId;
    final target = int.tryParse(userId);
    if (viewer == null || target == null || _busy) return;
    setState(() {
      _busy = true;
      _following = !_following;
    });
    try {
      if (_following) {
        await _api.follow(viewer, target);
      } else {
        await _api.unfollow(viewer, target);
      }
      await _load();
    } catch (_) {
      setState(() => _following = !_following); // revert
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _s(String key) => (_profile?[key] ?? '').toString();
  int _n(String key) => int.tryParse('${_profile?[key] ?? 0}') ?? 0;

  /// Opens the full post detail viewer for a tapped grid post.
  Future<void> _openPost(Map<String, dynamic> p) async {
    // The profile posts don't carry author info — merge it in so the
    // viewer shows the correct name/avatar/city.
    final merged = Map<String, dynamic>.from(p)
      ..putIfAbsent('user_id', () => _profile?['id'])
      ..putIfAbsent('full_name', () => _profile?['full_name'])
      ..putIfAbsent('profile_image', () => _profile?['profile_image'])
      ..putIfAbsent('city', () => _profile?['city']);
    var post = PostModel.fromJson(merged);
    // Fetch fresh full detail (viewer flags) when possible.
    try {
      final full = await _api.getPost(post.id, viewerId: _session.userId);
      post = PostModel.fromJson(full);
    } catch (_) {}
    Get.to(
      () => FullScreenPostViewer(post: post, initialIndex: 0),
      transition: Transition.fadeIn,
      fullscreenDialog: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: BrandAppBar(
        title: _loading ? 'Profile' : _s('full_name'),
        eyebrow: 'creator',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => showImageViewer(_s('profile_image')),
                        child: SafeNetworkImage(
                          url: _s('profile_image').isNotEmpty
                              ? _s('profile_image')
                              : 'https://ui-avatars.com/api/?name=User&background=D4A853&color=fff',
                          width: 90,
                          height: 90,
                          borderRadius: BorderRadius.circular(45),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(_s('full_name'),
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(_s('city'),
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _stat('${_n('followers_count')}', 'Followers'),
                          _stat('${_n('following_count')}', 'Following'),
                          _stat('${_n('posts_count')}', 'Posts'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (!_isMe)
                        SizedBox(
                          width: 200,
                          child: GradientButton(
                            label: _following ? 'Following' : 'Follow',
                            icon: _following
                                ? Icons.check
                                : Icons.person_add,
                            onTap: _toggleFollow,
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
                if (_posts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(30),
                    child: Center(
                      child: Text('No posts yet',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary)),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: _posts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemBuilder: (_, i) {
                      final p = Map<String, dynamic>.from(_posts[i]);
                      final media = (p['media'] is List) ? p['media'] : [];
                      final thumb = media.isNotEmpty
                          ? '${media.first['media_url']}'
                          : 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400';
                      final isVideo = media.isNotEmpty &&
                          '${media.first['media_type']}' == 'video';
                      return GestureDetector(
                        onTap: () => _openPost(p),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              SafeNetworkImage(url: thumb),
                              if (isVideo)
                                const Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Icon(Icons.play_circle_fill,
                                      color: Colors.white, size: 20),
                                ),
                              if ((p['media'] is List) &&
                                  (p['media'] as List).length > 1)
                                const Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Icon(Icons.collections,
                                      color: Colors.white, size: 18),
                                ),
                            ],
                          ),
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
