import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
// // import 'package:lucide_icons_flutter/lucide_icons.dart';  // Comment out for now  // Comment out for now
import '../../atoms/custom_button.dart';
import '../../../logic/auth_bloc/auth_bloc.dart';
import '../../../core/constants/app_colors.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          print('AuthView: Auth state changed to ${state.runtimeType}');
          if (state is AuthSuccess) {
            print('AuthView: Auth success! User: ${state.user.email ?? "anonymous"}');
            // Let AppTemplate handle navigation - don't navigate directly!
            print('AuthView: Auth successful, AppTemplate should handle navigation');
          } else if (state is AuthFailure) {
            print('AuthView: Auth failure: ${state.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.secondary,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Dismiss',
                  textColor: AppColors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          } else if (state is AuthEmailConfirmationPending) {
            print('AuthView: Email confirmation pending for: ${state.email}');
          }
        },
        builder: (context, state) {
          // Show email confirmation screen if pending
          if (state is AuthEmailConfirmationPending) {
            return _buildEmailConfirmationScreen(state.email);
          }
          
          // Show normal auth screen
          return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.primaryGradient,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                    // Logo Section
                    _buildLogo()
                        .animate()
                        .fadeIn(duration: 800.ms)
                        .slideY(begin: -0.2, end: 0),

                    const SizedBox(height: 48),

                    // Auth Card
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.whiteOpacity20,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.whiteOpacity30,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blackOpacity10,
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            child: _buildAuthForm(theme),
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 800.ms, delay: 200.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 24),

                    // Guest Login Option
                    _buildGuestLogin()
                        .animate()
                        .fadeIn(duration: 800.ms, delay: 400.ms),

                    const SizedBox(height: 16),
          ],
                ),
              ),
            ),
          ),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.whiteOpacity20,
            border: Border.all(
              color: AppColors.whiteOpacity30,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.blackOpacity20,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.explore,
            size: 50,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Urban Quest',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.white,
                fontSize: 32,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Albania',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.whiteOpacity90,
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
        ),
      ],
    );
  }

  Widget _buildAuthForm(ThemeData theme) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isLoginMode ? 'Welcome Back!' : 'Join the Adventure!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isLoginMode
                  ? 'Ready to explore hidden gems and untold stories?'
                  : 'Create your account and start discovering Albania!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.whiteOpacity90,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Email Field
            TextFormField(
              controller: _emailController,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: AppColors.whiteOpacity90),
                prefixIcon: Icon(Icons.mail, color: AppColors.whiteOpacity80),
                hintText: 'explorer@gmail.com',
                hintStyle: TextStyle(color: AppColors.whiteOpacity60),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.whiteOpacity30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.white, width: 2),
                ),
                filled: true,
                fillColor: AppColors.whiteOpacity10,
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),

            // Password Field
            TextFormField(
              controller: _passwordController,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: AppColors.whiteOpacity90),
                prefixIcon: Icon(Icons.lock, color: AppColors.whiteOpacity80),
                hintText: '••••••••',
                hintStyle: TextStyle(color: AppColors.whiteOpacity60),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.whiteOpacity30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.white, width: 2),
                ),
                filled: true,
                fillColor: AppColors.whiteOpacity10,
              ),
              obscureText: true,
              enabled: !isLoading,
            ),
            const SizedBox(height: 24),

            // Submit Button
            CustomButton(
              text: _isLoginMode ? 'Start Exploring!' : 'Create Account',
              onPressed: isLoading ? null : _handleSubmit,
              isLoading: isLoading,
              isFullWidth: true,
              size: ButtonSize.large,
              icon: Icons.explore,
            ),
            const SizedBox(height: 16),

            // Toggle Mode
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      setState(() {
                        _isLoginMode = !_isLoginMode;
                      });
                    },
              child: Text(
                _isLoginMode
                    ? "Don't have an account? Sign up"
                    : 'Already have an account? Sign in',
                style: TextStyle(
                  color: AppColors.whiteOpacity90,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuestLogin() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return CustomButton(
          text: 'Continue as Guest',
          onPressed: isLoading ? null : _handleGuestLogin,
          variant: ButtonVariant.outline,
          icon: Icons.person,
        );
      },
    );
  }

  Widget _buildDebugButtons() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.blackOpacity20,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.whiteOpacity30),
              ),
              child: Column(
                children: [
                  const Text(
                    '🔧 Debug Tools',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Test Anonymous',
                          onPressed: isLoading ? null : () {
                            print('Debug: Testing anonymous auth...');
                            context.read<AuthBloc>().add(GuestLoginEvent());
                          },
                          variant: ButtonVariant.ghost,
                          size: ButtonSize.small,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomButton(
                          text: 'Test Register',
                          onPressed: isLoading ? null : () {
                            print('Debug: Testing registration...');
                            final testEmail = 'test${DateTime.now().millisecondsSinceEpoch}@urbanquest.com';
                            context.read<AuthBloc>().add(
                              RegisterEvent(email: testEmail, password: 'test123456'),
                            );
                          },
                          variant: ButtonVariant.ghost,
                          size: ButtonSize.small,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleSubmit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    print('AuthView: Submit button pressed - Login mode: $_isLoginMode');
    print('AuthView: Email: $email, Password length: ${password.length}');

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_isLoginMode) {
      print('AuthView: Sending LoginEvent to AuthBloc');
      context.read<AuthBloc>().add(LoginEvent(email: email, password: password));
    } else {
      print('AuthView: Sending RegisterEvent to AuthBloc');
      context.read<AuthBloc>().add(RegisterEvent(email: email, password: password));
    }
  }

  void _handleGuestLogin() {
    print('AuthView: Guest login button pressed');
    // Use anonymous authentication instead of demo account
    context.read<AuthBloc>().add(GuestLoginEvent());
  }

  Widget _buildEmailConfirmationScreen(String email) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.primaryGradient,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Section
                _buildLogo(),
                const SizedBox(height: 48),

                // Email Confirmation Card
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.whiteOpacity20,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.whiteOpacity30,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blackOpacity10,
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Email Icon
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.whiteOpacity20,
                                border: Border.all(
                                  color: AppColors.whiteOpacity30,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.mail_outline,
                                size: 40,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Title
                            Text(
                              'Check Your Email',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),

                            // Subtitle
                            Text(
                              'We sent a confirmation link to:',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.whiteOpacity90,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),

                            // Email
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.whiteOpacity10,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.whiteOpacity30),
                              ),
                              child: Text(
                                email,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Instructions
                            Text(
                              'Click the link in your email to confirm your account and start exploring.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.whiteOpacity90,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // Resend Button
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                final isLoading = state is AuthLoading;
                                return CustomButton(
                                  text: 'Resend Email',
                                  onPressed: isLoading ? null : () {
                                    context.read<AuthBloc>().add(
                                      ResendConfirmationEvent(email: email),
                                    );
                                  },
                                  isLoading: isLoading,
                                  variant: ButtonVariant.outline,
                                  icon: Icons.refresh,
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // Back to Sign In
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLoginMode = true;
                                });
                                context.read<AuthBloc>().add(AuthCheckRequested());
                              },
                              child: Text(
                                'Back to Sign In',
                                style: TextStyle(
                                  color: AppColors.whiteOpacity90,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
