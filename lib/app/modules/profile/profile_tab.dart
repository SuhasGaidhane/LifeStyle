import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PALETTE  –  white/cream light theme (matches home_screen & data_tab)
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
  static const danger      = Color(0xFFCC3333); // red (slightly deeper on white)
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: _P.bg,
      body: Obx(() {
        final u = auth.user.value;
        if (u == null) return const SizedBox.shrink();

        return ListView(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          children: [
            // ── PROFILE HEADER ──────────────────────────────────────────
            _ProfileHeader(user: u),

            const SizedBox(height: 24),

            // ── ADMIN (only for is_admin users) ─────────────────────────
            if (auth.isAdmin) ...[
              _SectionLabel('ADMIN'),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Admin Panel',
                onTap: () => Get.toNamed(AppRoutes.adminPanel),
              ),
              const SizedBox(height: 20),
            ],

            // ── SECTION: ACCOUNT ────────────────────────────────────────
            _SectionLabel('ACCOUNT'),
            const SizedBox(height: 8),

            _MenuItem(
              icon: Icons.person_outline_rounded,
              label: 'User Profile',
              onTap: () => Get.toNamed(AppRoutes.updateProfile),
            ),
            _MenuItem(
              icon: Icons.add_business_outlined,
              label: 'Add Shop',
              onTap: () => Get.toNamed(AppRoutes.addShop),
            ),
            _MenuItem(
              icon: Icons.store_outlined,
              label: 'My Shops',
              onTap: () => Get.toNamed(AppRoutes.myShops),
            ),
            _MenuItem(
              icon: Icons.grid_on_outlined,
              label: 'My Posts',
              onTap: () => Get.toNamed(AppRoutes.myPosts),
            ),
            const SizedBox(height: 8),

            // Notifications — hidden for now
            // _MenuItem(
            //   icon: Icons.notifications_outlined,
            //   label: 'Notifications',
            //   onTap: () => Get.toNamed(AppRoutes.notifications),
            // ),

            const SizedBox(height: 20),

            // ── SECTION: SUPPORT ────────────────────────────────────────
            _SectionLabel('SUPPORT'),

            _MenuItem(
              icon: Icons.headset_mic_outlined,
              label: 'Contact Us',
              onTap: () => Get.toNamed(AppRoutes.contactUs),
            ),

            const SizedBox(height: 20),

            // ── DIVIDER ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(height: 1, color: _P.cardBorder),
            ),

            const SizedBox(height: 20),

            // ── LOGOUT ──────────────────────────────────────────────────
            _MenuItem(
              icon: Icons.logout_rounded,
              label: 'Logout',
              onTap: auth.logout,
              danger: true,
            ),

            const SizedBox(height: 32),

            // ── VERSION ─────────────────────────────────────────────────
            Center(
              child: Text('v1.0.0',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: _P.textMuted,
                    letterSpacing: 1,
                  )),
            ),

            const SizedBox(height: 32),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final dynamic user; // your User model
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background
        Container(
          height: 240,
          decoration: const BoxDecoration(color: _P.card),
          child: Stack(
            children: [
              // Subtle warm cream gradient wash
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFDF8F0), _P.card],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Radial gold glow behind avatar
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _P.goldLight.withOpacity(0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom border
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(height: 1, color: _P.cardBorder),
              ),
            ],
          ),
        ),

        // Content
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Avatar with gold ring
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_P.goldLight, _P.goldDim],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _P.gold.withOpacity(0.35),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _P.card,
                  ),
                  child: SafeNetworkImage(
                    url: user.avatar,
                    width: 88,
                    height: 88,
                    borderRadius: BorderRadius.circular(44),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Text(user.name,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _P.textPrimary,
                  )),

              const SizedBox(height: 4),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 12, color: _P.gold),
                  const SizedBox(width: 3),
                  Text(user.city,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: _P.textPrimary)),
                  const SizedBox(width: 10),
                  Container(
                      width: 3, height: 3,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _P.cardBorder)),
                  const SizedBox(width: 10),
                  Icon(Icons.phone_outlined,
                      size: 12, color: _P.gold),
                  const SizedBox(width: 3),
                  Text(user.mobile,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: _P.textPrimary)),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_P.goldLight, _P.goldDim],
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
              color: _P.textMuted,
              letterSpacing: 2.5,
            )),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MENU ITEM
// ─────────────────────────────────────────────────────────────────────────────
class _MenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  final bool highlight;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.highlight = false,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = widget.danger
        ? _P.danger
        : widget.highlight
        ? _P.gold
        : _P.gold;
    final Color textColor = widget.danger
        ? _P.danger
        : widget.highlight
        ? _P.goldDim
        : _P.textPrimary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        // decoration: BoxDecoration(
        //   // color: _pressed
        //   //     ? _P.surface
        //   //     : widget.highlight
        //   //     ? _P.goldBg
        //   //     : _P.card,
        //   // borderRadius: BorderRadius.circular(14),
        //   // border: Border.all(
        //   //   color: widget.highlight
        //   //       ? _P.goldLight.withOpacity(0.40)
        //   //       : _P.cardBorder,
        //   //   width: 1,
        //   // ),
        //   // boxShadow: [
        //   //   BoxShadow(
        //   //     color: Colors.black.withOpacity(_pressed ? 0.04 : 0.02),
        //   //     blurRadius: 8,
        //   //     offset: const Offset(0, 2),
        //   //   ),
        //   // ],
        // ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.danger
                    ? _P.danger.withOpacity(0.08)
                    : widget.highlight
                    ? _P.goldLight.withOpacity(0.20)
                    : _P.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, color: iconColor, size: 18),
            ),

            const SizedBox(width: 14),

            // Label
            Expanded(
              child: Text(widget.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  )),
            ),

            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.black,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}