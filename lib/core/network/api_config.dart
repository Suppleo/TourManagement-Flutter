import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get graphqlUrl => 'http://10.0.2.2:4000/graphql';
  static String get uploadUrl => 'http://10.0.2.2:4000/api/upload';
  static String get staticBaseUrl => 'http://10.0.2.2:4000/uploads/';
}
