import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/service_categories.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/service_model.dart';
import '../../../services/service_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialCategory});
  final String? initialCategory;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  late String _cat = validateSearchCategory(widget.initialCategory);

  static const _cats = kSearchCategories;

  @override
  void initState() { super.initState(); _ctrl.addListener(() => setState(() {})); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final wide = kIsWeb && MediaQuery.of(context).size.width > 860;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _ctrl,
            autofocus: !kIsWeb,
            decoration: InputDecoration(
              hintText: 'Search services...',
              prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.text3),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? GestureDetector(onTap: () { _ctrl.clear(); setState(() {}); },
                      child: const Icon(Icons.close, size: 18, color: AppColors.text3))
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              isDense: true,
            ),
          ),
        ),
      ),
      body: Column(children: [
        // Category chips
        Container(
          height: 46,
          color: AppColors.surfaceGrey,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (ctx, i) {
              final sel = _cats[i] == _cat;
              return GestureDetector(
                onTap: () => setState(() => _cat = _cats[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(_cats[i], style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? Colors.white : AppColors.text2)),
                ),
              );
            },
          ),
        ),

        // Results
        Expanded(child: StreamBuilder<List<ServiceModel>>(
          stream: _cat == 'All'
              ? context.read<ServiceService>().getAllServices()
              : context.read<ServiceService>().getServicesByCategory(_cat),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary));
            var svcs = snap.data ?? [];
            if (_ctrl.text.isNotEmpty) {
              final q = _ctrl.text.toLowerCase();
              svcs = svcs.where((s) => s.name.toLowerCase().contains(q) || s.description.toLowerCase().contains(q) || s.category.toLowerCase().contains(q)).toList();
            }
            if (svcs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.search_off_rounded, size: 52, color: AppColors.text3),
              const SizedBox(height: 14),
              Text(_ctrl.text.isEmpty ? 'No services available' : 'No results for "${_ctrl.text}"',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.text1), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text('Try a different search or category', style: TextStyle(fontSize: 13, color: AppColors.text3)),
            ]));

            // Web: 2-col grid. Mobile: list
            if (wide) {
              return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 960),
                child: Padding(padding: const EdgeInsets.all(20),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.4),
                    itemCount: svcs.length,
                    itemBuilder: (ctx, i) => _ServiceCard(s: svcs[i]),
                  ),
                ),
              ));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: svcs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _ServiceCard(s: svcs[i]),
            );
          },
        )),
      ]),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel s;
  const _ServiceCard({required this.s});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/service/${s.id}'),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryDim,
            border: Border.all(color: AppColors.primaryMid),
            borderRadius: BorderRadius.circular(12),
            image: s.imageUrls.isNotEmpty ? DecorationImage(image: NetworkImage(s.imageUrls.first), fit: BoxFit.cover) : null,
          ),
          child: s.imageUrls.isEmpty ? const Icon(Icons.construction_rounded, size: 24, color: AppColors.primaryDeep) : null,
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text1), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(s.description, style: const TextStyle(fontSize: 12, color: AppColors.text3), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primaryDim, borderRadius: BorderRadius.circular(4)),
              child: Text(s.category, style: const TextStyle(fontSize: 10, color: AppColors.primaryDeep, fontWeight: FontWeight.w600))),
            const Spacer(),
            Text('K${s.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryDeep)),
          ]),
        ])),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right, size: 18, color: AppColors.text3),
      ]),
    ),
  );
}
