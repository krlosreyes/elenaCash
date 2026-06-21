import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ── Background handler — debe ser top-level ──────────────────────────
// Registrado desde main.dart con FirebaseMessaging.onBackgroundMessage().
// En Android el sistema muestra la notificación automáticamente.
@pragma('vm:entry-point')
Future<void> onFirebaseBackgroundMessage(RemoteMessage message) async {
  // Firebase ya está inicializado antes del runApp — no necesitamos nada más.
}

// ── ValueNotifier para deep-link desde notificación ──────────────────
// El router de GoRouter escucha este notifier para navegar cuando el
// usuario abre la app al tocar una notificación.
final notificationRouteNotifier = ValueNotifier<String?>(null);

/// Servicio singleton para Firebase Cloud Messaging y notificaciones locales.
///
/// Flujo:
/// 1. main() llama NotificationService.instance.initialize()
/// 2. Se solicitan permisos, se crea el canal Android, se subscribe al topic
/// 3. Foreground messages → flutter_local_notifications muestra el banner
/// 4. Tap en notificación → notificationRouteNotifier.value = '/dashboard'
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannelId = 'trm_alerts';
  static const _androidChannelName = 'Alertas TRM';
  static const _androidChannelDesc =
      'Avisos cuando el dólar sube o baja más del 1.5%';

  static const _trmChannel = AndroidNotificationChannel(
    _androidChannelId,
    _androidChannelName,
    description: _androidChannelDesc,
    importance: Importance.high,
  );

  bool _initialized = false;

  /// Llamar desde main() después de Firebase.initializeApp().
  /// Es seguro llamarlo varias veces — solo inicializa una vez.
  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    _initialized = true;

    // ── Permisos ──────────────────────────────────────────────────
    if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    }

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // Crear canal de alta prioridad para alertas TRM
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_trmChannel);
    }

    // ── flutter_local_notifications init ─────────────────────────
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        final route = details.payload;
        if (route != null && route.isNotEmpty) {
          notificationRouteNotifier.value = route;
        }
      },
    );

    // ── FCM: foreground presentation options (iOS) ────────────────
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // ── Topic TRM ─────────────────────────────────────────────────
    await _messaging.subscribeToTopic('trm_alerts');

    // ── Listeners ─────────────────────────────────────────────────

    // Mensaje llega con app EN PRIMER PLANO → mostrar banner local
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // App estaba en background, usuario tocó la notificación
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTapped);

    // App estaba terminada, usuario tocó la notificación
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _onNotificationTapped(initialMessage);
  }

  // ── Privados ──────────────────────────────────────────────────────

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      // Usar hashCode del messageId para ID único; fallback a 0
      (message.messageId ?? '').hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['route'] as String?,
    );
  }

  void _onNotificationTapped(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route != null && route.isNotEmpty) {
      notificationRouteNotifier.value = route;
    }
  }

  // ── API pública ───────────────────────────────────────────────────

  /// Desuscribirse de las alertas TRM (para que el usuario lo apague).
  Future<void> disableTrmAlerts() =>
      _messaging.unsubscribeFromTopic('trm_alerts');

  /// Re-suscribirse a las alertas TRM.
  Future<void> enableTrmAlerts() =>
      _messaging.subscribeToTopic('trm_alerts');
}
