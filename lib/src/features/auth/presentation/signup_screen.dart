import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';

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

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthService>().signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        role: _role,
        name: _nameCtrl.text.trim(),
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.pop()),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            Text('Create account', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 6),
            Text('Join Sangaso to find or offer services', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),

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
            const SizedBox(height: 32),

            SizedBox(width: double.infinity, height: 46,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create Account'),
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
