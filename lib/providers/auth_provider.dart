import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../core/network/graphql_service.dart';
import '../graphql/mutations/auth_mutations.dart';
import '../graphql/queries/auth_queries.dart';
import '../models/user.dart';
import 'profile_provider.dart';
import 'package:provider/provider.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;

  User? get user => _user;
  String? get token => _token;

  Future<void> login(String email, String password) async {
    final client = GraphQLService.clientNotifier.value;
    if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

    final result = await client.mutate(MutationOptions(
      document: gql(mutationLogin),
      variables: {'email': email, 'password': password},
      fetchPolicy: FetchPolicy.noCache,
    ));

    if (result.hasException) throw result.exception!;

    final data = result.data?['login'];
    _token = data['token'];
    _user = User.fromJson(data['user']);

    GraphQLService.clientNotifier.value =
        GraphQLService.createClient(token: _token);

    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    _user = null;
    _token = null;

    // Reset GraphQL client
    GraphQLService.clientNotifier.value = GraphQLService.createClient();

    // ✅ Reset profile provider
    try {
      final profileProvider = context.read<ProfileProvider>();
      profileProvider.resetProfile();
    } catch (e) {
      debugPrint('[Logout] Warning: Không thể reset ProfileProvider: $e');
    }

    notifyListeners();
  }

  Future<void> loadMe() async {
    final client = GraphQLService.clientNotifier.value;
    if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

    final result = await client.query(
      QueryOptions(document: gql(queryMe)),
    );

    if (result.hasException) throw result.exception!;

    _user = User.fromJson(result.data!['me']);
    notifyListeners();
  }

  Future<void> setUser(User user, {String? token}) async {
    _user = user;
    if (token != null) {
      _token = token;
      GraphQLService.clientNotifier.value =
          GraphQLService.createClient(token: token);
    }
    notifyListeners();
  }
}
