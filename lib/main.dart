import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'app.dart';
import 'core/network/graphql_service.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/tour_provider.dart';
import 'providers/review_provider.dart';
import 'providers/voucher_provider.dart';
import 'providers/category_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/log_provider.dart';
import 'providers/profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GraphQLService.initClient(); // Khởi tạo client ban đầu (có thể null)

  runApp(MyBootstrap());
}

class MyBootstrap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GraphQLClient?>(
      valueListenable: GraphQLService.clientNotifier,
      builder: (context, client, _) {
        if (client == null) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return GraphQLProvider(
          client: ValueNotifier(client),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthProvider()),
              ChangeNotifierProvider(create: (_) => BookingProvider()),
              ChangeNotifierProvider(create: (_) => TourProvider()),
              ChangeNotifierProvider(create: (_) => ReviewProvider()),
              ChangeNotifierProvider(create: (_) => VoucherProvider()),
              ChangeNotifierProvider(create: (_) => CategoryProvider()),
              ChangeNotifierProvider(create: (_) => PaymentProvider()),
              ChangeNotifierProvider(create: (_) => LogProvider()),
              ChangeNotifierProvider(create: (_) => ProfileProvider()),
            ],
            child: const MyApp(),
          ),
        );
      },
    );
  }
}
