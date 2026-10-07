import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _idx(String loc) {
    if (loc.startsWith('/search'))        return 1;
    if (loc.startsWith('/bookings'))      return 2;
    if (loc.startsWith('/notifications')) return 3;
    if (loc.startsWith('/profile'))       return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    final idx = _idx(loc);
    final wide = kIsWeb && MediaQuery.of(context).size.width > 860;

    if (wide) return _WebShell(idx: idx, child: child);
    return _MobileShell(idx: idx, child: child);
  }
}

// ─── Mobile: bottom nav ───────────────────────────────────────────────────────

class _MobileShell extends StatelessWidget {
  final int idx;
  final Widget child;
  const _MobileShell({required this.idx, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(top: false,
          child: SizedBox(height: 56, child: Row(children: [
            _MItem(icon: Icons.home_outlined,          activeIcon: Icons.home_rounded,           label: 'Home',     i: 0, cur: idx, go: () => context.go('/home')),
            _MItem(icon: Icons.search_outlined,         activeIcon: Icons.search_rounded,          label: 'Search',   i: 1, cur: idx, go: () => context.go('/search')),
            _MItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded,  label: 'Bookings', i: 2, cur: idx, go: () => context.go('/bookings')),
            _MItem(icon: Icons.notifications_outlined,  activeIcon: Icons.notifications_rounded,   label: 'Alerts',   i: 3, cur: idx, go: () => context.go('/notifications')),
            _MItem(icon: Icons.person_outline_rounded,  activeIcon: Icons.person_rounded,          label: 'Profile',  i: 4, cur: idx, go: () => context.go('/profile')),
          ])),
        ),
      ),
    );
  }
}

class _MItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int i, cur;
  final VoidCallback go;
  const _MItem({required this.icon, required this.activeIcon, required this.label, required this.i, required this.cur, required this.go});
  @override
  Widget build(BuildContext context) {
    final on = i == cur;
    return Expanded(child: InkWell(onTap: go, splashColor: Colors.transparent, highlightColor: Colors.transparent,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(on ? activeIcon : icon, size: 22, color: on ? AppColors.primary : AppColors.text3),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: on ? FontWeight.w600 : FontWeight.w400, color: on ? AppColors.primary : AppColors.text3)),
      ]),
    ));
  }
}

// ─── Web: sidebar nav ─────────────────────────────────────────────────────────

class _WebShell extends StatelessWidget {
  final int idx;
  final Widget child;
  const _WebShell({required this.idx, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: Row(children: [
        // Sidebar
        Container(
          width: 220,
          color: Colors.white,
          child: Column(children: [
            // Logo
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
              alignment: Alignment.centerLeft,
              child: Row(children: [
                Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.handshake_outlined, size: 18, color: Colors.white)),
                const SizedBox(width: 10),
                const Text('Sangaso', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text1)),
              ]),
            ),
            // Nav items
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              child: Column(children: [
                _SideItem(icon: Icons.home_outlined,          label: 'Home',          i: 0, cur: idx, go: () => context.go('/home')),
                _SideItem(icon: Icons.search_outlined,         label: 'Search',        i: 1, cur: idx, go: () => context.go('/search')),
                _SideItem(icon: Icons.calendar_today_outlined, label: 'Bookings',      i: 2, cur: idx, go: () => context.go('/bookings')),
                _SideItem(icon: Icons.notifications_outlined,  label: 'Notifications', i: 3, cur: idx, go: () => context.go('/notifications')),
                _SideItem(icon: Icons.person_outline_rounded,  label: 'Profile',       i: 4, cur: idx, go: () => context.go('/profile')),
              ]),
            )),
          ]),
        ),
        // Vertical divider
        Container(width: 1, color: AppColors.divider),
        // Main content — constrained
        Expanded(child: ClipRect(child: child)),
      ]),
    );
  }
}

class _SideItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int i, cur;
  final VoidCallback go;
  const _SideItem({required this.icon, required this.label, required this.i, required this.cur, required this.go});
  @override
  Widget build(BuildContext context) {
    final on = i == cur;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(8),
        child: InkWell(onTap: go, borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: on ? AppColors.primaryDim : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(icon, size: 18, color: on ? AppColors.primary : AppColors.text2),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(fontSize: 14, fontWeight: on ? FontWeight.w600 : FontWeight.w400, color: on ? AppColors.primary : AppColors.text1)),
            ]),
          ),
        ),
      ),
    );
  }
}
