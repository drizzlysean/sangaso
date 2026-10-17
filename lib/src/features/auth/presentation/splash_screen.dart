import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack))
        .drive(Tween(begin: 0.6, end: 1.0));
    _fade  = CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 1.0, curve: Curves.easeIn))
        .drive(Tween(begin: 0.0, end: 1.0));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 10)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset('assets/images/logo_icon.png', fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _fade,
              child: Column(children: [
                Text('Sangaso', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.lightText, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text('Find quality services nearby', style: TextStyle(fontSize: 14, color: AppColors.mutedDark, fontWeight: FontWeight.w400)),
                const SizedBox(height: 40),
                SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primarySoft)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
