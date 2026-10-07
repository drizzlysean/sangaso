import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

import '02_how_it_works_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo/Header Section
                _buildHeader(),
                const SizedBox(height: 30),

                // Main Content
                _buildMainContent(),
                const SizedBox(height: 40),

                // How It Works Section
                _buildHowItWorksSection(context),
                const SizedBox(height: 40),

                // Testimonials
                _buildTestimonials(),
                const SizedBox(height: 40),

                // Login Button
                _buildLoginButton(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SANGASO',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          'Service Providers · Service Seekers',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Find trusted local service providers in minutes.',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          'SANGASO connects you to carpenters, electricians, plumbers, mechanics, cleaners and more — with transparent profiles, reviews, and quick booking.',
          style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
        ),
        const SizedBox(height: 25),

        // Features Grid with green and orange - FIXED FOR RESPONSIVENESS
        LayoutBuilder(
          builder: (context, constraints) {
            // Check screen width
            final screenWidth = constraints.maxWidth;

            // Use shorter text on smaller screens
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFeature(
                  '📍',
                  screenWidth < 380 ? 'Nearby' : 'Location-based nearby',
                  AppColors.accent,
                ),
                _buildFeature(
                  '✓',
                  screenWidth < 380 ? 'Verified' : 'Verified providers',
                  AppColors.primary,
                ),
                _buildFeature(
                  '⭐',
                  screenWidth < 380 ? 'Reviews' : 'Ratings & Reviews',
                  AppColors.primary,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeature(String icon, String text, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(icon, style: TextStyle(fontSize: 24, color: color)),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80, // Fixed width to control text wrapping
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorksSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'How it works',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HowItWorksScreen()),
                );
              },
              child: Text(
                'See more →',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // Quick Steps with green and orange
        _buildStepCard(
          'For Service Seekers',
          '1. Search a service by category and location.\n2. Compare providers (price, rating, distance).\n3. Book, chat, confirm, and get the job done.',
          '3 easy steps',
          AppColors.accent,
          Icons.search,
        ),
        const SizedBox(height: 15),
        _buildStepCard(
          'For Service Providers',
          '1. Create a profile (skills, location, photos).\n2. Receive job requests and respond fast.\n3. Deliver quality work and earn with good reviews.',
          'Grow your work',
          AppColors.primary,
          Icons.business_center,
        ),
      ],
    );
  }

  Widget _buildStepCard(
    String title,
    String content,
    String tag,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                tag,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestimonials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What users say',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 15),
        _buildTestimonialCard(
          'SANGASO helped me find a reliable electrician quickly. The profile and reviews made it easy to trust.',
          '★★★★★',
          AppColors.accent,
        ),
        const SizedBox(height: 10),
        _buildTestimonialCard(
          'I registered as a carpenter and started getting enquiries within a short time. It\'s a good platform.',
          '★★★★★',
          AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildTestimonialCard(String text, String rating, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  rating,
                  style: TextStyle(fontSize: 18, color: Colors.amber[700]),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                height: 4,
                width: 60,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          context.go('/login');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: AppColors.accent.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Login to Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }
}
