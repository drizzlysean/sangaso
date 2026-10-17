import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/booking_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/booking_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/review_service.dart';

class SeekerHomeScreen extends StatelessWidget {
  const SeekerHomeScreen({super.key});

  static const _cats = [
    {'icon': Icons.cleaning_services_outlined, 'label': 'Cleaning'},
    {'icon': Icons.plumbing_outlined,           'label': 'Plumbing'},
    {'icon': Icons.electric_bolt_outlined,      'label': 'Electrical'},
    {'icon': Icons.format_paint_outlined,       'label': 'Painting'},
    {'icon': Icons.handyman_outlined,           'label': 'Repairs'},
    {'icon': Icons.local_car_wash_outlined,     'label': 'Car Wash'},
    {'icon': Icons.yard_outlined,               'label': 'Gardening'},
    {'icon': Icons.carpenter,                   'label': 'Carpentry'},
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUserModel;
    if (user == null) return const SizedBox();
    final firstName = user.displayName?.split(' ').first ?? 'there';
    final wide = kIsWeb && MediaQuery.of(context).size.width > 860;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: wide ? null : AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hey, $firstName 👋', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text1)),
          Text('What do you need today?', style: TextStyle(fontSize: 11, color: AppColors.text3, fontWeight: FontWeight.w400)),
        ]),
        actions: [_NotifBell(userId: user.id), const SizedBox(width: 4)],
      ),
      body: wide
          ? _WebLayout(user: user, firstName: firstName)
          : _MobileLayout(user: user),
    );
  }
}

// ─── Web layout ──────────────────────────────────────────────────────────────

class _WebLayout extends StatelessWidget {
  final dynamic user;
  final String firstName;
  const _WebLayout({required this.user, required this.firstName});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header row
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Good day, $firstName 👋',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text1)),
                  const SizedBox(height: 4),
                  Text('Find a service provider near you',
                    style: TextStyle(fontSize: 14, color: AppColors.text3)),
                ]),
                _NotifBell(userId: user.id),
              ]),
              const SizedBox(height: 28),

              // Search bar — full width on web
              _SearchBar(),
              const SizedBox(height: 32),

              // Categories grid on web
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Browse Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text1)),
                GestureDetector(onTap: () => context.go('/search'),
                  child: const Text('See all', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 14),
              _CatGrid(),
              const SizedBox(height: 32),

              // Bookings
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Recent Bookings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text1)),
                GestureDetector(onTap: () => context.go('/bookings'),
                  child: const Text('View all', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 14),
              _BookingStream(userId: user.id),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Mobile layout ────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final dynamic user;
  const _MobileLayout({required this.user});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _SearchBar()),
        const SizedBox(height: 22),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Categories', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text1)),
            GestureDetector(onTap: () => context.go('/search'),
              child: const Text('See all', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600))),
          ])),
        const SizedBox(height: 10),
        SizedBox(height: 90, child: _CatRow()),
        const SizedBox(height: 22),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Recent Bookings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text1)),
            GestureDetector(onTap: () => context.go('/bookings'),
              child: const Text('View all', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600))),
          ])),
        const SizedBox(height: 10),
      ])),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: _BookingSliver(userId: user.id),
      ),
      const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
    ]);
  }
}

// ─── Shared components ────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.go('/search'),
    child: Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: AppColors.surfaceGrey, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        const Icon(Icons.search, size: 18, color: AppColors.text3),
        const SizedBox(width: 8),
        Text('Search cleaners, electricians...', style: TextStyle(fontSize: 14, color: AppColors.text3)),
      ]),
    ),
  );
}

class _NotifBell extends StatelessWidget {
  final String userId;
  const _NotifBell({required this.userId});
  @override
  Widget build(BuildContext context) => StreamBuilder<int>(
    stream: context.read<NotificationService>().getUnreadCount(userId),
    builder: (ctx, snap) {
      final n = snap.data ?? 0;
      return Stack(children: [
        IconButton(icon: const Icon(Icons.notifications_outlined, size: 22), onPressed: () => ctx.go('/notifications')),
        if (n > 0) Positioned(right: 8, top: 10, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))),
      ]);
    },
  );
}

class _CatGrid extends StatelessWidget {
  static const _cats = SeekerHomeScreen._cats;
  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.1),
    itemCount: _cats.length,
    itemBuilder: (ctx, i) {
      final cat = _cats[i];
      return GestureDetector(
        onTap: () => _openSearch(ctx, cat),
        child: Container(
          decoration: BoxDecoration(color: i.isEven ? AppColors.primaryDim : AppColors.surfaceGrey, borderRadius: BorderRadius.circular(12)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(cat['icon'] as IconData, size: 26, color: i.isEven ? AppColors.primary : AppColors.text2),
            const SizedBox(height: 6),
            Text(cat['label'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text1)),
          ]),
        ),
      );
    },
  );
}

void _openSearch(BuildContext context, Map<String, Object> cat) {
  context.go('/search?category=${Uri.encodeQueryComponent(cat['label'] as String)}');
}

