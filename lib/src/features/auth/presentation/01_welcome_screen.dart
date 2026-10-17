import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/brand.dart';
import 'package:google_fonts/google_fonts.dart';

import '02_how_it_works_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                _buildHeader(context),
                const SizedBox(height: 34),

                _buildHero(),
                const SizedBox(height: 26),

                _buildFeatureStrip(context),
                const SizedBox(height: 30),

                const CharcoalPanel(
                  child: _HowItWorksPeek(),
                ),
                const SizedBox(height: 30),

                _buildActions(context),
                const SizedBox(height: 18),

                _buildTruthfulFooter(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const BrandLogoMark(size: 44),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('SANGASO',
              style: GoogleFonts.barlowCondensed(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppColors.text1)),
          Text('Service providers · Service seekers',
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.text3, fontWeight: FontWeight.w500)),
        ]),
      ],
    );
  }

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionEyebrow('SERVICES MARKETPLACE'),
        const SizedBox(height: 12),
        const DisplayHeading(
          plain: 'Find quality local help',
          accentItalic: 'and trusted work.',
          size: 38,
        ),
        const SizedBox(height: 14),
        Text(
          'Sangaso connects you with carpenters, electricians, plumbers, '
          'cleaners, tutors and more — with transparent profiles, '
          'straightforward pricing and quick booking.',
          style: GoogleFonts.inter(
              fontSize: 14, height: 1.6, color: AppColors.text2),
        ),
      ],
    );
  }

  Widget _buildFeatureStrip(BuildContext context) {
    final features = const [
      (Icons.location_on_outlined, 'Find help nearby'),
      (Icons.badge_outlined, 'Real provider profiles'),
      (Icons.fork_right_rounded, 'Fast booking flow'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final f in features)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryMid),
                  ),
                  child: Icon(f.$1, size: 22, color: AppColors.primaryDeep),
                ),
                const SizedBox(height: 8),
                Text(
                  f.$2,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text2,
                      height: 1.25),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
          ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PrimaryButton(
          label: 'Get started',
          trailingIcon: Icons.arrow_forward_rounded,
          onPressed: () => context.go('/login'),
        ),
        const SizedBox(height: 12),
        SecondaryButton(
          label: 'How Sangaso works',
          trailingIcon: Icons.help_outline_rounded,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HowItWorksScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTruthfulFooter(BuildContext context) {
    return Center(
      child: Text(
        'Already have an account? Sign in to continue',
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3),
      ),
    );
  }
}

class _HowItWorksPeek extends StatelessWidget {
  const _HowItWorksPeek();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const SectionEyebrow('QUICK START', color: AppColors.primarySoft),
          const Spacer(),
          ArrowLink(
            label: 'See more',
            color: AppColors.primarySoft,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HowItWorksScreen()),
              );
            },
          ),
        ]),
        const SizedBox(height: 14),
        _peekStep(
            '1', 'Search a service by category, compare provider profiles.'),
        const SizedBox(height: 10),
        _peekStep(
            '2', 'Book, chat and confirm the job with the provider.'),
        const SizedBox(height: 10),
        _peekStep(
            '3', 'Providers respond to requests and complete great work.'),
      ],
    );
  }

  Widget _peekStep(String number, String text) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(7),
        ),
        alignment: Alignment.center,
        child: Text(number,
            style: GoogleFonts.barlowCondensed(
                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primarySoft)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 12.5, height: 1.5, color: AppColors.lightText)),
      ),
    ]);
  }
}
