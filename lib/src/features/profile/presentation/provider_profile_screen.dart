import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../models/review_model.dart';
import '../../../services/review_service.dart';

class ProviderProfileScreen extends StatefulWidget {
  final String userId;
  const ProviderProfileScreen({super.key, required this.userId});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  late final Future<UserModel?> _providerFuture;

  @override
  void initState() {
    super.initState();
    // Load once per screen instance, not on every rebuild — avoids
    // refetching Firestore and flashing the loading spinner unnecessarily.
    _providerFuture = _load();
  }

  Future<UserModel?> _load() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    return doc.exists ? UserModel.fromMap(doc.data()!) : null;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<UserModel?>(
    future: _providerFuture,
    builder: (ctx, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 2)));
      }
      if (snap.hasError) {
        return Scaffold(
          appBar: AppBar(title: const Text('Provider')),
          body: Center(child: Text('Failed to load provider: ${snap.error}')),
        );
      }
      final p = snap.data;
      if (p == null) return const Scaffold(body: Center(child: Text('Provider not found')));

      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: Text(p.tradingName ?? 'Provider')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Profile header
              Row(children: [
                CircleAvatar(radius: 36, backgroundColor: AppColors.primaryDim,
                  backgroundImage: p.photoUrl != null ? NetworkImage(p.photoUrl!) : null,
                  child: p.photoUrl == null ? const Icon(Icons.person, size: 36, color: AppColors.primary) : null),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.tradingName ?? 'Unknown', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text1)),
                  const SizedBox(height: 2),
                  Text(p.category ?? 'Service provider', style: const TextStyle(fontSize: 13, color: AppColors.text3)),
                  const SizedBox(height: 6),
                  Row(children: [
                    StreamBuilder<List<ReviewModel>>(
                      stream: ctx.read<ReviewService>().getReviewsForProvider(widget.userId),
                      builder: (ctx, ratingSnap) {
                        final reviews = ratingSnap.data ?? const <ReviewModel>[];
                        if (reviews.isEmpty) {
                          return const Text('No ratings yet', style: TextStyle(fontSize: 12, color: AppColors.text3));
                        }
                        final avg = reviews.fold<double>(0, (sum, r) => sum + r.rating) / reviews.length;
                        return Row(children: [
                          const Icon(Icons.star_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text1)),
                          Text(' (${reviews.length})', style: const TextStyle(fontSize: 12, color: AppColors.text3)),
                        ]);
                      },
                    ),
                    Text('  ·  ${p.city ?? 'Zambia'}', style: const TextStyle(fontSize: 12, color: AppColors.text3)),
                  ]),
                ])),
              ]),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Info rows
              _InfoRow(label: 'About', value: p.bio ?? 'No bio available.'),
              _InfoRow(label: 'Location', value: p.city ?? 'Not specified'),
              _InfoRow(label: 'Starting price', value: 'K${p.basePrice?.toStringAsFixed(0) ?? '0'}'),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Reviews
              const Text('Reviews', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text1)),
              const SizedBox(height: 12),
              StreamBuilder<List<ReviewModel>>(
                stream: ctx.read<ReviewService>().getReviewsForProvider(widget.userId),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  if (snap.hasError) return Text('Failed to load reviews: ${snap.error}', style: const TextStyle(fontSize: 13, color: AppColors.error));
                  final reviews = snap.data ?? const <ReviewModel>[];
                  if (reviews.isEmpty) return const Text('No reviews yet.', style: TextStyle(fontSize: 13, color: AppColors.text3));
                  return Column(children: reviews.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surfaceGrey, borderRadius: BorderRadius.circular(10)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          ...List.generate(r.rating.round().clamp(0, 5), (_) => const Icon(Icons.star_rounded, size: 14, color: AppColors.primary)),
                        ]),
                        if (r.comment.isNotEmpty) ...[const SizedBox(height: 6), Text(r.comment, style: const TextStyle(fontSize: 13, color: AppColors.text1))],
                      ]),
                    ),
                  )).toList());
                },
              ),
              const SizedBox(height: 80),
            ]),
          )),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.divider))),
          child: SafeArea(top: false, child: Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => _showMessageInfo(context),
              child: const Text('Message'),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(onPressed: () => context.push('/book/${widget.userId}'), child: const Text('Book Now'))),
          ])),
        ),
      );
    },
  );

  void _showMessageInfo(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('Start a booking to chat', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      content: const Text(
        'Messaging opens once you have an active booking with this provider. '
        'Book their service to start a conversation.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            context.push('/book/${widget.userId}');
          },
          child: const Text('Book Now'),
        ),
      ],
    ));
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.text3, fontWeight: FontWeight.w500))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 14, color: AppColors.text1))),
    ]),
  );
}
