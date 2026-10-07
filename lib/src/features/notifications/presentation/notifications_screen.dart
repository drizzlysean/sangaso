import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/notification_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final u = context.read<AuthService>().currentUserModel;
      if (u != null) await context.read<NotificationService>().markAllAsRead(u.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUserModel;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<List<NotificationModel>>(
        stream: context.read<NotificationService>().getUserNotifications(user.id),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          final list = snap.data ?? [];
          if (list.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.primaryDim, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.notifications_none_outlined, size: 28, color: AppColors.primary)),
            const SizedBox(height: 14),
            Text('All caught up', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('No new notifications', style: Theme.of(ctx).textTheme.bodyMedium),
          ]));

          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
            itemBuilder: (ctx, i) {
              final n = list[i];
              return InkWell(
                onTap: n.relatedId != null ? () => ctx.push('/booking/${n.relatedId}') : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(
                      color: n.isRead ? AppColors.surfaceGrey : AppColors.primaryDim,
                      shape: BoxShape.circle),
                      child: Icon(Icons.notifications_outlined, size: 18, color: n.isRead ? AppColors.text3 : AppColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(n.title, style: TextStyle(fontSize: 14, fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600, color: AppColors.text1)),
                      const SizedBox(height: 3),
                      Text(n.message, style: Theme.of(ctx).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(DateFormat('MMM d · h:mm a').format(n.createdAt), style: Theme.of(ctx).textTheme.labelSmall),
                    ])),
                    if (!n.isRead) Container(width: 7, height: 7, margin: const EdgeInsets.only(top: 5), decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
