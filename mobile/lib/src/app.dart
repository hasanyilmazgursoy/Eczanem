import 'package:eczanem/src/imports/core_imports.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    Widget current = _buildMaterialApp(context);

    current = ScreenUtilWrapper(child: current);

    return current;
  }

  Widget _buildMaterialApp(BuildContext context) {
    return MaterialApp.router(
      title: 'Eczanem',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(primaryColorHex: '#00897B'),
      darkTheme: buildDarkTheme(primaryColorHex: '#00897B'),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) {
        // SkeletonWrapper global builder'da kullanılmıyor; her ekran kendi
        // skeleton/loading state'ini yönetiyor. Burada sadece oturum dinleyici.
        return SessionListenerWrapper(child: child!);
      },
    );
  }
}