class _CatRow extends StatelessWidget {
  static const _cats = SeekerHomeScreen._cats;
  @override
  Widget build(BuildContext context) => ListView.separated(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    itemCount: _cats.length,
    separatorBuilder: (_, __) => const SizedBox(width: 10),
    itemBuilder: (ctx, i) {
      final cat = _cats[i];
      return GestureDetector(
        onTap: () => _openSearch(ctx, cat),
        child: SizedBox(width: 66, child: Column(children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: i.isEven ? AppColors.primaryDim : AppColors.surfaceGrey, borderRadius: BorderRadius.circular(13)),
            child: Icon(cat['icon'] as IconData, size: 22, color: i.isEven ? AppColors.primary : AppColors.text2)),
          const SizedBox(height: 6),
          Text(cat['label'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.text2), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
      );
    },
  );
}

class _BookingStream extends StatelessWidget {
  final String userId;
  const _BookingStream({required this.userId});
  @override
  Widget build(BuildContext context) => StreamBuilder<List<BookingModel>>(
    stream: context.read<BookingService>().getBookingsForUser(userId, false),
    builder: (ctx, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(strokeWidth: 2)));
      final list = snap.data ?? [];
      if (list.isEmpty) return _Empty(onSearch: () => ctx.go('/search'));
      return Column(children: list.map((b) => _BCard(b: b, onTap: () => ctx.push('/booking/${b.id}'), onReview: b.status == BookingStatus.completed ? () => showRateServiceDialog(ctx, b) : null)).toList());
    },
  );
}

class _BookingSliver extends StatelessWidget {
  final String userId;
  const _BookingSliver({required this.userId});
  @override
  Widget build(BuildContext context) => StreamBuilder<List<BookingModel>>(
    stream: context.read<BookingService>().getBookingsForUser(userId, false),
    builder: (ctx, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(strokeWidth: 2))));
      final list = snap.data ?? [];
      if (list.isEmpty) return SliverToBoxAdapter(child: _Empty(onSearch: () => ctx.go('/search')));
      return SliverList(delegate: SliverChildBuilderDelegate(
        (ctx, i) => _BCard(b: list[i], onTap: () => ctx.push('/booking/${list[i].id}'), onReview: list[i].status == BookingStatus.completed ? () => showRateServiceDialog(ctx, list[i]) : null),
        childCount: list.length,
      ));
    },
  );
}

/// Shows the "rate service" dialog for a completed booking. Shared by both
/// the mobile and web booking lists so review submission works everywhere.
void showRateServiceDialog(BuildContext ctx, BookingModel b) {
  double r = 5;
  final c = TextEditingController();
  bool submitting = false;
  showDialog(context: ctx, builder: (_) => StatefulBuilder(builder: (c2, ss) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    title: const Text('Rate service', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => GestureDetector(
        onTap: submitting ? null : () => ss(() => r = (i+1).toDouble()),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Icon(i < r ? Icons.star_rounded : Icons.star_outline_rounded, size: 28, color: i < r ? AppColors.primary : AppColors.text3)),
      ))),
      const SizedBox(height: 12),
      TextField(controller: c, maxLines: 3, enabled: !submitting, decoration: const InputDecoration(hintText: 'Share your experience (optional)...')),
    ]),
    actions: [
      TextButton(onPressed: submitting ? null : () => Navigator.pop(c2), child: const Text('Cancel')),
      ElevatedButton(
        onPressed: submitting ? null : () async {
          ss(() => submitting = true);
          try {
            await ctx.read<ReviewService>().addReview(bookingId: b.id, seekerId: b.seekerId, providerId: b.providerId, rating: r, comment: c.text.trim());
            if (ctx.mounted) {
              Navigator.pop(c2);
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Review submitted')));
            }
          } catch (e) {
            ss(() => submitting = false);
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed to submit review: $e'), backgroundColor: AppColors.error));
            }
          }
        },
        child: submitting
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Submit'),
      ),
    ],
  )));
}

class _BCard extends StatelessWidget {
  final BookingModel b;
  final VoidCallback onTap;
  final VoidCallback? onReview;
  const _BCard({required this.b, required this.onTap, this.onReview});

  Color _col() {
    switch (b.status) {
      case BookingStatus.completed:  return AppColors.success;
      case BookingStatus.accepted:   return AppColors.info;
      case BookingStatus.inProgress: return AppColors.primary;
      case BookingStatus.declined:   return AppColors.error;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primaryDim, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.build_outlined, size: 18, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.serviceType, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text1)),
            const SizedBox(height: 2),
            Text(b.providerName ?? 'Provider', style: const TextStyle(fontSize: 12, color: AppColors.text3)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _col().withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(b.status.name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _col()))),
            const SizedBox(height: 4),
            Text('K${b.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ]),
        ]),
        if (onReview != null) ...[
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onReview,
              icon: const Icon(Icons.star_outline_rounded, size: 16),
              label: const Text('Rate service'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ]),
    ),
  );
}

class _Empty extends StatelessWidget {
  final VoidCallback onSearch;
  const _Empty({required this.onSearch});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.primaryDim, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.calendar_today_outlined, size: 28, color: AppColors.primary)),
      const SizedBox(height: 16),
      const Text('No bookings yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text1)),
      const SizedBox(height: 6),
      const Text('Browse services and make your first booking', style: TextStyle(fontSize: 13, color: AppColors.text3), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      ElevatedButton.icon(onPressed: onSearch, icon: const Icon(Icons.search, size: 16), label: const Text('Browse Services')),
    ]),
  );
}
