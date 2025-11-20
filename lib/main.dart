import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ✅ Añadir esta línea
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';

import 'screens/login_screen.dart';
import 'screens/index_screen.dart';
import 'screens/document_list_screen.dart';
import 'screens/document_screen.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:entredos/theme/theme.dart';
import 'package:flutter/services.dart'; // ✅ Importación necesaria para orientación

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Bloquear orientación solo vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // register background handler for FCM
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // initialize notification service (gets token, requests permissions)
  await NotificationService().init();
  print('✅ Firebase inicializado correctamente');

  await FlutterDownloader.initialize(debug: true);

  runApp(EntreDosApp());
}

class EntreDosApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EntreDos',
      theme: theme,
      debugShowCheckedModeBanner: false,
      // 🗣️ Localización en español
      locale: const Locale('es', 'ES'),
      supportedLocales: [const Locale('es', 'ES')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: FirebaseAuth.instance.currentUser == null
          ? LoginScreen()
          : IndexScreen(),
    );
  }
}
