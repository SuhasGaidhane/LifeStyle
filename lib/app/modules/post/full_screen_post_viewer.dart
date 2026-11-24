import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../controllers/post_controller.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/post_share.dart';
import '../../widgets/common_widgets.dart';
import 'comments_bottom_sheet.dart';

bool _isVideoUrl(String url) {
  final u = url.toLowerCase().split('?').first;
  return u.endsWith('.mp4') ||
      u.endsWith('.mov') ||
      u.endsWith('.webm') ||
      u.endsWith('.m3u8');
}

// ─────────────────────────────────────────────────────────────────────────────
// FULL SCREEN POST VIEWER
// ─────────────────────────────────────────────────────────────────────────────
class FullScreenPostViewer extends StatefulWidget {
  final PostModel post;
  final int initialIndex;        // media index within the first post
  final List<PostModel>? posts;  // when provided -> vertical reel of posts
  final int postIndex;           // which post to start on
  const FullScreenPostViewer({
    super.key,
    required this.post,
    this.initialIndex = 0,
    this.posts,
    this.postIndex = 0,
  });

  @override
  State<FullScreenPostViewer> createState() => _FullScreenPostViewerState();
}

class _FullScreenPostViewerState extends State<FullScreenPostViewer> {
  late final PageController _vController;
  late int _vIndex;

