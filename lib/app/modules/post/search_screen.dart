import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _searchCtrl;
  late final FocusNode _focus;
  String _q = '';

  final List<String> _recent = [
    'Manoj Mahi',
    'Priya',
    'Rajesh',
    'Sunil Verma',
  ];

  /// Follow state keyed by user id (seeded from the API's is_following).
  final Set<String> _followingIds = {};

  final _api = Get.find<ApiService>();
  final _session = Get.find<SessionService>();

  final List<FollowerModel> _results = [];   // search results
  final List<FollowerModel> _suggested = [];  // shown when query is empty

  FollowerModel _mapUser(Map<String, dynamic> j) => FollowerModel(
        id: '${j['id'] ?? ''}',
        name: (j['full_name'] ?? '').toString(),
        avatar: (j['profile_image']?.toString().isNotEmpty ?? false)
            ? j['profile_image'].toString()
            : 'https://ui-avatars.com/api/?name=User&background=D4A853&color=fff',
        city: (j['city'] ?? '').toString(),
      );

  Future<void> _runSearch(String q) async {
    try {
      final list = await _api.searchUsers(q: q, viewerId: _session.userId);
      final users = <FollowerModel>[];
      for (final e in list) {
        final m = Map<String, dynamic>.from(e);
        final u = _mapUser(m);
        users.add(u);
        if (m['is_following'] == true || m['is_following'] == 1) {
          _followingIds.add(u.id);
        }
      }
      if (!mounted) return;
      setState(() {
        if (q.isEmpty) {
          _suggested
            ..clear()
            ..addAll(users);
        } else {
          _results
            ..clear()
            ..addAll(users);
        }
      });
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _focus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    _runSearch(''); // load suggested users
    _searchCtrl.addListener(() {
      final v = _searchCtrl.text.trim();
      if (v != _q) {
        setState(() => _q = v);
        _runSearch(v);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commitSearch(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    setState(() {
      _recent.remove(t);
      _recent.insert(0, t);
      if (_recent.length > 8) _recent.removeRange(8, _recent.length);
    });
  }

  bool _isFollowing(FollowerModel u) => _followingIds.contains(u.id);

  Future<void> _toggleFollow(FollowerModel u) async {
    final viewer = _session.userId;
    final target = int.tryParse(u.id);
    if (viewer == null || target == null) return;
    final wasFollowing = _followingIds.contains(u.id);
    setState(() {
      if (wasFollowing) {
        _followingIds.remove(u.id);
      } else {
        _followingIds.add(u.id);
      }
    });
    try {
      if (wasFollowing) {
        await _api.unfollow(viewer, target);
      } else {
        await _api.follow(viewer, target);
      }
    } catch (_) {
      // revert on failure
      setState(() {
        if (wasFollowing) {
          _followingIds.add(u.id);
        } else {
          _followingIds.remove(u.id);
        }
      });
    }
  }

  List<FollowerModel> get _users => _q.isEmpty ? const [] : _results;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              _Header(
                controller: _searchCtrl,
                focusNode: _focus,
                onBack: () => Navigator.pop(context),
                onSubmit: _commitSearch,
                onClear: () {
                  _searchCtrl.clear();
                  setState(() => _q = '');
                },
              ),
              Expanded(
                child: _q.isEmpty ? _buildEmptyState() : _buildResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty / discover state ────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      children: [
        if (_recent.isNotEmpty) ...[
          _SectionHeader(
            title: 'Recent',
            actionLabel: 'Clear all',
            onAction: () => setState(_recent.clear),
          ),
          const SizedBox(height: 6),
          ..._recent.map((r) => _RecentTile(
            text: r,
            onTap: () {
              _searchCtrl.text = r;
              _searchCtrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: r.length));
              setState(() => _q = r);
            },
            onRemove: () => setState(() => _recent.remove(r)),
          )),
          const SizedBox(height: 14),
        ],
        _SectionHeader(title: 'Trending Creators'),
        const SizedBox(height: 10),
        SizedBox(
          height: 102,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _suggested.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) => _TrendingCreator(user: _suggested[i]),
          ),
        ),
        const SizedBox(height: 10),
        _SectionHeader(title: 'Suggested for you'),
        const SizedBox(height: 4),
        ..._suggested.map((u) => _UserResultTile(
          user: u,
          following: _isFollowing(u),
          onTap: () =>
              Get.toNamed(AppRoutes.userProfile, arguments: u.id),
          onToggleFollow: () => _toggleFollow(u),
        )),
      ],
    );
  }

  // ── Results state ─────────────────────────────────────────────────────────
  Widget _buildResults() {
    final users = _users;
    if (users.isEmpty) return _NoResults(query: _q);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      children: [
        _SectionHeader(title: 'People · ${users.length}'),
        const SizedBox(height: 4),
        ...users.map((u) => _UserResultTile(
          user: u,
          following: _isFollowing(u),
          onTap: () {
            _commitSearch(_searchCtrl.text);
            Get.toNamed(AppRoutes.userProfile, arguments: u.id);
          },
          onToggleFollow: () => _toggleFollow(u),
        )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER  (back + search field + clear)
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onBack;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClear;
  const _Header({
    required this.controller,
    required this.focusNode,
    required this.onBack,
    required this.onSubmit,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 16, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 18, color: AppColors.textPrimary),
          ),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: focusNode.hasFocus
                      ? AppColors.goldLight.withOpacity(0.6)
                      : AppColors.cardBorder,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: AppColors.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      cursorColor: AppColors.gold,
                      textInputAction: TextInputAction.search,
                      onSubmitted: onSubmit,
                      style: GoogleFonts.dmSans(
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search people…',
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (_, v, __) {
                      if (v.text.isEmpty) return const SizedBox.shrink();
                      return GestureDetector(
                        onTap: onClear,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 22,
                          height: 22,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.cardBorder,
                          ),
                          child: const Icon(Icons.close,
                              size: 13, color: AppColors.textSecondary),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECENT TILE
// ─────────────────────────────────────────────────────────────────────────────
class _RecentTile extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _RecentTile({
    required this.text,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.card,
                  border:
                  Border.all(color: AppColors.cardBorder, width: 0.6),
                ),
                child: const Icon(Icons.history,
                    size: 15, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close,
                      size: 15, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRENDING CREATOR
// ─────────────────────────────────────────────────────────────────────────────
class _TrendingCreator extends StatelessWidget {
  final FollowerModel user;
  const _TrendingCreator({required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.userProfile, arguments: user.id),
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  color: AppColors.bg,
                  shape: BoxShape.circle,
                ),
                child: SafeNetworkImage(
                  url: user.avatar,
                  width: 56,
                  height: 56,
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 10.5,
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
// USER RESULT TILE  (with follow / following state)
// ─────────────────────────────────────────────────────────────────────────────
class _UserResultTile extends StatelessWidget {
  final FollowerModel user;
  final bool following;
  final VoidCallback onTap;
  final VoidCallback onToggleFollow;
  const _UserResultTile({
    required this.user,
    required this.following,
    required this.onTap,
    required this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(1.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.goldLight, AppColors.goldDim],
                  ),
                ),
                child: SafeNetworkImage(
                  url: user.avatar,
                  width: 42,
                  height: 42,
                  borderRadius: BorderRadius.circular(21),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
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
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      following ? 'Following' : 'Creator',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _FollowPill(
                following: following,
                onTap: onToggleFollow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FOLLOW PILL  (Follow gradient ↔ Following gold-tinted)
// ─────────────────────────────────────────────────────────────────────────────
class _FollowPill extends StatelessWidget {
  final bool following;
  final VoidCallback onTap;
  const _FollowPill({required this.following, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: following
            ? Container(
          key: const ValueKey('following'),
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 6),
          decoration: AppTheme.goldBadgeDecoration(radius: 30),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check,
                  size: 12, color: AppColors.gold),
              const SizedBox(width: 4),
              Text(
                'Following',
                style: GoogleFonts.dmSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        )
            : Container(
          key: const ValueKey('follow'),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NO RESULTS
// ─────────────────────────────────────────────────────────────────────────────
class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.goldBg,
                    AppColors.goldLight.withOpacity(0.08),
                  ],
                ),
                border: Border.all(
                  color: AppColors.goldLight.withOpacity(0.45),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.person_search,
                  size: 34, color: AppColors.gold),
            ),
            const SizedBox(height: 16),
            Text(
              'No people found for "$query"',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different name.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}