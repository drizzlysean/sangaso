import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/booking_model.dart';
import '../../../models/user_model.dart';
import '../../../services/admin_service.dart';
import '../../../services/auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _admin = AdminService();
  int _tab = 0;
  String _search = '';
  String _roleFilter = 'all';
  String _statusFilter = 'all';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  static const _tabs = ['Overview', 'Users', 'Bookings'];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 860;

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: Row(children: [
        // ─── Sidebar ───
        if (wide) Container(
          width: 220,
          color: Colors.white,
          child: Column(children: [
            // Logo area
            Container(height: 64, padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
              alignment: Alignment.centerLeft,
              child: Row(children: [
                Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.admin_panel_settings_outlined, size: 18, color: Colors.white)),
                const SizedBox(width: 10),
                const Text('Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text1)),
              ])),
            // Nav
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              child: Column(children: List.generate(_tabs.length, (i) {
                final icons = [Icons.dashboard_outlined, Icons.people_outline, Icons.receipt_long_outlined];
                final on = i == _tab;
                return Padding(padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(8),
                    child: InkWell(onTap: () => setState(() => _tab = i), borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: on ? AppColors.primaryDim : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                        child: Row(children: [
                          Icon(icons[i], size: 18, color: on ? AppColors.primary : AppColors.text2),
                          const SizedBox(width: 12),
                          Text(_tabs[i], style: TextStyle(fontSize: 14, fontWeight: on ? FontWeight.w600 : FontWeight.w400, color: on ? AppColors.primary : AppColors.text1)),
                        ]),
                      ),
                    ),
                  ),
                );
              })),
            )),
            // Logout
            Padding(padding: const EdgeInsets.all(10),
              child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(8),
                child: InkWell(borderRadius: BorderRadius.circular(8),
                  onTap: () => _logout(context),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: const Row(children: [
                      Icon(Icons.logout_outlined, size: 18, color: AppColors.text3),
                      SizedBox(width: 12),
                      Text('Log out', style: TextStyle(fontSize: 14, color: AppColors.text2)),
                    ])),
                ),
              ),
            ),
          ]),
        ),
        if (wide) Container(width: 1, color: AppColors.divider),

        // ─── Main content ───
        Expanded(child: Column(children: [
          // Top bar
          Container(
            height: 64, color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
            child: Row(children: [
              if (!wide) ...[
                PopupMenuButton<int>(
                  onSelected: (i) => setState(() => _tab = i),
                  icon: const Icon(Icons.menu, color: AppColors.text1),
                  itemBuilder: (_) => List.generate(_tabs.length, (i) => PopupMenuItem(value: i, child: Text(_tabs[i]))),
                ),
                const SizedBox(width: 8),
              ],
              Text(_tabs[_tab], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text1)),
              const Spacer(),
              if (!wide) IconButton(icon: const Icon(Icons.logout_outlined, size: 20), onPressed: () => _logout(context)),
              IconButton(icon: const Icon(Icons.refresh_outlined, size: 20), onPressed: () => setState(() {})),
            ]),
          ),
          // Body
          Expanded(child: [
            _Overview(admin: _admin),
            _UsersTab(admin: _admin, search: _search, roleFilter: _roleFilter, onSearch: (v) => setState(() => _search = v), onRole: (v) => setState(() => _roleFilter = v)),
            _BookingsTab(admin: _admin, statusFilter: _statusFilter, onStatus: (v) => setState(() => _statusFilter = v)),
          ][_tab]),
        ])),
      ]),
    );
  }

  void _logout(BuildContext ctx) async {
    final ok = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Log out?', style: TextStyle(fontSize: 15)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Log out')),
      ],
    ));
    if (ok == true && ctx.mounted) { await ctx.read<AuthService>().signOut(); if (ctx.mounted) ctx.go('/login'); }
  }
}

// ─── Overview ─────────────────────────────────────────────────────────────────

