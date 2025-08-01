import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../graphql/mutations/payment_mutations.dart';
import '../../../core/network/graphql_service.dart';

class StripeCheckoutWebView extends StatefulWidget {
  final String payUrl;
  final String paymentId;

  const StripeCheckoutWebView({
    super.key,
    required this.payUrl,
    required this.paymentId,
  });

  @override
  State<StripeCheckoutWebView> createState() => _StripeCheckoutWebViewState();
}

class _StripeCheckoutWebViewState extends State<StripeCheckoutWebView> {
  bool isConfirming = false;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) async {
            final url = request.url;

            if (url.contains('payment-success?session_id=')) {
              final uri = Uri.parse(url);
              final sessionId = uri.queryParameters['session_id'];

              if (sessionId != null && !isConfirming) {
                setState(() => isConfirming = true);

                final confirmed = await _confirmPayment(sessionId);
                if (confirmed) {
                  Navigator.of(context).pop(true); // Trả về kết quả thành công
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('❌ Xác nhận thanh toán thất bại')),
                  );
                  Navigator.of(context).pop(false);
                }
              }

              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.payUrl));
  }

  Future<bool> _confirmPayment(String sessionId) async {
    try {
      final client = GraphQLService.clientNotifier.value;
      if (client == null) throw Exception('GraphQL client chưa được khởi tạo');

      final result = await client.mutate(MutationOptions(
        document: gql(mutationConfirmPayment),
        variables: {
          'paymentId': widget.paymentId,
          'transactionId': sessionId,
        },
      ));

      if (result.hasException) {
        print('❌ confirmPayment error: ${result.exception}');
        return false;
      }

      print('✅ confirmPayment success!');
      return true;
    } catch (e) {
      print('❌ Exception trong confirmPayment: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán Stripe'),
        actions: [
          if (isConfirming)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
        ],
      ),

      // ✅ Thêm dòng này để không bị chèn nội dung WebView khi bàn phím bật hoặc có bottom bar
      resizeToAvoidBottomInset: false,

      // ✅ SafeArea đảm bảo WebView không bị che bởi bottom nav
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
