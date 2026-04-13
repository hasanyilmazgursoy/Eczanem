import 'package:go_router/go_router.dart';
import 'package:eczanem/src/routing/global_navigator.dart';
import 'package:eczanem/src/routing/app_routes.dart';

import 'package:eczanem/src/features/auth/presentation/screens/login_screen.dart';
import 'package:eczanem/src/features/auth/presentation/screens/signup_screen.dart';
import 'package:eczanem/src/features/auth/presentation/screens/forgot_password_screen.dart';

import 'package:eczanem/src/features/home/presentation/screens/home_page.dart';
import 'package:eczanem/src/features/onboarding/presentation/screens/onboarding_page.dart';
import 'package:eczanem/src/features/drug/presentation/screens/drug_camera_capture_screen.dart';
import 'package:eczanem/src/features/drug/presentation/screens/drug_image_candidates_screen.dart';
import 'package:eczanem/src/features/drug/presentation/screens/drug_photo_scan_screen.dart';
import 'package:eczanem/src/features/drug/presentation/screens/drug_prospectus_summary_screen.dart';
import 'package:eczanem/src/features/drug/presentation/screens/drug_search_screen.dart';
import 'package:eczanem/src/features/drug/presentation/screens/drug_detail_screen.dart';
import 'package:eczanem/src/features/drug/presentation/screens/drug_search_history_screen.dart';

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.onboarding,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      name: 'signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      name: 'forgotPassword',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.drugSearch,
      name: 'drugSearch',
      builder: (context, state) {
        final initialQuery = state.extra as String?;
        return DrugSearchScreen(initialQuery: initialQuery);
      },
    ),
    GoRoute(
      path: AppRoutes.drugPhotoScan,
      name: 'drugPhotoScan',
      builder: (context, state) => const DrugPhotoScanScreen(),
    ),
    GoRoute(
      path: AppRoutes.drugCameraCapture,
      name: 'drugCameraCapture',
      builder: (context, state) => const DrugCameraCaptureScreen(),
    ),
    GoRoute(
      path: AppRoutes.drugImageCandidates,
      name: 'drugImageCandidates',
      builder: (context, state) {
        final analysisData = state.extra as Map<String, dynamic>;
        return DrugImageCandidatesScreen(analysisData: analysisData);
      },
    ),
    GoRoute(
      path: AppRoutes.drugProspectusSummary,
      name: 'drugProspectusSummary',
      builder: (context, state) {
        final summaryData = state.extra as Map<String, dynamic>;
        return DrugProspectusSummaryScreen(summaryData: summaryData);
      },
    ),
    GoRoute(
      path: AppRoutes.drugDetail,
      name: 'drugDetail',
      builder: (context, state) {
        final drugData = state.extra as Map<String, dynamic>;
        return DrugDetailScreen(drugData: drugData);
      },
    ),
    GoRoute(
      path: AppRoutes.drugSearchHistory,
      name: 'drugSearchHistory',
      builder: (context, state) => const DrugSearchHistoryScreen(),
    ),
  ],
);
