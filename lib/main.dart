import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'controllers/auth_ctrl.dart';
import 'controllers/home_ctrl.dart';
import 'firebase_options.dart';
import 'utils/app_routes.dart';
import 'utils/app_theme.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (Platform.isIOS) {
    flutterLocalNotificationsPlugin.show(
      DateTime.now().microsecond,
      message.data['title'],
      message.data['body'],
      const NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      ),
    );
  }
  /*  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Messages with a notification payload are displayed automatically by the OS
  // in background/terminated state — no manual show() needed here.
  // Only data-only messages (message.notification == null) would need manual display.
  if (message.notification != null) return;

  // Data-only message: initialize the plugin and show manually.
  const AndroidInitializationSettings initAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: initAndroid),
  );
  final title = message.data['title'] as String?;
  final body = message.data['body'] as String?;
  if (title != null || body != null) {
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().microsecond,
      title,
      body,
      const NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      ),
      payload: message.data['payload'],
    );
  } */
}

Future<void> _onDidReceiveBackgroundNotification(
  NotificationResponse details,
) async {
  debugPrint(details.payload);
}

AndroidNotificationChannel? channel;

// INIT Local Notification
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ---------------------- FCM ---------------------- //
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  channel = const AndroidNotificationChannel(
    'luxormeet',
    'luxormeet',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel!);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    provisional: false,
    sound: true,
  );

  // ---------------------- Local Notification ---------------------- //
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings
  initializationSettingsIOS = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    defaultPresentBadge: false,
    // defaultPresentBadge: false,
    // defaultPresentBadge: false,
    // onDidReceiveLocalNotification: (int i, String? x, String? y, String? z) {},
  );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (details) {
      debugPrint(details.payload);
    },
    onDidReceiveBackgroundNotificationResponse:
        _onDidReceiveBackgroundNotification,
  );

  /*   // Show notifications when the app is in the foreground.
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['body'];
    if (title != null || body != null) {
      flutterLocalNotificationsPlugin.show(
        DateTime.now().microsecond,
        title,
        body,
        const NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics,
        ),
        payload: message.data['payload'],
      );
    }
  }); */

  Get.put(AuthCtrl());
  Get.put(HomeCtrl());

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const LuxorDrApp());
}

class LuxorDrApp extends StatefulWidget {
  const LuxorDrApp({super.key});

  @override
  State<LuxorDrApp> createState() => _LuxorDrAppState();
}

class _LuxorDrAppState extends State<LuxorDrApp> {
  late final GoRouterNotifier _notifier;
  late final GoRouter router;

  @override
  void initState() {
    super.initState();
    _notifier = GoRouterNotifier();
    router = buildRouter(_notifier);
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: MaterialApp.router(
        title: 'Luxor Doctor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
}

// Notification Channels //

const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'luxormeet',
      'luxormeet',
      importance: Importance.max,
      showWhen: false,
      playSound: true,
      enableLights: true,
    );

const DarwinNotificationDetails iOSPlatformChannelSpecifics =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
