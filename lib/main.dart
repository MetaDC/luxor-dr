import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'controllers/auth_ctrl.dart';
import 'controllers/home_ctrl.dart';
import 'firebase_options.dart';
import 'utils/app_routes.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  Get.put(AuthCtrl());
  Get.put(HomeCtrl());

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
    return MaterialApp.router(
      title: 'Luxor Doctor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
