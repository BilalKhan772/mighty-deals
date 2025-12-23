import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bootstrap.dart';
import 'app.dart';

void main() {
  bootstrap(() async => const ProviderScope(child: App()));
}
