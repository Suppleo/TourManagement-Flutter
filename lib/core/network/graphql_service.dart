import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'api_config.dart';

class GraphQLService {
  static final ValueNotifier<GraphQLClient?> clientNotifier =
  ValueNotifier<GraphQLClient?>(null);

  /// Hàm khởi tạo và gán client vào clientNotifier
  static Future<void> initClient({String? token}) async {
    final client = createClient(token: token);
    clientNotifier.value = client;
  }

  /// Tạo một GraphQLClient mới (dùng cho login/logout)
  static GraphQLClient createClient({String? token}) {
    final httpLink = HttpLink(ApiConfig.graphqlUrl);

    Link link = httpLink;
    if (token != null && token.isNotEmpty) {
      final authLink = AuthLink(getToken: () async => 'Bearer $token');
      link = authLink.concat(httpLink);
    }

    return GraphQLClient(
      cache: GraphQLCache(store: InMemoryStore()),
      link: link,
    );
  }
}
