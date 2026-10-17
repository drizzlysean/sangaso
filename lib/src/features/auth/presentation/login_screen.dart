import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/brand.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/auth_errors.dart';
import 'package:google_fonts/google_fonts.dart';

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
