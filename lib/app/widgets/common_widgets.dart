import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BRAND APP BAR  –  premium white-gold
// ─────────────────────────────────────────────────────────────────────────────
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? eyebrow;
  final List<Widget>? actions;
  final bool showBack;
  final Widget? leading;
  final VoidCallback? onBack;

  const BrandAppBar({
    super.key,
    required this.title,
    this.eyebrow,
    this.actions,
    this.showBack = true,
    this.leading,
    this.onBack,
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
              SizedBox(
                height: kToolbarHeight + 14,
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: leading ??
                          (showBack && Navigator.canPop(context)
                              ? _BackChip(onTap: onBack ?? Get.back)
                              : const SizedBox.shrink()),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (eyebrow != null) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                    width: 14,
                                    height: 1,
                                    color: AppColors.goldLight),
                                const SizedBox(width: 6),
                                Text(
                                  eyebrow!.toUpperCase(),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.gold,
                                    letterSpacing: 2.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                    width: 14,
                                    height: 1,
                                    color: AppColors.goldLight),
                              ],
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: actions ?? const [],
                      ),
                    ),
                  ],
                ),
              ),
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

class _BackChip extends StatelessWidget {
  final VoidCallback onTap;
  const _BackChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 38,
          height: 38,
          decoration: AppTheme.goldIconCircleDecoration(),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 14, color: AppColors.gold),
        ),
      ),
    );
  }
}

class BrandAppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  const BrandAppBarAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? AppColors.goldBg : Colors.transparent,
          border: Border.all(
            color: filled
                ? AppColors.goldLight.withOpacity(0.4)
                : AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: filled ? AppColors.gold : AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GRADIENT BUTTON  –  premium gold CTA
// ─────────────────────────────────────────────────────────────────────────────
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final double? width;
  final bool loading;
  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.width,
    this.loading = false,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

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
    final disabled = widget.loading || widget.onTap == null;
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => _ctrl.forward(),
        onTapUp: disabled
            ? null
            : (_) {
          _ctrl.reverse();
          widget.onTap?.call();
        },
        onTapCancel: disabled ? null : () => _ctrl.reverse(),
        child: Container(
          width: widget.width ?? double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.goldLight, AppColors.goldDim],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: disabled
                ? []
                : [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.30),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.loading
              ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.4, color: Colors.white),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
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
// CUSTOM TEXT BUTTON  –  Blue glowing text button
// ─────────────────────────────────────────────────────────────────────────────
class CustomTextButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final bool loading;

  const CustomTextButton({
    super.key,
    required this.label,
    required this.onTap,
    this.fontSize = 16,
    this.color = const Color(0xFF3C2B99),
    this.fontWeight = FontWeight.w700,
    this.loading = false,
  });

  @override
  State<CustomTextButton> createState() => _CustomTextButtonState();
}

class _CustomTextButtonState extends State<CustomTextButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.loading || widget.onTap == null;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => _controller.forward(),
        onTapUp: disabled
            ? null
            : (_) {
          _controller.reverse();
          widget.onTap?.call();
        },
        onTapCancel: disabled ? null : () => _controller.reverse(),
        child: widget.loading
            ? SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: widget.color,
          ),
        )
            : Text(
          widget.label,
          style: GoogleFonts.dmSans(
            fontSize: widget.fontSize,
            fontWeight: widget.fontWeight,
            color: disabled
                ? widget.color.withOpacity(0.5)
                : widget.color,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: widget.color.withOpacity(0.4),
                blurRadius: 14,
                offset: const Offset(0, 0),
              ),
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// BRAND TEXT FIELD  –  cream border, gold focus
// ─────────────────────────────────────────────────────────────────────────────
class BrandTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? label;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool readOnly;
  final bool obscureText;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const BrandTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
    this.obscureText = false,
    this.onTap,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          readOnly: readOnly,
          obscureText: obscureText,
          onTap: onTap,
          onChanged: onChanged,
          validator: validator,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.gold, size: 20)
                : null,
            suffixIcon: suffix,
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: AppColors.gold, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SAFE NETWORK IMAGE  –  cream shimmer, warm fallback
// ─────────────────────────────────────────────────────────────────────────────
/// App logo used as an image fallback (shop / owner photos when missing).
const String kLifestyleLogoAsset = 'assets/images/lifestylelogo.png';

class SafeNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// When set, this asset is shown if [url] is empty or fails to load
  /// (e.g. pass [kLifestyleLogoAsset] for shop / owner images).
  final String? fallbackAsset;

  const SafeNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackAsset,
  });

  Widget _fallback() {
    if (fallbackAsset != null) {
      return Container(
        width: width,
        height: height,
        color: AppColors.surface,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Image.asset(fallbackAsset!, fit: BoxFit.contain),
      );
    }
    return Container(
      width: width,
      height: height,
      color: AppColors.surface,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined,
          color: AppColors.textMuted, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget image = url.trim().isEmpty
        ? _fallback()
        : CachedNetworkImage(
            imageUrl: url,
            width: width,
            height: height,
            fit: fit,
            placeholder: (_, __) => Shimmer.fromColors(
              baseColor: AppColors.surface,
              highlightColor: AppColors.goldBg,
              child: Container(
                width: width,
                height: height,
                color: AppColors.surface,
              ),
            ),
            errorWidget: (_, __, ___) => _fallback(),
          );
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER PILL CHIP  –  gold-selected, white-rest
// ─────────────────────────────────────────────────────────────────────────────
// class FilterPillChip extends StatelessWidget {
//   final String label;
//   final bool selected;
//   final VoidCallback onTap;
//   const FilterPillChip({
//     super.key,
//     required this.label,
//     required this.selected,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       curve: Curves.easeOut,
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(24),
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             padding:
//             const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
//             decoration: BoxDecoration(
//               gradient: selected
//                   ? const LinearGradient(
//                 colors: [AppColors.goldLight, AppColors.goldDim],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               )
//                   : null,
//               color: selected ? null : AppColors.card,
//               borderRadius: BorderRadius.circular(24),
//               border: Border.all(
//                 color: selected
//                     ? AppColors.goldLight.withOpacity(0.3)
//                     : AppColors.cardBorder,
//                 width: 1,
//               ),
//               boxShadow: selected
//                   ? [
//                 BoxShadow(
//                   color: AppColors.gold.withOpacity(0.22),
//                   blurRadius: 10,
//                   offset: const Offset(0, 3),
//                 ),
//               ]
//                   : null,
//             ),
//             child: Text(
//               label,
//               style: GoogleFonts.dmSans(
//                 fontSize: 12,
//                 color: selected ? Colors.white : AppColors.textPrimary,
//                 fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
//                 letterSpacing: selected ? 0.3 : 0,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


class FilterPillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterPillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: selected ? 1.05 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: selected ? 14 : 13,
                fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF3C2B99)
                    : AppColors.textPrimary,

                // ✨ Glow / Shadow effect for selected text
                shadows: selected
                    ? [
                  Shadow(
                    color: const Color(0xFF3C2B99)
                        .withOpacity(0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 2),
                  ),
                ]
                    : [],

                letterSpacing: selected ? 0.4 : 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE  –  serif headline, gold icon halo
// ─────────────────────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Outer gold-tint halo
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.goldBg,
              border: Border.all(
                color: AppColors.goldLight.withOpacity(0.3),
                width: 1,
              ),
            ),
            // Inner gold gradient circle
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.goldLight, AppColors.goldDim],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.30),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, size: 40, color: Colors.white),
            ),
          ),
          const SizedBox(height: 22),
          // Eyebrow
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 12, height: 1, color: AppColors.goldLight),
              const SizedBox(width: 6),
              Text(
                'NOTHING HERE',
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                  width: 12, height: 1, color: AppColors.goldLight),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 22),
            action!,
          ],
        ],
      ),
    );
  }
}