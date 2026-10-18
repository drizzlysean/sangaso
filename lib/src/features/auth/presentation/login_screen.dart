import 'package:firebase_auth/firebase_auth.dart';
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false;
  bool _hidePass = true;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _googleSubmit() async {
    setState(() => _loading = true);
    try {
      final outcome = await context.read<AuthService>().signInWithGoogle();
      if (!mounted) return;
      if (outcome == GoogleSignInOutcome.consentRequired) {
        // New Google account: consent must be captured before the account
        // is created. Returning users never reach this dialog.
        final accepted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const _GoogleConsentDialog(),
        );
        if (accepted != true) {
          if (mounted) setState(() => _loading = false);
          return;
        }
        await context.read<AuthService>().completeGoogleConsent();
      }
      if (!mounted) return;
      final u = context.read<AuthService>().currentUserModel;
      if (u == null) { context.go('/'); return; }
      context.go(u.role == UserRole.admin ? '/admin' : '/home');
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyAuthError(e)), backgroundColor: AppColors.error));
      }
      return;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthService>().signIn(_emailCtrl.text.trim(), _passCtrl.text.trim());
      if (!mounted) return;
      final u = context.read<AuthService>().currentUserModel;
      if (u == null) { context.go('/'); return; }
      context.go(u.role == UserRole.admin ? '/admin' : '/home');
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAuthError(e)), backgroundColor: AppColors.error));
      return;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 46),

              const BrandLogoMark(size: 52, dark: true),
              const SizedBox(height: 26),

              const SectionEyebrow('SIGN IN'),
              const SizedBox(height: 10),
              const DisplayHeading(plain: 'Welcome back', accentItalic: 'again.', size: 36),
              const SizedBox(height: 6),
              Text('Sign in to your account', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 32),

              // Email
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email address'),
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 14),

              // Password
              TextFormField(
                controller: _passCtrl,
                obscureText: _hidePass,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _hidePass = !_hidePass),
                    child: Icon(_hidePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20, color: AppColors.text3),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
              ),
              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => showDialog(context: context, builder: (_) => _ForgotDialog()),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 24),

              PrimaryButton(
                label: 'Sign In',
                trailingIcon: Icons.arrow_forward_rounded,
                loading: _loading,
                onPressed: _loading ? null : _submit,
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
              const SizedBox(height: 26),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text("Don't have an account?  ", style: Theme.of(context).textTheme.bodyMedium),
                GestureDetector(
                  onTap: () => context.push('/signup'),
                  child: Text('Sign up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ]),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ForgotDialog extends StatefulWidget {
  @override
  State<_ForgotDialog> createState() => _ForgotDialogState();
}
class _ForgotDialogState extends State<_ForgotDialog> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    title: const Text('Reset password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Enter your email and we\'ll send a reset link.', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 14),
      TextField(controller: _ctrl, keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: 'Email')),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ElevatedButton(
        onPressed: _loading ? null : () async {
          if (_ctrl.text.trim().isEmpty) return;
          setState(() => _loading = true);
          try {
            await FirebaseAuth.instance.sendPasswordResetEmail(email: _ctrl.text.trim());
            if (mounted) { Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset email sent')));
            }
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyAuthError(e)), backgroundColor: AppColors.error));
          } finally { if (mounted) setState(() => _loading = false); }
        },
        child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Send'),
      ),
    ],
  );
}

/// Consent dialog for a brand-new Google account reached via the login
/// screen. Explicitly unchecked; completion only proceeds on accept.
class _GoogleConsentDialog extends StatefulWidget {
  const _GoogleConsentDialog();
  @override
  State<_GoogleConsentDialog> createState() => _GoogleConsentDialogState();
}
class _GoogleConsentDialogState extends State<_GoogleConsentDialog> {
  bool _consent = false;
  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    title: const Text('Before you continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('We could not find an existing Sangaso account for that Google address, so we will create one for you.',
        style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 14),
      GestureDetector(
        onTap: () => setState(() => _consent = !_consent),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 24, height: 24,
            child: Checkbox(value: _consent, onChanged: (v) => setState(() => _consent = v ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
          const SizedBox(width: 10),
          Expanded(child: Text.rich(TextSpan(
            style: const TextStyle(fontSize: 12.5, color: AppColors.text2, height: 1.5),
            children: [
              const TextSpan(text: 'I agree to the '),
              TextSpan(text: 'Terms of Service',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                recognizer: TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(kTermsUrl), mode: LaunchMode.externalApplication)),
              const TextSpan(text: ' and the '),
              TextSpan(text: 'Privacy Notice',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                recognizer: TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(kPrivacyUrl), mode: LaunchMode.externalApplication)),
            ]))),
        ]),
      ),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
      ElevatedButton(
        onPressed: _consent ? () => Navigator.pop(context, true) : null,
        child: const Text('Accept and continue'),
      ),
    ],
  );
}
