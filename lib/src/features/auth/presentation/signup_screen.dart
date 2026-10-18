import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/legal_links.dart';
import '../../../core/widgets/brand.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/auth_errors.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  UserRole _role = UserRole.seeker;
  bool _loading = false;
  bool _hidePass = true;
  bool _hideConf = true;
  bool _consent = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  void _consentError() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Please accept the Terms of Service and Privacy Notice to create an account.'),
      backgroundColor: AppColors.error,
    ));
  }

  Future<void> _googleSubmit() async {
    if (!_consent) { _consentError(); return; }
    setState(() => _loading = true);
    try {
      final outcome = await context.read<AuthService>().signInWithGoogle();
      if (outcome == GoogleSignInOutcome.consentRequired) {
        // Signup screen has already captured explicit consent, so the
        // pending Google account can be completed immediately.
        await context.read<AuthService>().completeGoogleConsent();
      }
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAuthError(e)), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_consent) { _consentError(); return; }
    setState(() => _loading = true);
    try {
      await context.read<AuthService>().signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        role: _role,
        name: _nameCtrl.text.trim(),
        acceptedConsent: _consent,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAuthError(e)), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.pop()),
        backgroundColor: AppColors.canvas,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            const BrandLogoMark(size: 44),
            const SizedBox(height: 14),
            const SectionEyebrow('JOIN SANGASO'),
            const SizedBox(height: 10),
            const DisplayHeading(plain: 'Create account', accentItalic: 'and start.', size: 34),
            const SizedBox(height: 28),

            TextFormField(controller: _nameCtrl, textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter your name' : null),
            const SizedBox(height: 14),

            TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Email address'),
              validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null),
            const SizedBox(height: 14),

            TextFormField(controller: _passCtrl, obscureText: _hidePass, textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: 'Password',
                suffixIcon: GestureDetector(onTap: () => setState(() => _hidePass = !_hidePass),
                  child: Icon(_hidePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.text3))),
              validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null),
            const SizedBox(height: 14),

            TextFormField(controller: _confirmCtrl, obscureText: _hideConf, textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(labelText: 'Confirm password',
                suffixIcon: GestureDetector(onTap: () => setState(() => _hideConf = !_hideConf),
                  child: Icon(_hideConf ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.text3))),
              validator: (v) => (v != _passCtrl.text) ? 'Passwords don\'t match' : null),
            const SizedBox(height: 28),

            // Role picker
            Text('I want to', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(children: [
              _RoleTile(label: 'Find services', sub: 'Hire a provider', icon: Icons.search_rounded,
                selected: _role == UserRole.seeker, onTap: () => setState(() => _role = UserRole.seeker)),
              const SizedBox(width: 12),
              _RoleTile(label: 'Offer services', sub: 'Earn as a pro', icon: Icons.handyman_rounded,
                selected: _role == UserRole.provider, onTap: () => setState(() => _role = UserRole.provider)),
            ]),

            // Legal consent: explicitly accepted, initially unchecked.
            // Both Create Account and Google signup are gated on it.
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _consent = !_consent),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _consent,
                    onChanged: (v) => setState(() => _consent = v ?? false),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 12.5, color: AppColors.text2, height: 1.5),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => launchUrl(Uri.parse(kTermsUrl), mode: LaunchMode.externalApplication),
                        ),
                        const TextSpan(text: ' and the '),
                        TextSpan(
                          text: 'Privacy Notice',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => launchUrl(Uri.parse(kPrivacyUrl), mode: LaunchMode.externalApplication),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            PrimaryButton(
              label: 'Create Account',
              trailingIcon: Icons.arrow_forward_rounded,
              loading: _loading,
              onPressed: _loading ? null : _consent ? _submit : _consentError,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _googleSubmit,
                icon: const Text('G', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF4285F4))),
                label: const Text('Continue with Google', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text1)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Already have an account?  ', style: Theme.of(context).textTheme.bodyMedium),
              GestureDetector(onTap: () => context.pop(),
                child: Text('Sign in', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13))),
            ])),
            const SizedBox(height: 32),
          ])),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String label, sub;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _RoleTile({required this.label, required this.sub, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDim : AppColors.surfaceGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 22, color: selected ? AppColors.primary : AppColors.text3),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? AppColors.primary : AppColors.text1)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 11, color: selected ? AppColors.primary.withOpacity(0.7) : AppColors.text3)),
        ]),
      ),
    ),
  );
}
