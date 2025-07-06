import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/user_repository.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class SignUpEvent extends AuthEvent {
  final String email;
  final String password;
  final String? displayName;

  const SignUpEvent({
    required this.email, 
    required this.password,
    this.displayName,
  });

  @override
  List<Object> get props => [email, password, displayName ?? ''];
}

class RegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String? displayName;

  const RegisterEvent({
    required this.email, 
    required this.password,
    this.displayName,
  });

  @override
  List<Object> get props => [email, password, displayName ?? ''];
}

class GuestLoginEvent extends AuthEvent {}

class ResendConfirmationEvent extends AuthEvent {
  final String email;

  const ResendConfirmationEvent({required this.email});

  @override
  List<Object> get props => [email];
}

class LogoutEvent extends AuthEvent {}

class ProfileCreationRequested extends AuthEvent {
  final User user;
  final String? displayName;

  const ProfileCreationRequested({
    required this.user,
    this.displayName,
  });

  @override
  List<Object> get props => [user, displayName ?? ''];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final User user;
  final bool isNewUser;

  const AuthSuccess({
    required this.user,
    this.isNewUser = false,
  });

  @override
  List<Object> get props => [user, isNewUser];
}

class AuthEmailConfirmationPending extends AuthState {
  final String email;

  const AuthEmailConfirmationPending({required this.email});

  @override
  List<Object> get props => [email];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object> get props => [message];
}

class ProfileCreationInProgress extends AuthState {}

class ProfileCreationComplete extends AuthState {
  final User user;

  const ProfileCreationComplete({required this.user});

  @override
  List<Object> get props => [user];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserRepository _userRepository = UserRepository();

  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginEvent>(_onLogin);
    on<SignUpEvent>(_onSignUp);
    on<RegisterEvent>(_onRegister);
    on<GuestLoginEvent>(_onGuestLogin);
    on<ResendConfirmationEvent>(_onResendConfirmation);
    on<LogoutEvent>(_onLogout);
    on<ProfileCreationRequested>(_onProfileCreationRequested);

    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      
      print('AuthBloc: Auth state changed - Event: $event');
      
      if (session?.user != null && event != AuthChangeEvent.signedOut) {
        print('AuthBloc: User authenticated: ${session!.user.email}');
        
        // Check if user profile exists, create if not
        final userExists = await _userRepository.userExists(session.user.id);
        if (!userExists && event == AuthChangeEvent.signedIn) {
          // New user - trigger profile creation
          add(ProfileCreationRequested(user: session.user));
        } else {
        add(AuthCheckRequested());
        }
      } else if (event == AuthChangeEvent.signedOut) {
        print('AuthBloc: User signed out');
        emit(AuthInitial());
      }
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      print('AuthBloc: Checking current auth state...');
      
      final session = _supabase.auth.currentSession;
      final user = session?.user;
      
