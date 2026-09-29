import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'collecta_api.dart';
import 'firebase/firebase_collecta_api.dart';
import 'mock/mock_collecta_api.dart';

/// Flip to `false` once `firebase_options.dart` is generated, the Dart
/// functions are deployed, and [FirebaseCollectaApi.functionsBaseUrl] is set.
const bool useMock = false;

/// The single backend gateway used across the app.
final collectaApiProvider = Provider<CollectaApi>((ref) {
  final api = useMock ? MockCollectaApi() : FirebaseCollectaApi();
  return api;
});

/// Emits whenever backend state changes (mock STK lifecycle, mutations) so
/// data controllers can refresh. Backed by [CollectaApi.changes].
final backendChangesProvider = StreamProvider<void>((ref) {
  return ref.watch(collectaApiProvider).changes;
});
