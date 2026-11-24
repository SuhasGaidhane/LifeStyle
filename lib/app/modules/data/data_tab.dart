import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/banner_controller.dart';
import '../../controllers/services_controller.dart';
import '../../data/models.dart';
import '../../routes/app_routes.dart';
import '../../widgets/image_viewer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE MAP
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, String> _categoryImages = {
  'Architect':
      'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=600&q=80',
  'Interior Designer':
      'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600&q=80',
  'Builders & Developers':
      'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?w=600&q=80',
  'Wallpaper':
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&q=80',
  'Curtains':
      'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=600&q=80',
  'Furniture':
      'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=600&q=80',
  'Painter':
      'https://images.unsplash.com/photo-1562259929-b4e1fd3aef09?w=600&q=80',
  'Plumber':
      'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=600&q=80',
  'Electrician':
      'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=600&q=80',
};

// ─────────────────────────────────────────────────────────────────────────────
// PALETTE  –  White-background luxury gold
// ─────────────────────────────────────────────────────────────────────────────
class _P {
  // Backgrounds
  static const bg = Color(0xFFFAF9F6); // warm off-white
  static const card = Color(0xFFFFFFFF); // pure white card
  static const cardBorder = Color(0xFFEDE9E1); // warm cream border
  static const surface = Color(0xFFF4F1EB); // slightly tinted surface

  // Gold
  static const gold = Color(0xFFB8912A); // deeper gold on white (more contrast)
  static const goldLight = Color(0xFFD4A853); // standard gold
  static const goldDim = Color(0xFF8C6B2F); // dark gold
  static const goldBg = Color(0xFFFDF6E7); // very light gold tint bg

  // Text
  static const textPrimary = Color(0xFF1A1610); // near-black warm
  static const textSecondary = Color(0xFF7A7060); // warm mid-grey
  static const textMuted = Color(0xFFB0A898); // light warm muted
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA TAB
// ─────────────────────────────────────────────────────────────────────────────
class DataTab extends StatefulWidget {
  const DataTab({super.key});

  @override
  State<DataTab> createState() => _DataTabState();
}

class _DataTabState extends State<DataTab> with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;
  final _scrollCtrl = ScrollController();
  double _heroParallax = 0;

  final _services = Get.find<ServicesController>();
  final _banners = Get.find<BannersController>();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _services.load(); // refresh from backend
    _banners.load();
    _scrollCtrl.addListener(() {
      setState(() => _heroParallax = _scrollCtrl.offset.clamp(0, 120));
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // dark icons because background is now white
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _P.bg,
        body: FadeTransition(
          opacity: _fade,
          child: Obx(() {
            // Home shows only services that currently have at least one
            // (active) shop — empty services are hidden here (Home only).
            final topThree =
                _services.premium.where((c) => c.shopsCount > 0).toList();
            final remaining =
                _services.free.where((c) => c.shopsCount > 0).toList();
            if (_services.isLoading.value && topThree.isEmpty && remaining.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: _P.gold),
              );
            }
            return CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── HERO (live banners from /banners) ─────────────────────────
              SliverToBoxAdapter(child: _BannerCarousel(controller: _banners)),

              // ── SECTION TITLE ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // eyebrow
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [_P.goldLight, _P.goldDim],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('PREMIUM SERVICES',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _P.gold,
                                letterSpacing: 3,
                              )),
                          const SizedBox(width: 8),
                          const Icon(Icons.workspace_premium,
                              size: 13, color: _P.goldLight),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── TOP 3 PREMIUM TILES ───────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _PremiumTile(
                      category: topThree[i],
                      index: i,
                      onTap: () => _onTopTap(auth, topThree[i]),
                    ),
                    childCount: topThree.length,
                  ),
                ),
              ),

              // ── DIVIDER ───────────────────────────────────────────────────
              // ── SECTION TITLE ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // eyebrow
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [_P.goldLight, _P.goldDim],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('MORE SERVICES',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _P.gold,
                                letterSpacing: 3,
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── REMAINING GRID ────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(   
                    (_, i) => _GridTile(
                      category: remaining[i],
                      delay: i * 60,
                      onTap: () => Get.toNamed(AppRoutes.serviceList,
                          arguments: remaining[i]),
                    ),
                    childCount: remaining.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                ),
              ),
                ],
              );
          }),
        ),
      ),
    );
  }

  void _onTopTap(AuthController auth, ServiceCategory cat) {
    // Premium services open only when the backend granted click-access.
    if (cat.access) {
      Get.toNamed(AppRoutes.serviceList, arguments: cat);
    } else {
      _showDialog(cat);
    }
  }

  void _showDialog(ServiceCategory cat) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: _P.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _P.cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: _P.gold.withOpacity(0.12),
                  blurRadius: 40,
                  spreadRadius: 4),
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8)),
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Premium Services',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: _P.textPrimary,
                  )),

              // Gold icon circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      colors: [_P.goldLight, _P.goldDim],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  boxShadow: [
                    BoxShadow(
                        color: _P.goldLight.withOpacity(0.35),
                        blurRadius: 20,
                        spreadRadius: 2)
                  ],
                ),
                child: const Icon(Icons.lock_open_sharp,
                    color: Colors.white, size: 35),
              ),
              const SizedBox(height: 10),
              Text(
                'To Unlock Services\n\nList your Shop\non this platform',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 16,
                    color: Colors.black,
                    height: 1.6,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: Get.back,
                      style: TextButton.styleFrom(
                        foregroundColor: _P.textMuted,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('Later',
                          style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoutes.addShop);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [_P.goldLight, _P.goldDim],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: _P.gold.withOpacity(0.30),
                                blurRadius: 16,
                                offset: const Offset(0, 6))
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text('Add My Shop',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.white,
                            )),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BANNER CAROUSEL  –  live banners from /banners
