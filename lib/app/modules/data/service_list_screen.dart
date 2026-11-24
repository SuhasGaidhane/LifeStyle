import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/shop_controller.dart';
import '../../data/models.dart';
import '../../services/api_service.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/image_viewer.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen>
    with TickerProviderStateMixin {
  late ServiceCategory category;
  String selectedState = 'All';
  String selectedCity = 'All';

  // ── Search state ─────────────────────────────────────────────────────
  bool _searching = false;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  static const Map<String, String> _categoryImages = {
    'Architect':
    'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=1200&q=85',
    'Interior Designer':
    'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=1200&q=85',
    'Builders & Developers':
    'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?w=1200&q=85',
    'Wallpaper':
    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=1200&q=85',
    'Curtains':
    'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=1200&q=85',
    'Furniture':
    'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=1200&q=85',
    'Painter':
    'https://images.unsplash.com/photo-1562259929-b4e1fd3aef09?w=1200&q=85',
    'Plumber':
    'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=1200&q=85',
    'Electrician':
    'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=1200&q=85',
  };

  final _shopCtrl = Get.find<ShopController>();
  final _api = Get.find<ApiService>();

  List<dynamic> _banners = [];

  // Only states/cities that actually have shops for THIS service.
  List<String> _facetStates = [];
  Map<String, List<String>> _facetCities = {};

  @override
  void initState() {
    super.initState();
    category = Get.arguments as ServiceCategory;
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    // Load this service's shops + its location facets for filtering.
    _shopCtrl.loadServiceShops(category);
    _loadFacets();
    _loadBanners();
  }

  Future<void> _loadFacets() async {
    final sid = int.tryParse(category.id);
    if (sid == null) return;
    try {
      final data = await _api.getShopFacets(sid);
      final states = List<String>.from(data['states'] ?? const []);
      final citiesRaw = Map<String, dynamic>.from(data['cities'] ?? const {});
      final cities = <String, List<String>>{};
      citiesRaw.forEach((k, v) => cities[k] = List<String>.from(v ?? const []));
      if (mounted) setState(() { _facetStates = states; _facetCities = cities; });
    } catch (_) {}
  }

  List<String> get _cityOptions =>
      (selectedState == 'All') ? const [] : (_facetCities[selectedState] ?? const []);

  Future<void> _loadBanners() async {
    final sid = int.tryParse(category.id);
    if (sid == null) return;
    try {
      final list = await _api.getServiceBanners(sid);
      if (mounted) setState(() => _banners = list);
    } catch (_) {}
  }

  // Reload shops from the backend for the current state/district selection.
  void _reload() {
    _shopCtrl.loadServiceShops(
      category,
      state: selectedState == 'All' ? null : selectedState,
      district: selectedCity == 'All' ? null : selectedCity,
    );
  }

  Future<void> _openShop(ShopModel shop) async {
    // Fetch the full detail (images/products/updates) before navigating.
    final full = await _shopCtrl.fetchShopDetail(shop.id);
    Get.toNamed(AppRoutes.ownerDetail, arguments: full ?? shop);
  }

  // @override
  // void dispose() {
  //   _fadeCtrl.dispose();
  //   _searchCtrl.dispose();
  //   _searchFocus.dispose();
  //   super.dispose();
  // }

  @override
  void dispose() {
    // Clear Service List data
    _shopCtrl.serviceShops.clear();

    // Clear State and City selection
    selectedState = 'All';
    selectedCity = 'All';

    // Clear search
    _searchCtrl.clear();
    _searchQuery = '';
    _searching = false;

    // Dispose controllers
    _searchCtrl.dispose();
    _searchFocus.dispose();

    super.dispose();
  }

  // ── Filtering with search ───────────────────────────────────────────
  // The state/district filtering happens server-side (see _reload); here we
  // only apply the free-text search over the loaded results.
  List<ShopModel> get filtered {
    final q = _searchQuery.trim().toLowerCase();
    final list = _shopCtrl.serviceShops;
    if (q.isEmpty) return list.toList();
    return list.where((s) {
      return s.firmName.toLowerCase().contains(q) ||
          s.ownerName.toLowerCase().contains(q) ||
          s.city.toLowerCase().contains(q) ||
          s.location.toLowerCase().contains(q) ||
          s.address.toLowerCase().contains(q);
    }).toList();
  }

  // ── Search toggle ───────────────────────────────────────────────────
  void _openSearch() {
    setState(() => _searching = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _searchFocus.unfocus();
    setState(() {
      _searching = false;
      _searchCtrl.clear();
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _searching
          ? _SearchAppBar(
        controller: _searchCtrl,
        focusNode: _searchFocus,
        hint: 'Search ${category.name.toLowerCase()}\u2026',
        onChanged: (v) => setState(() => _searchQuery = v),
        onClose: _closeSearch,
      )
          : BrandAppBar(
        title: category.name,
        eyebrow: category.isPremium ? 'Premium Category' : 'Service Category',
        actions: [
          BrandAppBarAction(
            icon: Icons.search,
            onTap: _openSearch,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: FadeTransition(
        opacity: _fade,
        child: Obx(() {
          final results = filtered;
          return CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            // Service banners (managed in Admin → Service Banners)
            if (!_searching && _banners.isNotEmpty)
              SliverToBoxAdapter(child: _serviceBanners()),

            // Active search indicator chip
            if (_searching && _searchQuery.isNotEmpty)
              SliverToBoxAdapter(child: _activeSearchChip()),

            SliverToBoxAdapter(child: _filterSection()),
            SliverToBoxAdapter(child: _resultsHeader(results.length)),

            if (results.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: _searching ? Icons.search_off : Icons.storefront,
                  title: _searching ? 'No Matches' : 'No Shops Found',
                  subtitle: _searching
                      ? 'Nothing matches "$_searchQuery" in ${category.name}. Try a different keyword.'
                      : 'Try changing the city or state filter\u2014or check back later for new listings.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, i) => _ShopCard(
                      shop: results[i],
                      index: i,
                      highlight: _searchQuery,
                      onTap: () => _openShop(results[i]),
                      serviceName: category.name,
                    ),
                    childCount: results.length,
                  ),
                ),
              ),
          ],
        );
        }),
      ),
    );
  }

  // ── SERVICE BANNERS ──────────────────────────────────────────────────
  Widget _serviceBanners() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 180,
          viewportFraction: 1.0,
          autoPlay: _banners.length > 1,
          autoPlayInterval: const Duration(seconds: 4),
        ),
        items: _banners.map((e) {
          final b = Map<String, dynamic>.from(e);
          return GestureDetector(
            onTap: () => showImageViewer('${b['image_url']}'),
            child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                SafeNetworkImage(url: '${b['image_url']}'),
                if ('${b['title'] ?? ''}'.isNotEmpty)
                  Positioned(
                    left: 14, right: 14, bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${b['title']}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ),
          );
        }).toList(),
      ),
    );
  }

  // ── HERO ────────────────────────────────────────────────────────────
  Widget _hero() {
    final img = _categoryImages[category.name] ??
        'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=1200&q=85';

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
      child: SizedBox(
        height: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                img,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surface,
                  alignment: Alignment.center,
                  child: Text(category.icon,
                      style: const TextStyle(fontSize: 48)),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0x44000000),
                      Color(0x22000000),
                      Color(0xBB000000),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.goldLight.withOpacity(0.35),
                  width: 1,
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: AppColors.goldLight.withOpacity(0.5),
                          width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium,
                            size: 11, color: AppColors.goldLight),
                        const SizedBox(width: 5),
                        Text('CURATED LISTINGS',
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
                  Text(category.name,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    '${filtered.length} professionals',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.85),
                      letterSpacing: 0.4,
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

  // ── ACTIVE SEARCH CHIP ──────────────────────────────────────────────
  Widget _activeSearchChip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search, size: 13, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  '"$_searchQuery"',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.25),
                    ),
                    child: const Icon(Icons.close,
                        size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── FILTER SECTION ──────────────────────────────────────────────────
  Widget _filterSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, _searching ? 14 : 18, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _filterLabel('STATE'),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      FilterPillChip(
                        label: 'All',
                        selected: selectedState == 'All',
                        onTap: () {
                          setState(() {
                            selectedState = 'All';
                            selectedCity = 'All';
                          });
                          _reload();
                        },
                      ),
                      const SizedBox(width: 8),
                      ..._facetStates.map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterPillChip(
                          label: s,
                          selected: selectedState == s,
                          onTap: () {
                            setState(() {
                              selectedState = s;
                              selectedCity = 'All';
                            });
                            _reload();
                          },
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // const SizedBox(height: 14),
          Row(
            children: [
              _filterLabel('CITY'),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      FilterPillChip(
                        label: 'All',
                        selected: selectedCity == 'All',
                        onTap: () {
                          setState(() => selectedCity = 'All');
                          _reload();
                        },
                      ),
                      const SizedBox(width: 8),
                      ..._cityOptions.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterPillChip(
                          label: c,
                          selected: selectedCity == c,
                          onTap: () {
                            setState(() => selectedCity = c);
                            _reload();
                          },
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // const SizedBox(height: 8),

        ],
      ),
    );
  }

  Widget _filterLabel(String text) {
    return Row(
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
        Text(text,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
              letterSpacing: 2.5,
            )),
      ],
    );
  }

  // ── RESULTS HEADER ──────────────────────────────────────────────────
  Widget _resultsHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.cardBorder.withOpacity(0),
                  AppColors.cardBorder,
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Text(count.toString(),
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                      height: 1,
                    )),
                const SizedBox(width: 6),
                Text(count == 1 ? 'RESULT' : 'RESULTS',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 2.5,
                    )),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.cardBorder,
                  AppColors.cardBorder.withOpacity(0),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH APP BAR  –  premium white-gold search bar with close chip
