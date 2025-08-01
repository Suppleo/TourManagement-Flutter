import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../core/network/graphql_service.dart';
import '../graphql/queries/voucher_queries.dart';
import '../graphql/mutations/voucher_mutations.dart';
import '../models/voucher.dart';

class VoucherProvider with ChangeNotifier {
  List<Voucher> _vouchers = [];
  bool _isLoading = false;
  String? _error;

  List<Voucher> get vouchers => _vouchers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Fetch danh sách tất cả vouchers từ server
  Future<void> fetchVouchers() async {
    try {
      _setLoading(true);
      _setError(null);

      final client = GraphQLService.clientNotifier?.value;
      if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

      final result = await client.query(
        QueryOptions(
          document: gql(queryVouchers),
          fetchPolicy: FetchPolicy.networkOnly, // Luôn fetch từ server
        ),
      );

      if (result.hasException) {
        debugPrint('❌ Lỗi fetch: ${result.exception}');
        throw result.exception!;
      }

      final List<dynamic> voucherData = result.data!['vouchers'] as List? ?? [];
      _vouchers = voucherData.map((e) => Voucher.fromJson(e)).toList();

      debugPrint('📦 Số lượng voucher: ${_vouchers.length}');
      _setError(null);
    } catch (e) {
      debugPrint('❌ Exception in fetchVouchers: $e');
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Tạo voucher mới
  Future<Voucher> createVoucher(Map<String, dynamic> input) async {
    try {
      _setError(null);

      final client = GraphQLService.clientNotifier?.value;
      if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

      final result = await client.mutate(
        MutationOptions(
          document: gql(mutationCreateVoucher),
          variables: input,
        ),
      );

      if (result.hasException) {
        debugPrint('❌ Lỗi tạo voucher: ${result.exception}');
        throw result.exception!;
      }

      final voucherData = result.data?['createVoucher'];
      if (voucherData != null) {
        final newVoucher = Voucher.fromJson(voucherData);
        _vouchers.add(newVoucher);
        notifyListeners();
        return newVoucher;
      } else {
        // Fallback: fetch lại toàn bộ danh sách
        await fetchVouchers();
        throw Exception('Không thể tạo voucher');
      }
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  /// Cập nhật voucher
  Future<Voucher> updateVoucher(String id, Map<String, dynamic> input) async {
    try {
      _setError(null);

      final client = GraphQLService.clientNotifier?.value;
      if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

      final result = await client.mutate(
        MutationOptions(
          document: gql(mutationUpdateVoucher),
          variables: {'id': id, ...input},
        ),
      );

      if (result.hasException) {
        debugPrint('❌ Lỗi cập nhật voucher: ${result.exception}');
        throw result.exception!;
      }

      final voucherData = result.data?['updateVoucher'];
      if (voucherData != null) {
        final updatedVoucher = Voucher.fromJson(voucherData);
        final index = _vouchers.indexWhere((v) => v.id == id);

        if (index != -1) {
          _vouchers[index] = updatedVoucher;
          notifyListeners();
          debugPrint('✅ Đã cập nhật voucher ${updatedVoucher.code}');
          return updatedVoucher;
        } else {
          // Nếu không tìm thấy trong danh sách local, fetch lại
          await fetchVouchers();
          throw Exception('Voucher không tồn tại trong danh sách local');
        }
      } else {
        throw Exception('Không nhận được dữ liệu voucher sau khi cập nhật');
      }
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  /// Xoá voucher
  Future<bool> deleteVoucher(String id) async {
    try {
      _setError(null);

      // Tìm voucher trước khi xóa để log
      final voucherToDelete = _vouchers.firstWhere(
            (v) => v.id == id,
        orElse: () => throw Exception('Voucher không tồn tại'),
      );

      debugPrint('🗑️ Đang xóa voucher: ${voucherToDelete.code} (ID: $id)');

      final client = GraphQLService.clientNotifier?.value;
      if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

      final result = await client.mutate(
        MutationOptions(
          document: gql(mutationDeleteVoucher),
          variables: {'id': id},
        ),
      );

      if (result.hasException) {
        debugPrint('❌ Lỗi xoá voucher: ${result.exception}');
        throw result.exception!;
      }

      // Kiểm tra kết quả xóa
      final deleteResult = result.data?['deleteVoucher'];
      debugPrint('📋 Kết quả xóa từ server: $deleteResult');

      if (deleteResult == true) {
        // Xóa khỏi danh sách local
        final beforeCount = _vouchers.length;
        _vouchers.removeWhere((v) => v.id == id);
        final afterCount = _vouchers.length;

        debugPrint('📊 Vouchers trước xóa: $beforeCount, sau xóa: $afterCount');

        if (beforeCount > afterCount) {
          notifyListeners();
          debugPrint('✅ Đã xóa voucher ${voucherToDelete.code} thành công');
          return true;
        } else {
          debugPrint('⚠️ Voucher không được xóa khỏi danh sách local');
          // Force refresh nếu local update không thành công
          await fetchVouchers();
          return true;
        }
      } else {
        throw Exception('Server không xác nhận việc xóa voucher');
      }
    } catch (e) {
      debugPrint('❌ Exception in deleteVoucher: $e');
      _setError(e.toString());
      rethrow;
    }
  }

  /// Tìm voucher theo ID
  Voucher? getVoucherById(String id) {
    try {
      return _vouchers.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Lọc voucher theo trạng thái
  List<Voucher> getVouchersByStatus(String status) {
    return _vouchers.where((v) => v.status == status).toList();
  }

  /// Clear tất cả dữ liệu
  void clear() {
    _vouchers.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
