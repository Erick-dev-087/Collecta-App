import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api_provider.dart';
import '../../data/models/collection.dart';
import '../../data/models/enums.dart';
import '../../state/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../utils/whatsapp.dart';
import '../../widgets/page_header.dart';
import '../../widgets/ui.dart';
import 'widgets/collection_card.dart';
import 'widgets/new_collection_sheet.dart';

class CollectionsScreen extends ConsumerStatefulWidget {
  const CollectionsScreen({super.key});

  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  String _query = '';
  String _category = 'All';
  String _statusFilter = 'All';

  static const _categories = [
    'All',
    'Trips & Events',
    'Capital Projects',
    'Youth & Camps',
    'Welfare',
  ];

  static const _statusFilters = [
    'All',
    'Active',
    'Cancelled',
    'Closed',
    'Expired',
  ];

  List<Collection> _filter(List<Collection> all) {
    return all.where((c) {
      final matchesCat = _category == 'All' || c.category == _category;
      final matchesStatus = _statusFilter == 'All' ||
          c.status == EventStatus.fromString(_statusFilter.toLowerCase());
      final q = _query.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          c.title.toLowerCase().contains(q) ||
          (c.shortCode ?? '').toLowerCase().contains(q);
      return matchesCat && matchesQuery && matchesStatus;
    }).toList();
  }

  Future<void> _copyLink(Collection c) async {
    await copyToClipboard('https://${c.payLink}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment link copied to clipboard')),
      );
    }
  }

  Future<void> _shareLink(Collection c) async {
    final text =
        'Contribute to ${c.title} via M-Pesa STK: https://${c.payLink}';
    final ok = await shareToWhatsApp(text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp is not available on this device')),
      );
    }
  }

  Future<void> _bulkStk(Collection c) async {
    final n = await ref.read(collectaApiProvider).triggerBulkStk(c.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dispatched $n STK prompt(s) for ${c.title}')),
      );
    }
  }

  void _openCreate() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NewCollectionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(collectionsProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: AppColors.emeraldDeep,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Collection'),
      ),
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppColors.emeraldDeep)),
          error: (e, _) =>
              AsyncStateView(message: 'Could not load collections.\n$e', isError: true),
          data: (all) => _content(all),
        ),
      ),
    );
  }

  Widget _content(List<Collection> all) {
    final active = all.where((c) => c.status.name == 'active').length;
    final gross = all.fold<num>(0, (s, c) => s + (c.targetAmount ?? 0));
    final collected = all.fold<num>(0, (s, c) => s + c.totalCollected);
    final filtered = _filter(all);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(collectionsProvider),
      color: AppColors.emeraldDeep,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
        children: [
          const CollectaHeader(
            title: 'Collections & Events',
            subtitle:
                'Create and track collections with automated M-Pesa STK reconciliation.',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _miniStat('Gross Active Quota', kesCompact(gross),
                    '${all.length} initiatives'),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: _miniStat('Collected Real-Time', kesCompact(collected),
                    '$active active'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, size: 20),
              hintText: 'Search collection by name or code…',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = cat == _category;
                return ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = cat),
                  showCheckmark: false,
                  selectedColor: AppColors.emeraldDeep,
                  backgroundColor: AppColors.panel,
                  labelStyle: AppType.labelMd.copyWith(
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                  side: BorderSide(
                      color: selected
                          ? AppColors.emeraldDeep
                          : AppColors.slateBorder),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statusFilters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final sf = _statusFilters[i];
                final selected = sf == _statusFilter;
                return ChoiceChip(
                  label: Text(sf),
                  selected: selected,
                  onSelected: (_) => setState(() => _statusFilter = sf),
                  showCheckmark: false,
                  selectedColor: AppColors.emeraldDeep,
                  backgroundColor: AppColors.panel,
                  labelStyle: AppType.labelMd.copyWith(
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                  side: BorderSide(
                      color: selected
                          ? AppColors.emeraldDeep
                          : AppColors.slateBorder),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: AsyncStateView(message: 'No collections match your filters.'),
            )
          else
            for (final c in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: CollectionCard(
                  collection: c,
                  onCopy: () => _copyLink(c),
                  onWhatsApp: () => _shareLink(c),
                  onStk: () => _bulkStk(c),
                  onViewLedger: () => context.push('/ledger-view/${c.id}'),
                ),
              ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, String caption) {
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppType.labelSm),
          const SizedBox(height: 6),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.currencyMd),
          const SizedBox(height: 2),
          Text(caption, style: AppType.bodySm),
        ],
      ),
    );
  }
}
