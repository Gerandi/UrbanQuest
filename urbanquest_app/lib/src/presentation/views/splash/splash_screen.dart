import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/auth_bloc/auth_bloc.dart';
import '../../../core/constants/app_colors.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';  // Comment out for now

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    print('SplashScreen: Initializing app...');
    
    // Add a splash duration for user to appreciate the design
    await Future.delayed(const Duration(seconds: 2));
    
    print('SplashScreen: Delay completed, checking if mounted...');
    
    if (mounted) {
      print('SplashScreen: Widget is mounted, triggering AuthCheckRequested...');
      context.read<AuthBloc>().add(AuthCheckRequested());
    } else {
      print('SplashScreen: Widget is not mounted, skipping auth check');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Just log the state changes, let AppTemplate handle navigation
        print('SplashScreen: AuthState changed to ${state.runtimeType}');
      },
      child: Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
              colors: AppColors.primaryGradient,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with animation
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                    color: AppColors.whiteOpacity20,
                ),
                child: const Icon(
                  Icons.explore,
                  size: 60,
                    color: AppColors.white,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scale(duration: 800.ms, curve: Curves.elasticOut)
                  .then()
                  .rotate(duration: 2000.ms, curve: Curves.easeInOut),

              const SizedBox(height: 32),

              // App Name
              const Text(
                'Urban Quest',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                    color: AppColors.white,
                  letterSpacing: -1,
                ),
              )
                  .animate()
                  .fadeIn(duration: 1000.ms, delay: 500.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 16),

              // Tagline
              const Text(
                'Discover • Explore • Adventure',
                style: TextStyle(
                  fontSize: 18,
                    color: AppColors.white,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
              ),
              )
                  .animate()
                  .fadeIn(duration: 1000.ms, delay: 1000.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 48),

              // Loading indicator
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                    backgroundColor: AppColors.whiteOpacity30,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
                  minHeight: 3,
                ),
              )
                  .animate()
                  .fadeIn(duration: 800.ms, delay: 1500.ms)
                  .scaleX(begin: 0, end: 1),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
