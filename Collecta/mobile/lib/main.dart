import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // When going live: initialise Firebase here (see api_provider.dart / README).
  runApp(const ProviderScope(child: CollectaApp()));
}