      if (user != null) {
        print('AuthBloc: Current user = ${user.email}');
        
        // Verify user profile exists in database
        final userExists = await _userRepository.userExists(user.id);
        if (!userExists) {
          print('AuthBloc: User profile missing, creating...');
          add(ProfileCreationRequested(user: user));
          return;
        }
        
        print('AuthBloc: User found, emitting AuthSuccess');
        emit(AuthSuccess(user: user));
      } else {
        print('AuthBloc: No user found, emitting AuthInitial');
        emit(AuthInitial());
      }
    } catch (e) {
      print('AuthBloc: Error checking auth state: $e');
      emit(AuthFailure(message: 'Authentication check failed: $e'));
    }
  }

  Future<void> _onLogin(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      print('AuthBloc: Attempting login with email: ${event.email}');
      emit(AuthLoading());

      final response = await _supabase.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );

      print('AuthBloc: Supabase response received');

      if (response.user != null) {
        print('AuthBloc: Login successful for user: ${response.user!.email}');
        
        // Verify user profile exists
        final userExists = await _userRepository.userExists(response.user!.id);
        if (!userExists) {
          print('AuthBloc: User profile missing, creating...');
          add(ProfileCreationRequested(user: response.user!));
        } else {
        emit(AuthSuccess(user: response.user!));
        }
      } else {
        print('AuthBloc: Login failed - no user in response');
        emit(const AuthFailure(message: 'Login failed. Please try again.'));
      }
    } on AuthException catch (e) {
      print('AuthBloc: Auth exception during login: ${e.message}');
      emit(AuthFailure(message: e.message));
    } catch (e) {
      print('AuthBloc: Unexpected error during login: $e');
      emit(AuthFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onSignUp(
    SignUpEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      print('AuthBloc: Attempting sign up with email: ${event.email}');
      emit(AuthLoading());

      final response = await _supabase.auth.signUp(
        email: event.email,
        password: event.password,
        data: event.displayName != null ? {
          'display_name': event.displayName,
        } : null,
      );

      print('AuthBloc: Sign up response received');

      if (response.user != null) {
        if (response.session != null) {
          // User is immediately signed in, create profile
          print('AuthBloc: Sign up successful and user logged in: ${response.user!.email}');
          add(ProfileCreationRequested(
            user: response.user!,
            displayName: event.displayName,
          ));
        } else {
          // Email confirmation required
          print('AuthBloc: Sign up successful, email confirmation required');
          emit(AuthEmailConfirmationPending(email: event.email));
        }
      } else {
        print('AuthBloc: Sign up failed - no user in response');
        emit(const AuthFailure(message: 'Sign up failed. Please try again.'));
      }
    } on AuthException catch (e) {
      print('AuthBloc: Auth exception during sign up: ${e.message}');
      emit(AuthFailure(message: e.message));
    } catch (e) {
      print('AuthBloc: Unexpected error during sign up: $e');
      emit(AuthFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onRegister(
    RegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    // RegisterEvent is handled the same as SignUpEvent
    add(SignUpEvent(
        email: event.email,
        password: event.password,
      displayName: event.displayName,
    ));
  }

  Future<void> _onGuestLogin(
    GuestLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      print('AuthBloc: Attempting guest login');
      emit(AuthLoading());

      // Generate a unique guest email
      final guestEmail = 'guest_${DateTime.now().millisecondsSinceEpoch}@urbanquest.app';
      final guestPassword = 'guest_password_${DateTime.now().millisecondsSinceEpoch}';

      final response = await _supabase.auth.signUp(
        email: guestEmail,
        password: guestPassword,
        data: {
          'display_name': 'Guest Explorer',
          'is_guest': true,
        },
      );

      if (response.user != null) {
        print('AuthBloc: Guest login successful');
        add(ProfileCreationRequested(
          user: response.user!,
          displayName: 'Guest Explorer',
        ));
      } else {
        emit(const AuthFailure(message: 'Guest login failed. Please try again.'));
      }
    } on AuthException catch (e) {
      print('AuthBloc: Auth exception during guest login: ${e.message}');
      emit(AuthFailure(message: e.message));
    } catch (e) {
      print('AuthBloc: Unexpected error during guest login: $e');
      emit(AuthFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onResendConfirmation(
    ResendConfirmationEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      print('AuthBloc: Resending confirmation email to: ${event.email}');
      emit(AuthLoading());

      await _supabase.auth.resend(
        type: OtpType.signup,
        email: event.email,
      );

      print('AuthBloc: Confirmation email resent successfully');
      emit(AuthEmailConfirmationPending(email: event.email));
    } on AuthException catch (e) {
      print('AuthBloc: Auth exception during resend: ${e.message}');
      emit(AuthFailure(message: e.message));
    } catch (e) {
      print('AuthBloc: Unexpected error during resend: $e');
      emit(AuthFailure(message: 'Failed to resend confirmation email: $e'));
    }
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      print('AuthBloc: Attempting logout');
      emit(AuthLoading());

      await _supabase.auth.signOut();
      
      print('AuthBloc: Logout successful');
      emit(AuthInitial());
    } catch (e) {
      print('AuthBloc: Error during logout: $e');
      emit(AuthFailure(message: 'Failed to logout: $e'));
    }
  }

  Future<void> _onProfileCreationRequested(
    ProfileCreationRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      print('AuthBloc: Creating user profile for: ${event.user.email}');
      emit(ProfileCreationInProgress());

      final success = await _userRepository.createUserProfile(
        userId: event.user.id,
        email: event.user.email!,
        displayName: event.displayName ?? 
                    event.user.userMetadata?['display_name'] ?? 
                    event.user.email!.split('@').first,
      );

      if (success) {
        print('AuthBloc: Profile created successfully');
        emit(AuthSuccess(user: event.user, isNewUser: true));
      } else {
        print('AuthBloc: Profile creation failed');
        emit(const AuthFailure(message: 'Failed to create user profile. Please try again.'));
      }
    } catch (e) {
      print('AuthBloc: Error creating profile: $e');
      emit(AuthFailure(message: 'Failed to create user profile: $e'));
    }
  }
}
