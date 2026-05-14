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
import 'package:eczanem/src/features/drug/presentation/screens/drug_interaction_screen.dart';
import 'package:eczanem/src/features/drug/presentation/screens/drug_natural_alternatives_screen.dart';
import 'package:eczanem/src/features/drug/presentation/screens/drug_scan_history_screen.dart';
import 'package:eczanem/src/features/drug/presentation/screens/drug_search_history_screen.dart';
import 'package:eczanem/src/features/drug/presentation/screens/ai_chat_screen.dart';
import 'package:eczanem/src/features/drug/presentation/screens/symptom_analysis_screen.dart';
import 'package:eczanem/src/features/reminder/presentation/screens/medication_reminders_screen.dart';
import 'package:eczanem/src/features/profile/presentation/screens/family_screen.dart';
import 'package:eczanem/src/features/profile/presentation/screens/family_member_detail_screen.dart';
import 'package:eczanem/src/features/profile/presentation/screens/account_settings_screen.dart';
import 'package:eczanem/src/features/profile/data/models/family_member.dart';
import 'package:eczanem/src/features/pharmacy/presentation/screens/pharmacy_screen.dart';
import 'package:eczanem/src/features/emergency/presentation/screens/emergency_card_screen.dart';
import 'package:eczanem/src/features/health_notes/presentation/screens/health_notes_screen.dart';

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
    GoRoute(
      path: AppRoutes.drugScanHistory,
      name: 'drugScanHistory',
      builder: (context, state) => const DrugScanHistoryScreen(),
    ),
    GoRoute(
      path: AppRoutes.medicationReminders,
      name: 'medicationReminders',
      builder: (context, state) {
        final initialDrugName = state.extra as String?;
        return MedicationRemindersScreen(initialDrugName: initialDrugName);
      },
    ),
    GoRoute(
      path: AppRoutes.drugInteraction,
      name: 'drugInteraction',
      builder: (context, state) {
        final initialDrugs = state.extra is List
            ? (state.extra as List).map((item) => item.toString()).toList()
            : const <String>[];
        return DrugInteractionScreen(initialDrugs: initialDrugs);
      },
    ),
    GoRoute(
      path: AppRoutes.drugNaturalAlternatives,
      name: 'drugNaturalAlternatives',
      builder: (context, state) {
        final initialDrugName = state.extra as String?;
        return DrugNaturalAlternativesScreen(initialDrugName: initialDrugName);
      },
    ),
    GoRoute(
      path: AppRoutes.familyMembers,
      name: 'familyMembers',
      builder: (context, state) => const FamilyScreen(),
    ),
    GoRoute(
      path: AppRoutes.familyMemberDetail,
      name: 'familyMemberDetail',
      builder: (context, state) {
        final member = state.extra as FamilyMember;
        return FamilyMemberDetailScreen(member: member);
      },
    ),
    GoRoute(
      path: AppRoutes.pharmacyNearby,
      name: 'pharmacyNearby',
      builder: (context, state) => const PharmacyScreen(),
    ),
    GoRoute(
      path: AppRoutes.emergencyCard,
      name: 'emergencyCard',
      builder: (context, state) => const EmergencyCardScreen(),
    ),
    GoRoute(
      path: AppRoutes.healthNotes,
      name: 'healthNotes',
      builder: (context, state) => const HealthNotesScreen(),
    ),
    GoRoute(
      path: AppRoutes.accountSettings,
      name: 'accountSettings',
      builder: (context, state) => const AccountSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.aiChat,
      name: 'aiChat',
      builder: (context, state) => const AiChatScreen(),
    ),
    GoRoute(
      path: AppRoutes.symptomAnalysis,
      name: 'symptomAnalysis',
      builder: (context, state) => const SymptomAnalysisScreen(),
    ),
  ],
);
