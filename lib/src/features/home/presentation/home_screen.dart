import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import 'seeker_home_screen.dart';
import 'provider_home_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use the reactive, already-cached user model instead of re-fetching
    // from Firestore on every rebuild — avoids refetch flicker and keeps
    // this screen in sync automatically when the profile changes.
    final user = context.watch<AuthService>().currentUserModel;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (user.role == UserRole.provider) return const ProviderHomeScreen();
    return const SeekerHomeScreen();
  }
}
