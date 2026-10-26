import 'dart:async';
import 'dart:convert';

import 'package:efoy_licensing/efoy_licensing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/licensing/license_access_state.dart';
import '../../core/licensing/license_gate.dart';
import '../../core/licensing/license_public_key.dart';
import '../../core/licensing/license_service.dart';
import '../../core/licensing/license_store.dart';
import '../../core/licensing/secure_store.dart';
import 'database_provider.dart';

/// Ed25519 verifier bound to the embedded public key.
final licenseVerifierProvider = Provider<LicenseVerifier>((ref) {
  return LicenseVerifier(
    publicKeyBytes: base64.decode(kLicensePublicKeyBase64),
  );
});

/// Isar-backed license persistence.
final licenseStoreProvider = FutureProvider<LicenseStore>((ref) async {
  final isar = await ref.watch(databaseProvider.future);
  return IsarLicenseStore(isar);
});

/// The one and only licensing decision maker.
final licenseServiceProvider = FutureProvider<LicenseService>((ref) async {
  final store = await ref.watch(licenseStoreProvider.future);
  return LicenseService(
    licenseStore: store,
    secureStore: const FlutterSecureStore(),
    verifier: ref.watch(licenseVerifierProvider),
  );
});

/// Enforcement gate injected into repositories.
final licenseGateProvider = FutureProvider<LicenseGate>((ref) async {
  final service = await ref.watch(licenseServiceProvider.future);
  return ServiceLicenseGate(service);
});

/// Live licensing state for the UI.
///
/// Re-emits when licenses change in the database and on a slow heartbeat so
/// a monthly license expiring mid-session is picked up without restarting.
final licenseAccessProvider = StreamProvider<LicenseAccessState>((ref) async* {
  final service = await ref.watch(licenseServiceProvider.future);
  yield await service.currentAccess();

  final store = await ref.watch(licenseStoreProvider.future);
  await for (final _ in _changeTicks(store)) {
    yield await service.currentAccess();
  }
});

Stream<void> _changeTicks(
  LicenseStore store, {
  Duration heartbeat = const Duration(minutes: 5),
}) {
  late StreamController<void> controller;
  StreamSubscription<void>? changes;
  Timer? timer;
  controller = StreamController<void>(
    onListen: () {
      changes = store.watchChanges().listen(controller.add);
      timer = Timer.periodic(heartbeat, (_) => controller.add(null));
    },
    onCancel: () {
      changes?.cancel();
      timer?.cancel();
    },
  );
  return controller.stream;
}