class _Overview extends StatelessWidget {
  final AdminService admin;
  const _Overview({required this.admin});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 960),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Platform Overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text1)),
        const SizedBox(height: 16),
        Row(children: [
          _StatCard(label: 'Total Users',    icon: Icons.people_outline,   stream: FirebaseFirestore.instance.collection('users').snapshots().map((s) => s.docs.length)),
          const SizedBox(width: 12),
          _StatCard(label: 'Providers',      icon: Icons.handyman_outlined, stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'provider').snapshots().map((s) => s.docs.length)),
          const SizedBox(width: 12),
          _StatCard(label: 'Total Bookings', icon: Icons.receipt_long_outlined, stream: FirebaseFirestore.instance.collection('bookings').snapshots().map((s) => s.docs.length)),
        ]),
        const SizedBox(height: 24),
        const Text('Recent Bookings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text1)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('bookings').orderBy('createdAt', descending: true).limit(8).snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            final docs = snap.data!.docs;
            if (docs.isEmpty) return const Text('No bookings yet.', style: TextStyle(fontSize: 13, color: AppColors.text3));
            return Column(children: docs.map((d) {
              final b = BookingModel.fromMap(d.data() as Map<String, dynamic>);
              Color col;
              switch (b.status) {
                case BookingStatus.completed: col = AppColors.success; break;
                case BookingStatus.accepted:  col = AppColors.info; break;
                case BookingStatus.inProgress:col = AppColors.primary; break;
                case BookingStatus.declined:  col = AppColors.error; break;
                default: col = AppColors.warning;
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(b.serviceType, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text1)),
                    Text('${b.seekerName ?? ''} → ${b.providerName ?? ''}', style: const TextStyle(fontSize: 11, color: AppColors.text3)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(b.status.name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: col))),
                    const SizedBox(height: 3),
                    Text('K${b.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ]),
                ]),
              );
            }).toList());
          },
        ),
      ]),
    )),
  );
}

class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Stream<int> stream;
  const _StatCard({required this.label, required this.icon, required this.stream});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 10),
        StreamBuilder<int>(stream: stream, builder: (_, s) => Text('${s.data ?? 0}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text1))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.text3)),
      ]),
    ),
  );
}

// ─── Users tab ────────────────────────────────────────────────────────────────

class _UsersTab extends StatelessWidget {
  final AdminService admin;
  final String search, roleFilter;
  final ValueChanged<String> onSearch, onRole;
  const _UsersTab({required this.admin, required this.search, required this.roleFilter, required this.onSearch, required this.onRole});

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(children: [
        Expanded(child: SizedBox(height: 38, child: TextField(onChanged: onSearch,
          decoration: const InputDecoration(hintText: 'Search users...', prefixIcon: Icon(Icons.search, size: 16), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 9))))),
        const SizedBox(width: 10),
        DropdownButton<String>(value: roleFilter, underline: const SizedBox(), style: const TextStyle(fontSize: 13, color: AppColors.text1),
          items: const [DropdownMenuItem(value: 'all', child: Text('All roles')), DropdownMenuItem(value: 'seeker', child: Text('Seekers')), DropdownMenuItem(value: 'provider', child: Text('Providers'))],
          onChanged: (v) => onRole(v ?? 'all')),
      ]),
    ),
    Expanded(child: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        var docs = snap.data!.docs;
        if (roleFilter != 'all') docs = docs.where((d) => (d.data() as Map)['role'] == roleFilter).toList();
        if (search.isNotEmpty) docs = docs.where((d) {
          final m = d.data() as Map;
          return '${m['displayName']} ${m['email']}'.toLowerCase().contains(search.toLowerCase());
        }).toList();
        if (docs.isEmpty) return Center(child: Text('No users found', style: TextStyle(fontSize: 13, color: AppColors.text3)));
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (ctx, i) {
            final user = UserModel.fromMap(docs[i].data() as Map<String, dynamic>);
            return _UserRow(admin: admin, user: user);
          },
        );
      },
    )),
  ]);
}

class _UserRow extends StatefulWidget {
  final AdminService admin;
  final UserModel user;
  const _UserRow({required this.admin, required this.user});

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _busy = false;

  /// Internal signal used to abort an action cleanly (e.g. the admin
  /// cancelled a confirmation dialog) without surfacing an error snackbar.
  static final Object _cancelled = Object();

