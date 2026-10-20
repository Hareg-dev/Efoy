import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../data/local/app_database.dart';
import '../../data/models/user_profile.dart';

/// Redirects unauthenticated users to `/auth` before showing a protected
/// screen. Used by every `/home`, `/sell`, `/inventory`, `/expenses` and
/// `/profile` route so deep links cannot bypass onboarding.
class SessionGuard extends StatefulWidget {
  const SessionGuard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> {
  late final Future<bool> _hasSession;
  bool _redirectScheduled = false;

  @override
  void initState() {
    super.initState();
    _hasSession = _checkSession();
  }

  Future<bool> _checkSession() async {
    try {
      final isar = await AppDatabase().init();
      final profile = await isar.userProfiles.where().findFirst();
      return profile?.passwordHash != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSession,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) return widget.child;

        if (!_redirectScheduled) {
          _redirectScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacementNamed('/auth');
          });
        }

        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }
}
