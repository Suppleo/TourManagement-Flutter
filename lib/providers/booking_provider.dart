import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../core/network/graphql_service.dart';
import '../graphql/queries/booking_queries.dart';
import '../models/booking.dart';
import '../graphql/mutations/booking_mutations.dart';

class BookingProvider with ChangeNotifier {
  List<Booking> _bookings = [];
  List<Booking> get bookings => _bookings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<Booking?> fetchBookingById(String id) async {
    final client = GraphQLService.clientNotifier?.value;
    if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

    final result = await client.query(
      QueryOptions(
        document: gql(queryBookingById),
        variables: {'id': id},
      ),
    );

    if (result.hasException) throw result.exception!;
    return Booking.fromJson(result.data!['booking']);
  }

  /// 📥 Fetch tất cả booking (theo quyền user hiện tại)
  Future<void> fetchBookings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final client = GraphQLService.clientNotifier?.value;
      if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

      final result = await client.query(
        QueryOptions(document: gql(queryBookings)),
      );

      if (result.hasException) throw result.exception!;

      final data = result.data;
      if (data == null || data['bookings'] == null) {
        _bookings = [];
      } else {
        _bookings = (data['bookings'] as List)
            .map((e) => Booking.fromJson(e))
            .toList();
      }
    } catch (e) {
      print('❌ Lỗi khi fetchBookings: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔄 Cập nhật trạng thái hoặc thanh toán của 1 booking
  Future<void> updateBookingStatus(String id, String newStatus, {String? paymentStatus}) async {
    final client = GraphQLService.clientNotifier?.value;
    if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

    try {
      final result = await client.mutate(
        MutationOptions(
          document: gql(mutationUpdateBooking),
          variables: {
            'id': id,
            'status': newStatus,
            if (paymentStatus != null) 'paymentStatus': paymentStatus,
          },
        ),
      );

      if (result.hasException) throw result.exception!;

      final updated = Booking.fromJson(result.data!['updateBooking']);
      final index = _bookings.indexWhere((b) => b.id == id);
      if (index != -1) {
        _bookings[index] = _bookings[index].copyWith(
          status: updated.status,
          paymentStatus: updated.paymentStatus,
        );
        notifyListeners();
      }
    } catch (e) {
      print('❌ Lỗi updateBookingStatus: $e');
      rethrow;
    }
  }

  /// 🗑 Xoá 1 booking
  Future<void> deleteBooking(String id) async {
    final client = GraphQLService.clientNotifier?.value;
    if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

    try {
      final result = await client.mutate(
        MutationOptions(
          document: gql(mutationDeleteBooking),
          variables: {'id': id},
        ),
      );

      if (result.hasException) throw result.exception!;

      _bookings.removeWhere((b) => b.id == id);
      notifyListeners();
    } catch (e) {
      print('❌ Lỗi deleteBooking: $e');
      rethrow;
    }
  }

  /// 🔍 Lọc booking theo search, status, paymentStatus
  List<Booking> filterBookings({
    String search = '',
    String status = 'all',
    String paymentStatus = 'all',
  }) {
    return _bookings.where((b) {
      final matchesSearch = b.tour?.title.toLowerCase().contains(search.toLowerCase()) == true ||
          b.user?.email.toLowerCase().contains(search.toLowerCase()) == true;
      final matchesStatus = status == 'all' || b.status == status;
      final matchesPayment = paymentStatus == 'all' || b.paymentStatus == paymentStatus;
      return matchesSearch && matchesStatus && matchesPayment;
    }).toList();
  }
}
