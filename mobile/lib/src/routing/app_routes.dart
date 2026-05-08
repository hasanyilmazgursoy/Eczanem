/// Centralized route path constants for GoRouter.
///
/// Use these variables instead of raw strings throughout the app.
/// Example: `context.go(AppRoutes.onboarding)` instead of `context.go('/')`.
abstract final class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String home = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String drugSearch = '/drug-search';
  static const String drugPhotoScan = '/drug-photo-scan';
  static const String drugCameraCapture = '/drug-camera-capture';
  static const String drugImageCandidates = '/drug-image-candidates';
  static const String drugProspectusSummary = '/drug-prospectus-summary';
  static const String drugDetail = '/drug-detail';
  static const String drugSearchHistory = '/drug-search-history';
  static const String drugScanHistory = '/drug-scan-history';
  static const String medicationReminders = '/medication-reminders';
  static const String drugInteraction = '/drug-interaction';
  static const String drugNaturalAlternatives = '/drug-natural-alternatives';
  static const String familyMembers = '/family';
  static const String familyMemberDetail = '/family-member-detail';
  static const String pharmacyNearby = '/pharmacy-nearby';
  static const String emergencyCard = '/emergency-card';
  static const String healthNotes = '/health-notes';
}
