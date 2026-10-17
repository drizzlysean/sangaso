import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/booking_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/booking_service.dart';

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});
  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUserModel;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.text3,
          indicatorColor: AppColors.primary,
          dividerColor: AppColors.divider,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [Tab(text: 'Active'), Tab(text: 'Completed')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _List(userId: user.id, isProvider: user.role.name == 'provider', active: true),
          _List(userId: user.id, isProvider: user.role.name == 'provider', active: false),
        ],
      ),
    );
  }
}

class _List extends StatelessWidget {
  final String userId;
  final bool isProvider, active;
  const _List({required this.userId, required this.isProvider, required this.active});

  static String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.requested:  return 'Requested';
      case BookingStatus.accepted:   return 'Accepted';
      case BookingStatus.inProgress: return 'In progress';
      case BookingStatus.completed:  return 'Completed';
      case BookingStatus.declined:   return 'Declined';
      case BookingStatus.cancelled:  return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<BookingModel>>(
    stream: context.read<BookingService>().getBookingsForUser(userId, isProvider),
    builder: (ctx, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      final all = snap.data ?? [];
      final done = {BookingStatus.completed, BookingStatus.declined, BookingStatus.cancelled};
      final list = active
          ? all.where((b) => !done.contains(b.status)).toList()
          : all.where((b) => done.contains(b.status)).toList();

      if (list.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.primaryDim, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.calendar_today_outlined, size: 28, color: AppColors.primary)),
        const SizedBox(height: 14),
        Text(active ? 'No active bookings' : 'No completed bookings', style: Theme.of(context).textTheme.titleMedium),
      ]));

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final b = list[i];
          Color col;
          switch (b.status) {
            case BookingStatus.completed:  col = AppColors.success; break;
            case BookingStatus.accepted:   col = AppColors.info; break;
            case BookingStatus.inProgress: col = AppColors.primary; break;
            case BookingStatus.declined:   col = AppColors.error; break;
            default: col = AppColors.warning;
          }
          return GestureDetector(
            onTap: () => ctx.push('/booking/${b.id}'),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.primaryDim, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.handyman_outlined, size: 20, color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b.serviceType, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(isProvider ? (b.seekerName ?? 'Customer') : (b.providerName ?? 'Provider'), style: Theme.of(context).textTheme.bodySmall),
                  Text(b.scheduledTime.toString().split(' ')[0], style: Theme.of(context).textTheme.bodySmall),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(_statusLabel(b.status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: col))),
                  const SizedBox(height: 6),
                  Text('K${b.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ]),
              ]),
            ),
          );
        },
      );
    },
  );
}
