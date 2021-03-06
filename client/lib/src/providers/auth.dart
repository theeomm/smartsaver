import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql/client.dart';
import 'package:smartsaver/src/gql/auth.graphql.dart';
import 'package:smartsaver/src/providers/client.dart';

enum AuthState {
  unauthenticated,
  authenticated,
  authenticating,
  failed,
}

// Authentication State
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>(
    (ref) => AuthStateNotifier(ref.read));

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier(this.reader) : super(AuthState.unauthenticated);
  Reader reader;

  void logout() {
    // Remove JWT
    reader(gqlClientProvider.notifier).removeAuthToken();
    state = AuthState.unauthenticated;
  }

  Future<void> login(Variables$Mutation$Login params) async {
    if (params.email.isEmpty || params.password.isEmpty) {
      state = AuthState.failed;
      return;
    }
    state = AuthState.authenticating;

    final client = reader(gqlClientProvider);
    final notifier = reader(gqlClientProvider.notifier);
    final result = await client.mutate(
      MutationOptions(
        document: queryDocumentLogin,
        variables: {
          "email": params.email,
          "password": params.password,
        },
      ),
    );

    if (result.hasException) {
      state = AuthState.failed;
      throw result.exception?.graphqlErrors.first.message ?? "Unknown Error";
    }

    if (result.data != null) {
      final data = Mutation$Login.fromJson(result.data!);
      // Set JWT Token
      notifier.addAuthToken(data.tokenAuth!.token);
      state = AuthState.authenticated;
    } else {
      state = AuthState.failed;
    }
  }
}
