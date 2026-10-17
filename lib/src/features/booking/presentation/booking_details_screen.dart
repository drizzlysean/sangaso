import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/booking_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/booking_service.dart';

class BookingDetailsScreen extends StatelessWidget {
  final String bookingId;
  const BookingDetailsScreen({super.key, required this.bookingId});

  // ── helpers ──────────────────────────────────────────────────────────
  static Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.completed:  return AppColors.success;
      case BookingStatus.accepted:   return AppColors.info;
      case BookingStatus.inProgress: return AppColors.primary;
      case BookingStatus.declined:   return AppColors.error;
      case BookingStatus.cancelled:  return AppColors.error;
      default: return AppColors.warning;
    }
  }

  static String _statusLabel(BookingStatus s) {
    switch (s) {
      case BookingStatus.requested:  return 'Pending';
      case BookingStatus.accepted:   return 'Confirmed';
      case BookingStatus.inProgress: return 'In Progress';
      case BookingStatus.completed:  return 'Completed';
      case BookingStatus.cancelled:  return 'Cancelled';
      case BookingStatus.declined:   return 'Declined';
    }
  }

  static String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final p = d.hour >= 12 ? 'PM' : 'AM';
    return '${m[d.month-1]} ${d.day}, ${d.year}  ·  $h:${d.minute.toString().padLeft(2,'0')} $p';
  }

  Future<void> _call(BuildContext ctx, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
    else { Clipboard.setData(ClipboardData(text: phone)); if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Phone copied: $phone'))); }
  }

  // ── build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthService>().currentUserModel;
    if (me == null) return const Scaffold(body: Center(child: Text('Not authenticated')));
    final isProvider = me.role.name == 'provider';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Booking Details')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').doc(bookingId).snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          if (!snap.data!.exists) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            const Text('Booking not found'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => ctx.go('/bookings'), child: const Text('Back to Bookings')),
          ]));

          final b = BookingModel.fromMap(snap.data!.data() as Map<String, dynamic>);
          final col = _statusColor(b.status);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ─── Status badge ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: col.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: col.withOpacity(0.2)),
                ),
                child: Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Text(_statusLabel(b.status), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: col)),
                  const Spacer(),
                  Text('# ${b.id.substring(0,8).toUpperCase()}', style: Theme.of(ctx).textTheme.bodySmall),
                ]),
              ),
              const SizedBox(height: 16),

              // ─── Service card ───
              _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primaryDim, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.work_outline, size: 22, color: AppColors.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(b.serviceType, style: Theme.of(ctx).textTheme.titleSmall),
                    Text(b.providerName ?? 'Provider', style: Theme.of(ctx).textTheme.bodySmall),
                  ])),
                  Text('K${b.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ]),
              ])),
              const SizedBox(height: 10),

              // ─── Schedule ───
              _Card(child: Column(children: [
                _Row(Icons.calendar_today_outlined, 'Scheduled', _fmtDate(b.scheduledTime)),
                if (b.completedAt != null) ...[
                  const Divider(height: 20),
                  _Row(Icons.check_circle_outline, 'Completed', _fmtDate(b.completedAt!)),
                ],
              ])),
              const SizedBox(height: 10),

              // ─── Location ───
              _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Row(Icons.location_on_outlined, 'Location', b.address),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(b.address)}');
                    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.directions_outlined, size: 16),
                  label: const Text('Get Directions'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38), padding: const EdgeInsets.symmetric(horizontal: 14)),
                ),
              ])),
              const SizedBox(height: 10),

              // ─── Contact ───
              if (isProvider && b.seekerName != null || !isProvider && b.providerName != null) ...[
                _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _Row(Icons.person_outline_rounded, isProvider ? 'Customer' : 'Provider',
                    isProvider ? (b.seekerName ?? '') : (b.providerName ?? '')),
                  if ((isProvider ? b.seekerPhone : b.providerPhone) != null) ...[
                    const Divider(height: 20),
                    Row(children: [
                      ElevatedButton.icon(
                        onPressed: () => context.push('/chat/$bookingId'),
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text('Message'),
                        style: ElevatedButton.styleFrom(minimumSize: const Size(0, 38), padding: const EdgeInsets.symmetric(horizontal: 14)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _call(context, isProvider ? (b.seekerPhone ?? '') : (b.providerPhone ?? '')),
                        icon: const Icon(Icons.phone_outlined, size: 16),
                        label: const Text('Call'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38), padding: const EdgeInsets.symmetric(horizontal: 14)),
                      ),
                    ]),
                  ],
                ])),
                const SizedBox(height: 10),
              ],

              // ─── Notes ───
              if (b.specialInstructions != null && b.specialInstructions!.isNotEmpty) ...[
                _Card(child: _Row(Icons.note_outlined, 'Notes', b.specialInstructions!)),
                const SizedBox(height: 10),
              ],

              // ─── Timeline ───
              _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Timeline', style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 14),
                _TLItem(label: 'Booking created', date: b.createdAt, isLast: b.acceptedAt == null && b.startedAt == null && b.completedAt == null),
                if (b.acceptedAt != null) _TLItem(label: 'Accepted', date: b.acceptedAt!, isLast: b.startedAt == null && b.completedAt == null),
                if (b.startedAt  != null) _TLItem(label: 'Job started', date: b.startedAt!, isLast: b.completedAt == null),
                if (b.completedAt!= null) _TLItem(label: 'Completed', date: b.completedAt!, isLast: true),
              ])),
              const SizedBox(height: 24),
            ]),
          );
        },
      ),
      bottomNavigationBar: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').doc(bookingId).snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();
          final b = BookingModel.fromMap(snap.data!.data() as Map<String, dynamic>);
          return _ActionBar(b: b, isProvider: isProvider);
        },
      ),
    );
  }
}

