import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../core/network/graphql_service.dart';
import '../graphql/queries/log_queries.dart';
import '../models/log.dart';

class LogProvider with ChangeNotifier {
  List<Log> _logs = [];
  List<Log> get logs => _logs;

  Future<void> fetchLogs() async {
    print('👉 Bắt đầu fetchLogs');

    try {
      final client = GraphQLService.clientNotifier?.value;
      if (client == null) {
        print('❌ GraphQL client chưa được khởi tạo.');
        throw Exception('GraphQL client chưa được khởi tạo');
      }

      final result = await client.query(
        QueryOptions(document: gql(queryLogs)),
      );

      if (result.hasException) {
        print('❌ GraphQL Exception: ${result.exception.toString()}');
        throw result.exception!;
      }

      final data = result.data;
      if (data == null || data['logs'] == null) {
        print('⚠ Không có dữ liệu logs');
        _logs = [];
      } else {
        print('✅ API trả dữ liệu: ${data['logs']}');
        _logs = (data['logs'] as List).map((e) => Log.fromJson(e)).toList();
      }

      notifyListeners();
    } catch (e) {
      print('❌ Lỗi khi fetchLogs: $e');
      rethrow;
    }
  }
}
