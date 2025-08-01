import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // 👈 Dùng để mở Stripe URL
import '../../../graphql/mutations/payment_mutations.dart'; // file chứa mutationCheckout

class CheckoutScreen extends StatelessWidget {
  final String bookingId;

  const CheckoutScreen({super.key, required this.bookingId});

  Future<void> _startCheckout(BuildContext context) async {
    final client = GraphQLProvider.of(context).value;

    final result = await client.mutate(MutationOptions(
      document: gql(mutationCheckout),
      variables: {
        'bookingId': bookingId,
        'method': 'Stripe', // 👈 Chỉ hỗ trợ Stripe hiện tại
      },
    ));

    if (result.hasException) {
      final error = result.exception.toString();
      print('❌ Checkout error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi thanh toán: $error')),
      );
      return;
    }

    final data = result.data?['checkout'];
    final payUrl = data?['payUrl'];
    final paymentId = data?['payment']?['id'];

    if (payUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không lấy được URL thanh toán')),
      );
      return;
    }

    print('✅ payUrl: $payUrl');
    // 👉 Mở trình duyệt để thanh toán
    if (await canLaunchUrl(Uri.parse(payUrl))) {
      await launchUrl(Uri.parse(payUrl), mode: LaunchMode.externalApplication);
    } else {
      throw 'Không thể mở URL: $payUrl';
    }

    // 👇 Sau thanh toán xong, frontend sẽ xử lý tiếp (ở trang success/cancel)
    // Có thể quay lại app và xác nhận payment tại đó nếu cần.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _startCheckout(context),
          child: const Text('Thanh toán ngay'),
        ),
      ),
    );
  }
}
