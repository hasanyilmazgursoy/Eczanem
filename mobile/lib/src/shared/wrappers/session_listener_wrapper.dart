import 'package:eczanem/src/features/auth/presentation/providers/session_provider.dart';
import 'package:eczanem/src/imports/core_imports.dart';
import 'package:eczanem/src/imports/packages_imports.dart';

class SessionListenerWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const SessionListenerWrapper({super.key, required this.child});

  @override
  ConsumerState<SessionListenerWrapper> createState() =>
      _SessionListenerWrapperState();
}

class _SessionListenerWrapperState
    extends ConsumerState<SessionListenerWrapper> {
  bool _splashRemoved = false;

  @override
  void initState() {
    super.initState();
    // ref.listen yalnızca state değişimlerini yakalar; SessionNotifier hızlı
    // başlatılırsa ilk değer kaçabilir. İlk frame sonrası mevcut state'i de
    // değerlendirip native splash'ı garanti kaldırıyoruz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handle(ref.read(sessionProvider));
    });
  }

  void _handle(SessionState next) {
    if (next.status == SessionStatus.unknown) return;
    if (!_splashRemoved) {
      _splashRemoved = true;
      FlutterNativeSplash.remove();
    }
    // MaterialApp.router builder context'i GoRouter'ın üzerinde olduğundan
    // context.go() çalışmaz; global appRouter instance doğrudan kullanılır
    if (next.status == SessionStatus.authenticated) {
      appRouter.go(AppRoutes.home);
    }
    // Unauthenticated durumda router redirect'i onboarding/login kararını verir
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SessionState>(sessionProvider, (prev, next) => _handle(next));
    return widget.child;
  }
}
