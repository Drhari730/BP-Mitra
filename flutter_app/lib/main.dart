// BP Mitra – Application Entry Point
// Initializes Flutter bindings, timezone data, local notifications,
// and mounts the root widget with all BLoC providers.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'blocs/medication/medication_bloc.dart';
import 'blocs/vitals/vitals_bloc.dart';
import 'blocs/diet/diet_bloc.dart';
import 'blocs/activity/activity_bloc.dart';
import 'blocs/ai_assistant/ai_assistant_bloc.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'views/app_router.dart';
import 'theme/app_theme.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for consistent clinical UI layout.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar styling to complement Dark Blue (#1543A4) header.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: AppTheme.darkBlue,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize timezone database for local notification scheduling.
  tz.initializeTimeZones();

  // Bootstrap the notification service (local notifications + channels).
  await NotificationService.instance.initialize(flutterLocalNotificationsPlugin);

  runApp(const BpMitraApp());
}

class BpMitraApp extends StatelessWidget {
  const BpMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => MedicationBloc(apiService: apiService)),
        BlocProvider(create: (_) => VitalsBloc(apiService: apiService)),
        BlocProvider(create: (_) => DietBloc(apiService: apiService)),
        BlocProvider(create: (_) => ActivityBloc()),
        BlocProvider(create: (_) => AiAssistantBloc(apiService: apiService)),
      ],
      child: MaterialApp.router(
        title: 'BP Mitra',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
