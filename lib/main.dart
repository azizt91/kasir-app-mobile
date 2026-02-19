import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Import
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/main_page.dart';
import 'injection_container.dart' as di;

import 'features/product/presentation/bloc/product_bloc.dart';
import 'features/stock/presentation/bloc/stock_bloc.dart';
import 'features/pos/presentation/bloc/pos_bloc.dart';
import 'features/receivable/presentation/bloc/receivable_bloc.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/notification/presentation/bloc/notification_bloc.dart'; // Import
import 'features/notification/presentation/bloc/notification_event.dart'; // Import
import 'features/history/presentation/pages/history_page.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import
import 'core/theme/app_theme.dart'; // Import Theme

import 'package:intl/date_symbol_data_local.dart'; // Import for date formatting
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

import 'package:flutter/services.dart'; // Import for SystemChrome
import 'package:firebase_core/firebase_core.dart'; // Import Firebase
import 'core/services/notification_service.dart'; // Import NotificationService
// import 'firebase_options.dart'; // Removed because user uses google-services.json

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set Status Bar Style (White/Transparent with Dark Icons)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Transparent to let background user color show (or use Colors.white)
    statusBarIconBrightness: Brightness.dark, // Dark icons for light background
    statusBarBrightness: Brightness.light, // For iOS (Dark icons)
  ));
  
  // Initialize Database for Desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Error loading .env file: $e");
    // Fallback: Initialize with empty env to prevent crash when accessing dotenv.env
    dotenv.testLoad(fileInput: '');
  }
  await di.init();
  await initializeDateFormatting('id_ID', null); // Initialize Locale
  
  // Initialize Notifications
  // We use google-services.json, so no need for DefaultFirebaseOptions usually.
  try {
     await Firebase.initializeApp(); 
     await NotificationService().initialize();
  } catch (e) {
     debugPrint("Firebase initialization failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider(
          create: (_) => di.sl<ProductBloc>(),
        ),
        BlocProvider(
          create: (_) => di.sl<StockBloc>(),
        ),
        BlocProvider(
          create: (_) => di.sl<PosBloc>(),
        ),
        BlocProvider(
          create: (_) => di.sl<ReceivableBloc>(),
        ),
        BlocProvider(
          create: (_) => di.sl<DashboardBloc>(),
        ),
        BlocProvider(
          create: (_) => di.sl<NotificationBloc>()..add(LoadNotifications()),
        ),
      ],
      child: MaterialApp(
        title: 'Kasir App Mobile',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light, // Force Light Mode for Contoh_UI consistency
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('id', 'ID'),
        ],
        home: const AuthWrapper(),
        routes: {
          '/history': (context) => const HistoryPage(),
          // Add other routes here if needed
        },
      ),
    );
  }
}
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          // Trigger Sync on initial load if needed
          context.read<ProductBloc>().add(SyncProducts()); // ENABLED
          
          return const MainPage();
        }
        return const LoginPage();
      },
    );
  }
}