// ─────────────────────────────────────────────────────────────────────────────
class _SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const _SearchAppBar({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Container(
        color: AppColors.bg,
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    // Search field
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.goldLight.withOpacity(0.5),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withOpacity(0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            const Icon(Icons.search,
                                size: 18, color: AppColors.gold),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: controller,
                                focusNode: focusNode,
                                onChanged: onChanged,
                                textInputAction: TextInputAction.search,
                                cursorColor: AppColors.gold,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                                  hintText: hint,
                                  hintStyle: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                              ),
                            ),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: controller,
                              builder: (_, value, __) {
                                if (value.text.isEmpty) {
                                  return const SizedBox(width: 14);
                                }
                                return Padding(
                                  padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                                  child: GestureDetector(
                                    onTap: () {
                                      controller.clear();
                                      onChanged('');
                                    },
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.goldBg,
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 12,
                                          color: AppColors.gold),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Close button (matches BrandAppBarAction style)
                    GestureDetector(
                      onTap: onClose,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Gold hairline divider
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.cardBorder.withOpacity(0),
                      AppColors.goldLight.withOpacity(0.6),
                      AppColors.cardBorder.withOpacity(0),
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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 28);
}

// ─────────────────────────────────────────────────────────────────────────────
// SHOP CARD  –  premium tile with press animation + search highlight
// ─────────────────────────────────────────────────────────────────────────────
class _ShopCard extends StatefulWidget {
  final ShopModel shop;
  final int index;
  final String highlight;
  final VoidCallback onTap;
  final String serviceName;
  const _ShopCard({
    required this.shop,
    required this.index,
    required this.highlight,
    required this.onTap,
    required this.serviceName,
  });

  @override
  State<_ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<_ShopCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _fade;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    // _ctrl = AnimationController(
    //     vsync: this, duration: const Duration(milliseconds: 5));
    // _slide = Tween(begin: 14.0, end: 0.0)
    //     .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    // _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    // Future.delayed(Duration(milliseconds: widget.index * 60), () {
    //   if (mounted) _ctrl.forward();
    // });
  }

  @override
  void dispose() {
    // _ctrl.dispose();
    super.dispose();
  }

  // Highlight matched text in gold
  TextSpan _highlighted(String text, TextStyle baseStyle) {
    final q = widget.highlight.trim();
    if (q.isEmpty) return TextSpan(text: text, style: baseStyle);

    final lower = text.toLowerCase();
    final query = q.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int idx;
    while ((idx = lower.indexOf(query, start)) != -1) {
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: baseStyle));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: baseStyle.copyWith(
          color: AppColors.gold,
          fontWeight: FontWeight.w800,
          backgroundColor: AppColors.goldBg,
        ),
      ));
      start = idx + query.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
    }
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.shop;

    // return AnimatedBuilder(
    //   animation: _ctrl,
    //   builder: (_, child) => Opacity(
    //     opacity: _fade.value.clamp(0.0, 1.0),
    //     child:
    //     Transform.translate(offset: Offset(0, _slide.value), child: child),
    //   ),
      return  Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _pressed
                      ? AppColors.goldLight.withOpacity(0.6)
                      : AppColors.cardBorder,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _pressed
                        ? AppColors.gold.withOpacity(0.14)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: _pressed ? 22 : 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Padding(
                padding: const EdgeInsets.all(14),
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
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.card,
                          shape: BoxShape.circle,
                        ),
                        child: SafeNetworkImage(
                          url: s.avatar,
                          width: 60,
                          height: 60,
                          borderRadius: BorderRadius.circular(30),
                          fallbackAsset: kLifestyleLogoAsset,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: AppTheme.goldBadgeDecoration(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified,
                                    size: 10, color: AppColors.gold),
                                const SizedBox(width: 3),
                                Text('VERIFIED',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.gold,
                                      letterSpacing: 1,
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: _highlighted(
                              (widget.serviceName == 'Architect' ||
                                  widget.serviceName == 'Interior Designer')
                                  ? s.ownerName
                                  : s.firmName,
                              GoogleFonts.cormorantGaramond(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_city_outlined,
                                  size: 11, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              RichText(
                                text: _highlighted(
                                  s.city,
                                  GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                  color: AppColors.textMuted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: RichText(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  text: _highlighted(
                                    s.location,
                                    GoogleFonts.dmSans(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: AppTheme.goldIconCircleDecoration(),
                      child: const Icon(Icons.arrow_forward_ios,
                          size: 12, color: AppColors.gold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    // );
  }
}