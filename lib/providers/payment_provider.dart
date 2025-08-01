import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../core/network/graphql_service.dart';
import '../graphql/queries/payment_queries.dart';
import '../models/payment.dart';

class PaymentProvider with ChangeNotifier {
  List<Payment> _payments = [];
  List<Payment> get payments => _payments;

  Future<void> fetchPayments() async {
    print('👉 Bắt đầu fetchPayments');

    try {
      final client = GraphQLService.clientNotifier?.value;
      if (client == null) {
        print('❌ GraphQL client chưa được khởi tạo.');
        throw Exception('GraphQL client chưa được khởi tạo');
      }

      final result = await client.query(
        QueryOptions(document: gql(queryPayments)),
      );

      if (result.hasException) {
        print('❌ GraphQL Exception: ${result.exception.toString()}');
        throw result.exception!;
      }

      final data = result.data;
      if (data == null || data['payments'] == null) {
        print('⚠ Không có dữ liệu payments');
        _payments = [];
      } else {
        print('✅ API trả dữ liệu: ${data['payments']}');
        _payments = (data['payments'] as List).map((e) => Payment.fromJson(e)).toList();
      }

      notifyListeners();
    } catch (e) {
      print('❌ Lỗi khi fetchPayments: $e');
      rethrow;
    }
  }
}
