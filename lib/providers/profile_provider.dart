import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../models/profile.dart';
import '../core/network/graphql_service.dart';
import '../graphql/queries/profile_queries.dart';
import '../graphql/mutations/profile_mutations.dart';

class ProfileProvider with ChangeNotifier {
  Profile? _profile;
  Profile? get profile => _profile;

  GraphQLClient? get _client => GraphQLService.clientNotifier.value;

  /// Lấy hồ sơ của chính mình
  Future<void> fetchMyProfile() async {
    final client = _client;
    if (client == null) {
      debugPrint('❌ fetchMyProfile Error: GraphQL client is null');
      return;
    }

    try {
      final result = await client.query(QueryOptions(
        document: gql(getMyProfileQuery),
        fetchPolicy: FetchPolicy.networkOnly,
      ));

      if (!result.hasException && result.data?['getMyProfile'] != null) {
        _profile = Profile.fromJson(result.data!['getMyProfile']);
        notifyListeners();
      } else {
        debugPrint('❌ fetchMyProfile Error: ${result.exception}');
      }
    } catch (e) {
      debugPrint('❌ fetchMyProfile Exception: $e');
    }
  }

  /// Tạo hồ sơ mới
  Future<bool> createProfile(String userId, Profile p) async {
    final client = _client;
    if (client == null) return false;

    try {
      final result = await client.mutate(MutationOptions(
        document: gql(createProfileMutation),
        variables: {
          'userId': userId,
          'input': _toInput(p),
        },
      ));

      if (!result.hasException && result.data?['createProfile'] != null) {
        _profile = Profile.fromJson(result.data!['createProfile']);
        notifyListeners();
        return true;
      } else {
        debugPrint('❌ createProfile Error: ${result.exception}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ createProfile Exception: $e');
      return false;
    }
  }

  /// Cập nhật hồ sơ hiện tại
  Future<bool> updateMyProfile(Profile p) async {
    final client = _client;
    if (client == null) return false;

    try {
      final result = await client.mutate(MutationOptions(
        document: gql(updateMyProfileMutation),
        variables: {'input': _toInput(p)},
      ));

      if (!result.hasException && result.data?['updateMyProfile'] != null) {
        _profile = Profile.fromJson(result.data!['updateMyProfile']);
        notifyListeners();
        return true;
      } else {
        debugPrint('❌ updateMyProfile Error: ${result.exception}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ updateMyProfile Exception: $e');
      return false;
    }
  }

  /// Xóa hồ sơ
  Future<bool> deleteMyProfile() async {
    final client = _client;
    if (client == null) return false;

    try {
      final result = await client.mutate(MutationOptions(
        document: gql(deleteMyProfileMutation),
      ));

      if (!result.hasException && result.data?['deleteMyProfile'] == true) {
        _profile = null;
        notifyListeners();
        return true;
      } else {
        debugPrint('❌ deleteMyProfile Error: ${result.exception}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ deleteMyProfile Exception: $e');
      return false;
    }
  }

  /// Xóa dữ liệu profile hiện tại khi logout
  void resetProfile() {
    _profile = null;
    notifyListeners();
  }

  Map<String, dynamic> _toInput(Profile p) {
    return {
      'fullName': p.fullName,
      'gender': p.gender,
      'dob': p.dob,
      'address': p.address,
      'avatar': p.avatar,
      'identityNumber': p.identityNumber,
      'issuedDate': p.issuedDate,
      'issuedPlace': p.issuedPlace,
      'nationality': p.nationality,
      'emergencyContact': p.emergencyContact?.toJson(),
    };
  }
}
