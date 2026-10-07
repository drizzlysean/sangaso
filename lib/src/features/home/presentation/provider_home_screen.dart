import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/booking_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/booking_service.dart';
import '../../../services/notification_service.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});
  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  @override
  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUserModel;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall),
          Text('Manage your jobs', style: Theme.of(context).textTheme.bodySmall),
        ]),
        actions: [
          StreamBuilder<int>(
            stream: context.read<NotificationService>().getUnreadCount(user.id),
            builder: (ctx, snap) {
              final n = snap.data ?? 0;
              return Stack(children: [
                IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => ctx.go('/notifications')),
                if (n > 0) Positioned(right: 8, top: 10, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))),
              ]);
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.text3,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorWeight: 2,
          dividerColor: AppColors.divider,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          tabs: const [Tab(text: 'Requests'), Tab(text: 'Active'), Tab(text: 'History')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _JobList(userId: user.id, statuses: [BookingStatus.requested]),
          _JobList(userId: user.id, statuses: [BookingStatus.accepted, BookingStatus.inProgress]),
          _JobList(userId: user.id, statuses: [BookingStatus.completed, BookingStatus.declined, BookingStatus.cancelled]),
        ],
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  final String userId;
  final List<BookingStatus> statuses;
  const _JobList({required this.userId, required this.statuses});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BookingModel>>(
      stream: context.read<BookingService>().getBookingsForUser(userId, true),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        final all  = snap.data ?? [];
        final list = all.where((b) => statuses.contains(b.status)).toList();

        if (list.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.primaryDim, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.inbox_outlined, size: 28, color: AppColors.primary)),
          const SizedBox(height: 14),
          Text('No jobs here', style: Theme.of(context).textTheme.titleMedium),
        ]));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) => _ProviderJobCard(b: list[i]),
        );
      },
    );
  }
}

class _ProviderJobCard extends StatelessWidget {
  final BookingModel b;
  const _ProviderJobCard({required this.b});

  Color _col() {
    switch (b.status) {
      case BookingStatus.completed:  return AppColors.success;
      case BookingStatus.accepted:   return AppColors.info;
      case BookingStatus.inProgress: return AppColors.primary;
      case BookingStatus.declined:   return AppColors.error;
      case BookingStatus.requested:  return AppColors.warning;
      default: return AppColors.text3;
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/booking/${b.id}'),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(b.serviceType, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _col().withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(b.status.name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _col()))),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.person_outline, size: 13, color: AppColors.text3),
          const SizedBox(width: 4),
          Text(b.seekerName ?? 'Customer', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 12),
          const Icon(Icons.location_on_outlined, size: 13, color: AppColors.text3),
          const SizedBox(width: 4),
          Expanded(child: Text(b.address, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('K${b.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
          Text(b.scheduledTime.toString().split(' ')[0], style: Theme.of(context).textTheme.bodySmall),
        ]),
      ]),
    ),
  );
}
