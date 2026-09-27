import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/member.dart';
import '../../state/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/page_header.dart';
import '../../widgets/ui.dart';
import 'widgets/add_member_sheet.dart';
import 'widgets/member_tile.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  String _query = '';
  bool _pendingOnly = false;

  List<Member> _filter(List<Member> all) {
    final q = _query.trim().toLowerCase();
    return all.where((m) {
      final matches = q.isEmpty ||
          m.fullName.toLowerCase().contains(q) ||
          m.phone.contains(q) ||
          m.id.toLowerCase().contains(q);
      final pending = !_pendingOnly || m.contributionCount == 0;
      return matches && pending;
    }).toList();
  }

  void _openAdd() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddMemberSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(membersProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: AppColors.emeraldDeep,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add Member'),
      ),
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.emeraldDeep)),
          error: (e, _) => AsyncStateView(
              message: 'Could not load members.\n$e', isError: true),
          data: (all) => _content(all),
        ),
      ),
    );
  }

  Widget _content(List<Member> all) {
    final verified = all.where((m) => m.stkVerified).length;
    final active = all.where((m) => m.contributionCount > 0).length;
    final contributions = all.fold<num>(0, (s, m) => s + m.totalContributed);
    final filtered = _filter(all);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(membersProvider),
      color: AppColors.emeraldDeep,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
        children: [
          const CollectaHeader(
            title: 'Members Directory',
            subtitle:
                'Verify phone numbers for M-Pesa STK and review lifetime contributions.',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                  child: _stat('Total Members', '${all.length}',
                      '$active active')),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                  child: _stat('Contributions', kesCompact(contributions),
                      'Audit balanced')),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                  child: _stat('STK Verified', '$verified/${all.length}',
                      'Safaricom ready')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, size: 20),
              hintText: 'Search by name, phone or member ID…',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text('${filtered.length} shown', style: AppType.labelMd),
              const Spacer(),
              FilterChip(
                label: const Text('Pending dues only'),
                selected: _pendingOnly,
                onSelected: (v) => setState(() => _pendingOnly = v),
                showCheckmark: false,
                selectedColor: AppColors.emeraldDeep,
                labelStyle: AppType.labelMd.copyWith(
                    color: _pendingOnly ? Colors.white : AppColors.textSecondary),
                side: BorderSide(
                    color: _pendingOnly
                        ? AppColors.emeraldDeep
                        : AppColors.slateBorder),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: AsyncStateView(message: 'No members match your search.'),
            )
          else
            for (final m in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: MemberTile(member: m),
              ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, String caption) {
    return SectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppType.labelSm),
          const SizedBox(height: 6),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.currencyMd.copyWith(fontSize: 17)),
          const SizedBox(height: 2),
          Text(caption, style: AppType.bodySm),
        ],
      ),
    );
  }
}