  Future<void> _run(Future<void> Function() action, {String? successMessage}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (e) {
      if (identical(e, _cancelled)) {
        // Admin cancelled the confirmation dialog — not an error.
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm(String title, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true) throw _cancelled;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final role = user.role.name;
    final isProvider = user.role == UserRole.provider;
    final pendingKyc = isProvider && !user.isVerified;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 18, backgroundColor: AppColors.primaryDim,
            backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? Text((user.displayName?.isNotEmpty == true ? user.displayName! : 'U')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600))
                : null),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.displayName?.isNotEmpty == true ? user.displayName! : 'Unknown', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text1)),
            Text(user.email, style: const TextStyle(fontSize: 11, color: AppColors.text3)),
          ])),
          if (user.isBanned) Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: const Text('Banned', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.error)),
          ),
          if (user.isSuspended) Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: const Text('Suspended', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warning)),
          ),
          if (pendingKyc) Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: AppColors.info.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: const Text('KYC pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.info)),
          ),
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: isProvider ? AppColors.primaryDim : AppColors.surfaceGrey, borderRadius: BorderRadius.circular(20)),
            child: Text(role, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isProvider ? AppColors.primary : AppColors.text2))),
        ]),
        const SizedBox(height: 10),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (pendingKyc) ...[
              OutlinedButton(
                onPressed: () => _run(
                  () => widget.admin.approveKYC(user.id),
                  successMessage: 'KYC approved for ${user.displayName ?? user.email}',
                ),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.success, side: const BorderSide(color: AppColors.success), minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 10)),
                child: const Text('Approve KYC', style: TextStyle(fontSize: 12)),
              ),
              OutlinedButton(
                onPressed: () => _run(
                  () => widget.admin.rejectKYC(user.id, 'Rejected by admin'),
                  successMessage: 'KYC rejected for ${user.displayName ?? user.email}',
                ),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 10)),
                child: const Text('Reject KYC', style: TextStyle(fontSize: 12)),
              ),
            ],
            OutlinedButton(
              onPressed: () => _run(() async {
                if (!user.isBanned) {
                  await _confirm('Ban user?', 'This will prevent ${user.displayName ?? user.email} from being treated as an active user. This can be undone later.');
                }
                await widget.admin.updateUserStatus(user.id, isBanned: !user.isBanned);
              }, successMessage: user.isBanned ? 'User unbanned' : 'User banned'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 10)),
              child: Text(user.isBanned ? 'Unban' : 'Ban', style: const TextStyle(fontSize: 12)),
            ),
            OutlinedButton(
              onPressed: () => _run(
                () => widget.admin.updateUserStatus(user.id, isSuspended: !user.isSuspended),
                successMessage: user.isSuspended ? 'User unsuspended' : 'User suspended',
              ),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.warning, side: const BorderSide(color: AppColors.warning), minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 10)),
              child: Text(user.isSuspended ? 'Unsuspend' : 'Suspend', style: const TextStyle(fontSize: 12)),
            ),
          ]),
      ]),
    );
  }
}

// ─── Bookings tab ─────────────────────────────────────────────────────────────

class _BookingsTab extends StatelessWidget {
  final AdminService admin;
  final String statusFilter;
  final ValueChanged<String> onStatus;
  const _BookingsTab({required this.admin, required this.statusFilter, required this.onStatus});

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(children: [
        const Text('Filter:', style: TextStyle(fontSize: 13, color: AppColors.text3)),
        const SizedBox(width: 8),
        DropdownButton<String>(value: statusFilter, underline: const SizedBox(), style: const TextStyle(fontSize: 13, color: AppColors.text1),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All')),
            DropdownMenuItem(value: 'requested', child: Text('Pending')),
            DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
            DropdownMenuItem(value: 'completed', child: Text('Completed')),
          ],
          onChanged: (v) => onStatus(v ?? 'all')),
      ]),
    ),
    Expanded(child: StreamBuilder<QuerySnapshot>(
      stream: statusFilter == 'all'
          ? FirebaseFirestore.instance.collection('bookings').orderBy('createdAt', descending: true).snapshots()
          : FirebaseFirestore.instance.collection('bookings').where('status', isEqualTo: statusFilter).snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        final docs = snap.data!.docs;
        if (docs.isEmpty) return Center(child: Text('No bookings', style: TextStyle(fontSize: 13, color: AppColors.text3)));
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (ctx, i) {
            final b = BookingModel.fromMap(docs[i].data() as Map<String, dynamic>);
            Color col;
            switch (b.status) {
              case BookingStatus.completed: col = AppColors.success; break;
              case BookingStatus.accepted:  col = AppColors.info; break;
              case BookingStatus.inProgress:col = AppColors.primary; break;
              case BookingStatus.declined:  col = AppColors.error; break;
              default: col = AppColors.warning;
            }
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b.serviceType, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text1)),
                  const SizedBox(height: 2),
                  Text('${b.seekerName ?? 'Seeker'}  →  ${b.providerName ?? 'Provider'}', style: const TextStyle(fontSize: 11, color: AppColors.text3)),
                  Text(b.scheduledTime.toString().split(' ')[0], style: const TextStyle(fontSize: 11, color: AppColors.text3)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(b.status.name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: col))),
                  const SizedBox(height: 4),
                  Text('K${b.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ]),
              ]),
            );
          },
        );
      },
    )),
  ]);
}
