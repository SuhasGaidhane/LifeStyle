import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/shop_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/app_update_service.dart';
import '../data/data_tab.dart';
import '../post/post_tab.dart';
import '../profile/profile_tab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHARED LUXURY PALETTE  –  white/cream light theme (mirrors data_tab.dart)
// ─────────────────────────────────────────────────────────────────────────────
class _P {
  static const bg          = Color(0xFFFAF9F6); // warm off-white
  static const card        = Color(0xFFFFFFFF); // pure white
  static const cardBorder  = Color(0xFFEDE9E1); // warm cream border
  static const gold        = Color(0xFFB8912A); // deeper gold (contrast on white)
  static const goldLight   = Color(0xFFD4A853); // standard gold
  static const goldDim     = Color(0xFF8C6B2F); // dark gold
  static const goldBg      = Color(0xFFFDF6E7); // light gold tint
  static const surface     = Color(0xFFF4F1EB); // tinted surface
  static const textPrimary = Color(0xFF1A1610); // near-black warm
  static const textMuted   = Color(0xFF9A9080); // warm mid-grey
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c    = Get.find<HomeController>();
    final tabs = const [DataTab(), PostTab()];

    // After the first frame: check for an app update and refresh the
    // logged-in user (so admin-access changes reflect the Admin tab).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService.check();
      Get.find<AuthController>().refreshUser();
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _P.bg,

        // Refresh admin status each time the menu opens.
        onDrawerChanged: (open) {
          if (open) Get.find<AuthController>().refreshUser();
        },

        // ── DRAWER ────────────────────────────────────────────────────────
        drawer: _LuxuryDrawer(),

        // ── APP BAR ───────────────────────────────────────────────────────
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: _LuxuryAppBar(),
        ),

        // ── BODY ──────────────────────────────────────────────────────────
        body: Obx(() => IndexedStack(
          index: c.selectedIndex.value,
          children: tabs,
        )),

        // ── BOTTOM NAV ────────────────────────────────────────────────────
        bottomNavigationBar: Obx(() => _LuxuryBottomNav(
          selectedIndex: c.selectedIndex.value,
          onTap: c.changeTab,
        )),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _LuxuryAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _P.card,
        border: Border(
          bottom: BorderSide(color: _P.cardBorder, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                // ── Hamburger ─────────────────────────────────────────────
                Builder(
                  builder: (ctx) => IconButton(
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                    icon: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MenuLine(width: 25),
                        const SizedBox(height: 5),
                        _MenuLine(width: 19),
                        const SizedBox(height: 5),
                        _MenuLine(width: 15),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 2),

                // ── Add Post Button ─────────────────────────────────────
                GestureDetector(
                  onTap: () {
                    // Add Post — gated on having at least one shop (premium).
                    Get.find<ShopController>().openUploadPost();
                  },
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.black26,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.black87,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          "Add Post",
                          style: GoogleFonts.dmSans(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),



                const Spacer(),

                // ── Brand ─────────────────────────────────────────────────
                Image.asset("assets/images/lifestylelogo.png", height: 50,),

                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// thin horizontal line used inside hamburger icon
class _MenuLine extends StatelessWidget {
  final double width;
  const _MenuLine({required this.width});
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 1.8,
    decoration: BoxDecoration(
      color: _P.textPrimary,
      borderRadius: BorderRadius.circular(1),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV
// ─────────────────────────────────────────────────────────────────────────────
class _LuxuryBottomNav extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;
  const _LuxuryBottomNav(
      {required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _P.card,
        border: const Border(
            top: BorderSide(color: _P.cardBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                index: 0,
                selectedIndex: selectedIndex,
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view_rounded,
                label: 'Discover',
                onTap: onTap,
              ),
              // thin vertical separator
              Container(
                  width: 1, height: 28, color: _P.cardBorder),
              _NavItem(
                index: 1,
                selectedIndex: selectedIndex,
                icon: Icons.add_circle_outline_rounded,
                activeIcon: Icons.add_circle_rounded,
                label: 'Post',
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final void Function(int) onTap;

  const _NavItem({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? _P.goldBg
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                border: selected
                    ? Border.all(
                    color: _P.goldLight.withOpacity(0.45), width: 1)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? activeIcon : icon,
                    color: selected ? _P.gold : _P.textMuted,
                    size: 21,
                  ),
                  // Label is always shown (both active & inactive tabs).
                  Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: Text(label,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                          color: selected ? _P.gold : _P.textMuted,
                        )),
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
// DRAWER  –  dark shell that wraps ProfileTab
// ─────────────────────────────────────────────────────────────────────────────
class _LuxuryDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _P.bg,
      width: MediaQuery.of(context).size.width * 0.82,
      child: const SafeArea(child: ProfileTab()),
    );
  }
}