// ─────────────────────────────────────────────────────────────────────────────
class _BannerCarousel extends StatefulWidget {
  final BannersController controller;
  const _BannerCarousel({required this.controller});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  int _current = 0;

  // Fallback banner shown while loading or if the API returns nothing.
  static final _fallback = BannerModel(
    id: '0',
    title: 'Discover Premium\nHome Services',
    subtitle: '',
    imageUrl:
        'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=1200&q=85',
    linkUrl: '',
  );

  Future<void> _openLink(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = widget.controller.banners.isEmpty
          ? [_fallback]
          : widget.controller.banners.toList();

      return SizedBox(
        height: 230,
        child: Stack(
          children: [
            CarouselSlider.builder(
              itemCount: list.length,
              options: CarouselOptions(
                height: 230,
                viewportFraction: 1,
                autoPlay: list.length > 1,
                autoPlayInterval: const Duration(seconds: 4),
                onPageChanged: (i, _) => setState(() => _current = i),
              ),
              itemBuilder: (_, i, __) => _slide(list[i]),
            ),
            // Page dots
            if (list.length > 1)
              Positioned(
                bottom: 12,
                right: 22,
                child: Row(
                  children: List.generate(
                    list.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: i == _current ? 18 : 5,
                      height: 5,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: i == _current
                            ? _P.goldLight
                            : Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _slide(BannerModel b) {
    return GestureDetector(
      onTap: () => b.linkUrl.isNotEmpty ? _openLink(b.linkUrl) : showImageViewer(b.imageUrl),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            child: Image.network(
              b.imageUrl,
              fit: BoxFit.fitHeight,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(color: _P.surface),
            ),
          ),
          // Gradient overlay
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            child: Container(
              // decoration: const BoxDecoration(
              //   gradient: LinearGradient(
              //     colors: [
              //       Color(0x88000000),
              //       Color(0x33000000),
              //       Color(0xBB000000),
              //     ],
              //     begin: Alignment.topCenter,
              //     end: Alignment.bottomCenter,
              //   ),
              // ),
            ),
          ),
          // Title + subtitle
          Positioned(
            left: 22,
            bottom: 28,
            right: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Container(
                //   padding:
                //       const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                //   decoration: BoxDecoration(
                //     color: _P.goldLight.withOpacity(0.18),
                //     borderRadius: BorderRadius.circular(30),
                //     border:
                //         Border.all(color: _P.goldLight.withOpacity(0.5), width: 1),
                //   ),
                //   child: Row(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       const Icon(Icons.auto_awesome, size: 10, color: _P.goldLight),
                //       const SizedBox(width: 5),
                //       Text('LIFE STYLE EXPOSURE',
                //           style: GoogleFonts.dmSans(
                //             fontSize: 9,
                //             fontWeight: FontWeight.w700,
                //             color: _P.goldLight,
                //             letterSpacing: 1.5,
                //           )),
                //     ],
                //   ),
                // ),
                const SizedBox(height: 10),
                Text(b.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.15,
                    )),
                if (b.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(b.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM TILE  –  full-width horizontal card
// ─────────────────────────────────────────────────────────────────────────────
class _PremiumTile extends StatefulWidget {
  final ServiceCategory category;
  final int index;
  final VoidCallback onTap;

  const _PremiumTile(
      {required this.category, required this.index, required this.onTap});

  @override
  State<_PremiumTile> createState() => _PremiumTileState();
}

class _PremiumTileState extends State<_PremiumTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = widget.category.iconUrl.isNotEmpty
        ? widget.category.iconUrl
        : (_categoryImages[widget.category.name] ??
            'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=600');

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          onTapDown: (_) {
            setState(() => _pressed = true);
            _ctrl.forward();
          },
          onTapUp: (_) {
            setState(() => _pressed = false);
            _ctrl.reverse();
            widget.onTap();
          },
          onTapCancel: () {
            setState(() => _pressed = false);
            _ctrl.reverse();
          },
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: _P.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _pressed ? _P.goldLight.withOpacity(0.6) : _P.cardBorder,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _pressed
                      ? _P.gold.withOpacity(0.14)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: _pressed ? 22 : 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Row(
              children: [
                // Image section
                SizedBox(
                  width: 110,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(img,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                                color: _P.surface,
                                child: Center(
                                    child: Text(widget.category.icon,
                                        style: const TextStyle(fontSize: 30))),
                              )),
                      // Right fade to white card
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, _P.card],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Text section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Premium badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _P.goldBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: _P.goldLight.withOpacity(0.4), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium,
                                  size: 10, color: _P.gold),
                              const SizedBox(width: 3),
                              Text('PREMIUM',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: _P.gold,
                                    letterSpacing: 1,
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(widget.category.name,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _P.textPrimary,
                            )),
                      ],
                    ),
                  ),
                ),

                // Arrow button
                // Arrow / Lock button
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.category.access
                          ? _P.goldBg
                          : Colors.red.withOpacity(0.08),
                      border: Border.all(
                        color: widget.category.access
                            ? _P.goldLight.withOpacity(0.4)
                            : Colors.red.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      widget.category.access
                          ? Icons.arrow_forward_ios
                          : Icons.lock,
                      size: 12,
                      color: widget.category.access ? _P.gold : Colors.red,
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
// GRID TILE  –  compact card for "More Services"
// ─────────────────────────────────────────────────────────────────────────────
class _GridTile extends StatefulWidget {
  final ServiceCategory category;
  final int delay;
  final VoidCallback onTap;

  const _GridTile(
      {required this.category, required this.delay, required this.onTap});

  @override
  State<_GridTile> createState() => _GridTileState();
}

class _GridTileState extends State<_GridTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slide = Tween(begin: 20.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Prefer the admin-uploaded icon URL; else the built-in image; else emoji.
    final img = widget.category.iconUrl.isNotEmpty
        ? widget.category.iconUrl
        : _categoryImages[widget.category.name];

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _fade.value,
        child:
            Transform.translate(offset: Offset(0, _slide.value), child: child),
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _P.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _P.cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image / icon area
              Expanded(
                flex: 5,
                child: img != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(img,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _iconFallback()),
                          // Bottom fade to white
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 28,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    _P.card.withOpacity(0.85),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : _iconFallback(),
              ),

              // Label area
              Expanded(
                flex: 3,
                child: Container(
                  color: _P.card,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.category.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _P.textPrimary,
                            height: 1.2,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconFallback() => Container(
        color: _P.surface,
        alignment: Alignment.center,
        child: Text(widget.category.icon, style: const TextStyle(fontSize: 28)),
      );
}
