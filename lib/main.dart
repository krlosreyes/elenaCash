import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'firebase_options.dart';
import 'shared/providers/firebase_providers.dart';

// ── Background FCM handler (top-level, fuera de main) ────────────────
// Debe registrarse antes de runApp.
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) =>
    onFirebaseBackgroundMessage(message);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Registrar handler de mensajes en background/terminated
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
  }

  // ── RevenueCat — solo móvil (no funciona en Flutter Web) ─────────
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    final apiKey = Platform.isAndroid
        ? AppConstants.revenueCatApiKeyAndroid
        : AppConstants.revenueCatApiKeyIOS;
    await Purchases.configure(PurchasesConfiguration(apiKey));
    await Purchases.setLogLevel(LogLevel.error);
  }

  // ── FCM + Notificaciones locales ──────────────────────────────────
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await NotificationService.instance.initialize();
  }

  // Crashlytics: solo activo en release y cuando Firebase está configurado
  if (!kDebugMode) {
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } else {
    // En debug: imprimir errores en consola en vez de crashear con Crashlytics
    FlutterError.onError = FlutterError.presentError;
  }

  runApp(
    const ProviderScope(
      child: ElenaCashApp(),
    ),
  );
}

class ElenaCashApp extends ConsumerWidget {
  const ElenaCashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ElenaCash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CO'),
        Locale('es', 'MX'),
        Locale('es'),
      ],
    );
  }
}
