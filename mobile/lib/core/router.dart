import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/drug/drug_detail_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/drug-detail',
      builder: (context, state) {
        final drugData = state.extra as Map<String, dynamic>;
        return DrugDetailScreen(drugData: drugData);
      },
    ),
  ],
);