  @override
  void initState() {
    super.initState();
    _vIndex = widget.postIndex;
    _vController = PageController(initialPage: widget.postIndex);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _vController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posts = widget.posts;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: (posts != null && posts.isNotEmpty)
            // Reel: swipe up/down to move between posts.
            ? PageView.builder(
                scrollDirection: Axis.vertical,
                controller: _vController,
                itemCount: posts.length,
                onPageChanged: (i) => setState(() => _vIndex = i),
                itemBuilder: (_, i) => _PostPage(
                  post: posts[i],
                  active: i == _vIndex,
                  initialMediaIndex: i == widget.postIndex ? widget.initialIndex : 0,
                  onClose: () => Navigator.pop(context),
                ),
              )
            : _PostPage(
                post: widget.post,
                active: true,
                initialMediaIndex: widget.initialIndex,
                onClose: () => Navigator.pop(context),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SINGLE POST PAGE  (one page of the vertical reel)
// ─────────────────────────────────────────────────────────────────────────────
class _PostPage extends StatefulWidget {
  final PostModel post;
  final bool active;
  final int initialMediaIndex;
  final VoidCallback onClose;
  const _PostPage({
    required this.post,
    required this.active,
    required this.onClose,
    this.initialMediaIndex = 0,
  });

  @override
  State<_PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<_PostPage> {
  late final PageController _pageCtrl;
  late int _currentIndex;
  bool _descExpanded = false;
  bool _showChrome = true;
  PostController? _ctrl;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialMediaIndex;
    _pageCtrl = PageController(initialPage: widget.initialMediaIndex);
    if (Get.isRegistered<PostController>()) {
      _ctrl = Get.find<PostController>();
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _toggleChrome() => setState(() => _showChrome = !_showChrome);

  void _call(String number) async {
    if (number.isEmpty) return;
    final uri = Uri.parse('tel:$number');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${(d.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    return Stack(
      children: [
        // ── Media pager (horizontal) ───────────────────────────────
        GestureDetector(
          onTap: _toggleChrome,
          behavior: HitTestBehavior.opaque,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: p.media.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) {
              final m = p.media[i];
              final isVideo = m.isVideo || _isVideoUrl(m.url);
              if (isVideo) {
                return _FullScreenVideo(
                  url: m.url,
                  isActive: widget.active && i == _currentIndex,
                );
              }
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: SafeNetworkImage(url: m.url, fit: BoxFit.contain),
                ),
              );
            },
          ),
        ),

        // ── Top chrome ─────────────────────────────────────────────
        AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: _showChrome ? 1 : 0,
          child: IgnorePointer(
            ignoring: !_showChrome,
            child: Align(
              alignment: Alignment.topCenter,
              child: _TopChrome(
                post: p,
                onClose: widget.onClose,
                index: _currentIndex,
                total: p.media.length,
              ),
            ),
          ),
        ),

        // ── Bottom chrome ──────────────────────────────────────────
        AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: _showChrome ? 1 : 0,
          child: IgnorePointer(
            ignoring: !_showChrome,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _BottomChrome(
                post: p,
                descExpanded: _descExpanded,
                onExpand: () => setState(() => _descExpanded = !_descExpanded),
                onLike: () {
                  _ctrl?.toggleLike(p.id);
                  setState(() {});
                },
                onShare: () => sharePostWithMedia(p),
                onCall: () => _call(p.contactNumber),
                timeAgo: _timeAgo(p.createdAt),
                pageDotsIndex: _currentIndex,
              ),
            ),
          ),
        ),

        // Subtle "swipe up for next" hint on the active page
        if (widget.active)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 2,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Icon(Icons.keyboard_arrow_up,
                    color: Colors.white.withOpacity(0.35), size: 20),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP CHROME
// ─────────────────────────────────────────────────────────────────────────────
class _TopChrome extends StatelessWidget {
  final PostModel post;
  final VoidCallback onClose;
  final int index;
  final int total;
  const _TopChrome({
    required this.post,
    required this.onClose,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.78), Colors.transparent],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        bottom: 28,
        left: 6,
        right: 12,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
          ),
          Container(
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
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: SafeNetworkImage(
                url: post.userAvatar,
                width: 32,
                height: 32,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        post.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified,
                        size: 12, color: AppColors.gold),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 10, color: Colors.white70),
                    const SizedBox(width: 2),
                    Text(
                      post.userCity,
                      style: GoogleFonts.dmSans(
                        fontSize: 10.5,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (total > 1)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white24, width: 0.5),
              ),
              child: Text(
                '${index + 1} / $total',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM CHROME
// ─────────────────────────────────────────────────────────────────────────────
class _BottomChrome extends StatelessWidget {
  final PostModel post;
  final bool descExpanded;
  final VoidCallback onExpand;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onCall;
  final String timeAgo;
  final int pageDotsIndex;
  const _BottomChrome({
    required this.post,
    required this.descExpanded,
    required this.onExpand,
    required this.onLike,
    required this.onShare,
    required this.onCall,
    required this.timeAgo,
    required this.pageDotsIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.88),
            Colors.black.withOpacity(0.55),
            Colors.transparent,
          ],
          stops: const [0, 0.55, 1],
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 40,
        left: 18,
        right: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page dots
          if (post.media.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  post.media.length,
                      (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == pageDotsIndex ? 22 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == pageDotsIndex
                          ? AppColors.gold
                          : Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),

          // Actions row
          Row(
            children: [
              _RoundAction(
                icon: post.liked ? Icons.favorite : Icons.favorite_border,
                color: post.liked ? AppColors.error : Colors.white,
                label: '${post.likeCount}',
                onTap: onLike,
              ),
              const SizedBox(width: 12),
              _RoundAction(
                icon: Icons.chat_bubble_outline,
                color: Colors.white,
                label: '${post.commentCount}',
                onTap: () => CommentsBottomSheet.show(context, post),
              ),
              const SizedBox(width: 12),
              _RoundAction(
                icon: Icons.send_outlined,
                color: Colors.white,
                onTap: onShare,
              ),
              const Spacer(),
              _RoundAction(
                icon: Icons.call,
                color: AppColors.gold,
                filled: true,
                onTap: onCall,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Description (expandable)
          if (post.description.isNotEmpty)
            GestureDetector(
              onTap: onExpand,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topLeft,
                child: RichText(
                  maxLines: descExpanded ? null : 2,
                  overflow: descExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  text: TextSpan(
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.45,
                    ),
                    children: [
                      TextSpan(
                        text: '${post.userName}  ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: post.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (!descExpanded && post.description.length > 80)
                        TextSpan(
                          text: '  more',
                          style: GoogleFonts.dmSans(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),
          Text(
            timeAgo,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: Colors.white60,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? label;
  final VoidCallback onTap;
  final bool filled;
  const _RoundAction({
    required this.icon,
    required this.color,
    required this.onTap,
    this.label,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled
                  ? AppColors.gold.withOpacity(0.18)
                  : Colors.white.withOpacity(0.12),
              border: Border.all(
                color: filled
                    ? AppColors.goldLight.withOpacity(0.5)
                    : Colors.white24,
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(
              label!,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FULLSCREEN VIDEO — autoplay with sound when active, with scrubber
// ─────────────────────────────────────────────────────────────────────────────
class _FullScreenVideo extends StatefulWidget {
  final String url;
  final bool isActive;
  const _FullScreenVideo({required this.url, required this.isActive});

  @override
  State<_FullScreenVideo> createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<_FullScreenVideo> {
  VideoPlayerController? _ctrl;
  bool _ready = false;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _FullScreenVideo old) {
    super.didUpdateWidget(old);
    if (_ctrl != null && _ready) {
      if (widget.isActive && !_ctrl!.value.isPlaying) {
        _ctrl!.play();
      } else if (!widget.isActive && _ctrl!.value.isPlaying) {
        _ctrl!.pause();
      }
    }
  }

  void _init() async {
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _ctrl = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(1);
      if (!mounted) return;
      setState(() => _ready = true);
      if (widget.isActive) c.play();
    } catch (_) {}
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_ctrl == null || !_ready) return;
    if (_ctrl!.value.isPlaying) {
      _ctrl!.pause();
    } else {
      _ctrl!.play();
    }
    setState(() {});
  }

  void _toggleMute() async {
    _muted = !_muted;
    await _ctrl?.setVolume(_muted ? 0 : 1);
    setState(() {});
  }

  /// Seeks by [delta] (negative = reverse), clamped to the video bounds.
  void _seekBy(Duration delta) {
    final c = _ctrl;
    if (c == null || !_ready) return;
    var target = c.value.position + delta;
    if (target < Duration.zero) target = Duration.zero;
    if (target > c.value.duration) target = c.value.duration;
    c.seekTo(target);
    setState(() {});
  }

  Widget _seekButton(IconData icon, VoidCallback onTap, {double size = 48}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.4),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.55),
      ),
    );
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _ctrl == null) {
      return const Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
              strokeWidth: 2.8, color: AppColors.gold),
        ),
      );
    }
    final isPlaying = _ctrl!.value.isPlaying;
    return GestureDetector(
      onTap: _togglePlay,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _ctrl!.value.aspectRatio,
              child: VideoPlayer(_ctrl!),
            ),
          ),

          // Center play overlay when paused
          Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: isPlaying ? 0 : 1,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.goldLight, AppColors.goldDim],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.45),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Icon(Icons.play_arrow,
                    color: Colors.white, size: 40),
              ),
            ),
          ),

          // Progress + mute (sits above bottom chrome)
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 170,
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _ctrl!,
              builder: (_, v, __) {
                return Row(
                  children: [
                    // Reverse 10s — left of the progress bar
                    _seekButton(Icons.replay_10,
                        () => _seekBy(const Duration(seconds: -10)),
                        size: 40),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag anywhere on the bar to seek forward / reverse.
                          VideoProgressIndicator(
                            _ctrl!,
                            allowScrubbing: true,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            colors: const VideoProgressColors(
                              playedColor: AppColors.gold,
                              bufferedColor: Colors.white38,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmt(v.position),
                                  style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                              Text(_fmt(v.duration),
                                  style: GoogleFonts.dmSans(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Forward 10s — right of the progress bar
                    _seekButton(Icons.forward_10,
                        () => _seekBy(const Duration(seconds: 10)),
                        size: 40),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _toggleMute,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.5),
                        ),
                        child: Icon(
                          _muted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}