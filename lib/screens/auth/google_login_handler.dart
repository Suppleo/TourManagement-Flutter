import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../core/network/graphql_service.dart';
import 'package:go_router/go_router.dart';

class GoogleLoginHandler {
  static const _oauthUrl = 'https://62770dd4b1f0.ngrok-free.app/api/auth/google'; // sửa lại port nếu cần

  static Future<void> startGoogleLogin(BuildContext context) async {
    late StreamSubscription sub;

    try {
      // 1️⃣ Lắng nghe callback từ Google
      sub = linkStream.listen((String? link) async {
        if (link != null && link.contains('token=')) {
          final uri = Uri.parse(link);
          final token = uri.queryParameters['token'];

          if (token != null) {
            // 2️⃣ Tạo client mới với AuthLink
            final httpLink = HttpLink('http://172.27.145.10:4000/graphql');
            final authLink = AuthLink(getToken: () async => 'Bearer $token');
            final link = authLink.concat(httpLink);

            final newClient = GraphQLClient(
              cache: GraphQLCache(store: InMemoryStore()),
              link: link,
            );

            GraphQLService.clientNotifier.value = newClient;

            // 3️⃣ Gọi query me
            final result = await newClient.query(QueryOptions(
              document: gql(r'''
                query Me {
                  me {
                    id
                    email
                    role
                  }
                }
              '''),
              fetchPolicy: FetchPolicy.networkOnly,
            ));

            if (result.hasException) throw result.exception!;
            final user = User.fromJson(result.data!['me']);
            Provider.of<AuthProvider>(context, listen: false).setUser(user);

            // 4️⃣ Điều hướng về Home
            if (context.mounted) context.go('/home');
          }

          // ✅ Hủy lắng nghe sau khi hoàn tất
          await sub.cancel();
        }
      });

      // 5️⃣ Mở trình duyệt Google login
      final uri = Uri.parse(_oauthUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Không thể mở Google login');
      }
    } catch (e) {
      print('❌ Google login error: $e');
      await sub.cancel(); // tránh rò rỉ nếu lỗi
    }
  }
}
