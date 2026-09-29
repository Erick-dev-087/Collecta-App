import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/collecta_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifier = TextEditingController();
  final _pin = TextEditingController();
  bool _useEmail = true;
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _identifier.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      await ref.read(authControllerProvider.notifier).signIn(
            _identifier.text.trim(),
            _pin.text.trim(),
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not sign in: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _brandPanel(),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _signInCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _brandPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.emeraldDeep, Color(0xFF00351C)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CollectaWordmark(
              caption: 'TREASURY & LEDGER ENGINE', onDark: true, size: 34),
          const SizedBox(height: AppSpacing.lg),
          _tierChip(),
          const SizedBox(height: 12),
          Text('One clear ledger for every\ncontribution your group collects.',
              style: AppType.headlineLg.copyWith(color: Colors.white)),
          const SizedBox(height: 10),
          Text(
            "Collecta reconciles the money your group, chama or church "
            "collects — matching every member's payment to what they pledged.",
            style: AppType.bodyMd.copyWith(color: const Color(0xFFB9E6C8)),
          ),
        ],
      ),
    );
  }

  Widget _tierChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                    color: AppColors.mintNeon, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('Live payment reconciliation',
                style: AppType.labelSm.copyWith(color: AppColors.mintNeon)),
          ],
        ),
      );

  Widget _signInCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slateBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: AppColors.panelAlt,
                borderRadius: BorderRadius.circular(999)),
            child: Text('INSTITUTIONAL ACCESS',
                style: AppType.labelSm.copyWith(color: AppColors.emeraldDeep)),
          ),
          const SizedBox(height: 14),
          Text('Sign in to your\nOrganization Portal', style: AppType.headlineMd),
          const SizedBox(height: 6),
          Text(
              'Manage your collections, reconcile every contribution and share '
              'WhatsApp receipts.',
              style: AppType.bodyMd.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Text(_useEmail ? 'Email' : 'Phone Number',
                  style: AppType.labelMd),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _useEmail = !_useEmail),
                child: Text(_useEmail ? 'Use Phone' : 'Use Email Format',
                    style:
                        AppType.labelMd.copyWith(color: AppColors.emeraldDeep)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _identifier,
            keyboardType:
                _useEmail ? TextInputType.emailAddress : TextInputType.phone,
            decoration: InputDecoration(
              prefixIcon: _useEmail
                  ? const Icon(Icons.mail_outline, size: 20)
                  : _prefix254(),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              hintText: _useEmail ? 'treasury@org.co.ke' : '712 345 678',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Security PIN / Master Password', style: AppType.labelMd),
              const Spacer(),
              Text('Forgot PIN?',
                  style: AppType.labelMd.copyWith(color: AppColors.emeraldDeep)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pin,
            obscureText: _obscure,
            onSubmitted: (_) => _busy ? null : _signIn(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              hintText: 'Enter 4-8 digit PIN or passphrase',
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                    size: 20, color: AppColors.slateMuted),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : _signIn,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Sign In to Portal'),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.verified_user_outlined,
                  size: 16, color: AppColors.slateMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                    'Secured with 256-bit institutional encryption & Safaricom '
                    'partner compliance.',
                    style: AppType.bodySm),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('New to Collecta?',
                  style:
                      AppType.bodyMd.copyWith(color: AppColors.textSecondary)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => context.push('/register'),
                child: Text('Create an account',
                    style: AppType.labelLg
                        .copyWith(color: AppColors.emeraldDeep)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _prefix254() => Padding(
        padding: const EdgeInsets.only(left: 12, right: 10),
        child: Text('+254',
            style: AppType.labelLg.copyWith(color: AppColors.slateInk)),
      );
}
