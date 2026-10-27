import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/core/constants/app_locales.dart';
import 'package:efoy_retail_app/core/constants/app_strings.dart';
import 'package:efoy_retail_app/core/licensing/license_access_state.dart';
import 'package:efoy_retail_app/data/models/user_profile.dart';
import 'package:efoy_retail_app/logic/providers/license_provider.dart';
import 'package:efoy_retail_app/logic/providers/repository_providers.dart';
import 'package:efoy_retail_app/ui/screens/profile_screen.dart';

/// A merchant deep enough into the trial that the licence question is live.
final LicenseAccessState _trialOver = LicenseAccessState(
  status: LicenseAccessStatus.trialExpired,
  installationId: 'AAAA-BBBB-CCCC-DDDD',
  expiresAt: DateTime.now().subtract(const Duration(days: 1)),
);

final LicenseAccessState _licensed = LicenseAccessState(
  status: LicenseAccessStatus.licensed,
  installationId: 'AAAA-BBBB-CCCC-DDDD',
  plan: 'monthly',
  expiresAt: DateTime.now().add(const Duration(days: 26, hours: 1)),
);

Future<void> pump(
  WidgetTester tester, {
  required LicenseAccessState access,
  Locale locale = const Locale('en'),
  UserProfile? profile,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProfileProvider.overrideWith(
          (ref) => Stream<UserProfile?>.value(
            profile ??
                UserProfile(
                  businessName: 'Rift Valley Grocery',
                  ownerName: 'Hareg Alemu Bekele',
                ),
          ),
        ),
        licenseAccessProvider.overrideWith((ref) => Stream.value(access)),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: appSupportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        home: const ProfileScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  group('ProfileScreen identity block', () {
    testWidgets('shows the business name and the owner full name', (
      tester,
    ) async {
      await pump(tester, access: _licensed);

      expect(find.text('Rift Valley Grocery'), findsOneWidget);
      expect(find.text('Hareg Alemu Bekele'), findsOneWidget);
    });

    testWidgets('falls back to the store glyph until a photo is picked', (
      tester,
    ) async {
      await pump(tester, access: _licensed);

      expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
      expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    });

    testWidgets('stays English even when the rest of the app speaks Amharic', (
      tester,
    ) async {
      await pump(tester, access: _licensed, locale: const Locale('am'));

      expect(find.text('PROFILE'), findsOneWidget);
      expect(find.text('Store, security and data settings'), findsOneWidget);
      expect(find.text('Change password'), findsOneWidget);
      expect(find.text('መገለጫ'), findsNothing);
      expect(find.text('የይለፍ ቃል ቀይር'), findsNothing);
    });
  });

  group('ProfileScreen support card', () {
    testWidgets('offers the team contacts once the trial is over', (
      tester,
    ) async {
      await pump(tester, access: _trialOver);

      expect(find.text('Customer support'), findsOneWidget);
      expect(find.text(AppStrings.supportTelegram), findsOneWidget);
      expect(find.text(AppStrings.supportPhone), findsWidgets);
      expect(find.text(AppStrings.supportPhoneAlt), findsOneWidget);
      expect(
        find.text('${AppStrings.supportPhone} · ${AppStrings.supportTeam}'),
        findsOneWidget,
      );
      expect(find.text('AAAA-BBBB-CCCC-DDDD'), findsOneWidget);
    });

    testWidgets('stays reachable while the licence is paid up', (tester) async {
      await pump(tester, access: _licensed);

      expect(find.text('Customer support'), findsOneWidget);
      expect(find.text(AppStrings.supportTelegram), findsOneWidget);
    });

    testWidgets('no longer asks the merchant for their own bank account', (
      tester,
    ) async {
      await pump(tester, access: _licensed);

      expect(find.text('Payment details'), findsNothing);
      expect(find.text('Bank'), findsNothing);
      expect(find.text('Demo'), findsNothing);
    });
  });
}
