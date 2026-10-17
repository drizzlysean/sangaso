import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/brand.dart';
import 'package:google_fonts/google_fonts.dart';

import '02_how_it_works_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const int _pageCount = 5;

  final PageController _pageController = PageController(viewportFraction: 0.94);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 12, 4),
              child: _buildHeader(context),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: const [
                  _OnboardPage(
                    icon: Icons.travel_explore_rounded,
                    title: 'Find quality local help',
                    isHero: true,
                    bullets: [
                      'Carpenters, electricians, plumbers, cleaners, tutors and more in one app.',
                      'Transparent profiles with straightforward pricing.',
                    ],
                  ),
                  _OnboardPage(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Compare and choose with confidence',
                    bullets: [
                      'Real provider profiles with photos, skills and location.',
                      'Ratings and reviews from people who used the service.',
                      'Upfront prices — you know the cost before you book.',
                    ],
                  ),
                  _OnboardPage(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Book and chat in one place',
                    bullets: [
                      'Pick a date, time and service address in a guided flow.',
                      'Message the provider to agree details before the job.',
                      'Track your booking status from request to completion.',
                    ],
                  ),
                  _OnboardPage(
                    icon: Icons.handyman_outlined,
                    title: 'Are you a service provider?',
                    bullets: [
                      'Build a profile that shows your skills and work area.',
                      'Publish your services and set your own prices.',
                      'Receive booking requests and chat with customers.',
                    ],
                    footerLabel: 'See how provider signup works',
                  ),
                  _OnboardPage(
                    icon: Icons.verified_rounded,
                    title: 'Ready when you are',
                    isFinal: true,
                    bullets: [
                      'Create a free account as a seeker or provider.',
                      'Your bookings, messages and reviews live in one place.',
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
              child: _buildBottomBar(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const BrandLogoMark(size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('SANGASO',
                style: GoogleFonts.barlowCondensed(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: AppColors.text1)),
            Text('Service providers · Service seekers',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.text3,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
        TextButton(
          onPressed:
              _currentPage >= _pageCount - 1 ? null : () => _goToPage(_pageCount - 1),
          child: Text('Skip intro',
              style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _currentPage >= _pageCount - 1
                      ? AppColors.text3
                      : AppColors.primaryDeep)),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final isLast = _currentPage >= _pageCount - 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _pageCount; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _currentPage ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _currentPage
                      ? AppColors.primary
                      : AppColors.primaryMid,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            const SizedBox(width: 14),
            AnimatedOpacity(
              opacity: isLast ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 220),
              child: IgnorePointer(
                ignoring: isLast,
                child: ArrowLink(
                  label: 'Continue',
                  onTap: () => _goToPage(_currentPage + 1),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 6),
      ],
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> bullets;
  final bool isHero;
  final bool isFinal;
  final String? footerLabel;

  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.bullets,
    this.isHero = false,
    this.isFinal = false,
    this.footerLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFinal) ...[
              const CharcoalPanel(
                child: _HowItWorksPeek(),
              ),
              const SizedBox(height: 20),
            ],
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryDim,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.primaryMid),
              ),
              child: Icon(icon, size: 24, color: AppColors.primaryDeep),
            ),
            const SizedBox(height: 16),
            DisplayHeading(
              plain: title,
              accentItalic: isHero ? 'and trusted work.' : '',
              size: 30,
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < bullets.length; i++) ...[
              _bullet(bullets[i]),
              if (i < bullets.length - 1) const SizedBox(height: 10),
            ],
            if (footerLabel != null) ...[
              const SizedBox(height: 14),
              ArrowLink(
                label: footerLabel ?? '',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HowItWorksScreen()),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.check_circle_rounded,
              size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
                fontSize: 13.5, height: 1.55, color: AppColors.text2),
          ),
        ),
      ],
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
