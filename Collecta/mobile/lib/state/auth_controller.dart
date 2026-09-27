import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_provider.dart';
import '../data/models/organization.dart';

/// Holds the signed-in administrator. Starts null (logged out) so the login
/// gate always shows first, even though the mock backend has a seeded user.
class AuthController extends Notifier<AppUser?> {
  @override
  AppUser? build() => null;

  Future<void> signIn(String identifier, String secret) async {
    final api = ref.read(collectaApiProvider);
    state = await api.signIn(identifier: identifier, secret: secret);
  }

  Future<void> register({
    required String fullName,
    required String organizationName,
    required String email,
    required String phone,
    required String secret,
  }) async {
    final api = ref.read(collectaApiProvider);
    state = await api.register(
      fullName: fullName,
      organizationName: organizationName,
      email: email,
      phone: phone,
      secret: secret,
    );
  }

  Future<void> signOut() async {
    await ref.read(collectaApiProvider).signOut();
    state = null;
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AppUser?>(AuthController.new);

final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider) != null;
});
