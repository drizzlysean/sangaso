import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand orange primary button with trailing affordance (arrow), clear
/// pressed/loading/disabled states.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.trailingIcon,
    this.expand = true,
    this.height = 48,
    this.deepOrange = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? trailingIcon;
  final bool expand;
  final double height;
  final bool deepOrange;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return SizedBox(
      width: expand ? double.infinity : null,
      height: height,
      child: Material(
        color: enabled
            ? (deepOrange ? AppColors.primaryDeep : AppColors.primary)
            : AppColors.primaryDim,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.primarySoft.withValues(alpha: 0.35),
          highlightColor: AppColors.primaryDeep.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: loading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Row(
                        key: ValueKey(label),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label,
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                  color: enabled
                                      ? Colors.white
                                      : AppColors.text3)),
                          if (trailingIcon != null) ...[
                            const SizedBox(width: 8),
                            Icon(trailingIcon,
                                size: 17,
                                color: enabled
                                    ? Colors.white
                                    : AppColors.text3),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary/ghost button with visible ivory border.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.expand = true,
    this.onDark = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final bool expand;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? AppColors.lightText : AppColors.text1;
    return SizedBox(
      width: expand ? double.infinity : null,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: BorderSide(
              color: onDark
                  ? AppColors.lightText.withValues(alpha: 0.35)
                  : AppColors.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: trailingIcon != null ? Icon(trailingIcon, size: 17) : const SizedBox.shrink(),
        label: Text(label,
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Brand logo mark: charcoal rounded square with an orange "S".
class BrandLogoMark extends StatelessWidget {
  const BrandLogoMark({super.key, this.size = 52, this.dark = true});

  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? AppColors.charcoal : AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: AppColors.primarySoft, width: dark ? 1.5 : 0),
      ),
      alignment: Alignment.center,
      child: Text('S',
          style: GoogleFonts.barlowCondensed(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primary)),
    );
  }
}

/// Small caps eyebrow label above a section (deep orange, wide tracking).
class SectionEyebrow extends StatelessWidget {
  const SectionEyebrow({super.key, required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: color ?? AppColors.primaryDeep,
            height: 1.2));
  }
}

/// Large editorial headline with optional italic accent phrase.
class DisplayHeading extends StatelessWidget {
  const DisplayHeading({
    super.key,
    this.plain,
    this.accentItalic,
    this.onDark = false,
    this.size = 34,
    this.textAlign = TextAlign.start,
  });

  final String? plain;
  final String? accentItalic;
  final bool onDark;
  final double size;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final main = GoogleFonts.barlowCondensed(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.06,
        letterSpacing: -0.5,
        color: onDark ? AppColors.lightText : AppColors.text1);
    final accent = GoogleFonts.playfairDisplay(
        fontStyle: FontStyle.italic,
        fontSize: size * 0.92,
        height: 1.06,
        color: onDark ? AppColors.primarySoft : AppColors.primaryDeep);

    final accentPart = accentItalic;
    return Text.rich(
      TextSpan(
        style: main,
        children: [
          if (plain != null) TextSpan(text: plain),
          if (accentPart != null)
            TextSpan(text: ' ${accentPart}', style: accent),
        ],
      ),
      textAlign: textAlign,
    );
  }
}

/// Charcoal editorial panel (hero / announcement surface).
class CharcoalPanel extends StatelessWidget {
  const CharcoalPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Warm-tinted intentional card used across task screens.
class BrandCard extends StatelessWidget {
  const BrandCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 14,
    this.borderColor,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return box;
    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: box,
    );
  }
}

/// Slim orangeArrow used on links like "See more".
class ArrowLink extends StatelessWidget {
  const ArrowLink({super.key, required this.label, this.onTap, this.color});

  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color ?? AppColors.primaryDeep)),
        const SizedBox(width: 4),
        Icon(Icons.arrow_forward_rounded,
            size: 15, color: color ?? AppColors.primaryDeep),
      ]),
    );
  }
}
