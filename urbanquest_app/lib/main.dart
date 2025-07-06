import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'src/logic/auth_bloc/auth_bloc.dart';
import 'src/presentation/templates/app_template.dart';
import 'src/core/constants/app_colors.dart';
import 'src/core/services/pedometer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get Supabase configuration from environment or use defaults for development
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tbvjpjoqlsinlkoopnwg.supabase.co',
  );
  
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRidmpwam9xbHNpbmxrb29wbndnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyMDU0MTcsImV4cCI6MjA2Njc4MTQxN30.DKCEuwT_8u5-LasNJQX0vRmlASwYe1TPwHkbbt60hmA',
  );

  // Initialize Supabase with your project credentials
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  print('Supabase initialized successfully');

  // Initialize pedometer service and restore any previous tracking state
  try {
    await PedometerService().restoreTrackingState();
    print('Pedometer service initialized');
  } catch (e) {
    print('Failed to initialize pedometer service: $e');
  }

  runApp(const UrbanQuestApp());
}

// Global Supabase client instance
final supabase = Supabase.instance.client;

class UrbanQuestApp extends StatelessWidget {
  const UrbanQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'Urban Quest',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const AppTemplate(),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
