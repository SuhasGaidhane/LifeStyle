import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lifestyle/app/modules/post/search_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../controllers/post_controller.dart';
import '../../controllers/shop_controller.dart';
import '../../data/dummy_data.dart';
import '../../data/models.dart';
import '../../routes/app_routes.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/post_share.dart';
import '../../widgets/common_widgets.dart';
import 'comments_bottom_sheet.dart';
import 'full_screen_post_viewer.dart';

bool _isVideoUrl(String url) {
  final u = url.toLowerCase().split('?').first;
  return u.endsWith('.mp4') ||
      u.endsWith('.mov') ||
      u.endsWith('.webm') ||
      u.endsWith('.m3u8');
}

// ─────────────────────────────────────────────────────────────────────────────
// POST TAB
// ─────────────────────────────────────────────────────────────────────────────
class PostTab extends StatefulWidget {
  const PostTab({super.key});

  @override
  State<PostTab> createState() => _PostTabState();
}

class _PostTabState extends State<PostTab> with TickerProviderStateMixin {
  late final PostController c;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    c = Get.isRegistered<PostController>()
        ? Get.find<PostController>()
        : Get.put(PostController());
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: FadeTransition(
          opacity: _fade,
          child: RefreshIndicator(
            color: AppColors.gold,
            backgroundColor: AppColors.card,
            onRefresh: () async {
              await Future.wait([c.loadFeed(), c.loadFollowing()]);
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // ── Top action bar (Search + Profile) ──────────────────
                SliverToBoxAdapter(
                  child: _TopActionBar(
                    avatarUrl: Get.find<SessionService>().user?.avatar ?? '',
                    onSearch: () => Get.to(
                          () => const SearchScreen(),
                      transition: Transition.fadeIn,
                    ),
                    onProfile: () => Get.toNamed(
                      AppRoutes.userProfile,
                      arguments: Get.find<SessionService>().user?.id ??
                          DummyData.currentUser.id,
                    ),
                  ),
                ),
                // ── Stories strip: my profile + who I follow ────────────
                SliverToBoxAdapter(
                  child: Obx(() => _StoriesStrip(
                        myAvatar:
                            Get.find<SessionService>().user?.avatar ?? '',
                        following: c.followers.toList(),
                      )),
                ),

                // ── Gold divider ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppColors.cardBorder.withOpacity(0),
                          AppColors.goldLight.withOpacity(0.5),
                          AppColors.cardBorder.withOpacity(0),
                        ]),
                      ),
                    ),
                  ),
                ),

                // ── Posts list ──────────────────────────────────────────
                Obx(() {
                  final posts = c.posts;
                  if (posts.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.photo_library_outlined,
                        title: 'No Posts Yet',
                        subtitle:
                        'Follow creators or upload your own to see beautiful work here.',
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(0, 6, 0, 30),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _PostCard(
                          post: posts[i],
                          index: i,
                          onLike: () => c.toggleLike(posts[i].id),
                          onComment: () => CommentsBottomSheet.show(ctx, posts[i]),
                          onFollow: () => c.toggleFollow(posts[i].id),
                          onTapUser: () => Get.toNamed(
                              AppRoutes.userProfile,
                              arguments: posts[i].userId),
                        ),
                        childCount: posts.length,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP ACTION BAR  –  Search pill + Profile avatar
// ─────────────────────────────────────────────────────────────────────────────
class _TopActionBar extends StatelessWidget {
  final String avatarUrl;
  final VoidCallback onSearch;
  final VoidCallback onProfile;
  const _TopActionBar({
    required this.avatarUrl,
    required this.onSearch,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Row(
          children: [
            // ── Search pill ────────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: onSearch,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.goldLight.withOpacity(0.35),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.search,
                          size: 18, color: AppColors.gold),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Search creators, posts, tags…',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Profile avatar ─────────────────────────────────────────
            GestureDetector(
              onTap: onProfile,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.goldLight, AppColors.goldDim],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: const BoxDecoration(
                    color: AppColors.bg,
                    shape: BoxShape.circle,
                  ),
                  child: SafeNetworkImage(
                    url: avatarUrl,
                    width: 34,
                    height: 34,
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onUpload;
  final VoidCallback onNotifications;
  const _TopBar({required this.onUpload, required this.onNotifications});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
        child: Row(
          children: [
            // Brand serif name with gold dash
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.goldLight, AppColors.goldDim],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.workspace_premium,
                        color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Exposure',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            _TopIcon(
              icon: Icons.add_box_outlined,
              onTap: onUpload,
            ),
            const SizedBox(width: 4),
            _TopIcon(
              icon: Icons.notifications_none,
              onTap: onNotifications,
              badge: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;
  const _TopIcon({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: AppColors.textPrimary),
          ),
          if (badge)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.goldLight, AppColors.goldDim],
                  ),
                  border: Border.all(color: AppColors.bg, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STORIES STRIP
// ─────────────────────────────────────────────────────────────────────────────
class _StoriesStrip extends StatelessWidget {
  final String myAvatar;
  final List<FollowerModel> following;
  const _StoriesStrip({required this.myAvatar, required this.following});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: following.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          if (i == 0) {
            // First tile = my profile ("Your story")
            return _YourStoryTile(
              avatar: myAvatar,
              onTap: () => Get.find<ShopController>().openUploadPost(),
            );
          }
          // Right side = users I follow
          final f = following[i - 1];
          return _StoryAvatar(follower: f);
        },
      ),
    );
  }
}

class _YourStoryTile extends StatelessWidget {
  final String avatar;
  final VoidCallback onTap;
  const _YourStoryTile({required this.avatar, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 66,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.cardBorder,
                      width: 1.5,
                    ),
                  ),
                  child: SafeNetworkImage(
                    url: avatar,
                    width: 58,
                    height: 58,
                    borderRadius: BorderRadius.circular(29),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.goldLight, AppColors.goldDim],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: AppColors.bg, width: 2),
                    ),
                    child: const Icon(Icons.add,
                        color: Colors.white, size: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Your story',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 6,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final FollowerModel follower;
  const _StoryAvatar({required this.follower});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Get.toNamed(AppRoutes.userProfile, arguments: follower.id),
      child: SizedBox(
        width: 66,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.goldLight, AppColors.goldDim],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.bg,
                  shape: BoxShape.circle,
                ),
                child: SafeNetworkImage(
                  url: follower.avatar,
                  width: 54,
                  height: 54,
                  borderRadius: BorderRadius.circular(27),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              follower.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POST CARD
// ─────────────────────────────────────────────────────────────────────────────
class _PostCard extends StatefulWidget {
  final PostModel post;
  final int index;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onFollow;
  final VoidCallback onTapUser;
  const _PostCard({
    required this.post,
    required this.index,
    required this.onLike,
    required this.onComment,
    required this.onFollow,
    required this.onTapUser,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  int _currentMedia = 0;
  bool _saved = false;

  void _onDoubleTap() {
    if (!widget.post.liked) widget.onLike();
  }

  bool _sharing = false;

  Future<void> _sharePost() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await sharePostWithMedia(widget.post);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    // The logged-in user should not see Follow/Following on their own posts.
    final isMe = Get.find<SessionService>().user?.id == p.userId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onTapUser,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.goldLight, AppColors.goldDim],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.bg,
                        shape: BoxShape.circle,
                      ),
                      child: SafeNetworkImage(
                        url: p.userAvatar,
                        width: 34,
                        height: 34,
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onTapUser,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified,
                                size: 12, color: AppColors.gold),
                            if (!isMe) const SizedBox(width: 10),
                            if (!isMe && !p.following)
                              GestureDetector(
                                onTap: widget.onFollow,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.goldLight, AppColors.goldDim],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.gold.withOpacity(0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'Follow',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              )
                            else if (!isMe)
                              GestureDetector(
                                onTap: widget.onFollow, // tap to unfollow
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration:
                                      AppTheme.goldBadgeDecoration(radius: 30),
                                  child: Text(
                                    'Following',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ),
                              ),

                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 10, color: AppColors.textMuted),
                            const SizedBox(width: 2),
                            Text(
                              p.userCity,
                              style: GoogleFonts.dmSans(
                                fontSize: 10.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),


                _ActionButton(
                  icon: Icons.call,
                  activeColor: AppColors.gold,
                  filled: true,
                  onTap: () => _call(p.contactNumber),
                ),
                // IconButton(
                //   onPressed: () => _showMoreSheet(context, p),
                //   icon: const Icon(Icons.more_horiz,
                //       size: 20, color: AppColors.textSecondary),
                //   padding: EdgeInsets.zero,
                //   constraints: const BoxConstraints(
                //       minWidth: 32, minHeight: 32),
                // ),
              ],
            ),
          ),

          // Media
          // Media
          // Media
          GestureDetector(
            onDoubleTap: _onDoubleTap,
            child: _MediaCarousel(
              media: p.media,
              currentIndex: _currentMedia,
              onPageChanged: (i) => setState(() => _currentMedia = i),
              onTapMedia: (i) {
                final all = Get.find<PostController>().posts.toList();
                final pIndex = all.indexWhere((x) => x.id == p.id);
                Get.to(
                      () => FullScreenPostViewer(
                    post: p,
                    initialIndex: i,
                    posts: all,
                    postIndex: pIndex < 0 ? 0 : pIndex,
                  ),
                  transition: Transition.fadeIn,
                  fullscreenDialog: true,
                  opaque: true,
                );
              },
            ),
          ),

          // Dots (only if multi-media)
          if (p.media.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  p.media.length,
                      (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: i == _currentMedia ? 18 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: i == _currentMedia
                          ? AppColors.gold
                          : AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),

          // Action row — counts sit right next to each icon
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Row(
              children: [
                _ActionButton(
                  icon: p.liked ? Icons.favorite : Icons.favorite_border,
                  activeColor: AppColors.error,
                  active: p.liked,
                  onTap: widget.onLike,
                ),
                Text(
                  '${p.likeCount}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 14),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  onTap: widget.onComment,
                ),
                Text(
                  '${p.commentCount}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 14),
                _ActionButton(
                  icon: Icons.send_outlined,
                  onTap: _sharePost,
                ),
              ],
            ),
          ),

          // Description (left) + time (right)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: p.description.isEmpty
                      ? const SizedBox.shrink()
                      : RichText(
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: GoogleFonts.dmSans(
                              fontSize: 12.5,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text: '${p.userName}  ',
                                style:
                                    const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              TextSpan(
                                text: p.description,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Text(
                  _timeAgo(p.createdAt),
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreSheet(BuildContext context, PostModel p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostMoreSheet(post: p),
    );
  }

  void _call(String number) async {
    if (number.isEmpty) return;
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${(d.inDays / 7).floor()}w ago';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final bool filled;
  final Color activeColor;
  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.filled = false,
    this.activeColor = AppColors.gold,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? AppColors.goldBg : Colors.transparent,
          border: filled
              ? Border.all(
              color: AppColors.goldLight.withOpacity(0.5), width: 1)
              : null,
        ),
        child: Icon(
          icon,
          size: 22,
          color: active ? activeColor : AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEDIA CAROUSEL  –  supports images + videos
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// MEDIA CAROUSEL  –  supports images + videos, tap to open fullscreen
// ─────────────────────────────────────────────────────────────────────────────
class _MediaCarousel extends StatefulWidget {
  final List<PostMediaItem> media;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onTapMedia;
  const _MediaCarousel({
    required this.media,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onTapMedia,
  });

  @override
  State<_MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<_MediaCarousel> {
  final PageController _pageCtrl = PageController();

  // App-wide cache of media aspect ratios (w/h), keyed by URL — so a post
  // that's been seen once renders at its true height instantly with no jump.
  static final Map<String, double> _aspectCache = {};
  double _aspect = 1;

  @override
  void initState() {
    super.initState();
    // If the ratio is already known, start at the correct height (no jump).
    _aspect = _cached(widget.currentIndex) ?? 1;
    _resolve(widget.currentIndex);
  }

  @override
  void didUpdateWidget(covariant _MediaCarousel old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _resolve(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  double? _cached(int i) {
    if (i < 0 || i >= widget.media.length) return null;
    return _aspectCache[widget.media[i].url];
  }

  /// Applies a resolved ratio for [i]; if it's the current page, resizes.
  /// Uses the media's true aspect ratio (w/h) — no clamping, no animation.
  void _setRatio(int i, double r) {
    if (r.isNaN || r <= 0) return;
    _aspectCache[widget.media[i].url] = r;
    if (i == widget.currentIndex && _aspect != r) {
      // Defer to avoid setState during build/layout (image cache can fire
      // the stream listener synchronously).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _aspect != r) setState(() => _aspect = r);
      });
    }
  }

  /// Ensures the aspect ratio for page [i] is known (images resolve here;
  /// videos report theirs via a callback once initialized).
  void _resolve(int i) {
    if (i < 0 || i >= widget.media.length) return;
    final cached = _cached(i);
    if (cached != null) {
      _setRatio(i, cached);
      return;
    }
    final m = widget.media[i];
    if (m.isVideo || _isVideoUrl(m.url)) return; // handled by the player
    final stream = NetworkImage(m.url).resolve(const ImageConfiguration());
    ImageStreamListener? listener;
    listener = ImageStreamListener((info, _) {
      _setRatio(i, info.image.width / info.image.height);
      if (listener != null) stream.removeListener(listener!);
    }, onError: (_, __) {
      if (listener != null) stream.removeListener(listener!);
    });
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: _aspect,
          child: Container(
            color: AppColors.surface,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _pageCtrl,
                  itemCount: widget.media.length,
                  onPageChanged: widget.onPageChanged,
                  itemBuilder: (_, i) {
                    final m = widget.media[i];
                    final isVideo = m.isVideo || _isVideoUrl(m.url);
                    if (isVideo) {
                      return _InlineVideoPlayer(
                        url: m.url,
                        onOpenFullscreen: () => widget.onTapMedia(i),
                        onAspectRatio: (ar) => _setRatio(i, ar),
                      );
                    }
                    return GestureDetector(
                      onTap: () => widget.onTapMedia(i),
                      child: SafeNetworkImage(url: m.url, fit: BoxFit.cover),
                    );
                  },
                ),

                // Multi-media index pill
                if (widget.media.length > 1)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.collections,
                              color: Colors.white, size: 11),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.currentIndex + 1}/${widget.media.length}',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// INLINE VIDEO PLAYER  –  auto-mute, tap to play
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// INLINE VIDEO PLAYER  –  muted preview; tap opens fullscreen viewer
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// INLINE VIDEO PLAYER  –  auto-play when on screen, pause when off
// ─────────────────────────────────────────────────────────────────────────────
class _InlineVideoPlayer extends StatefulWidget {
  final String url;
  final VoidCallback onOpenFullscreen;
  final ValueChanged<double>? onAspectRatio;
  const _InlineVideoPlayer({
    required this.url,
    required this.onOpenFullscreen,
    this.onAspectRatio,
  });

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  VideoPlayerController? _ctrl;
  bool _ready = false;
  bool _muted = false;
  bool _shouldPlay = false; // dictated by visibility

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _ctrl = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(1);
      if (!mounted) return;
      // Report the real aspect ratio so the card can size to the video.
      final ar = c.value.aspectRatio;
      if (ar > 0) widget.onAspectRatio?.call(ar);
      setState(() => _ready = true);
      // If we were already determined visible during init, start playing
      if (_shouldPlay) c.play();
    } catch (_) {}
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final visible = info.visibleFraction > 0.6;
    if (visible == _shouldPlay) return;
    _shouldPlay = visible;
    final c = _ctrl;
    if (c == null || !_ready) return;
    if (visible) {
      c.play();
    } else {
      c.pause();
    }
  }

  void _toggleMute() async {
    _muted = !_muted;
    await _ctrl?.setVolume(_muted ? 0 : 1);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('inline-video-${widget.url}-${identityHashCode(this)}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: (!_ready || _ctrl == null)
          ? Container(
        color: AppColors.surface,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
              strokeWidth: 2.4, color: AppColors.gold),
        ),
      )
          : GestureDetector(
        onTap: widget.onOpenFullscreen,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _ctrl!.value.size.width,
                height: _ctrl!.value.size.height,
                child: VideoPlayer(_ctrl!),
              ),
            ),

            // Top-left "Video" badge
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_circle_outline,
                        color: Colors.white, size: 11),
                    const SizedBox(width: 4),
                    Text(
                      'Video',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom-right mute toggle
            Positioned(
              bottom: 10,
              right: 10,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.55),
                  ),
                  child: Icon(
                    _muted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// POST MORE SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _PostMoreSheet extends StatelessWidget {
  final PostModel post;
  const _PostMoreSheet({required this.post});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SheetItem(icon: Icons.share_outlined, label: 'Share', onTap: () {
        Navigator.pop(context);
        sharePostWithMedia(post);
      }),
      _SheetItem(icon: Icons.link, label: 'Copy link', onTap: () {
        Navigator.pop(context);
        Get.snackbar('Copied', 'Link copied to clipboard',
            snackPosition: SnackPosition.BOTTOM);
      }),
      _SheetItem(
          icon: Icons.person_off_outlined,
          label: 'Unfollow ${post.userName}',
          onTap: () {
            Navigator.pop(context);
          }),
      _SheetItem(
          icon: Icons.flag_outlined,
          label: 'Report',
          danger: true,
          onTap: () => Navigator.pop(context)),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ...items.map((it) => ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: AppTheme.goldIconCircleDecoration(),
              child: Icon(it.icon,
                  size: 17,
                  color: it.danger ? AppColors.error : AppColors.gold),
            ),
            title: Text(it.label,
                style: GoogleFonts.dmSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color:
                  it.danger ? AppColors.error : AppColors.textPrimary,
                )),
            onTap: it.onTap,
          )),
        ],
      ),
    );
  }
}

class _SheetItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  _SheetItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });
}