// ─── small reusable widgets ───────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: child,
  );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Row(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, size: 16, color: AppColors.text3),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 3),
      Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14)),
    ])),
  ]);
}

class _TLItem extends StatelessWidget {
  final String label;
  final DateTime date;
  final bool isLast;
  const _TLItem({required this.label, required this.date, required this.isLast});
  @override
  Widget build(BuildContext context) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final str = '${m[date.month-1]} ${date.day}, ${date.year}';
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
        if (!isLast) Container(width: 2, height: 28, color: AppColors.divider),
      ]),
      const SizedBox(width: 12),
      Padding(padding: const EdgeInsets.only(top: 1, bottom: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 13)),
        Text(str, style: Theme.of(context).textTheme.bodySmall),
      ])),
    ]);
  }
}

class _ActionBar extends StatelessWidget {
  final BookingModel b;
  final bool isProvider;
  const _ActionBar({required this.b, required this.isProvider});

  @override
  Widget build(BuildContext context) {
    final done = {BookingStatus.completed, BookingStatus.cancelled, BookingStatus.declined};
    if (done.contains(b.status)) return const SizedBox.shrink();

    Widget? btn;
    if (isProvider) {
      if (b.status == BookingStatus.requested) {
        btn = Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => _act(context, BookingStatus.declined, 'Decline this booking?'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
            child: const Text('Decline'),
          )),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: ElevatedButton(
            onPressed: () => _act(context, BookingStatus.accepted, 'Accept this booking?'),
            child: const Text('Accept Booking'),
          )),
        ]);
      } else if (b.status == BookingStatus.accepted) {
        btn = SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () => _act(context, BookingStatus.inProgress, 'Mark job as started?'),
          icon: const Icon(Icons.play_arrow, size: 18), label: const Text('Start Job'),
        ));
      } else if (b.status == BookingStatus.inProgress) {
        btn = SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () => _act(context, BookingStatus.completed, 'Mark job as completed?'),
          icon: const Icon(Icons.check_circle_outline, size: 18), label: const Text('Complete Job'),
        ));
      }
    } else {
      if (b.status == BookingStatus.requested) {
        btn = SizedBox(width: double.infinity, child: OutlinedButton(
          onPressed: () => _act(context, BookingStatus.cancelled, 'Cancel this booking?'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
          child: const Text('Cancel Booking'),
        ));
      }
    }

    if (btn == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.divider))),
      child: SafeArea(top: false, child: btn),
    );
  }

  void _act(BuildContext ctx, BookingStatus next, String msg) async {
    final ok = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(msg, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
      ],
    ));
    if (ok == true && ctx.mounted) {
      try {
        await ctx.read<BookingService>().updateBookingStatus(b.id, next);
        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Updated to ${next.name}')));
      } catch (e) {
        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }
}
