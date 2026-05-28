// BP Mitra – GoRouter navigation configuration.
// Defines named routes for all 5 module views plus the main dashboard.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'dashboard/dashboard_view.dart';
import 'medication/medication_view.dart';
import 'diet/diet_view.dart';
import 'diet/recipe_browser_view.dart';
import 'diet/recipe_detail_view.dart';
import 'diet/nutrition_targets_view.dart';
import 'vitals/vitals_view.dart';
import 'vitals/manual_entry_view.dart';
import 'vitals/rppg_capture_view.dart';
import 'activity/activity_view.dart';
import 'ai_assistant/ai_assistant_view.dart';
import 'auth/login_view.dart';
import 'auth/register_view.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    routes: [
      // ── Authentication ──────────────────────────────────────
      GoRoute(path: '/login',    builder: (_, __) => const LoginView()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterView()),

      // ── Core Dashboard ──────────────────────────────────────
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardView()),

      // ── Module 1: Medication Tracker ────────────────────────
      GoRoute(path: '/medications', builder: (_, __) => const MedicationView()),

      // ── Module 2: DASH Diet ─────────────────────────────────
      GoRoute(path: '/diet', builder: (_, __) => const DietView()),
      GoRoute(path: '/diet/recipes', builder: (_, __) => const RecipeBrowserView()),
      GoRoute(
        path: '/diet/recipes/:id',
        builder: (_, state) => RecipeDetailView(
          recipeId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/diet/targets', builder: (_, __) => const NutritionTargetsView()),

      // ── Module 3: Vitals ────────────────────────────────────
      GoRoute(path: '/vitals',       builder: (_, __) => const VitalsView()),
      GoRoute(path: '/vitals/rppg',  builder: (_, __) => const RppgCaptureView()),
      GoRoute(path: '/vitals/manual', builder: (_, __) => const ManualEntryView()),

      // ── Module 4: Activity Tracker ──────────────────────────
      GoRoute(path: '/activity', builder: (_, __) => const ActivityView()),

      // ── Module 5: AI Clinical Assistant ────────────────────
      GoRoute(path: '/ai', builder: (_, __) => const AiAssistantView()),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
}
