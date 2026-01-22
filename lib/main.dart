import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:unstop/bloc/auth_bloc.dart';
import 'package:unstop/bloc/auth_event.dart';
import 'package:unstop/bloc/auth_state.dart';
import 'package:unstop/firebase_options.dart';
import 'package:unstop/screens/auth/login_screen.dart';
import 'package:unstop/screens/homescreen.dart';
import 'package:unstop/splash/splash_screen.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load environment variables
  await dotenv.load(fileName: ".env");

  // ✅ Initialize Stripe
  final publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
  if (publishableKey == null || publishableKey.isEmpty) {
    throw Exception("❌ STRIPE_PUBLISHABLE_KEY not found in .env");
  }
  Stripe.publishableKey = publishableKey;
  await Stripe.instance.applySettings();

  // ✅ Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Initialize Local Notifications
  await initializeNotifications();

  // ✅ Lock orientation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    BlocProvider(
      create: (_) => AuthBloc()..add(AppStarted()),
      child: const MyApp(),
    ),
  );
}

Future<void> initializeNotifications() async {
  try {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    final initialized = await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    debugPrint('✅ Notifications initialized: $initialized');

    // ✅ Request notification permission
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        debugPrint('🚫 Notification permission not granted.');
      } else {
        debugPrint('✅ Notification permission granted');
      }
    }

    // ✅ Android notification channel with better configuration
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'your_channel_id',
        'Item Reminders',
        description: 'Notifications for item reminders and alerts',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      );

             await flutterLocalNotificationsPlugin
           .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
           ?.createNotificationChannel(channel);
       
       debugPrint('✅ Notification channel created');
    }
  } catch (e) {
    debugPrint('❌ Error initializing notifications: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Un-Lost',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return const HomeScreen();
          } else if (state is Unauthenticated) {
            return const SplashScreen();
          } else {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }
}
