import 'dart:ui';
import 'package:flutter/material.dart';
import 'core/services/local_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/shell/presentation/main_shell_screen.dart';

class LogiFaenaApp extends StatelessWidget {
  const LogiFaenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hasActiveSession = LocalStorageService.instance.readBool(
      'auth.session.active',
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LogiFaena Enterprise',
      theme: AppTheme.light,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: true,
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      ),
      home: hasActiveSession
          ? const MainShellScreen()
          : const LoginScreen(),
    );
  }
}
