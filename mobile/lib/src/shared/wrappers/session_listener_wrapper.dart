import 'package:eczanem/src/imports/core_imports.dart';
import 'package:eczanem/src/imports/packages_imports.dart';

import 'package:eczanem/src/features/auth/presentation/providers/session_provider.dart';

class SessionListenerWrapper extends ConsumerWidget {
  final Widget child;
  const SessionListenerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<SessionState>(sessionProvider, (prev, next) {
      if (next.status != SessionStatus.unknown) {
        FlutterNativeSplash.remove();
        // MaterialApp.router builder context'i GoRouter'ın üzerinde olduğundan
        // context.go() çalışmaz; global appRouter instance doğrudan kullanılır
        if (next.status == SessionStatus.authenticated) {
          appRouter.go(AppRoutes.home);
        } else if (next.status == SessionStatus.unauthenticated) {
          appRouter.go(AppRoutes.onboarding);
        }
      }
    });

    return child;
  }
}
