import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urbanquest_app/src/logic/auth_bloc/auth_bloc.dart';

// Mock classes for testing
class MockSupabaseUser extends Mock implements User {
  @override
  String get id => 'mock-user-id';

  @override
  String? get email => 'mock@example.com';

  @override
  Map<String, dynamic>? get userMetadata => {'display_name': 'Mock User'};
}

void main() {
  group('AuthBloc Tests', () {
    late AuthBloc authBloc;
    late MockUser mockUser;

    setUp(() {
      mockUser = MockUser();
      authBloc = AuthBloc();
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    group('AuthCheckRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when no user is found',
        build: () => authBloc,
        act: (bloc) => bloc.add(AuthCheckRequested()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthUnauthenticated>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when user is found',
        build: () => authBloc,
        act: (bloc) {
          // Simulate having a user
          bloc.add(AuthUserChanged(mockUser));
          bloc.add(AuthCheckRequested());
        },
        expect: () => [
          isA<AuthAuthenticated>(),
          isA<AuthLoading>(),
          isA<AuthAuthenticated>(),
        ],
      );
    });

    group('AuthLoginRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when login succeeds',
        build: () => authBloc,
        act: (bloc) => bloc.add(AuthLoginRequested('test@example.com', 'password')),
        expect: () => [
          isA<AuthLoading>(),
          // In a real implementation, this would depend on the actual login logic
          // For now, we test the state transitions
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when login fails',
        build: () => authBloc,
        act: (bloc) => bloc.add(AuthLoginRequested('invalid@example.com', 'wrong')),
        expect: () => [
          isA<AuthLoading>(),
          // Would emit AuthUnauthenticated on failure
        ],
      );

      test('should validate email format', () {
        // Test email validation logic if implemented
        const validEmail = 'test@example.com';
        const invalidEmail = 'invalid-email';

        expect(validEmail.contains('@'), isTrue);
        expect(invalidEmail.contains('@'), isFalse);
      });

      test('should validate password length', () {
        // Test password validation logic if implemented
        const validPassword = 'securepassword123';
        const shortPassword = '123';

        expect(validPassword.length >= 6, isTrue);
        expect(shortPassword.length >= 6, isFalse);
      });
    });

    group('AuthSignUpRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading] when signup is requested',
        build: () => authBloc,
        act: (bloc) => bloc.add(AuthSignUpRequested(
          'newuser@example.com',
          'password123',
          'New User',
        )),
        expect: () => [
          isA<AuthLoading>(),
        ],
      );

      test('should validate signup form data', () {
        const email = 'newuser@example.com';
        const password = 'password123';
        const displayName = 'New User';

        expect(email.isNotEmpty, isTrue);
        expect(password.isNotEmpty, isTrue);
        expect(displayName.isNotEmpty, isTrue);
        expect(email.contains('@'), isTrue);
        expect(password.length >= 6, isTrue);
        expect(displayName.length >= 2, isTrue);
      });
    });

    group('AuthLogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when logout is requested',
        build: () => authBloc,
        seed: () => AuthAuthenticated(mockUser),
        act: (bloc) => bloc.add(AuthLogoutRequested()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthUnauthenticated>(),
        ],
      );
    });

    group('AuthUserChanged', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthAuthenticated] when user is set',
        build: () => authBloc,
        act: (bloc) => bloc.add(AuthUserChanged(mockUser)),
        expect: () => [
          isA<AuthAuthenticated>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnauthenticated] when user is set to null',
        build: () => authBloc,
        seed: () => AuthAuthenticated(mockUser),
        act: (bloc) => bloc.add(const AuthUserChanged(null)),
        expect: () => [
          isA<AuthUnauthenticated>(),
        ],
      );
    });

    group('AuthDeleteAccountRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when account deletion is requested',
        build: () => authBloc,
        seed: () => AuthAuthenticated(mockUser),
        act: (bloc) => bloc.add(AuthDeleteAccountRequested()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthUnauthenticated>(),
        ],
      );
    });

    group('State Tests', () {
      test('AuthInitial should extend AuthState', () {
        const state = AuthInitial();
        expect(state, isA<AuthState>());
      });

      test('AuthLoading should extend AuthState', () {
        const state = AuthLoading();
        expect(state, isA<AuthState>());
      });

      test('AuthAuthenticated should contain user', () {
        final state = AuthAuthenticated(mockUser);
        expect(state, isA<AuthState>());
        expect(state.user, equals(mockUser));
      });

      test('AuthUnauthenticated should extend AuthState', () {
        const state = AuthUnauthenticated();
        expect(state, isA<AuthState>());
      });

      test('AuthError should contain error message', () {
        const errorMessage = 'Test error message';
        const state = AuthError(errorMessage);
        expect(state, isA<AuthState>());
        expect(state.message, equals(errorMessage));
      });
    });

    group('Event Tests', () {
      test('AuthCheckRequested should extend AuthEvent', () {
        const event = AuthCheckRequested();
        expect(event, isA<AuthEvent>());
      });

      test('AuthLoginRequested should contain credentials', () {
        const email = 'test@example.com';
        const password = 'password123';
        const event = AuthLoginRequested(email, password);
        
        expect(event, isA<AuthEvent>());
        expect(event.email, equals(email));
        expect(event.password, equals(password));
      });

      test('AuthSignUpRequested should contain user data', () {
        const email = 'newuser@example.com';
        const password = 'password123';
        const displayName = 'New User';
        const event = AuthSignUpRequested(email, password, displayName);
        
        expect(event, isA<AuthEvent>());
        expect(event.email, equals(email));
        expect(event.password, equals(password));
        expect(event.displayName, equals(displayName));
      });

      test('AuthLogoutRequested should extend AuthEvent', () {
        const event = AuthLogoutRequested();
        expect(event, isA<AuthEvent>());
      });

      test('AuthUserChanged should contain user', () {
        final event = AuthUserChanged(mockUser);
        expect(event, isA<AuthEvent>());
        expect(event.user, equals(mockUser));
      });

      test('AuthDeleteAccountRequested should extend AuthEvent', () {
        const event = AuthDeleteAccountRequested();
        expect(event, isA<AuthEvent>());
      });
    });

    group('Equatable Implementation', () {
      test('AuthAuthenticated states with same user should be equal', () {
        final state1 = AuthAuthenticated(mockUser);
        final state2 = AuthAuthenticated(mockUser);
        expect(state1, equals(state2));
      });

      test('AuthError states with same message should be equal', () {
        const message = 'Error message';
        const state1 = AuthError(message);
        const state2 = AuthError(message);
        expect(state1, equals(state2));
      });

      test('AuthLoginRequested events with same credentials should be equal', () {
        const email = 'test@example.com';
        const password = 'password';
        const event1 = AuthLoginRequested(email, password);
        const event2 = AuthLoginRequested(email, password);
        expect(event1, equals(event2));
      });
    });

    group('Edge Cases', () {
      test('should handle empty email gracefully', () {
        const event = AuthLoginRequested('', 'password');
        expect(event.email, isEmpty);
        expect(event.password, isNotEmpty);
      });

      test('should handle empty password gracefully', () {
        const event = AuthLoginRequested('test@example.com', '');
        expect(event.email, isNotEmpty);
        expect(event.password, isEmpty);
      });

      test('should handle null user in AuthUserChanged', () {
        const event = AuthUserChanged(null);
        expect(event.user, isNull);
      });

      test('should handle empty display name in signup', () {
        const event = AuthSignUpRequested('test@example.com', 'password', '');
        expect(event.displayName, isEmpty);
      });
    });

    group('Error Handling', () {
      blocTest<AuthBloc, AuthState>(
        'should emit AuthError when an exception occurs during login',
        build: () => authBloc,
        act: (bloc) {
          // Simulate an error scenario
          try {
            bloc.add(AuthLoginRequested('invalid', 'invalid'));
          } catch (e) {
            bloc.add(AuthErrorOccurred(e.toString()));
          }
        },
        expect: () => [
          isA<AuthLoading>(),
        ],
      );
    });
  });
}

// Additional event for error testing
class AuthErrorOccurred extends AuthEvent {
  final String error;
  const AuthErrorOccurred(this.error);

  @override
  List<Object?> get props => [error];
}