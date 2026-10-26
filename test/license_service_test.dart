import 'dart:convert';

import 'package:efoy_licensing/efoy_licensing.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/core/licensing/license_access_state.dart';
import 'package:efoy_retail_app/core/licensing/license_gate.dart';

import 'license_test_utils.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 10);
  const threeDays = Duration(days: 3);

  group('Trial policy', () {
    test('starts a three-day trial on first use', () async {
      final harness = await LicenseHarness.create(now: t0);
      final state = await harness.service.currentAccess();

      expect(state.status, LicenseAccessStatus.trial);
      expect(state.canPerformPaidOperations, isTrue);
      expect(state.hasLicense, isFalse);
      expect(
        state.expiresAt!.millisecondsSinceEpoch,
        t0.millisecondsSinceEpoch + threeDays.inMilliseconds,
      );
      expect(
        state.installationId,
        matches(RegExp(r'^[0-9A-F]{4}(-[0-9A-F]{4}){3}$')),
      );
    });

    test('pins the trial end across restarts and clock changes', () async {
      final harness = await LicenseHarness.create(now: t0);
      final first = await harness.service.currentAccess();

      harness.clock.now = t0.add(const Duration(days: 1));
      final second = await harness.restart().currentAccess();

      expect(second.status, LicenseAccessStatus.trial);
      expect(
        second.expiresAt!.millisecondsSinceEpoch,
        first.expiresAt!.millisecondsSinceEpoch,
      );
      expect(second.installationId, first.installationId);
    });

    test('cannot be extended by rolling the clock back', () async {
      final harness = await LicenseHarness.create(now: t0);
      final first = await harness.service.currentAccess();

      // Twelve hours back is within the rollback tolerance: the trial stays
      // active but its end date never moves.
      harness.clock.now = t0
          .add(const Duration(days: 1))
          .subtract(const Duration(hours: 12));
      final state = await harness.service.currentAccess();
      expect(state.status, LicenseAccessStatus.trial);
      expect(
        state.expiresAt!.millisecondsSinceEpoch,
        first.expiresAt!.millisecondsSinceEpoch,
      );
    });

    test('expires after three days', () async {
      final harness = await LicenseHarness.create(now: t0);
      await harness.service.currentAccess();

      harness.clock.now = t0.add(threeDays);
      final state = await harness.service.currentAccess();
      expect(state.status, LicenseAccessStatus.trialExpired);
      expect(state.canPerformPaidOperations, isFalse);
    });

    test('flags multi-day clock rollbacks while on trial', () async {
      final harness = await LicenseHarness.create(now: t0);
      await harness.service.currentAccess();

      // Time passes beyond the trial window (records a high-water mark).
      harness.clock.now = t0.add(const Duration(days: 4));
      await harness.service.currentAccess();

      // Clock is wound back two days: beyond the 24h tolerance.
      harness.clock.now = t0.add(const Duration(days: 2));
      final rolled = await harness.service.currentAccess();
      expect(rolled.status, LicenseAccessStatus.trialExpired);
      expect(rolled.clockRollbackSuspected, isTrue);

      // Once the clock catches up with the recorded time, the flag clears.
      harness.clock.now = t0.add(const Duration(days: 4));
      final recovered = await harness.service.currentAccess();
      expect(recovered.clockRollbackSuspected, isFalse);
      expect(recovered.status, LicenseAccessStatus.trialExpired);
    });

    test('activation upgrades a running trial to licensed', () async {
      final harness = await LicenseHarness.create(now: t0);
      expect(
        (await harness.service.currentAccess()).status,
        LicenseAccessStatus.trial,
      );

      final result = await harness.service.activate(
        await harness.monthlyCode(),
      );
      expect(result.success, isTrue);
      expect(result.state!.status, LicenseAccessStatus.licensed);
    });
  });

  group('Monthly license policy', () {
    test('activates for thirty days', () async {
      final harness = await LicenseHarness.create(now: t0);
      final result = await harness.service.activate(
        await harness.monthlyCode(),
      );

      expect(result.success, isTrue);
      final state = result.state!;
      expect(state.status, LicenseAccessStatus.licensed);
      expect(state.plan, 'monthly');
      expect(state.licenseId, 'EFY-TEST-0001');
      expect(
        state.expiresAt!.millisecondsSinceEpoch,
        t0.millisecondsSinceEpoch + const Duration(days: 30).inMilliseconds,
      );
      expect(state.canPerformPaidOperations, isTrue);
    });

    test('expires at the end of its window', () async {
      final harness = await LicenseHarness.create(now: t0);
      await harness.service.activate(await harness.monthlyCode());

      harness.clock.now = t0.add(const Duration(days: 31));
      final state = await harness.service.currentAccess();
      expect(state.status, LicenseAccessStatus.expired);
      expect(state.canPerformPaidOperations, isFalse);
      expect(state.hasLicense, isTrue); // record preserved, never deleted
      expect(state.plan, 'monthly');
    });

    test('supports renewal with a fresh code after expiry', () async {
      final harness = await LicenseHarness.create(now: t0);
      await harness.service.activate(await harness.monthlyCode());
      harness.clock.now = t0.add(const Duration(days: 31));
      expect(
        (await harness.service.currentAccess()).status,
        LicenseAccessStatus.expired,
      );

      // The operator issues a renewal for the remaining period.
      final renewal = await harness.monthlyCode(licenseId: 'EFY-TEST-0002');
      final result = await harness.service.activate(renewal);
      expect(result.success, isTrue);
      expect(result.state!.status, LicenseAccessStatus.licensed);
      expect(result.state!.licenseId, 'EFY-TEST-0002');
      expect((await harness.licenseStore.latest())!.licenseId, 'EFY-TEST-0002');
    });
  });

  group('Lifetime license policy', () {
    test('never expires, even decades later', () async {
      final harness = await LicenseHarness.create(now: t0);
      final result = await harness.service.activate(
        await harness.lifetimeCode(),
      );

      expect(result.success, isTrue);
      expect(result.state!.status, LicenseAccessStatus.licensed);
      expect(result.state!.expiresAt, isNull);
      expect(result.state!.isLifetime, isTrue);

      harness.clock.now = t0.add(const Duration(days: 365 * 100));
      final state = await harness.service.currentAccess();
      expect(state.status, LicenseAccessStatus.licensed);
      expect(state.canPerformPaidOperations, isTrue);
    });
  });

  group('Clock rollback detection on licensed installs', () {
    test('locks time-limited licenses when the clock moves back', () async {
      final harness = await LicenseHarness.create(now: t0);
      await harness.service.activate(await harness.monthlyCode());

      harness.clock.now = t0.add(const Duration(days: 10));
      expect(
        (await harness.service.currentAccess()).status,
        LicenseAccessStatus.licensed,
      );

      harness.clock.now = t0.add(const Duration(days: 5));
      final rolled = await harness.service.currentAccess();
      expect(rolled.status, LicenseAccessStatus.expired);
      expect(rolled.clockRollbackSuspected, isTrue);

      // The license unlocks again once the clock reaches recorded time.
      harness.clock.now = t0.add(const Duration(days: 10));
      final recovered = await harness.service.currentAccess();
      expect(recovered.status, LicenseAccessStatus.licensed);
      expect(recovered.clockRollbackSuspected, isFalse);
    });

    test('ignores rollbacks within the 24h tolerance', () async {
      final harness = await LicenseHarness.create(now: t0);
      await harness.service.activate(await harness.monthlyCode());

      harness.clock.now = t0.add(const Duration(days: 2));
      await harness.service.currentAccess(); // records the high-water mark

      // 18 hours back is within tolerance: not treated as tampering.
      harness.clock.now = t0.add(const Duration(hours: 30));
      final state = await harness.service.currentAccess();
      expect(state.status, LicenseAccessStatus.licensed);
      expect(state.clockRollbackSuspected, isFalse);
    });

    test('never flags lifetime licenses', () async {
      final harness = await LicenseHarness.create(now: t0);
      await harness.service.activate(await harness.lifetimeCode());

      harness.clock.now = t0.add(const Duration(days: 10));
      await harness.service.currentAccess();
      harness.clock.now = t0.add(const Duration(days: 2));
      final state = await harness.service.currentAccess();
      expect(state.status, LicenseAccessStatus.licensed);
      expect(state.clockRollbackSuspected, isFalse);
    });
  });

  group('Activation rejections at the service level', () {
    test('rejects a code bound to another installation', () async {
      final harness = await LicenseHarness.create(now: t0);
      final foreign = await harness.issuer.issueCode(
        monthlyPayload(
          installationId: 'EEEE-EEEE-EEEE-EEEE',
          issuedAtMs: harness.clock.nowMs,
        ),
      );
      final result = await harness.service.activate(foreign);
      expect(result.success, isFalse);
      expect(result.rejection, LicenseRejectionReason.installationMismatch);
      expect(await harness.licenseStore.latest(), isNull);
    });

    test('rejects an already-expired code', () async {
      final harness = await LicenseHarness.create(now: t0);
      final expired = await harness.monthlyCode(
        issuedAtMs: harness.clock.nowMs - 40 * 24 * 60 * 60 * 1000,
      );
      final result = await harness.service.activate(expired);
      expect(result.rejection, LicenseRejectionReason.expired);
    });

    test('rejects a forged signature', () async {
      final harness = await LicenseHarness.create(now: t0);
      final forger = await TestIssuer.create();
      final forged = await forger.issueCode(
        monthlyPayload(
          installationId: await harness.installationId(),
          issuedAtMs: harness.clock.nowMs,
        ),
      );
      final result = await harness.service.activate(forged);
      expect(result.rejection, LicenseRejectionReason.invalidSignature);
    });

    test('rejects garbage input', () async {
      final harness = await LicenseHarness.create(now: t0);
      final result = await harness.service.activate('not a real code');
      expect(result.rejection, LicenseRejectionReason.malformedCode);
    });

    test('rejects an unsupported plan with a precise reason', () async {
      final harness = await LicenseHarness.create(now: t0);
      final payloadJson = monthlyPayload(
        installationId: await harness.installationId(),
        issuedAtMs: harness.clock.nowMs,
      ).toJson();
      payloadJson['plan'] = 'yearly';
      final code = base64.encode(
        utf8.encode(
          json.encode({
            'v': 1,
            'lic': payloadJson,
            'sig': base64.encode([1, 2, 3]),
          }),
        ),
      );
      final result = await harness.service.activate(code);
      expect(result.rejection, LicenseRejectionReason.unsupportedPlan);
    });
  });

  group('Secure storage failure and recovery', () {
    test('blocks paid operations while storage is unavailable', () async {
      final harness = await LicenseHarness.create(now: t0);
      harness.secureStore.broken = true;

      final state = await harness.service.currentAccess();
      expect(state.status, LicenseAccessStatus.blocked);
      expect(state.blockReason, LicenseBlockReason.storageUnavailable);
      expect(state.installationId, isNull);
      expect(state.canPerformPaidOperations, isFalse);

      final gate = harness.service.asGate();
      for (final operation in LicensedOperation.values) {
        await expectBlocked(gate.ensureAllowed(operation), operation);
      }

      // Activation cannot proceed: the identity cannot even be read, so the
      // code is never parsed or persisted.
      final result = await harness.service.activate('any code at all');
      expect(result.storageFailure, isTrue);
      expect(result.success, isFalse);
    });

    test(
      'recovers with identity and trial intact once storage returns',
      () async {
        final harness = await LicenseHarness.create(now: t0);
        final idBefore = await harness.installationId();
        final trialEndBefore =
            (await harness.service.currentAccess()).expiresAt;

        harness.secureStore.broken = true;
        expect(
          (await harness.service.currentAccess()).status,
          LicenseAccessStatus.blocked,
        );

        harness.secureStore.broken = false;
        final recovered = await harness.service.currentAccess();
        expect(recovered.status, LicenseAccessStatus.trial);
        expect(recovered.installationId, idBefore);
        expect(
          recovered.expiresAt!.millisecondsSinceEpoch,
          trialEndBefore!.millisecondsSinceEpoch,
        );
      },
    );
  });

  group('Persistence across application restarts', () {
    test('keeps the activated license and its expiry', () async {
      final harness = await LicenseHarness.create(now: t0);
      await harness.service.activate(await harness.monthlyCode());
      final id = await harness.installationId();

      harness.clock.now = t0.add(const Duration(days: 1));
      final state = await harness.restart().currentAccess();
      expect(state.status, LicenseAccessStatus.licensed);
      expect(state.installationId, id);
      expect(state.licenseId, 'EFY-TEST-0001');

      harness.clock.now = t0.add(const Duration(days: 31));
      final expired = await harness.restart().currentAccess();
      expect(expired.status, LicenseAccessStatus.expired);
      expect(expired.hasLicense, isTrue);
    });
  });

  group('Installation binding', () {
    test(
      'a license restored from another device does not authorize here',
      () async {
        final original = await LicenseHarness.create(now: t0);
        await original.service.activate(await original.monthlyCode());

        // Simulate restoring the original device's database backup onto a
        // different installation (fresh secure storage).
        final restored = await LicenseHarness.create(now: t0);
        await restored.licenseStore.save(
          (await original.licenseStore.latest())!,
        );

        final state = await restored.service.currentAccess();
        expect(state.status, LicenseAccessStatus.expired);
        expect(state.canPerformPaidOperations, isFalse);
        expect(state.licenseId, 'EFY-TEST-0001'); // record kept for support
      },
    );
  });

  group('ServiceLicenseGate enforcement', () {
    test('allows every operation on a running trial', () async {
      final harness = await LicenseHarness.create(now: t0);
      await harness.service.currentAccess();
      final gate = harness.service.asGate();
      for (final operation in LicensedOperation.values) {
        await gate.ensureAllowed(operation); // must not throw
      }
    });

    test('allows every operation with an active license', () async {
      final harness = await LicenseHarness.create(now: t0);
      await harness.service.activate(await harness.monthlyCode());
      final gate = harness.service.asGate();
      for (final operation in LicensedOperation.values) {
        await gate.ensureAllowed(operation);
      }
    });

    test('throws with full context when the trial has ended', () async {
      final harness = await LicenseHarness.create(now: t0);
      await harness.service.currentAccess();
      harness.clock.now = t0.add(threeDays);
      final gate = harness.service.asGate();

      for (final operation in LicensedOperation.values) {
        await expectBlocked(gate.ensureAllowed(operation), operation);
      }
    });

    test('throws with the computed state when a license expired', () async {
      final harness = await LicenseHarness.create(now: t0);
      await harness.service.activate(await harness.monthlyCode());
      harness.clock.now = t0.add(const Duration(days: 31));
      final gate = harness.service.asGate();

      try {
        await gate.ensureAllowed(LicensedOperation.recordSale);
        fail('LicenseRequiredException expected');
      } on LicenseRequiredException catch (error) {
        expect(error.operation, LicensedOperation.recordSale);
        expect(error.state.status, LicenseAccessStatus.expired);
        expect(error.state.hasLicense, isTrue);
        expect(error.state.plan, 'monthly');
      }
    });

    test('test gates behave as documented', () async {
      const allowed = AlwaysAllowedLicenseGate();
      const blocked = AlwaysBlockedLicenseGate();
      for (final operation in LicensedOperation.values) {
        await allowed.ensureAllowed(operation);
        await expectBlocked(blocked.ensureAllowed(operation), operation);
      }
    });
  });

  group('LicenseAccessState derived flags', () {
    test('trial expiring within a week is flagged as expiring soon', () {
      final state = LicenseAccessState(
        status: LicenseAccessStatus.trial,
        installationId: 'AAAA-BBBB-CCCC-DDDD',
        expiresAt: DateTime.now().add(const Duration(days: 2, hours: 1)),
      );
      expect(state.daysRemaining, 2);
      expect(state.isExpiringSoon, isTrue);
      expect(state.canPerformPaidOperations, isTrue);
    });

    test('a monthly license with more than a week left is not flagged', () {
      final state = LicenseAccessState(
        status: LicenseAccessStatus.licensed,
        installationId: 'AAAA-BBBB-CCCC-DDDD',
        plan: 'monthly',
        expiresAt: DateTime.now().add(const Duration(days: 20, hours: 1)),
      );
      expect(state.daysRemaining, 20);
      expect(state.isExpiringSoon, isFalse);
    });

    test('expired and blocked states allow nothing', () {
      final expired = LicenseAccessState(
        status: LicenseAccessStatus.expired,
        installationId: 'AAAA-BBBB-CCCC-DDDD',
        plan: 'monthly',
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(expired.canPerformPaidOperations, isFalse);
      expect(expired.daysRemaining, 0);
      expect(expired.isExpiringSoon, isFalse);

      const blocked = LicenseAccessState.blocked(
        installationId: null,
        blockReason: LicenseBlockReason.storageUnavailable,
      );
      expect(blocked.canPerformPaidOperations, isFalse);
      expect(blocked.hasLicense, isFalse);
    });

    test('lifetime licenses never report an expiry', () {
      final state = LicenseAccessState(
        status: LicenseAccessStatus.licensed,
        installationId: 'AAAA-BBBB-CCCC-DDDD',
        plan: 'lifetime',
      );
      expect(state.isLifetime, isTrue);
      expect(state.expiresAt, isNull);
      expect(state.daysRemaining, 0);
      expect(state.isExpiringSoon, isFalse);
      expect(state.canPerformPaidOperations, isTrue);
    });
  });
}
