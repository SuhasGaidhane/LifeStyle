import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/shop_share.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/image_viewer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper — detect a video URL by extension
// ─────────────────────────────────────────────────────────────────────────────
bool _isVideoUrl(String url) {
  final u = url.toLowerCase().split('?').first;
  return u.endsWith('.mp4') ||
      u.endsWith('.mov') ||
      u.endsWith('.webm') ||
      u.endsWith('.m3u8') ||
      u.endsWith('.mkv');
}

class OwnerDetailScreen extends StatefulWidget {
  const OwnerDetailScreen({super.key});

  @override
  State<OwnerDetailScreen> createState() => _OwnerDetailScreenState();
}

class _OwnerDetailScreenState extends State<OwnerDetailScreen>
    with TickerProviderStateMixin {
  late final ShopModel shop;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    shop = Get.arguments as ShopModel;
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

  // Latest Updates feed — updates/on-site media only. Shop gallery images
  // (profileImages) are intentionally excluded here.
  List<String> get _updates => [
    ...shop.onSiteWorkImages,
  ].toSet().toList();

  /// url → structured item (title/description) for the story viewer caption.
  Map<String, OnSiteWorkItem> get _updateMeta {
    final m = <String, OnSiteWorkItem>{};
    for (final w in [...shop.latestUpdates, ...shop.onSiteWorks]) {
      if (w.url.isNotEmpty && !m.containsKey(w.url)) m[w.url] = w;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BrandAppBar(
        title: shop.firmName,
        eyebrow: shop.categories.isNotEmpty ? shop.categories.first : null,
        actions: [
          BrandAppBarAction(
            icon: Icons.share_outlined,
            onTap: () => _share(shop),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: FadeTransition(
        opacity: _fade,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _hero()),
            SliverToBoxAdapter(child: _ownerCard()),

            SliverToBoxAdapter(child: _locationMap()),
            if (shop.description.isNotEmpty)
              SliverToBoxAdapter(child: _aboutSection()),
            // Products are hidden for premium-service shops.
            if (shop.products.isNotEmpty && !shop.isPremium)
              SliverToBoxAdapter(child: _productsSection()),
            if (_updates.isNotEmpty)
              SliverToBoxAdapter(child: _updatesSection()),
            if (shop.onSiteWorks.isNotEmpty)
              SliverToBoxAdapter(child: _onSiteWorkSection()),
            // Upcoming Project — premium-service shops only.
            if (shop.isPremium && shop.upcomingProjects.isNotEmpty)
              SliverToBoxAdapter(child: _upcomingSection()),
            if (shop.clientList.isNotEmpty)
              SliverToBoxAdapter(child: _clientsSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // Hero — first non-video SHOP image only; falls back to the Lifestyle
  // logo (NOT the owner photo) when the shop has no image.
  Widget _hero() {
    final firstImage = shop.profileImages.firstWhere(
          (u) => !_isVideoUrl(u),
      orElse: () => '',
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: GestureDetector(
        onTap: () => showImageViewer(firstImage),
        child: SizedBox(
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SafeNetworkImage(
                  url: firstImage, fallbackAsset: kLifestyleLogoAsset),
            ),
            // ClipRRect(
            //   borderRadius: BorderRadius.circular(24),
            //   child: Container(
            //     decoration: const BoxDecoration(
            //       gradient: LinearGradient(
            //         colors: [
            //           Color(0x33000000),
            //           Color(0x11000000),
            //           Color(0xCC000000),
            //         ],
            //         begin: Alignment.topCenter,
            //         end: Alignment.bottomCenter,
            //       ),
            //     ),
            //   ),
            // ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.goldLight.withOpacity(0.35),
                  width: 1,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _ownerCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(radius: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment:MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Expanded(
                  child: Column(
                    children: [

                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.goldLight.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: AppColors.goldLight.withOpacity(0.6),
                                  width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified,
                                    size: 11, color: AppColors.goldLight),
                                const SizedBox(width: 5),
                                Text('VERIFIED PARTNER',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.goldLight,
                                      letterSpacing: 1.8,
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            shop.firmName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 12, color: Colors.black),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                    '${shop.city}  ·  ${shop.location}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    )
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          GestureDetector(
                            onTap: () => showImageViewer(shop.avatar),
                            child: Container(
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
                                color: AppColors.card,
                                shape: BoxShape.circle,
                              ),
                              child: SafeNetworkImage(
                                url: shop.avatar,
                                width: 56,
                                height: 56,
                                borderRadius: BorderRadius.circular(28),
                                fallbackAsset: kLifestyleLogoAsset,
                              ),
                            ),
                          ),
                          ),
                          const SizedBox(width: 14),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [


                              Text('OWNER',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.gold,
                                    letterSpacing: 2.2,
                                  )),
                              const SizedBox(height: 3),
                              Text(
                                shop.ownerName,
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.phone,
                                      size: 12, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(shop.mobile,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      )),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      if (shop.otherMobile.isNotEmpty ||
                          shop.email.isNotEmpty ||
                          shop.address.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              AppColors.cardBorder.withOpacity(0),
                              AppColors.goldLight.withOpacity(0.5),
                              AppColors.cardBorder.withOpacity(0),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (shop.otherMobile.isNotEmpty)
                          _InfoRow(
                              icon: Icons.phone_iphone,
                              label: 'Alt. Mobile',
                              value: shop.otherMobile,
                              onTap: () => _call(shop.otherMobile)),
                        if (shop.email.isNotEmpty)
                          _InfoRow(
                              icon: Icons.mail_outline,
                              label: 'Email',
                              value: shop.email,
                              onTap: () => _email(shop.email)),
                        if (shop.address.isNotEmpty)
                          _InfoRow(
                              icon: Icons.home_outlined,
                              label: 'Address',
                              value: shop.address,
                              isLast: true),
                      ],

                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Column(
                  children: [
                    const SizedBox(width: 10),
                    ImageActionButton(
                      image: "assets/images/whatsappIcon.png",
                      onTap: () => _whatsapp(shop.mobile),
                    ),
                    const SizedBox(height: 10),
                    _IconActionButton(
                      icon: Icons.call,
                      onTap: () => _call(shop.mobile),
                    ),
                    const SizedBox(height: 10),
                    _IconActionButton(
                      icon: Icons.mail_outline,
                      onTap: () => _email(shop.email),
                    ),
                    const SizedBox(height: 8),
                    _IconActionButton(
                      icon: Icons.chat_bubble_outline,
                      onTap: () => _message(shop.mobile),
                    ),
                  ],
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }

  // ── UPDATES SECTION ──────────────────────────────────────────────────
  Widget _updatesSection() {
    final videoCount = _updates.where(_isVideoUrl).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            eyebrow: 'LIVE FEED',
            title: 'Latest Updates',
            trailing: '${_updates.length}',
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _updates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _StoryThumb(
                url: _updates[i],
                index: i,
                onTap: () => _openStoryViewer(i),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            videoCount > 0
                ? '${_updates.length - videoCount} photos · $videoCount videos  ·  Swipe up for details'
                : 'Tap any update to view  ·  Swipe up inside for details',
            style: GoogleFonts.dmSans(
              fontSize: 10.5,
              color: AppColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  void _openStoryViewer(int startIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => _StoryViewer(
          shop: shop,
          items: _updates,
          startIndex: startIndex,
          meta: _updateMeta,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // ── LOCATION MAP ─────────────────────────────────────────────────────
  Widget _locationMap() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            eyebrow: 'LOCATION',
            title: 'Find Us Here',
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _openMap(shop),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _MapCanvasPainter()),
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.9,
                        colors: [
                          Colors.transparent,
                          AppColors.textPrimary.withOpacity(0.08),
                        ],
                      ),
                    ),
                  ),
                  const Center(child: _MapPin()),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.card.withOpacity(0.96),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.goldLight.withOpacity(0.4),
                            width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.goldLight,
                                  AppColors.goldDim
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(Icons.navigation,
                                size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  shop.location.isEmpty
                                      ? shop.city
                                      : shop.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Tap to open in Google Maps',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: AppTheme.goldIconCircleDecoration(),
                            child: const Icon(Icons.arrow_forward_ios,
                                size: 11, color: AppColors.gold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(eyebrow: 'ABOUT', title: 'The Story'),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration(radius: 16),
            child: Text(
              shop.description,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            eyebrow: 'PRODUCTS',
            title: 'My Products',
            trailing: '${shop.products.length}',
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: shop.products.length,
              separatorBuilder: (_, __) =>
              const SizedBox(width: 14),

              itemBuilder: (_, i) {
                final product = shop.products[i];

                return GestureDetector(
                  onTap: () => Get.to(
                    () => ProductDetailScreen(product: product),
                    transition: Transition.cupertino,
                  ),
                  child: Container(
                  width: 180,
                  decoration: AppTheme.cardDecoration(radius: 20),
                  clipBehavior: Clip.hardEdge,

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Product Image
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [

                            SafeNetworkImage(
                              url: product.image,
                            ),

                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.goldBg,
                                  borderRadius:
                                  BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '₹${product.price}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Details
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [

                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                              GoogleFonts.cormorantGaramond(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              product.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                height: 1.5,
                                color:
                                AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── ON-SITE WORK  (media + title + description) ──────────────────────
  Widget _onSiteWorkSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            eyebrow: shop.isPremium ? 'COMPLETED' : 'PORTFOLIO',
            title: shop.isPremium ? 'Completed Project' : 'On-Site Work',
            trailing: '${shop.onSiteWorks.length}',
          ),
          const SizedBox(height: 14),
          ...shop.onSiteWorks.map((w) {
            final isVideo = w.isVideo || _isVideoUrl(w.url);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: AppTheme.cardDecoration(radius: 16),
              clipBehavior: Clip.hardEdge,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // media thumbnail (fixed size — avoids unbounded height)
                  GestureDetector(
                    onTap: () => _openStoryViewer(
                      _updates.indexOf(w.url).clamp(0, _updates.length - 1),
                    ),
                    child: SizedBox(
                      width: 96,
                      height: 96,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (isVideo)
                            _VideoPoster(url: w.url)
                          else
                            SafeNetworkImage(url: w.url),
                          if (isVideo)
                            const Center(
                              child: Icon(Icons.play_circle_fill,
                                  color: Colors.white, size: 28),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // title + description
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            w.title.isEmpty ? 'On-site work' : w.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (w.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              w.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                height: 1.4,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── UPCOMING PROJECT (premium-only; media + title + description) ─────
  Widget _upcomingSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            eyebrow: 'UPCOMING',
            title: 'Upcoming Project',
            trailing: '${shop.upcomingProjects.length}',
          ),
          const SizedBox(height: 14),
          ...shop.upcomingProjects.map((w) {
            final isVideo = w.isVideo || _isVideoUrl(w.url);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: AppTheme.cardDecoration(radius: 16),
              clipBehavior: Clip.hardEdge,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => isVideo ? null : showImageViewer(w.url),
                    child: SizedBox(
                      width: 96,
                      height: 96,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (isVideo)
                            _VideoPoster(url: w.url)
                          else
                            SafeNetworkImage(url: w.url),
                          if (isVideo)
                            const Center(
                              child: Icon(Icons.play_circle_fill,
                                  color: Colors.white, size: 28),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            w.title.isEmpty ? 'Upcoming project' : w.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (w.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              w.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                height: 1.4,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _clientsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            eyebrow: 'TRUSTED BY',
            title: 'Clients',
            trailing: '${shop.clientList.length}',
          ),
          const SizedBox(height: 14),
          ...shop.clientList.map((cl) => GestureDetector(
                onTap: () => Get.to(
                  () => ClientDetailScreen(client: cl),
                  transition: Transition.cupertino,
                ),
                child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: AppTheme.cardDecoration(radius: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.goldLight.withOpacity(0.5),
                            width: 1),
                      ),
                      child: cl.image.isEmpty
                          ? const CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColors.goldBg,
                              child: Icon(Icons.person, color: AppColors.gold),
                            )
                          : SafeNetworkImage(
                              url: cl.image,
                              width: 52,
                              height: 52,
                              borderRadius: BorderRadius.circular(26),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cl.name.isEmpty ? 'Client' : cl.name,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (cl.details.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              cl.details,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                height: 1.4,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              )),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────
  /// Launches a uri; on failure copies [copyValue] to the clipboard.
  Future<void> _open(String uri, {String? copyValue}) async {
    bool ok = false;
    try {
      ok = await launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && copyValue != null) {
      await Clipboard.setData(ClipboardData(text: copyValue));
      Get.snackbar('No app found', 'Copied "$copyValue" to clipboard',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _call(String number) {
    if (number.isEmpty) return;
    _open('tel:$number', copyValue: number);
  }

  void _email(String email) {
    if (email.isEmpty) return;
    _open('mailto:$email', copyValue: email);
  }

  void _whatsapp(String number) {
    if (number.isEmpty) return;
    final cleaned = number.replaceAll(RegExp(r'\D'), '');
    _open('https://wa.me/$cleaned', copyValue: number);
  }

  void _openMap(ShopModel s) {
    final lat = s.latitude.trim();
    final lng = s.longitude.trim();
    final hasCoords = lat.isNotEmpty &&
        lng.isNotEmpty &&
        (double.tryParse(lat) ?? 0) != 0 &&
        (double.tryParse(lng) ?? 0) != 0;
    if (hasCoords) {
      // Precise pin from the shop's saved coordinates.
      _open('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      return;
    }
    // Fall back to a text search on the shop's address details.
    final query = Uri.encodeComponent(
        '${s.firmName}, ${s.address}, ${s.location}, ${s.city}');
    _open('https://www.google.com/maps/search/?api=1&query=$query');
  }

  void _share(ShopModel s) {
    shareShopWithDetails(s);
  }

  void _message(String number) {
    if (number.isEmpty) return;
    _open('sms:$number', copyValue: number);
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? trailing;
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.goldLight, AppColors.goldDim],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    eyebrow,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: AppTheme.goldBadgeDecoration(radius: 20),
            child: Text(
              trailing!,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO ROW
// ─────────────────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  final VoidCallback? onTap;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: AppTheme.goldIconCircleDecoration(),
            child: Icon(icon, size: 13, color: AppColors.gold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ICON ACTION BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: AppColors.goldBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.goldLight.withOpacity(0.5), width: 1),
        ),
        child: Icon(icon, color: AppColors.gold, size: 25),
      ),
    );
  }
}

class ImageActionButton extends StatelessWidget {
  final String image;
  final VoidCallback onTap;
  final double iconSize;

  const ImageActionButton({
    super.key,
    required this.image,
    required this.onTap,
    this.iconSize = 25,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.black12,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Image.asset(
          image,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIDEO POSTER  –  lightweight placeholder with first-frame when ready
// Keeps the controller paused so multiple posters don't drain bandwidth.
// ─────────────────────────────────────────────────────────────────────────────
class _VideoPoster extends StatefulWidget {
  final String url;
  const _VideoPoster({required this.url});

  @override
  State<_VideoPoster> createState() => _VideoPosterState();
}

class _VideoPosterState extends State<_VideoPoster> {
  VideoPlayerController? _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _ctrl = c;
    try {
      await c.initialize();
      if (!mounted) return;
      await c.setVolume(0);
      await c.seekTo(const Duration(milliseconds: 500));
      setState(() => _ready = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _ctrl == null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2A2418), Color(0xFF1A1610)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: _ctrl!.value.size.width,
        height: _ctrl!.value.size.height,
        child: VideoPlayer(_ctrl!),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STORY THUMB  –  circular thumbnail (image or video)
// ─────────────────────────────────────────────────────────────────────────────
class _StoryThumb extends StatelessWidget {
  final String url;
  final int index;
  final VoidCallback onTap;
  const _StoryThumb({
    required this.url,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = _isVideoUrl(url);
    return GestureDetector(
      onTap: onTap,
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
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: SizedBox(
                  width: 66,
                  height: 66,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (isVideo)
                        _VideoPoster(url: url)
                      else
                        SafeNetworkImage(url: url),
                      if (isVideo)
                        Container(
                          color: Colors.black.withOpacity(0.30),
                          child: const Center(
                            child: Icon(Icons.play_arrow,
                                color: Colors.white, size: 26),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isVideo ? 'Video ${index + 1}' : 'Update ${index + 1}',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isVideo ? AppColors.gold : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STORY VIEWER  –  plays images (5s) + videos (native duration)
// ─────────────────────────────────────────────────────────────────────────────
class _StoryViewer extends StatefulWidget {
  final ShopModel shop;
  final List<String> items;
  final int startIndex;
  final Map<String, OnSiteWorkItem> meta;
  const _StoryViewer({
    required this.shop,
    required this.items,
    required this.startIndex,
    this.meta = const {},
  });

  @override
  State<_StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<_StoryViewer>
    with SingleTickerProviderStateMixin {
  late final PageController _pageCtrl;
  late final AnimationController _progressCtrl;
  VideoPlayerController? _videoCtrl;
  late int _current;
  bool _paused = false;

  static const _imageDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _current = widget.startIndex;
    _pageCtrl = PageController(initialPage: _current);
    _progressCtrl = AnimationController(vsync: this, duration: _imageDuration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _goNext();
      });
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrent());
  }

  @override
  void dispose() {
    _disposeVideo();
    _pageCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  void _disposeVideo() {
    _videoCtrl?.removeListener(_onVideoTick);
    _videoCtrl?.dispose();
    _videoCtrl = null;
  }

  Future<void> _loadCurrent() async {
    _progressCtrl.stop();
    _progressCtrl.reset();
    _disposeVideo();

    final url = widget.items[_current];
    if (_isVideoUrl(url)) {
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      _videoCtrl = c;
      try {
        await c.initialize();
        if (!mounted || _videoCtrl != c) return;
        setState(() {});
        _progressCtrl.duration = c.value.duration;
        c.addListener(_onVideoTick);
        if (!_paused) {
          c.play();
          _progressCtrl.forward();
        }
      } catch (_) {
        // Fall back to 5s still
        if (!mounted) return;
        _progressCtrl.duration = _imageDuration;
        if (!_paused) _progressCtrl.forward();
      }
    } else {
      _progressCtrl.duration = _imageDuration;
      if (!_paused) _progressCtrl.forward();
    }
  }

  void _onVideoTick() {
    final v = _videoCtrl;
    if (v == null || !v.value.isInitialized) return;
    if (v.value.position >= v.value.duration &&
        !v.value.isPlaying &&
        _progressCtrl.status != AnimationStatus.completed) {
      _goNext();
    }
  }

  void _goNext() {
    if (_current < widget.items.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goPrev() {
    if (_current > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _onPageChanged(int i) {
    setState(() => _current = i);
    _loadCurrent();
  }

  void _togglePause(bool paused) {
    setState(() => _paused = paused);
    if (paused) {
      _progressCtrl.stop();
      _videoCtrl?.pause();
    } else {
      _videoCtrl?.play();
      _progressCtrl.forward();
    }
  }

  void _openListSheet() {
    _togglePause(true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _UpdatesListSheet(
        shop: widget.shop,
        items: widget.items,
        currentIndex: _current,
        onSelect: (i) {
          Navigator.of(context).pop();
          _pageCtrl.jumpToPage(i);
        },
      ),
    ).then((_) => _togglePause(false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTapUp: (details) {
                final w = MediaQuery.of(context).size.width;
                if (details.globalPosition.dx < w / 3) {
                  _goPrev();
                } else {
                  _goNext();
                }
              },
              onLongPressStart: (_) => _togglePause(true),
              onLongPressEnd: (_) => _togglePause(false),
              onVerticalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                if (v > 500) {
                  Navigator.of(context).pop();
                } else if (v < -500) {
                  _openListSheet();
                }
              },
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: widget.items.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (_, i) {
                  final url = widget.items[i];
                  if (i != _current) {
                    // Not-current pages show a still placeholder — avoids
                    // spawning multiple video controllers.
                    if (_isVideoUrl(url)) {
                      return Container(
                        color: Colors.black,
                        child: const Center(
                          child: Icon(Icons.play_circle_outline,
                              color: Colors.white24, size: 64),
                        ),
                      );
                    }
                    return Center(
                      child: SafeNetworkImage(url: url, fit: BoxFit.contain),
                    );
                  }
                  // Current page
                  if (_isVideoUrl(url)) {
                    final c = _videoCtrl;
                    if (c == null || !c.value.isInitialized) {
                      return const Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.goldLight,
                          ),
                        ),
                      );
                    }
                    return Center(
                      child: AspectRatio(
                        aspectRatio: c.value.aspectRatio,
                        child: VideoPlayer(c),
                      ),
                    );
                  }
                  return Center(
                    child: SafeNetworkImage(url: url, fit: BoxFit.contain),
                  );
                },
              ),
            ),

            // Top + bottom dim gradients
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xCC000000), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 300,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xE6000000)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),

            // Progress bars
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Row(
                children: List.generate(
                  widget.items.length,
                      (i) => Expanded(
                    child: Container(
                      height: 2.5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: AnimatedBuilder(
                        animation: _progressCtrl,
                        builder: (_, __) {
                          double value;
                          if (i < _current) {
                            value = 1;
                          } else if (i == _current) {
                            value = _progressCtrl.value;
                          } else {
                            value = 0;
                          }
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.goldLight,
                                    AppColors.goldDim,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 22, 14, 0),
              child: Row(
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
                    child: SafeNetworkImage(
                      url: widget.shop.avatar,
                      width: 32,
                      height: 32,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.shop.firmName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            if (_isVideoUrl(widget.items[_current]))
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.goldLight
                                        .withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                        color: AppColors.goldLight
                                            .withOpacity(0.5),
                                        width: 0.5),
                                  ),
                                  child: Text(
                                    'VIDEO',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.goldLight,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            Flexible(
                              child: Text(
                                '${_current + 1} of ${widget.items.length}  ·  ${widget.shop.city}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Pause/play indicator for videos
                  if (_isVideoUrl(widget.items[_current]) && _videoCtrl != null)
                    GestureDetector(
                      onTap: () => _togglePause(!_paused),
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                        ),
                        child: Icon(
                          _paused ? Icons.play_arrow : Icons.pause,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // Caption — title + description of the current update
            Builder(builder: (_) {
              final info = widget.meta[widget.items[_current]];
              final title = info?.title.trim() ?? '';
              final desc = info?.description.trim() ?? '';
              if (title.isEmpty && desc.isEmpty) {
                return const SizedBox.shrink();
              }
              return Positioned(
                left: 18,
                right: 18,
                bottom: 58,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cormorantGaramond(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: SingleChildScrollView(
                          child: Text(
                            desc,
                            style: GoogleFonts.dmSans(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12.5,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            // Swipe-up hint
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: GestureDetector(
                onTap: _openListSheet,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.goldLight.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Swipe up for all updates',
                      style: GoogleFonts.dmSans(
                        fontSize: 10.5,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
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
// UPDATES LIST SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _UpdatesListSheet extends StatelessWidget {
  final ShopModel shop;
  final List<String> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  const _UpdatesListSheet({
    required this.shop,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ALL UPDATES',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gold,
                              letterSpacing: 2.5,
                            )),
                        const SizedBox(height: 2),
                        Text(shop.firmName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.1,
                            )),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: AppTheme.goldBadgeDecoration(radius: 20),
                    child: Text(
                      '${items.length}',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.cardBorder.withOpacity(0),
                  AppColors.goldLight.withOpacity(0.5),
                  AppColors.cardBorder.withOpacity(0),
                ]),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final url = items[i];
                  final isVideo = _isVideoUrl(url);
                  final isCurrent = i == currentIndex;
                  return GestureDetector(
                    onTap: () => onSelect(i),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrent
                              ? AppColors.goldLight.withOpacity(0.7)
                              : AppColors.cardBorder,
                          width: isCurrent ? 1.4 : 1,
                        ),
                        boxShadow: isCurrent
                            ? [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (isVideo)
                                    _VideoPoster(url: url)
                                  else
                                    SafeNetworkImage(url: url),
                                  if (isVideo)
                                    Container(
                                      color: Colors.black.withOpacity(0.3),
                                      child: const Center(
                                        child: Icon(Icons.play_arrow,
                                            color: Colors.white, size: 22),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      isVideo ? 'Video' : 'Photo',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.gold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text('· #${i + 1}',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 9,
                                          color: AppColors.textMuted,
                                        )),
                                  ],
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  isVideo
                                      ? 'Tap to play'
                                      : 'Update #${i + 1}',
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isCurrent ? 'Now viewing' : 'Tap to view',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: isCurrent
                                        ? AppColors.gold
                                        : AppColors.textMuted,
                                    fontWeight: isCurrent
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: AppTheme.goldIconCircleDecoration(),
                            child: Icon(
                              isVideo
                                  ? Icons.play_arrow
                                  : Icons.arrow_forward_ios,
                              size: isVideo ? 16 : 12,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAP PIN + CANVAS PAINTER (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class _MapPin extends StatefulWidget {
  const _MapPin();
  @override
  State<_MapPin> createState() => _MapPinState();
}

class _MapPinState extends State<_MapPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              return Stack(
                alignment: Alignment.center,
                children: List.generate(3, (i) {
                  final progress = ((_ctrl.value + i / 3) % 1.0);
                  return Opacity(
                    opacity: (1 - progress).clamp(0.0, 1.0),
                    child: Container(
                      width: 80 * progress,
                      height: 80 * progress,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.goldLight.withOpacity(0.7),
                            width: 1.5),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.goldLight, AppColors.goldDim],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.5),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.location_on,
                color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = AppColors.surface;
    canvas.drawRect(Offset.zero & size, bg);

    final block = Paint()
      ..color = AppColors.cardBorder.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final rng = math.Random(42);
    for (int i = 0; i < 18; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final w = 18.0 + rng.nextDouble() * 42;
      final h = 14.0 + rng.nextDouble() * 32;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h),
          const Radius.circular(3),
        ),
        block,
      );
    }

    final street = Paint()
      ..color = AppColors.card
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final streetMinor = Paint()
      ..color = AppColors.card.withOpacity(0.7)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, size.height * 0.55),
        Offset(size.width, size.height * 0.48), street);
    canvas.drawLine(Offset(size.width * 0.45, 0),
        Offset(size.width * 0.52, size.height), street);
    canvas.drawLine(Offset(0, size.height * 0.25),
        Offset(size.width, size.height * 0.22), streetMinor);
    canvas.drawLine(Offset(0, size.height * 0.78),
        Offset(size.width, size.height * 0.82), streetMinor);
    canvas.drawLine(Offset(size.width * 0.18, 0),
        Offset(size.width * 0.22, size.height), streetMinor);
    canvas.drawLine(Offset(size.width * 0.78, 0),
        Offset(size.width * 0.82, size.height), streetMinor);

    final river = Paint()
      ..color = AppColors.goldLight.withOpacity(0.35)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    path.moveTo(0, size.height * 0.9);
    path.quadraticBezierTo(size.width * 0.3, size.height * 0.7,
        size.width * 0.5, size.height * 0.75);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.82,
        size.width, size.height * 0.65);
    canvas.drawPath(path, river);

    final green = Paint()..color = AppColors.goldBg;
    for (int i = 0; i < 8; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 6 + rng.nextDouble() * 6, green);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT DETAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const BrandAppBar(title: 'Product', eyebrow: 'DETAILS'),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // Image (tap to zoom)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: GestureDetector(
              onTap: () => showImageViewer(product.image),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: SafeNetworkImage(url: product.image),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name.isEmpty ? 'Product' : product.name,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.goldBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '₹${product.price}',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text('DESCRIPTION',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                        letterSpacing: 2.5,
                      )),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration(radius: 16),
                    child: Text(
                      product.description,
                      style: GoogleFonts.dmSans(
                        fontSize: 13.5,
                        height: 1.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLIENT DETAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ClientDetailScreen extends StatelessWidget {
  final ClientItem client;
  const ClientDetailScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const BrandAppBar(title: 'Client', eyebrow: 'TRUSTED BY'),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 24),
          // Avatar (tap to zoom)
          Center(
            child: GestureDetector(
              onTap: () => showImageViewer(client.image),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.goldLight, AppColors.goldDim],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: client.image.isEmpty
                    ? const CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.goldBg,
                        child: Icon(Icons.person,
                            color: AppColors.gold, size: 48),
                      )
                    : SafeNetworkImage(
                        url: client.image,
                        width: 120,
                        height: 120,
                        borderRadius: BorderRadius.circular(60),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              client.name.isEmpty ? 'Client' : client.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (client.details.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ABOUT',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                        letterSpacing: 2.5,
                      )),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration(radius: 16),
                    child: Text(
                      client.details,
                      style: GoogleFonts.dmSans(
                        fontSize: 13.5,
                        height: 1.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}