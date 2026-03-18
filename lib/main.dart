import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/app_state.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/notification_parser.dart';
import 'services/sync_service.dart';
import 'screens/home_screen.dart';

bool firebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
  } catch (e) {
    debugPrint('Firebase 未配置，云端同步功能不可用: $e');
  }
  runApp(const AutoBookkeeperApp());
}

class AutoBookkeeperApp extends StatelessWidget {
  const AutoBookkeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();
    final notificationService = NotificationService();
    final parser = NotificationParser();
    final syncService = SyncService(dbService);

    return ChangeNotifierProvider(
      create: (_) => AppState(
        dbService: dbService,
        notificationService: notificationService,
        parser: parser,
        syncService: syncService,
      )..initialize(),
      child: MaterialApp(
        title: '自动记账',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF1677FF),
          useMaterial3: true,
          brightness: Brightness.light,
          cardTheme: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!),
            ),
          ),
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: const Color(0xFF1677FF),
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
