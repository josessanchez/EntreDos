import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:entredos/utils/app_logger.dart';

/// Top-level background message handler required by firebase_messaging.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Note: keep this minimal. Firebase initialization is already done in main.
  // This runs in its own isolate.
  // We simply log the payload so Cloud Functions/system handles display.
  if (kDebugMode) {
    appLogger.d('[FCM] Background message received: ${message.messageId}');
  }
}

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService _instance =
      NotificationService._privateConstructor();
  factory NotificationService() => _instance;

  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  // Local notifications plugin: used to display notifications while app is foreground
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  // Channel details for Android foreground notifications
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'entredos_messages',
        'Mensajes',
        description: 'Canal para notificaciones de mensajes',
        importance: Importance.high,
      );

  bool _initialized = false;
  String? _currentUid;

  Future<void> init() async {
    if (_initialized) return;
    // Initialize local notifications for foreground display
    try {
      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      final DarwinInitializationSettings iosInit =
          DarwinInitializationSettings();
      final InitializationSettings initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      await _localNotif.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) async {
          if (kDebugMode) {
            appLogger.d('[LocalNotif] tapped: ${response.payload}');
          }
        },
      );

      // Create Android channel
      await _localNotif
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);
    } catch (e) {
      if (kDebugMode) {
        appLogger.w('[LocalNotif] initialization failed: $e');
      }
    }

    // Request permission (iOS/macOS)
    await requestPermission();

    // Ensure we have an identity so tokens can be associated. If the app
    // doesn't have a signed-in user, sign in anonymously so tokens can be
    // persisted immediately and the user can receive notifications after
    // installing the app.
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        final cred = await FirebaseAuth.instance.signInAnonymously();
        if (kDebugMode) {
          appLogger.d('[FCM] signed in anonymously: ${cred.user?.uid}');
        }
        // store anon uid for potential migration later
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('anon_uid', cred.user?.uid ?? '');
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.w('[FCM] anonymous sign-in failed: $e');
      }
    }

    // Track current uid for sign-out cleanup
    _currentUid = FirebaseAuth.instance.currentUser?.uid;

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (kDebugMode) {
        appLogger.d('[FCM] onMessage: ${message.messageId}');
      }
      await showLocalNotificationFromRemote(message);
    });

    // Handle when user taps the notification (app in background -> opened)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        appLogger.d('[FCM] onMessageOpenedApp: ${message.messageId}');
      }
      // App-specific navigation can be triggered here by exposing a stream or callback
    });

    // Get token and persist to Firestore
    final token = await _fm.getToken();
    if (token != null) {
      if (kDebugMode) {
        appLogger.d('[FCM] got token: $token');
      }
      await _saveTokenToFirestore(token);
    }

    // Listen for token refresh
    _fm.onTokenRefresh.listen((newToken) async {
      if (kDebugMode) {
        appLogger.d('[FCM] token refreshed');
      }
      await _saveTokenToFirestore(newToken);
    });

    _initialized = true;

    // Listen for auth state changes: if user becomes a real (non-anon) user,
    // flush any pending tokens saved locally.
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      final previousUid = _currentUid;
      _currentUid = user?.uid;

      // If the user just signed out (user == null) remove this device token
      // from the previous user's token collection to avoid leaking tokens.
      if (previousUid != null && user == null) {
        await _removeTokenFromUid(previousUid);
      }

      // When user becomes a real (non-anon) user, flush any pending tokens
      if (user != null && !user.isAnonymous) {
        await _flushPendingTokensToUser(user.uid);
      }
    });
  }

  Future<void> requestPermission() async {
    try {
      final settings = await _fm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      if (kDebugMode) appLogger.d('[FCM] permission: $settings');
    } catch (e) {
      if (kDebugMode) appLogger.w('[FCM] permission request failed: $e');
    }
  }

  Future<void> showLocalNotificationFromRemote(RemoteMessage message) async {
    // Show local notification when the app is in foreground.
    try {
      final notif = message.notification;
      final title = notif?.title ?? message.data['title'] ?? 'Notificación';
      final body = notif?.body ?? message.data['body'] ?? '';
      if (kDebugMode) {
        appLogger.d(
          '[LocalNotif] foreground message - title: $title body: $body data: ${message.data}',
        );
      }

      // Android details
      final androidDetails = AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      );

      final iosDetails = DarwinNotificationDetails();

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await _localNotif.show(
        id,
        title,
        body,
        details,
        payload: message.data['messageId'],
      );
    } catch (e) {
      if (kDebugMode) {
        appLogger.w('[LocalNotif] error handling remote message: $e');
      }
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fm.subscribeToTopic(topic);
    } catch (e) {
      if (kDebugMode) {
        appLogger.w('[FCM] subscribeToTopic failed: $e');
      }
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fm.unsubscribeFromTopic(topic);
    } catch (e) {
      if (kDebugMode) {
        appLogger.w('[FCM] unsubscribeFromTopic failed: $e');
      }
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        // No uid available: persist token locally and flush later when
        // the user signs in.
        final prefs = await SharedPreferences.getInstance();
        final pending = prefs.getStringList('pending_fcm_tokens') ?? <String>[];
        if (!pending.contains(token)) {
          if (kDebugMode) {
            appLogger.d('[FCM] saving pending token: ${token.length} chars');
          }
          pending.add(token);
          await prefs.setStringList('pending_fcm_tokens', pending);
        }
        if (kDebugMode) {
          appLogger.d('[FCM] saved token pending for later');
        }
        return;
      }
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(token);
      await docRef.set({
        'token': token,
        'platform': Platform.operatingSystem,
        'device': Platform.operatingSystemVersion,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (kDebugMode) {
        appLogger.d(
          '[FCM] saved token to firestore for uid=$uid (len=${token.length})',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.w('[FCM] save token failed: $e');
      }
    }
  }

  Future<void> _flushPendingTokensToUser(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList('pending_fcm_tokens') ?? <String>[];
      if (pending.isEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      final col = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('fcmTokens');
      for (final t in pending) {
        final doc = col.doc(t);
        batch.set(doc, {
          'token': t,
          'platform': Platform.operatingSystem,
          'device': Platform.operatingSystemVersion,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeenAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
      await prefs.remove('pending_fcm_tokens');
      if (kDebugMode) {
        appLogger.d('[FCM] flushed ${pending.length} pending tokens to $uid');
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.w('[FCM] flush pending tokens failed: $e');
      }
    }
  }

  Future<void> _removeTokenFromUid(String uid) async {
    try {
      final token = await _fm.getToken();
      if (token == null || token.isEmpty) return;
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(token);
      final snap = await docRef.get();
      if (snap.exists) {
        await docRef.delete();
        if (kDebugMode) {
          appLogger.d('[FCM] removed token for uid=$uid');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.w('[FCM] remove token failed: $e');
      }
    }
  }
}
